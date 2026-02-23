import 'package:zephyron/enums.dart';

class Artifact {
  final String id;
  final String name;
  final String avatar;
  final DateTime timestamp;
  final String message;
  final Status? status;
  final Map<String, dynamic>? metadata;

  Artifact({
    required this.id,
    required this.name,
    required this.avatar,
    required this.timestamp,
    required this.message,
    this.status,
    this.metadata,
  });

  factory Artifact.fromJson(Map<String, dynamic> json) {
    return Artifact(
      id: json['\$id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? '',
      timestamp: json['timestamp'] is DateTime
          ? json['timestamp']
          : DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      message: json['message'] ?? '',
      status: json['status'] != null
          ? Status.values.firstWhere(
            (status) => status.name == json['status'],
        orElse: () => Status.sent,
      )
          : null,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '\$id': id,
      'name': name,
      'avatar': avatar,
      'timestamp': timestamp.toIso8601String(),
      'message': message,
      'status': status?.name,
      'metadata': metadata,
    };
  }

  Artifact copyWith({
    String? id,
    String? name,
    String? avatar,
    DateTime? timestamp,
    String? message,
    Status? status,
    Map<String, dynamic>? metadata,
  }) {
    return Artifact(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      timestamp: timestamp ?? this.timestamp,
      message: message ?? this.message,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }
}