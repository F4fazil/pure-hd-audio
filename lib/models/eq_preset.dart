class EQPresetData {
  final String id;
  final String name;
  final String description;
  final List<double> values;

  EQPresetData({
    required this.id,
    required this.name,
    required this.description,
    required this.values,
  });

  factory EQPresetData.fromJson(Map<String, dynamic> json) {
    return EQPresetData(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      values: (json['values'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }
}

class EQConfiguration {
  final String version;
  final String description;
  final int bandCount;
  final List<String> frequencies;
  final double minValue;
  final double maxValue;
  final String unit;
  final List<EQPresetData> presets;

  EQConfiguration({
    required this.version,
    required this.description,
    required this.bandCount,
    required this.frequencies,
    required this.minValue,
    required this.maxValue,
    required this.unit,
    required this.presets,
  });

  factory EQConfiguration.fromJson(Map<String, dynamic> json) {
    final bands = json['bands'] as Map<String, dynamic>;
    final range = bands['range'] as Map<String, dynamic>;
    
    return EQConfiguration(
      version: json['version'] as String,
      description: json['description'] as String,
      bandCount: bands['count'] as int,
      frequencies: (bands['frequencies'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      minValue: (range['min'] as num).toDouble(),
      maxValue: (range['max'] as num).toDouble(),
      unit: range['unit'] as String,
      presets: (json['presets'] as List<dynamic>)
          .map((preset) => EQPresetData.fromJson(preset as Map<String, dynamic>))
          .toList(),
    );
  }
}