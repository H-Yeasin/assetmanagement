// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loan_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LoanAdapter extends TypeAdapter<Loan> {
  @override
  final int typeId = 0;

  @override
  Loan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Loan(
      id: fields[0] as String?,
      userId: fields[1] as String,
      name: fields[2] as String,
      category: fields[3] as String,
      monthlyPayment: fields[4] as double,
      paymentDate: fields[5] as DateTime?,
      autoPay: fields[6] as bool,
      totalAmount: fields[7] as double,
      interestRate: fields[8] as double,
      startDate: fields[9] as DateTime?,
      endDate: fields[10] as DateTime?,
      remainingBalance: fields[11] as double,
      lender: fields[12] as String?,
      notes: fields[13] as String?,
      status: fields[14] as String,
      completedAt: fields[15] as DateTime?,
      documents: (fields[16] as List).cast<dynamic>(),
      createdAt: fields[17] as DateTime?,
      updatedAt: fields[18] as DateTime?,
      propertyAddress: fields[19] as String?,
      apartmentName: fields[20] as String?,
      amortizationPeriod: fields[21] as String?,
      totalPayments: fields[22] as int,
      completedPayments: fields[23] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Loan obj) {
    writer
      ..writeByte(24)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.monthlyPayment)
      ..writeByte(5)
      ..write(obj.paymentDate)
      ..writeByte(6)
      ..write(obj.autoPay)
      ..writeByte(7)
      ..write(obj.totalAmount)
      ..writeByte(8)
      ..write(obj.interestRate)
      ..writeByte(9)
      ..write(obj.startDate)
      ..writeByte(10)
      ..write(obj.endDate)
      ..writeByte(11)
      ..write(obj.remainingBalance)
      ..writeByte(12)
      ..write(obj.lender)
      ..writeByte(13)
      ..write(obj.notes)
      ..writeByte(14)
      ..write(obj.status)
      ..writeByte(15)
      ..write(obj.completedAt)
      ..writeByte(16)
      ..write(obj.documents)
      ..writeByte(17)
      ..write(obj.createdAt)
      ..writeByte(18)
      ..write(obj.updatedAt)
      ..writeByte(19)
      ..write(obj.propertyAddress)
      ..writeByte(20)
      ..write(obj.apartmentName)
      ..writeByte(21)
      ..write(obj.amortizationPeriod)
      ..writeByte(22)
      ..write(obj.totalPayments)
      ..writeByte(23)
      ..write(obj.completedPayments);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
