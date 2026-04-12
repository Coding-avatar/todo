import 'package:hive/hive.dart';
import '../../../domain/models/models.dart';

/// Hive TypeAdapter for HabitLogModel
/// TypeId: 2
class HabitLogModelAdapter extends TypeAdapter<HabitLogModel> {
  @override
  final typeId = 2;

  @override
  HabitLogModel read(BinaryReader reader) {
    final id = reader.read() as String;
    final habitId = reader.read() as String;
    final date = reader.read() as DateTime;
    final completed = reader.read() as bool;
    final createdAt = reader.read() as DateTime;
    final version = reader.read() as int;
    final syncStatus = reader.read() as String;
    final deviceId = reader.read() as String?;

    return HabitLogModel(
      id: id,
      habitId: habitId,
      date: date,
      completed: completed,
      createdAt: createdAt,
      version: version,
      syncStatus: syncStatus,
      deviceId: deviceId,
    );
  }

  @override
  void write(BinaryWriter writer, HabitLogModel obj) {
    writer.write(obj.id);
    writer.write(obj.habitId);
    writer.write(obj.date);
    writer.write(obj.completed);
    writer.write(obj.createdAt);
    writer.write(obj.version);
    writer.write(obj.syncStatus);
    writer.write(obj.deviceId);
  }
}
