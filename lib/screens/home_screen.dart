import 'package:flutter/material.dart';
import '../screens/add_connection_screen.dart';
import '../screens/terminal_screen.dart';
import '../services/connection_service.dart';
import '../entity/connection.dart';
import '../widgets/home/connection_list_tile.dart';
import '../widgets/home/rename_connection_dialog.dart';
import '../widgets/home/delete_connection_dialog.dart';
import '../widgets/home/empty_connections_view.dart';

class HomeScreen extends StatefulWidget {
  final int userId;

  const HomeScreen({
    super.key,
    required this.userId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _connectionService = ConnectionService();
  List<Connection> _connections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  @override
  void dispose() {
    _connectionService.dispose();
    super.dispose();
  }

  Future<void> _loadConnections() async {
    setState(() => _isLoading = true);

    try {
      final connections = await _connectionService.getConnections(widget.userId);
      setState(() {
        _connections = connections;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Ошибка загрузки подключений: $e', isError: true);
    }
  }

  Future<void> _openAddConnectionScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddConnectionScreen(
          userId: widget.userId,
          onAdd: (conn) async {
            await _connectionService.addConnection(conn);
            _loadConnections();
          },
        ),
      ),
    );
  }

  Future<void> _openTerminal(Connection conn) async {
    // Обновляем время последнего использования
    if (conn.id != null) {
      await _connectionService.updateLastUsed(conn.id!);
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TerminalScreen(connection: conn),
      ),
    );

    // Перезагружаем список после возврата
    _loadConnections();
  }

  Future<void> _renameConnection(Connection conn) async {
    if (conn.id == null) return;

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => RenameConnectionDialog(currentName: conn.name),
    );

    if (newName != null && newName.isNotEmpty && mounted) {
      try {
        await _connectionService.renameConnection(conn.id!, newName);
        _loadConnections();
        _showSnackBar('Подключение переименовано');
      } catch (e) {
        _showSnackBar('Ошибка переименования: $e', isError: true);
      }
    }
  }

  Future<void> _deleteConnection(Connection conn) async {
    if (conn.id == null) return;

    final confirmed = await DeleteConnectionDialog.show(context, conn.name);

    if (confirmed && mounted) {
      try {
        await _connectionService.deleteConnection(conn.id!);
        _loadConnections();
        _showSnackBar('Подключение удалено');
      } catch (e) {
        _showSnackBar('Ошибка удаления: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Подключения"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Обновить",
            onPressed: _loadConnections,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Выйти",
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _connections.isEmpty
                ? const EmptyConnectionsView()
                : RefreshIndicator(
              onRefresh: _loadConnections,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: _connections.length,
                itemBuilder: (context, index) {
                  final conn = _connections[index];
                  return ConnectionListTile(
                    connection: conn,
                    onRename: () => _renameConnection(conn),
                    onDelete: () => _deleteConnection(conn),
                    onTap: () => _openTerminal(conn),
                  );
                },
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openAddConnectionScreen,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    "Добавить подключение",
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}