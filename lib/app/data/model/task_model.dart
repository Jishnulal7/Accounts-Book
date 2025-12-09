import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';
part 'task_model.g.dart';

@HiveType(typeId: 21)
class TaskModel extends HiveObject {
  @HiveField(0)
  String eventTitle;

  @HiveField(1)
  String eventDescp;

  @HiveField(2)
  DateTime startTime;

  @HiveField(3)
  DateTime endTime;

  @HiveField(5)
  String id;

  TaskModel({
    required this.eventTitle,
    required this.eventDescp,
    required this.startTime,
    required this.endTime,
    String? id, // Make id optional to handle default Uuid generation
  }) : id = id ?? const Uuid().v4(); // Generate a new Uuid if id is not provided

  // Method to convert TaskModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'eventTitle': eventTitle,
      'eventDescp': eventDescp,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'id': id,
    };
  }

  // Factory constructor to create a TaskModel from JSON
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      eventTitle: json['eventTitle'] as String,
      eventDescp: json['eventDescp'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      id: json['id'] as String,
    );
  }
}
