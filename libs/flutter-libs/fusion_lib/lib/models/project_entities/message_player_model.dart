import 'package:fusion_lib/fusion_lib.dart';

/// Represents a single message in a message player
class MessageModel {
  final String id;
  final String name;
  final String? audioFileId;
  final String? audioFileName;
  final double gain;
  final bool repeat;
  final int repeatCount;
  final int repeatIntervalSeconds;
  final List<String> assignedZoneIds;

  const MessageModel({
    required this.id,
    required this.name,
    this.audioFileId,
    this.audioFileName,
    this.gain = 0.0,
    this.repeat = false,
    this.repeatCount = 1,
    this.repeatIntervalSeconds = 2,
    this.assignedZoneIds = const <String>[],
  });

  factory MessageModel.create({String? name}) {
    return MessageModel(
      id: 'MSG${FusionUtils.shortStringUUID()}',
      name: name ?? 'Untitled_01',
    );
  }

  MessageModel copyWith({
    String? id,
    String? name,
    String? audioFileId,
    String? audioFileName,
    double? gain,
    bool? repeat,
    int? repeatCount,
    int? repeatIntervalSeconds,
    List<String>? assignedZoneIds,
    bool clearAudioFile = false,
  }) {
    return MessageModel(
      id: id ?? this.id,
      name: name ?? this.name,
      audioFileId: clearAudioFile ? null : (audioFileId ?? this.audioFileId),
      audioFileName: clearAudioFile ? null : (audioFileName ?? this.audioFileName),
      gain: gain ?? this.gain,
      repeat: repeat ?? this.repeat,
      repeatCount: repeatCount ?? this.repeatCount,
      repeatIntervalSeconds: repeatIntervalSeconds ?? this.repeatIntervalSeconds,
      assignedZoneIds: assignedZoneIds ?? this.assignedZoneIds,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'audioFileId': audioFileId,
    'audioFileName': audioFileName,
    'gain': gain,
    'repeat': repeat,
    'repeatCount': repeatCount,
    'repeatIntervalSeconds': repeatIntervalSeconds,
    'assignedZoneIds': assignedZoneIds,
  };

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
    id: json['id'] as String,
    name: json['name'] as String,
    audioFileId: json['audioFileId'] as String?,
    audioFileName: json['audioFileName'] as String?,
    gain: (json['gain'] as num?)?.toDouble() ?? 0.0,
    repeat: json['repeat'] as bool? ?? false,
    repeatCount: json['repeatCount'] as int? ?? 1,
    repeatIntervalSeconds: json['repeatIntervalSeconds'] as int? ?? 2,
    assignedZoneIds: (json['assignedZoneIds'] as List<dynamic>?)?.map((dynamic e) => e as String).toList() ?? <String>[],
  );
}

/// Represents a Message Player source
class MessagePlayerModel {
  final String id;
  final String name;
  final List<MessageModel> messages;
  final bool isZoneSelectType;

  const MessagePlayerModel({
    required this.id,
    required this.name,
    this.messages = const <MessageModel>[],
    this.isZoneSelectType = false,
  });

  factory MessagePlayerModel.create({
    required String name,
    bool isZoneSelectType = false,
  }) {
    return MessagePlayerModel(
      id: 'MSGPLAYER${FusionUtils.shortStringUUID()}',
      name: name,
      isZoneSelectType: isZoneSelectType,
    );
  }

  MessagePlayerModel copyWith({
    String? id,
    String? name,
    List<MessageModel>? messages,
    bool? isZoneSelectType,
  }) {
    return MessagePlayerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      messages: messages ?? this.messages,
      isZoneSelectType: isZoneSelectType ?? this.isZoneSelectType,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'messages': messages.map((MessageModel m) => m.toJson()).toList(),
    'isZoneSelectType': isZoneSelectType,
  };

  factory MessagePlayerModel.fromJson(Map<String, dynamic> json) => MessagePlayerModel(
    id: json['id'] as String,
    name: json['name'] as String,
    messages: (json['messages'] as List<dynamic>?)?.map((dynamic e) => MessageModel.fromJson(e as Map<String, dynamic>)).toList() ?? <MessageModel>[],
    isZoneSelectType: json['isZoneSelectType'] as bool? ?? false,
  );
}
