class PavaMessageModel {
  final String id;
  final String origName;
  final String displayName;
  final String filename;
  final String mimeType;
  final DateTime uploaded;
  final int sizeBytes;
  final List<String> tags;
  final String checksum;

  PavaMessageModel({
    required this.id,
    required this.origName,
    required this.displayName,
    required this.filename,
    required this.mimeType,
    required this.uploaded,
    required this.sizeBytes,
    required this.tags,
    required this.checksum,
  });

  factory PavaMessageModel.fromJson(Map<String, dynamic> json) {
    return PavaMessageModel(
      id: json['id'] as String,
      origName: json['orig_name'] as String,
      displayName: json['display_name'] as String,
      filename: json['filename'] as String,
      mimeType: json['mime_type'] as String,
      uploaded: DateTime.parse(json['uploaded'] as String),
      sizeBytes: json['size_bytes'] as int,
      tags: List<String>.from(json['tags'] as List<dynamic>? ?? <dynamic>[]),
      checksum: json['checksum'] as String,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'orig_name': origName,
    'display_name': displayName,
    'filename': filename,
    'mime_type': mimeType,
    'uploaded': uploaded.toIso8601String(),
    'size_bytes': sizeBytes,
    'tags': tags,
    'checksum': checksum,
  };
}
