import 'package:flutter/material.dart';
import 'admin_user_list.dart';
import 'admin_create_user_screen.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab>
    with SingleTickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 3, vsync: this); // ⬅️ 3 tabs
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminCreateUserScreen(),
            ),
          );
        },
      ),
      body: Column(
        children: [
          /// 🧭 TABS
          TabBar(
            controller: _controller,
            tabs: const [
              Tab(text: 'Customers'),
              Tab(text: 'Doctors'),
              Tab(text: 'Admins'), // ⬅️ NEW
            ],
          ),

          /// 📄 TAB CONTENT
          Expanded(
            child: TabBarView(
              controller: _controller,
              children: const [
                AdminUserList(role: 'customer'),
                AdminUserList(role: 'doctor'),
                AdminUserList(role: 'admin'), // ⬅️ NEW
              ],
            ),
          ),
        ],
      ),
    );
  }
}
