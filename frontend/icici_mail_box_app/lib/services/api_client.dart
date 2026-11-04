import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dashboard_summary.dart';
import '../models/app_user.dart';
import '../models/admin_user.dart';
import '../models/audit_log.dart';
import '../models/master_option.dart';
import '../models/shipment.dart';

class ApiClient {
  ApiClient({http.Client? httpClient, FlutterSecureStorage? secureStorage})
    : _httpClient = httpClient ?? http.Client(),
      _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _baseUrlKey = 'api_base_url';
  static const _accessTokenKey = 'access_token';
  static const _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5053',
  );
  static const uiPreviewEnabled = bool.fromEnvironment(
    'ENABLE_UI_PREVIEW',
    defaultValue: false,
  );
  static bool _previewMode = false;
  static bool get previewMode => _previewMode;
  static AppUser? _previewUser;
  static List<Shipment> _previewShipments = _createPreviewShipments();
  static List<AdminUser> _previewUsers = _createPreviewUsers();
  static List<MasterOption> _previewBranches = [
    const MasterOption(id: 1, code: 'MUM', name: 'Mumbai Hub'),
    const MasterOption(id: 2, code: 'DEL', name: 'Delhi Hub'),
    const MasterOption(id: 3, code: 'BLR', name: 'Bengaluru Branch'),
    const MasterOption(id: 4, code: 'MAA', name: 'Chennai Branch'),
  ];
  static const List<MasterOption> _previewCustomers = [
    MasterOption(id: 1, code: 'DEMO-001', name: 'Demo Corporate Services'),
    MasterOption(id: 2, code: 'DEMO-002', name: 'Demo Retail Operations'),
    MasterOption(id: 3, code: 'DEMO-003', name: 'Demo Treasury Office'),
    MasterOption(id: 4, code: 'DEMO-004', name: 'Demo External Sender'),
  ];
  static const List<MasterOption> _previewCategories = [
    MasterOption(id: 1, code: 'DOC', name: 'Confidential documents'),
    MasterOption(id: 2, code: 'IT', name: 'IT equipment'),
    MasterOption(id: 3, code: 'CARD', name: 'Banking cards'),
    MasterOption(id: 4, code: 'KIT', name: 'Branch operations kit'),
    MasterOption(id: 5, code: 'OTHER', name: 'Other parcel'),
  ];
  static final Map<int, List<ShipmentEvent>> _previewEvents = {};
  static final List<AuditLog> _previewAudit = _createPreviewAudit();
  static int _nextPreviewShipmentId = 21;
  static int _nextPreviewBranchId = 5;
  static int _nextPreviewUserId = 6;

  final http.Client _httpClient;
  final FlutterSecureStorage _secureStorage;

  static void startPreviewSession(AppUser user) {
    _previewMode = true;
    _previewUser = user;
  }

  static void endPreviewSession() {
    _previewMode = false;
    _previewUser = null;
  }

  Future<void> saveBaseUrl(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_baseUrlKey, _normalizeBaseUrl(value));
  }

  Future<String> getBaseUrl() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_baseUrlKey) ?? _defaultBaseUrl;
  }

  Future<DashboardSummary> getDashboardSummary() async {
    if (_previewMode) return _previewDashboardSummary();
    final response = await _get('/api/dashboard/summary');

    return DashboardSummary.fromJson(_jsonMap(response));
  }

  Future<List<BranchShipmentSummary>> getBranchShipmentSummary() async {
    if (_previewMode) return _previewBranchSummaries();
    final response = await _get('/api/dashboard/branches');
    return _jsonList(response)
        .map(BranchShipmentSummary.fromJson)
        .toList(growable: false);
  }

  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    if (_previewMode) {
      throw ApiException('Exit preview mode before using live sign-in.');
    }

    final response = await _send(
      'POST',
      '/api/auth/login',
      body: {'username': username, 'password': password},
      expectedStatusCodes: const {200},
    );
    final result = LoginResult.fromJson(_jsonMap(response));
    await saveAccessToken(result.accessToken);
    return result;
  }

  Future<AppUser> getCurrentUser() async {
    if (_previewMode && _previewUser != null) return _previewUser!;
    final response = await _get('/api/auth/me');
    return AppUser.fromJson(_jsonMap(response));
  }

  Future<bool> hasAccessToken() async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<List<MasterOption>> getBranches() async {
    if (_previewMode) return _previewBranches;
    final response = await _get('/api/masters/branches');
    return _jsonList(response)
        .map((item) => MasterOption.fromJson(item))
        .toList(growable: false);
  }

  Future<List<MasterOption>> getCustomers() async {
    if (_previewMode) return _previewCustomers;
    final response = await _get('/api/masters/customers');
    return _jsonList(response)
        .map((item) => MasterOption.fromJson(item))
        .toList(growable: false);
  }

  Future<List<MasterOption>> getPackageCategories() async {
    if (_previewMode) return _previewCategories;
    final response = await _get('/api/masters/package-categories');
    return _jsonList(response)
        .map((item) => MasterOption.fromJson(item))
        .toList(growable: false);
  }

  Future<List<AdminUser>> getUsers() async {
    if (_previewMode) return List.unmodifiable(_previewUsers);
    final response = await _get('/api/users');
    return _jsonList(response).map(AdminUser.fromJson).toList(growable: false);
  }

  Future<List<AuditLog>> getAuditLogs() async {
    if (_previewMode) return List.unmodifiable(_previewAudit);
    final response = await _get('/api/audit');
    return _jsonList(response).map(AuditLog.fromJson).toList(growable: false);
  }

  Future<void> createBranchOperator({
    required String username,
    required String displayName,
    required String password,
    required int branchId,
  }) async {
    if (_previewMode) {
      _previewUsers = [
        ..._previewUsers,
        AdminUser(
          userId: _nextPreviewUserId++,
          username: username,
          displayName: displayName,
          isActive: true,
          roleName: 'BranchOperator',
          branchId: branchId,
          branchName: _previewBranchName(branchId),
        ),
      ];
      _addPreviewAudit(
        'Create',
        'User',
        username,
        'Preview operator account created.',
      );
      return;
    }

    await _send(
      'POST',
      '/api/users',
      body: {
        'username': username,
        'displayName': displayName,
        'password': password,
        'roleName': 'BranchOperator',
        'branchId': branchId,
      },
      expectedStatusCodes: const {201},
    );
  }

  Future<void> setUserActive(int userId, bool isActive) async {
    if (_previewMode) {
      _previewUsers = _previewUsers
          .map(
            (user) => user.userId == userId
                ? AdminUser(
                    userId: user.userId,
                    username: user.username,
                    displayName: user.displayName,
                    isActive: isActive,
                    roleName: user.roleName,
                    branchId: user.branchId,
                    branchName: user.branchName,
                  )
                : user,
          )
          .toList();
      _addPreviewAudit(
        'SetActive',
        'User',
        '$userId',
        isActive ? 'Activated' : 'Deactivated',
      );
      return;
    }

    await _send(
      'PATCH',
      '/api/users/$userId/active',
      body: {'isActive': isActive},
      expectedStatusCodes: const {204},
    );
  }

  Future<void> createBranch({
    required String branchCode,
    required String branchName,
    required String city,
  }) async {
    if (_previewMode) {
      final branchId = _nextPreviewBranchId++;
      _previewBranches = [
        ..._previewBranches,
        MasterOption(
          id: branchId,
          code: branchCode,
          name: '$branchName · $city',
        ),
      ];
      _addPreviewAudit('Create', 'Branch', '$branchId', branchName);
      return;
    }

    await _send(
      'POST',
      '/api/branches',
      body: {'branchCode': branchCode, 'branchName': branchName, 'city': city},
      expectedStatusCodes: const {201},
    );
  }

  Future<List<Shipment>> getShipments({
    String? direction,
    String? search,
    String? status,
    int? branchId,
    DateTime? fromUtc,
    DateTime? toUtc,
    int? limit,
  }) async {
    if (_previewMode) {
      final user = _previewUser;
      final shipments = _previewShipments.where((shipment) {
        final branchMatches =
            user == null ||
            user.isMaster ||
            (shipment.direction == 'Inbound'
                ? shipment.destinationBranchId == user.branchId
                : shipment.originBranchId == user.branchId);
        final date =
            shipment.receivedUtc ?? shipment.sentUtc ?? shipment.createdUtc;
        return branchMatches &&
            (direction == null || shipment.direction == direction) &&
            (status == null || shipment.status == status) &&
            (branchId == null ||
                shipment.originBranchId == branchId ||
                shipment.destinationBranchId == branchId) &&
            (fromUtc == null || !date.isBefore(fromUtc)) &&
            (toUtc == null ||
                !date.isAfter(toUtc.add(const Duration(days: 1)))) &&
            (search == null ||
                search.trim().isEmpty ||
                _previewShipmentMatches(shipment, search.trim()));
      }).toList()..sort((a, b) => b.createdUtc.compareTo(a.createdUtc));
      return shipments.take(limit ?? 500).toList(growable: false);
    }

    final response = await _get(
      '/api/shipments',
      queryParameters: {
        ...?_optionalParameter('direction', direction),
        ...?_optionalParameter(
          'search',
          search == null || search.trim().isEmpty ? null : search.trim(),
        ),
        ...?_optionalParameter('status', status),
        ...?_optionalParameter('branchId', branchId?.toString()),
        ...?_optionalParameter('fromUtc', fromUtc?.toUtc().toIso8601String()),
        ...?_optionalParameter('toUtc', toUtc?.toUtc().toIso8601String()),
        ...?_optionalParameter('limit', limit?.toString()),
      },
    );

    return _jsonList(response)
        .map((item) => Shipment.fromJson(item))
        .toList(growable: false);
  }

  Future<String> getShipmentsCsv({
    String? direction,
    String? search,
    String? status,
    int? branchId,
    DateTime? fromUtc,
    DateTime? toUtc,
    int? limit,
  }) async {
    if (_previewMode) {
      final shipments = await getShipments(
        direction: direction,
        search: search,
        status: status,
        branchId: branchId,
        fromUtc: fromUtc,
        toUtc: toUtc,
        limit: limit,
      );
      final rows = <List<String>>[
        [
          'Tracking number',
          'Direction',
          'Sender',
          'Origin branch',
          'Destination branch',
          'Recipient',
          'Category',
          'Weight kg',
          'Status',
          'Created UTC',
        ],
        for (final shipment in shipments)
          [
            shipment.trackingNumber,
            shipment.direction,
            shipment.senderName ?? shipment.customerName,
            shipment.originBranchName,
            shipment.destinationBranchName,
            shipment.recipientName,
            shipment.packageCategoryName,
            shipment.packageWeightKg?.toStringAsFixed(3) ?? '',
            shipment.status,
            shipment.createdUtc.toUtc().toIso8601String(),
          ],
      ];
      return rows.map((row) => row.map(_csv).join(',')).join('\n');
    }

    final response = await _get(
      '/api/shipments/export',
      queryParameters: {
        ...?_optionalParameter('direction', direction),
        ...?_optionalParameter(
          'search',
          search == null || search.trim().isEmpty ? null : search.trim(),
        ),
        ...?_optionalParameter('status', status),
        ...?_optionalParameter('branchId', branchId?.toString()),
        ...?_optionalParameter('fromUtc', fromUtc?.toUtc().toIso8601String()),
        ...?_optionalParameter('toUtc', toUtc?.toUtc().toIso8601String()),
        ...?_optionalParameter('limit', limit?.toString()),
      },
    );
    return response.body;
  }

  Future<Shipment> createShipment(CreateShipmentRequest request) async {
    if (_previewMode) {
      final now = DateTime.now();
      final origin = _previewBranches.firstWhere(
        (branch) => branch.id == request.originBranchId,
      );
      final destination = _previewBranches.firstWhere(
        (branch) => branch.id == request.destinationBranchId,
      );
      final customer = _previewCustomers.firstWhere(
        (item) => item.id == request.customerId,
      );
      final category = _previewCategories.firstWhere(
        (item) => item.id == request.packageCategoryId,
      );
      final shipment = Shipment(
        shipmentId: _nextPreviewShipmentId++,
        direction: request.direction,
        trackingNumber: request.trackingNumber,
        customerId: request.customerId,
        customerName: customer.name,
        senderName: request.senderName,
        originBranchId: request.originBranchId,
        originBranchName: origin.name,
        destinationBranchId: request.destinationBranchId,
        destinationBranchName: destination.name,
        packageCategoryId: request.packageCategoryId,
        packageCategoryName: category.name,
        packageWeightKg: request.packageWeightKg,
        packageDescription: request.packageDescription,
        recipientName: request.recipientName,
        recipientAddress: request.recipientAddress,
        courierServiceProvider: request.courierServiceProvider,
        remarks: request.remarks,
        status: 'Pending',
        receivedUtc: request.receivedUtc,
        sentUtc: request.sentUtc,
        createdByName: _previewUser?.displayName ?? 'Preview User',
        isDemo: true,
        createdUtc: now,
        updatedUtc: now,
      );
      _previewShipments = [shipment, ..._previewShipments];
      _addPreviewAudit(
        'Create',
        'Shipment',
        '${shipment.shipmentId}',
        'Preview shipment created.',
      );
      return shipment;
    }

    final response = await _send(
      'POST',
      '/api/shipments',
      body: request.toJson(),
      expectedStatusCodes: const {201},
    );
    return Shipment.fromJson(_jsonMap(response));
  }

  Future<List<ShipmentEvent>> getShipmentEvents(int shipmentId) async {
    if (_previewMode) {
      return List.unmodifiable(
        _previewEvents[shipmentId] ??
            [
              ShipmentEvent(
                shipmentEventId: shipmentId,
                eventType: 'Created',
                previousStatus: null,
                newStatus: 'Pending',
                eventDescription: 'Preview shipment created.',
                eventUtc: DateTime.now(),
                changedByName: _previewUser?.displayName ?? 'Preview User',
              ),
            ],
      );
    }

    final response = await _get('/api/shipments/$shipmentId/events');
    return _jsonList(response)
        .map(ShipmentEvent.fromJson)
        .toList(growable: false);
  }

  Future<void> updateShipmentStatus({
    required int shipmentId,
    required String status,
  }) async {
    if (_previewMode) {
      final index = _previewShipments.indexWhere(
        (item) => item.shipmentId == shipmentId,
      );
      if (index < 0) throw ApiException('Shipment not found in preview data.');
      final old = _previewShipments[index];
      final updated = _copyWithStatus(old, status);
      _previewShipments[index] = updated;
      final events = _previewEvents.putIfAbsent(shipmentId, () => []);
      events.insert(
        0,
        ShipmentEvent(
          shipmentEventId: events.length + 1,
          eventType: 'StatusChanged',
          previousStatus: old.status,
          newStatus: status,
          eventDescription: 'Status changed in UI preview.',
          eventUtc: DateTime.now(),
          changedByName: _previewUser?.displayName ?? 'Preview User',
        ),
      );
      _addPreviewAudit(
        'UpdateStatus',
        'Shipment',
        '$shipmentId',
        '${old.status} to $status',
      );
      return;
    }

    await _send(
      'PATCH',
      '/api/shipments/$shipmentId/status',
      body: {
        'status': status,
        'eventDescription':
            'Status changed from the ICICI Mail Box application.',
      },
      expectedStatusCodes: const {204},
    );
  }

  DashboardSummary _previewDashboardSummary() {
    final user = _previewUser;
    final scopedShipments = _previewShipments.where((shipment) {
      if (user == null || user.isMaster) return true;
      return shipment.direction == 'Inbound'
          ? shipment.destinationBranchId == user.branchId
          : shipment.originBranchId == user.branchId;
    }).toList();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool isToday(Shipment shipment) {
      final date = shipment.receivedUtc ?? shipment.sentUtc;
      return date != null &&
          !date.isBefore(today) &&
          date.isBefore(today.add(const Duration(days: 1)));
    }

    return DashboardSummary(
      totalShipments: scopedShipments.length,
      totalInbound: scopedShipments
          .where((s) => s.direction == 'Inbound')
          .length,
      totalOutbound: scopedShipments
          .where((s) => s.direction == 'Outbound')
          .length,
      pendingShipments: scopedShipments
          .where((s) => s.status == 'Pending')
          .length,
      inTransitShipments: scopedShipments
          .where((s) => s.status == 'InTransit')
          .length,
      deliveredShipments: scopedShipments
          .where((s) => s.status == 'Delivered')
          .length,
      receivedToday: scopedShipments
          .where((s) => s.direction == 'Inbound' && isToday(s))
          .length,
      dispatchedToday: scopedShipments
          .where((s) => s.direction == 'Outbound' && isToday(s))
          .length,
      activeBranches: user?.isMaster == true ? _previewBranches.length : 1,
      activeOperators: user?.isMaster == true
          ? _previewUsers
                .where((u) => u.roleName == 'BranchOperator' && u.isActive)
                .length
          : 1,
    );
  }

  List<BranchShipmentSummary> _previewBranchSummaries() => [
    for (final branch in _previewBranches)
      () {
        final shipments = _previewShipments.where((shipment) {
          return shipment.direction == 'Inbound'
              ? shipment.destinationBranchId == branch.id
              : shipment.originBranchId == branch.id;
        });
        final list = shipments.toList();
        return BranchShipmentSummary(
          branchId: branch.id,
          branchCode: branch.code,
          branchName: branch.name,
          totalShipments: list.length,
          inboundShipments: list.where((s) => s.direction == 'Inbound').length,
          outboundShipments: list
              .where((s) => s.direction == 'Outbound')
              .length,
          pendingShipments: list.where((s) => s.status == 'Pending').length,
          deliveredShipments: list.where((s) => s.status == 'Delivered').length,
        );
      }(),
  ];

  static String _previewBranchName(int? branchId) =>
      _previewBranches
          .where((branch) => branch.id == branchId)
          .map((branch) => branch.name)
          .firstOrNull ??
      'Unknown branch';

  static bool _previewShipmentMatches(Shipment shipment, String query) {
    final normalized = query.toLowerCase();
    return shipment.trackingNumber.toLowerCase().contains(normalized) ||
        (shipment.senderName ?? '').toLowerCase().contains(normalized) ||
        shipment.customerName.toLowerCase().contains(normalized) ||
        shipment.recipientName.toLowerCase().contains(normalized) ||
        shipment.originBranchName.toLowerCase().contains(normalized) ||
        shipment.destinationBranchName.toLowerCase().contains(normalized);
  }

  static void _addPreviewAudit(
    String action,
    String entityType,
    String entityId,
    String detail,
  ) {
    _previewAudit.insert(
      0,
      AuditLog(
        auditLogId: _previewAudit.length + 1,
        username: _previewUser?.username,
        displayName: _previewUser?.displayName,
        action: action,
        entityType: entityType,
        entityId: entityId,
        detail: detail,
        occurredUtc: DateTime.now(),
      ),
    );
  }

  static String _csv(String value) => '"${value.replaceAll('"', '""')}"';

  static Shipment _copyWithStatus(Shipment shipment, String status) => Shipment(
    shipmentId: shipment.shipmentId,
    direction: shipment.direction,
    trackingNumber: shipment.trackingNumber,
    customerId: shipment.customerId,
    customerName: shipment.customerName,
    senderName: shipment.senderName,
    originBranchId: shipment.originBranchId,
    originBranchName: shipment.originBranchName,
    destinationBranchId: shipment.destinationBranchId,
    destinationBranchName: shipment.destinationBranchName,
    packageCategoryId: shipment.packageCategoryId,
    packageCategoryName: shipment.packageCategoryName,
    packageWeightKg: shipment.packageWeightKg,
    packageDescription: shipment.packageDescription,
    recipientName: shipment.recipientName,
    recipientAddress: shipment.recipientAddress,
    courierServiceProvider: shipment.courierServiceProvider,
    remarks: shipment.remarks,
    status: status,
    receivedUtc: shipment.receivedUtc,
    sentUtc: shipment.sentUtc,
    createdByName: shipment.createdByName,
    isDemo: shipment.isDemo,
    createdUtc: shipment.createdUtc,
    updatedUtc: DateTime.now(),
  );

  static List<AdminUser> _createPreviewUsers() => const [
    AdminUser(
      userId: 1,
      username: 'ho.admin',
      displayName: 'Head Office Administrator',
      isActive: true,
      roleName: 'MasterUser',
    ),
    AdminUser(
      userId: 2,
      username: 'mumbai.operator',
      displayName: 'Mumbai Branch Operator',
      isActive: true,
      roleName: 'BranchOperator',
      branchId: 1,
      branchName: 'Mumbai Hub',
    ),
    AdminUser(
      userId: 3,
      username: 'delhi.operator',
      displayName: 'Delhi Branch Operator',
      isActive: true,
      roleName: 'BranchOperator',
      branchId: 2,
      branchName: 'Delhi Hub',
    ),
    AdminUser(
      userId: 4,
      username: 'bengaluru.operator',
      displayName: 'Bengaluru Branch Operator',
      isActive: true,
      roleName: 'BranchOperator',
      branchId: 3,
      branchName: 'Bengaluru Branch',
    ),
    AdminUser(
      userId: 5,
      username: 'chennai.operator',
      displayName: 'Chennai Branch Operator',
      isActive: true,
      roleName: 'BranchOperator',
      branchId: 4,
      branchName: 'Chennai Branch',
    ),
  ];

  static List<AuditLog> _createPreviewAudit() => [
    for (var index = 0; index < 3; index++)
      AuditLog(
        auditLogId: index + 1,
        username: 'ho.admin',
        displayName: 'Head Office Administrator',
        action: index == 0 ? 'UpdateStatus' : 'Create',
        entityType: 'Shipment',
        entityId: 'ICICI-DEMO-${1001 + index}',
        detail: index == 0 ? 'InTransit to Delivered' : 'Demo shipment seeded.',
        occurredUtc: DateTime.now().subtract(Duration(hours: index + 2)),
      ),
  ];

  static List<Shipment> _createPreviewShipments() {
    const branchNames = {
      1: 'Mumbai Hub',
      2: 'Delhi Hub',
      3: 'Bengaluru Branch',
      4: 'Chennai Branch',
    };
    const senderNames = [
      'Aarav Sharma',
      'Priya Nair',
      'Rohan Mehta',
      'Ananya Iyer',
      'ICICI Head Office',
      'Neha Kapoor',
      'Vikram Rao',
      'Demo Corporate Services',
      'Kavita Shah',
      'Arjun Menon',
    ];
    const recipientNames = [
      'Mumbai Records Desk',
      'Delhi Operations Team',
      'Bengaluru IT Desk',
      'Chennai Branch Manager',
      'Head Office Compliance',
      'Retail Services Team',
      'Treasury Operations',
      'Customer Service Desk',
      'Branch Audit Team',
      'Card Operations',
    ];
    const descriptions = [
      'Confidential account opening documents',
      'Replacement card packet',
      'Encrypted laptop accessory',
      'Branch operations supply kit',
      'Compliance correspondence',
      'Customer KYC file',
      'Secure token device',
      'Signed audit documents',
      'ATM service component',
      'Priority banking welcome kit',
    ];
    const categoryIds = [1, 3, 2, 4, 1, 1, 2, 1, 2, 5];
    const statuses = [
      'Delivered',
      'InTransit',
      'Pending',
      'Delivered',
      'Pending',
      'InTransit',
      'Delivered',
      'Cancelled',
      'Pending',
      'Delivered',
    ];
    const customer = _previewCustomers;
    const categories = _previewCategories;
    final now = DateTime.now();
    return [
      for (var index = 0; index < 20; index++)
        () {
          final inbound = index < 10;
          final itemIndex = index % 10;
          final destinationId = inbound
              ? 1 + itemIndex % 4
              : 1 + (itemIndex + 1) % 4;
          final originId = inbound
              ? 1 + (itemIndex + 1) % 4
              : 1 + itemIndex % 4;
          final recorded = now.subtract(Duration(days: itemIndex + 1));
          final customerOption = customer[itemIndex % customer.length];
          final categoryOption = categories[categoryIds[itemIndex] - 1];
          return Shipment(
            shipmentId: index + 1,
            direction: inbound ? 'Inbound' : 'Outbound',
            trackingNumber: 'ICICI-DEMO-${1001 + index}',
            customerId: customerOption.id,
            customerName: customerOption.name,
            senderName: senderNames[itemIndex],
            originBranchId: originId,
            originBranchName: branchNames[originId]!,
            destinationBranchId: destinationId,
            destinationBranchName: branchNames[destinationId]!,
            packageCategoryId: categoryOption.id,
            packageCategoryName: categoryOption.name,
            packageWeightKg: 0.25 + itemIndex * 0.42,
            packageDescription: descriptions[itemIndex],
            recipientName: recipientNames[itemIndex],
            recipientAddress: '${branchNames[destinationId]} mail desk',
            courierServiceProvider: itemIndex.isEven
                ? 'ICICI Internal Logistics'
                : 'SecureExpress',
            remarks: 'DEMO RECORD · sample data for interface preview',
            status: statuses[itemIndex],
            receivedUtc: inbound ? recorded : null,
            sentUtc: inbound ? null : recorded,
            createdByName: inbound
                ? 'Mumbai Branch Operator'
                : 'Head Office Administrator',
            isDemo: true,
            createdUtc: recorded,
            updatedUtc: recorded,
          );
        }(),
    ];
  }

  Future<http.Response> _get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl$path')
        .replace(queryParameters: queryParameters);
    final headers = await _headers();
    final response = await _sendRequest(
      () => _httpClient
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15)),
      baseUrl,
    );

    _ensureSuccess(response, const {200});
    return response;
  }

  Future<http.Response> _send(
    String method,
    String path, {
    required Map<String, dynamic> body,
    required Set<int> expectedStatusCodes,
  }) async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers(includeJsonContentType: true);
    final payload = jsonEncode(body);

    final response = await _sendRequest(
      () => switch (method) {
        'POST' => _httpClient.post(uri, headers: headers, body: payload),
        'PATCH' => _httpClient.patch(uri, headers: headers, body: payload),
        _ => throw UnsupportedError('Unsupported HTTP method: $method'),
      },
      baseUrl,
    );

    _ensureSuccess(response, expectedStatusCodes);
    return response;
  }

  Future<http.Response> _sendRequest(
    Future<http.Response> Function() request,
    String baseUrl,
  ) async {
    try {
      return await request();
    } on http.ClientException {
      throw ApiException(
        'Cannot connect to the API at $baseUrl. Check that the API is running and the URL is correct.',
      );
    } on TimeoutException {
      throw ApiException(
        'The API at $baseUrl did not respond in time. Check the server and try again.',
      );
    }
  }

  Future<Map<String, String>> _headers({
    bool includeJsonContentType = false,
  }) async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    return {
      'Accept': 'application/json',
      if (includeJsonContentType) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _jsonMap(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw ApiException('The API returned an invalid JSON response.');
    }
  }

  List<Map<String, dynamic>> _jsonList(http.Response response) {
    try {
      return (jsonDecode(response.body) as List<dynamic>)
          .cast<Map<String, dynamic>>();
    } on FormatException {
      throw ApiException('The API returned an invalid JSON response.');
    }
  }

  void _ensureSuccess(http.Response response, Set<int> expectedStatusCodes) {
    if (expectedStatusCodes.contains(response.statusCode)) {
      return;
    }

    var message = 'Request failed (${response.statusCode}).';
    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      message =
          payload['detail'] as String? ??
          payload['title'] as String? ??
          message;
    } on FormatException {
      // Non-JSON errors still receive a useful HTTP-status message.
    }

    throw ApiException(message, statusCode: response.statusCode);
  }

  static String _normalizeBaseUrl(String value) {
    final normalized = value.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(normalized);
    if (normalized.isEmpty ||
        uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty) {
      throw ApiException(
        'Enter a complete API URL, such as http://localhost:5053.',
      );
    }

    return normalized;
  }

  Future<void> saveAccessToken(String token) =>
      _secureStorage.write(key: _accessTokenKey, value: token);

  Future<void> clearSession() => _secureStorage.delete(key: _accessTokenKey);
}

Map<String, String>? _optionalParameter(String key, String? value) =>
    value == null ? null : {key: value};

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
