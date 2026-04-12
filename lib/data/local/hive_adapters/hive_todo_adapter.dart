import 'package:hive/hive.dart';
import '../../../domain/models/models.dart';
import '../../../core/enums/enums.dart';

/// Hive TypeAdapter for TodoModel
/// TypeId: 0
class TodoModelAdapter extends TypeAdapter<TodoModel> {
  @override
  final typeId = 0;

  @override
  TodoModel read(BinaryReader reader) {
    final id = reader.read() as String;
    final title = reader.read() as String;
    final description = reader.read() as String?;
    final categoryId = reader.read() as String;
    final color = reader.read() as int;
    final priority = reader.read() as int;
    final statusStr = reader.read() as String;
    final dueDate = reader.read() as DateTime?;
    final reminderAt = reader.read() as DateTime?;
    final repeatRuleStr = reader.read() as String;
    final notes = reader.read() as String?;
    final createdAt = reader.read() as DateTime;
    final updatedAt = reader.read() as DateTime;
    final version = reader.read() as int;
    final syncStatus = reader.read() as String;
    final deviceId = reader.read() as String?;

    return TodoModel(
      id: id,
      title: title,
      description: description,
      categoryId: categoryId,
      color: color,
      priority: priority,
      status: TodoStatus.fromJson(statusStr),
      dueDate: dueDate,
      reminderAt: reminderAt,
      repeatRule: RepeatRule.fromJson(repeatRuleStr),
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      version: version,
      syncStatus: syncStatus,
      deviceId: deviceId,
    );
  }

  @override
  void write(BinaryWriter writer, TodoModel obj) {
    writer.write(obj.id);
    writer.write(obj.title);
    writer.write(obj.description);
    writer.write(obj.categoryId);
    writer.write(obj.color);
    writer.write(obj.priority);
    writer.write(obj.status.toJson());
    writer.write(obj.dueDate);
    writer.write(obj.reminderAt);
    writer.write(obj.repeatRule.toJson());
    writer.write(obj.notes);
    writer.write(obj.createdAt);
    writer.write(obj.updatedAt);
    writer.write(obj.version);
    writer.write(obj.syncStatus);
    writer.write(obj.deviceId);
  }
}
