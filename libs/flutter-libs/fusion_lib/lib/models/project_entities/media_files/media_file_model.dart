import 'package:fusion_lib/fusion_lib.dart';
import 'package:intl/intl.dart';

class MediaFileModel {
  final String id;
  final String name;
  final String path;
  final int size;
  final Duration? length;
  final DateTime date;

  MediaFileModel({
    String? id,
    required this.name,
    required this.path,
    required this.size,
    this.length,
    required this.date,
  }) : id = id ?? 'MEDIA${FusionUtils.shortStringUUID()}';

  //copy with
  MediaFileModel copyWith({
    String? id,
    String? name,
    String? path,
    int? size,
    Duration? length,
    DateTime? date,
  }) {
    return MediaFileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      size: size ?? this.size,
      length: length ?? this.length,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'path': path,
    'size': size,
    'length': length?.inMilliseconds,
    'date': date.toIso8601String(),
  };

  factory MediaFileModel.fromJson(Map<String, dynamic> json) {
    return MediaFileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      size: json['size'] as int,
      length: json['length'] != null ? Duration(milliseconds: json['length'] as int) : null,
      date: DateTime.parse(json['date'] as String),
    );
  }

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(0)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedLength {
    if (length == null) {
      return '';
    }
    final int minutes = length!.inMinutes;
    final int seconds = length!.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedDate {
    return DateFormat('M/d/yyyy; HH:mm').format(date);
  }
}
