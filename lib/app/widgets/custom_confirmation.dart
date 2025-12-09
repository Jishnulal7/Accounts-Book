import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String confirmButtonText;
  final String cancelButtonText;
  final Color confirmButtonColor;
  final String? actions;
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onCancel,
    required this.onConfirm,
    required this.confirmButtonText,
    required this.cancelButtonText,
    this.actions,
    this.confirmButtonColor = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: <Widget>[
        TextButton(
          onPressed: onCancel,
          child: Text(cancelButtonText),
        ),
        TextButton(
          onPressed: onConfirm,
          child: Text(
            confirmButtonText,
            style: TextStyle(color: confirmButtonColor),
          ),
        ),
      ],
    );
  }
}
