import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/master_option.dart';
import '../models/shipment.dart';
import '../services/api_client.dart';

class ShipmentScreen extends StatefulWidget {
  const ShipmentScreen({required this.direction, super.key});

  final String direction;

  @override
  State<ShipmentScreen> createState() => _ShipmentScreenState();
}

class _ShipmentScreenState extends State<ShipmentScreen> {
  final _apiClient = ApiClient();
  final _formKey = GlobalKey<FormState>();
  final _trackingController = TextEditingController();
  final _weightController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _recipientAddressController = TextEditingController();
  final _searchController = TextEditingController();

  List<MasterOption> _branches = const [];
  List<MasterOption> _customers = const [];
  List<Shipment> _shipments = const [];
  int? _customerId;
  int? _originBranchId;
  int? _destinationBranchId;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isSubmitting = false;
  DateTime _handlingTime = DateTime.now();

  bool get _isInbound => widget.direction == 'Inbound';

  String get _title => '${widget.direction} shipments';

  bool get _canSubmit =>
      !_isLoading &&
      !_isSubmitting &&
      _errorMessage == null &&
      _customers.isNotEmpty &&
      _branches.length >= 2;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _trackingController.dispose();
    _weightController.dispose();
    _recipientNameController.dispose();
    _recipientAddressController.dispose();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait<Object>([
        _apiClient.getBranches(),
        _apiClient.getCustomers(),
        _apiClient.getShipments(direction: widget.direction),
      ]);
      final branches = results[0] as List<MasterOption>;
      final customers = results[1] as List<MasterOption>;
      final shipments = results[2] as List<Shipment>;

      if (!mounted) {
        return;
      }

      setState(() {
        _branches = branches;
        _customers = customers;
        _shipments = shipments;
        _customerId ??= customers.isEmpty ? null : customers.first.id;
        _originBranchId ??= branches.isEmpty ? null : branches.first.id;
        _destinationBranchId ??= branches.length < 2 ? _originBranchId : branches[1].id;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) {
      _showMessage('Connect to the API and load master data before saving.', isError: true);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_originBranchId == _destinationBranchId) {
      _showMessage('Origin and destination branches must be different.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _apiClient.createShipment(
        CreateShipmentRequest(
          direction: widget.direction,
          trackingNumber: _trackingController.text.trim(),
          customerId: _customerId!,
          originBranchId: _originBranchId!,
          destinationBranchId: _destinationBranchId!,
          packageWeightKg: double.parse(_weightController.text.trim()),
          recipientName: _recipientNameController.text.trim(),
          recipientAddress: _recipientAddressController.text.trim(),
          receivedUtc: _isInbound ? _handlingTime : null,
          sentUtc: _isInbound ? null : _handlingTime,
        ),
      );
      _trackingController.clear();
      _weightController.clear();
      _recipientNameController.clear();
      _recipientAddressController.clear();
      await _load();
      if (mounted) {
        _showMessage('${widget.direction} shipment saved.');
      }
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _updateStatus(Shipment shipment, String status) async {
    try {
      await _apiClient.updateShipmentStatus(
        shipmentId: shipment.shipmentId,
        status: status,
      );
      await _load();
      if (mounted) {
        _showMessage('${shipment.trackingNumber} marked $status.');
      }
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString(), isError: true);
      }
    }
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _selectHandlingTime() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _handlingTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selectedDate == null || !mounted) {
      return;
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_handlingTime),
    );
    if (selectedTime == null || !mounted) {
      return;
    }

    setState(() {
      _handlingTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final filteredShipments = _filteredShipments();
    final titleStyle = Theme.of(context).textTheme.headlineMedium;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Expanded(child: Text(_title, style: titleStyle)),
              IconButton(
                tooltip: 'Refresh $_title',
                onPressed: _isLoading ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _isInbound
                ? 'Record mail and consignments received by your branch.'
                : 'Create dispatch records and manage delivery progress.',
          ),
          const SizedBox(height: 20),
          if (_errorMessage != null) _buildConnectionError(context),
          _buildForm(context),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: Text('Shipment register', style: Theme.of(context).textTheme.titleLarge),
              ),
              Text('${filteredShipments.length} record${filteredShipments.length == 1 ? '' : 's'}'),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search tracking number, sender, or recipient',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filteredShipments.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No shipments match this view yet.'),
              ),
            )
          else
            for (final shipment in filteredShipments)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ShipmentCard(
                  shipment: shipment,
                  onStatusSelected: (status) => _updateStatus(shipment, status),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildConnectionError(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_outlined, color: Theme.of(context).colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Could not load shipment data. Check that the API is running, its SQL connection is configured, and the API URL is set in the app settings.\n$_errorMessage',
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildForm(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add ${widget.direction.toLowerCase()} shipment', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text('New shipments are recorded with Pending status.'),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final fieldWidth = constraints.maxWidth >= 720
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(width: fieldWidth, child: _trackingField()),
                    SizedBox(width: fieldWidth, child: _customerField()),
                    SizedBox(width: fieldWidth, child: _originField()),
                    SizedBox(width: fieldWidth, child: _destinationField()),
                    SizedBox(width: fieldWidth, child: _weightField()),
                    SizedBox(width: fieldWidth, child: _handlingTimeField(context)),
                    SizedBox(width: fieldWidth, child: _recipientNameField()),
                    SizedBox(width: fieldWidth, child: _recipientAddressField()),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _canSubmit ? _submit : null,
                icon: _isSubmitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSubmitting ? 'Saving…' : 'Save shipment'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _trackingField() => TextFormField(
    controller: _trackingController,
    maxLength: 50,
    textCapitalization: TextCapitalization.characters,
    decoration: const InputDecoration(
      labelText: 'Tracking number',
      hintText: 'ICICI-OUT-0001',
      border: OutlineInputBorder(),
    ),
    validator: (value) => value == null || value.trim().isEmpty ? 'Tracking number is required.' : null,
  );

  Widget _weightField() => TextFormField(
    controller: _weightController,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: const InputDecoration(
      labelText: 'Package weight',
      suffixText: 'kg',
      hintText: '1.250',
      border: OutlineInputBorder(),
    ),
    validator: (value) {
      final weight = double.tryParse(value?.trim() ?? '');
      if (weight == null || weight <= 0) {
        return 'Enter a weight greater than zero.';
      }
      return null;
    },
  );

  Widget _handlingTimeField(BuildContext context) {
    final label = _isInbound ? 'Receiving time' : 'Send time';
    final formatter = DateFormat('dd MMM yyyy, hh:mm a');
    return InputDecorator(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      child: Row(
        children: [
          Expanded(child: Text(formatter.format(_handlingTime))),
          IconButton(
            tooltip: 'Choose $label',
            onPressed: _canSubmit ? _selectHandlingTime : null,
            icon: const Icon(Icons.schedule_outlined),
          ),
        ],
      ),
    );
  }

  Widget _customerField() => DropdownButtonFormField<int>(
    initialValue: _customerId,
    isExpanded: true,
    decoration: const InputDecoration(labelText: 'Sender / customer', border: OutlineInputBorder()),
    items: _customers
        .map((customer) => DropdownMenuItem(value: customer.id, child: Text(customer.label)))
        .toList(growable: false),
    onChanged: _canSubmit ? (value) => setState(() => _customerId = value) : null,
    validator: (value) => value == null ? 'Choose a sender/customer.' : null,
  );

  Widget _originField() => DropdownButtonFormField<int>(
    initialValue: _originBranchId,
    isExpanded: true,
    decoration: const InputDecoration(labelText: 'Origin branch', border: OutlineInputBorder()),
    items: _branches
        .map((branch) => DropdownMenuItem(value: branch.id, child: Text(branch.label)))
        .toList(growable: false),
    onChanged: _canSubmit ? (value) => setState(() => _originBranchId = value) : null,
    validator: (value) => value == null ? 'Choose an origin branch.' : null,
  );

  Widget _destinationField() => DropdownButtonFormField<int>(
    initialValue: _destinationBranchId,
    isExpanded: true,
    decoration: const InputDecoration(labelText: 'Destination branch', border: OutlineInputBorder()),
    items: _branches
        .map((branch) => DropdownMenuItem(value: branch.id, child: Text(branch.label)))
        .toList(growable: false),
    onChanged: _canSubmit ? (value) => setState(() => _destinationBranchId = value) : null,
    validator: (value) => value == null ? 'Choose a destination branch.' : null,
  );

  Widget _recipientNameField() => TextFormField(
    controller: _recipientNameController,
    maxLength: 160,
    textCapitalization: TextCapitalization.words,
    decoration: const InputDecoration(labelText: 'Recipient name', border: OutlineInputBorder()),
    validator: (value) => value == null || value.trim().isEmpty ? 'Recipient name is required.' : null,
  );

  Widget _recipientAddressField() => TextFormField(
    controller: _recipientAddressController,
    maxLength: 500,
    minLines: 2,
    maxLines: 3,
    textCapitalization: TextCapitalization.sentences,
    decoration: const InputDecoration(labelText: 'Recipient address', border: OutlineInputBorder()),
    validator: (value) => value == null || value.trim().isEmpty ? 'Recipient address is required.' : null,
  );

  List<Shipment> _filteredShipments() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _shipments;
    }

    return _shipments.where((shipment) {
      return shipment.trackingNumber.toLowerCase().contains(query) ||
          shipment.customerName.toLowerCase().contains(query) ||
          shipment.recipientName.toLowerCase().contains(query);
    }).toList(growable: false);
  }
}

class _ShipmentCard extends StatelessWidget {
  const _ShipmentCard({required this.shipment, required this.onStatusSelected});

  final Shipment shipment;
  final ValueChanged<String> onStatusSelected;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(shipment.trackingNumber, style: Theme.of(context).textTheme.titleMedium),
                ),
                _StatusChip(status: shipment.status),
                PopupMenuButton<String>(
                  tooltip: 'Update status',
                  onSelected: onStatusSelected,
                  itemBuilder: (context) => [
                    for (final status in const ['Pending', 'InTransit', 'Delivered', 'Cancelled'])
                      if (status != shipment.status) PopupMenuItem(value: status, child: Text('Mark $status')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Sender: ${shipment.customerName}'),
            Text('Route: ${shipment.originBranchName} → ${shipment.destinationBranchName}'),
            Text(
              shipment.packageWeightKg == null
                  ? 'Weight: not recorded for this legacy shipment'
                  : 'Weight: ${shipment.packageWeightKg!.toStringAsFixed(3)} kg',
            ),
            Text('Recipient: ${shipment.recipientName}'),
            Text(shipment.recipientAddress, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            if (shipment.direction == 'Inbound' && shipment.receivedUtc != null)
              Text('Received ${dateFormat.format(shipment.receivedUtc!)}'),
            if (shipment.direction == 'Outbound' && shipment.sentUtc != null)
              Text('Sent ${dateFormat.format(shipment.sentUtc!)}'),
            Text(
              'Created ${dateFormat.format(shipment.createdUtc)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Delivered' => Colors.green,
      'InTransit' => Colors.purple,
      'Cancelled' => Colors.red,
      _ => Colors.orange,
    };
    return Chip(
      label: Text(status),
      labelStyle: TextStyle(color: color),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      backgroundColor: color.withValues(alpha: 0.1),
    );
  }
}
