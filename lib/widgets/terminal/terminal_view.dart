import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';

class SSHTerminalWidget extends StatefulWidget {
  final Terminal terminal;

  const SSHTerminalWidget({
    super.key,
    required this.terminal,
  });

  @override
  State<SSHTerminalWidget> createState() => _SSHTerminalWidgetState();
}

class _SSHTerminalWidgetState extends State<SSHTerminalWidget> {
  final FocusNode _focusNode = FocusNode();
  // ❌ УДАЛИТЕ ЭТУ СТРОКУ:
  // final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    // ❌ УДАЛИТЕ ЭТУ СТРОКУ:
    // _textController.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    final key = event.logicalKey;

    // Обработка специальных клавиш
    if (key == LogicalKeyboardKey.enter) {
      widget.terminal.keyInput(TerminalKey.enter);
    } else if (key == LogicalKeyboardKey.backspace) {
      widget.terminal.keyInput(TerminalKey.backspace);
    } else if (key == LogicalKeyboardKey.tab) {
      widget.terminal.keyInput(TerminalKey.tab);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      widget.terminal.keyInput(TerminalKey.arrowUp);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      widget.terminal.keyInput(TerminalKey.arrowDown);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      widget.terminal.keyInput(TerminalKey.arrowLeft);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      widget.terminal.keyInput(TerminalKey.arrowRight);
    } else if (key == LogicalKeyboardKey.delete) {
      widget.terminal.keyInput(TerminalKey.delete);
    } else if (key == LogicalKeyboardKey.home) {
      widget.terminal.keyInput(TerminalKey.home);
    } else if (key == LogicalKeyboardKey.end) {
      widget.terminal.keyInput(TerminalKey.end);
    } else if (key == LogicalKeyboardKey.pageUp) {
      widget.terminal.keyInput(TerminalKey.pageUp);
    } else if (key == LogicalKeyboardKey.pageDown) {
      widget.terminal.keyInput(TerminalKey.pageDown);
    } else if (key == LogicalKeyboardKey.escape) {
      widget.terminal.keyInput(TerminalKey.escape);
    } else if (event.character != null && event.character!.isNotEmpty) {
      // Обработка обычных символов
      widget.terminal.textInput(event.character!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Container(
          color: const Color(0xFF1E1E1E),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TerminalView(
                widget.terminal,
                backgroundOpacity: 1.0,
                theme: TerminalThemes.defaultTheme,
              ),
            ),
          ),
        ),
      ),
    );
  }
}