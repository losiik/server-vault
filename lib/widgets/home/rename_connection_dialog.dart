import 'package:flutter/material.dart';

class RenameConnectionDialog extends StatefulWidget {
  final String currentName;

  const RenameConnectionDialog({
    super.key,
    required this.currentName,
  });

  @override
  State<RenameConnectionDialog> createState() => _RenameConnectionDialogState();

  static Future<String?> show(BuildContext context, String currentName) {
    return showDialog<String>(
      context: context,
      builder: (context) => RenameConnectionDialog(currentName: currentName),
    );
  }
}

class _RenameConnectionDialogState extends State<RenameConnectionDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Переименовать"),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: "Новое имя",
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Введите имя';
            }
            return null;
          },
          onFieldSubmitted: (_) => _save(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Отмена"),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text("Сохранить"),
        ),
      ],
    );
  }
}