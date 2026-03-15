import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../../../models/models.dart';
import '../../../widgets/widgets.dart';

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await ApiService.getAllUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Text('Manage Users', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          Expanded(
            child: _isLoading
                ? const LoadingIndicator()
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.lightPurple,
                              child: Text(user.fullName[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                            ),
                            title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${user.email}\nRole: ${user.role}'),
                            isThreeLine: true,
                            trailing: Switch(
                              value: user.isActive,
                              onChanged: (_) async {
                                await ApiService.toggleUserActive(user.id);
                                _loadUsers();
                              },
                              activeThumbColor: AppTheme.success,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
