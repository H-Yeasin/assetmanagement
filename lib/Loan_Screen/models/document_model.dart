import 'package:hive/hive.dart';

part 'document_model.g.dart';

@HiveType(typeId: 1)
class DocumentFile extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String? userId;
  @HiveField(2)
  final String? module;
  @HiveField(3)
  final String originalName;
  @HiveField(4)
  final String displayName;
  @HiveField(5)
  final String filename;
  @HiveField(6)
  final String mimeType;
  @HiveField(7)
  final int size;
  @HiveField(8)
  final String path;
  @HiveField(9)
  final String? relatedType;
  @HiveField(10)
  final String? relatedId;
  @HiveField(11)
  final DateTime? createdAt;
  @HiveField(12)
  final DateTime? updatedAt;

  DocumentFile({
    required this.id,
    this.userId,
    this.module,
    required this.originalName,
    required this.displayName,
    required this.filename,
    required this.mimeType,
    required this.size,
    required this.path,
    this.relatedType,
    this.relatedId,
    this.createdAt,
    this.updatedAt,
  });

  factory DocumentFile.fromJson(Map<String, dynamic> json) {
    return DocumentFile(
      id: json['_id'] ?? '',
      userId: json['userId'],
      module: json['module'],
      originalName: json['originalName'] ?? '',
      displayName: json['displayName'] ?? '',
      filename: json['filename'] ?? '',
      mimeType: json['mimeType'] ?? '',
      size: json['size'] ?? 0,
      path: json['path'] ?? '',
      relatedType: json['relatedType'],
      relatedId: json['relatedId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'module': module,
      'originalName': originalName,
      'displayName': displayName,
      'filename': filename,
      'mimeType': mimeType,
      'size': size,
      'path': path,
      'relatedType': relatedType,
      'relatedId': relatedId,
    };
  }
}
