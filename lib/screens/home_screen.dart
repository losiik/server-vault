import 'package:flutter/material.dart';
import '../screens/add_connection_screen.dart';
import '../screens/terminal_screen.dart';
import '../services/connection_service.dart';
import '../widgets/home/connection_list_tile.dart';
import '../widgets/home/rename_connection_dialog.dart';
import '../widgets/home/delete_connection_dialog.dart';
import '../widgets/home/empty_connections_view.dart';
import '../entity/connection.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _connectionService = ConnectionService();

  Future<void> _openAddConnectionScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddConnectionScreen(
          onAdd: (conn) {
            setState(() {
              _connectionService.addConnection(conn);
            });
          },
        ),
      ),
    );
  }

  void _openTerminal(Connection conn) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TerminalScreen(connection: conn),
      ),
    );
  }

  Future<void> _renameConnection(Connection conn) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => RenameConnectionDialog(currentName: conn.name),
    );

    if (newName != null && newName.isNotEmpty && mounted) {
      setState(() {
        _connectionService.renameConnection(conn.id, newName);
      });

      _showSnackBar('Подключение переименовано');
    }
  }

  Future<void> _deleteConnection(Connection conn) async {
    final confirmed = await DeleteConnectionDialog.show(context, conn.name);

    if (confirmed && mounted) {
      setState(() {
        _connectionService.deleteConnection(conn.id);
      });

      _showSnackBar('Подключение удалено');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connections = _connectionService.getConnections();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Подключения"),
        actions: [
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
            child: connections.isEmpty
                ? const EmptyConnectionsView()
                : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: connections.length,
              itemBuilder: (context, index) {
                final conn = connections[index];
                return ConnectionListTile(
                  connection: conn,
                  onRename: () => _renameConnection(conn),
                  onDelete: () => _deleteConnection(conn),
                  onTap: () => _openTerminal(conn),
                );
              },
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