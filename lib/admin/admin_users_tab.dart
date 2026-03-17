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

  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);
  static const Color kSoftBlue = Color(0xFFB3EBF2);

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _tabItem(String text) {
    return Tab(
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,

      appBar: AppBar(
        title: const Text(
          'User Management',
          style: TextStyle(
            color: kDarkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kWhite,
        elevation: 0.6,
        iconTheme: const IconThemeData(color: kDarkBlue),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
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
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TabBar(
              controller: _controller,
              indicatorColor: kPrimaryBlue,
              indicatorWeight: 3,
              labelColor: kPrimaryBlue,
              unselectedLabelColor: Colors.black54,
              tabs: [
                _tabItem('Customers'),
                _tabItem('Doctors'),
                _tabItem('Admins'),
              ],
            ),
          ),

          const SizedBox(height: 6),

          Expanded(
            child: TabBarView(
              controller: _controller,
              children: const [
                AdminUserList(role: 'customer'),
                AdminUserList(role: 'doctor'),
                AdminUserList(role: 'admin'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}