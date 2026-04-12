import 'package:hive/hive.dart';
import '../../../domain/models/models.dart';

/// Hive TypeAdapter for HabitModel
/// TypeId: 1
class HabitModelAdapter extends TypeAdapter<HabitModel> {
  @override
  final typeId = 1;

  @override
  HabitModel read(BinaryReader reader) {
    final id = reader.read() as String;
    final name = reader.read() as String;
    final description = reader.read() as String?;
    final categoryId = reader.read() as String?;
    final startDate = reader.read() as DateTime;
    final active = reader.read() as bool;
    final isFuture = reader.read() as bool;
    final createdAt = reader.read() as DateTime;
    final updatedAt = reader.read() as DateTime;
    final version = reader.read() as int;
    final syncStatus = reader.read() as String;
    final deviceId = reader.read() as String?;

    return HabitModel(
      id: id,
      name: name,
      description: description,
      categoryId: categoryId,
      startDate: startDate,
      active: active,
      isFuture: isFuture,
      createdAt: createdAt,
      updatedAt: updatedAt,
      version: version,
      syncStatus: syncStatus,
      deviceId: deviceId,
    );
  }

  @override
  void write(BinaryWriter writer, HabitModel obj) {
    writer.write(obj.id);
    writer.write(obj.name);
    writer.write(obj.description);
    writer.write(obj.categoryId);
    writer.write(obj.startDate);
    writer.write(obj.active);
    writer.write(obj.isFuture);
    writer.write(obj.createdAt);
    writer.write(obj.updatedAt);
    writer.write(obj.version);
    writer.write(obj.syncStatus);
    writer.write(obj.deviceId);
  }
}
