import 'package:flutter/material.dart';
typedef TimeSelectedCallback = void Function(TimeOfDay? time);

class CustomTimePicker extends StatefulWidget {
  final TimeOfDay? initialStartTime;
  final TimeOfDay? initialEndTime;
  final TimeSelectedCallback? onStartTimeSelected;
  final TimeSelectedCallback? onEndTimeSelected;

  const CustomTimePicker({
    super.key,
    this.initialStartTime,
    this.initialEndTime,
    this.onStartTimeSelected,
    this.onEndTimeSelected,
  });

  @override
  CustomTimePickerState createState() => CustomTimePickerState();
}

class CustomTimePickerState extends State<CustomTimePicker> {
  late TimeOfDay? _startTime;
  late TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    _startTime = widget.initialStartTime;
    _endTime = widget.initialEndTime;
  }

  void _onStartTimeSelected(TimeOfDay? time) {
    setState(() {
      _startTime = time;
    });
    widget.onStartTimeSelected?.call(time);
  }

  void _onEndTimeSelected(TimeOfDay? time) {
    setState(() {
      _endTime = time;
    });
    widget.onEndTimeSelected?.call(time);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: TimePicker(
            initialTime: _startTime,
            onTimeSelected: _onStartTimeSelected,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TimePicker(
            initialTime: _endTime,
            onTimeSelected: _onEndTimeSelected,
          ),
        ),
      ],
    );
  }
}

class TimePicker extends StatelessWidget {
  final TimeOfDay? initialTime;
  final TimeSelectedCallback? onTimeSelected;

  const TimePicker({
    super.key,
    this.initialTime,
    this.onTimeSelected,
  });

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      initialEntryMode: TimePickerEntryMode.input,
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null) {
      onTimeSelected?.call(pickedTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => _pickTime(context),
      child: Text(
        initialTime != null ? initialTime!.format(context) : 'Select Time',
      ),
    );
  }
}
