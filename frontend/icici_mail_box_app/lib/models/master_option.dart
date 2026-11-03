class MasterOption {
  const MasterOption({
    required this.id,
    required this.code,
    required this.name,
  });

  final int id;
  final String code;
  final String name;

  String get label => '$name ($code)';

  factory MasterOption.fromJson(Map<String, dynamic> json) => MasterOption(
    id: (json['id'] as num).toInt(),
    code: json['code'] as String,
    name: json['name'] as String,
  );
}
