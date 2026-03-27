import 'package:flutter/material.dart';
import 'admin_user_list.dart';

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

  bool allowAdminCreation = false;

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
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const SizedBox(height: 10),

            /// TABS
            TabBar(
              controller: _controller,
              indicatorColor: kPrimaryBlue,
              indicatorWeight: 3,
              labelColor: kPrimaryBlue,
              unselectedLabelColor: Colors.black54,
              tabs: [
                _tabItem('Patient'),
                _tabItem('Doctors'),
                _tabItem('Admins'),
              ],
            ),

            const SizedBox(height: 10),

            /// CONTENT
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
      ),
    );
  }


}