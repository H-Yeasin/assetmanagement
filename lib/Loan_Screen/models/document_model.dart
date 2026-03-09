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
  @HiveField(13)
  final String? folderId;

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
    this.folderId,
  });

  factory DocumentFile.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic date) {
      if (date == null) return null;
      if (date is String) return DateTime.parse(date);
      try {
        return date.toDate();
      } catch (_) {
        return null;
      }
    }

    return DocumentFile(
      id: json['_id'] ?? json['id'] ?? '',
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
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      folderId: json['folderId'],
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
      'folderId': folderId,
    };
  }
}
