// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DocumentFileAdapter extends TypeAdapter<DocumentFile> {
  @override
  final int typeId = 1;

  @override
  DocumentFile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DocumentFile(
      id: fields[0] as String,
      userId: fields[1] as String?,
      module: fields[2] as String?,
      originalName: fields[3] as String,
      displayName: fields[4] as String,
      filename: fields[5] as String,
      mimeType: fields[6] as String,
      size: fields[7] as int,
      path: fields[8] as String,
      relatedType: fields[9] as String?,
      relatedId: fields[10] as String?,
      createdAt: fields[11] as DateTime?,
      updatedAt: fields[12] as DateTime?,
      folderId: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DocumentFile obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.module)
      ..writeByte(3)
      ..write(obj.originalName)
      ..writeByte(4)
      ..write(obj.displayName)
      ..writeByte(5)
      ..write(obj.filename)
      ..writeByte(6)
      ..write(obj.mimeType)
      ..writeByte(7)
      ..write(obj.size)
      ..writeByte(8)
      ..write(obj.path)
      ..writeByte(9)
      ..write(obj.relatedType)
      ..writeByte(10)
      ..write(obj.relatedId)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt)
      ..writeByte(13)
      ..write(obj.folderId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentFileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
