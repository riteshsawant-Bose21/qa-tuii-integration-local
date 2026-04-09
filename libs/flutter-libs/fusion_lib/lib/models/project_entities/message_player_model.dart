import 'package:fusion_lib/fusion_lib.dart';

/// Represents a single message in a message player
class MessageModel {
  final String id;
  final String name;
  final double gain;
  final bool repeat;
  final int repeatCount;
  final int repeatIntervalSeconds;

  const MessageModel({
    required this.id,
    required this.name,
    this.gain = 0.0,
    this.repeat = false,
    this.repeatCount = 1,
    this.repeatIntervalSeconds = 5,
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
    double? gain,
    bool? repeat,
    int? repeatCount,
    int? repeatIntervalSeconds,
  }) {
    return MessageModel(
      id: id ?? this.id,
      name: name ?? this.name,
      gain: gain ?? this.gain,
      repeat: repeat ?? this.repeat,
      repeatCount: repeatCount ?? this.repeatCount,
      repeatIntervalSeconds: repeatIntervalSeconds ?? this.repeatIntervalSeconds,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'gain': gain,
    'repeat': repeat,
    'repeatCount': repeatCount,
    'repeatIntervalSeconds': repeatIntervalSeconds,
  };

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
    id: json['id'] as String,
    name: json['name'] as String,
    gain: (json['gain'] as num?)?.toDouble() ?? 0.0,
    repeat: json['repeat'] as bool? ?? false,
    repeatCount: json['repeatCount'] as int? ?? 1,
    repeatIntervalSeconds: json['repeatIntervalSeconds'] as int? ?? 2,
  );
}

/// Represents a Message Player source
// class MessagePlayerModel {
//   final String id;
//   final String name;
//   final List<MessageModel> messages;
//
//   const MessagePlayerModel({
//     required this.id,
//     required this.name,
//     this.messages = const <MessageModel>[],
//   });
//
//   factory MessagePlayerModel.create({
//     required String name,
//   }) {
//     return MessagePlayerModel(
//       id: 'MSGPLAYER${FusionUtils.shortStringUUID()}',
//       name: name,
//     );
//   }
//
//   MessagePlayerModel copyWith({
//     String? id,
//     String? name,
//     List<MessageModel>? messages,
//   }) {
//     return MessagePlayerModel(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       messages: messages ?? this.messages,
//     );
//   }
//
//   Map<String, dynamic> toJson() => <String, dynamic>{
//     'id': id,
//     'name': name,
//     'messages': messages.map((MessageModel m) => m.toJson()).toList(),
//   };
//
//   factory MessagePlayerModel.fromJson(Map<String, dynamic> json) => MessagePlayerModel(
//     id: json['id'] as String,
//     name: json['name'] as String,
//     messages: (json['messages'] as List<dynamic>?)?.map((dynamic e) => MessageModel.fromJson(e as Map<String, dynamic>)).toList() ?? <MessageModel>[],
//   );
// }
