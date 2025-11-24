import 'package:flutter/material.dart';

class DeleteConnectionDialog extends StatelessWidget {
  final String connectionName;

  const DeleteConnectionDialog({
    super.key,
    required this.connectionName,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: Colors.orange,
        size: 48,
      ),
      title: const Text("Удалить подключение"),
      content: Text(
        "Вы уверены, что хотите удалить подключение «$connectionName»?",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Отмена"),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text("Удалить"),
        ),
      ],
    );
  }

  static Future<bool> show(BuildContext context, String connectionName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteConnectionDialog(connectionName: connectionName),
    );
    return result ?? false;
  }
}