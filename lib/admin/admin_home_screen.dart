import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_doctor_list.dart';
import 'admin_add_doctor.dart';
import 'admin_category_list.dart';
import 'admin_users_tab.dart';
import 'admin_profile_tab.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _index = 0;

  // 🎨 Brand colors
  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);

  final List<Widget> pages = const [
    AdminDoctorList(),
    AdminAddDoctor(),
    AdminCategoryList(),
    AdminUsersTab(),
    AdminProfileTab(),
  ];

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  String _title() {
    switch (_index) {
      case 0:
        return 'Doctors';
      case 1:
        return 'Add Doctor';
      case 2:
        return 'Categories';
      case 3:
        return 'Users';
      case 4:
        return 'Profile';
      default:
        return 'Admin';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,

      /// 🔝 ADMIN TOP BAR (optional – you can remove later)
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0.8,
        title: Text(
          _title(),
          style: const TextStyle(
            color: kDarkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: kDarkBlue),
            onPressed: logout,
          ),
        ],
      ),

      /// 📄 BODY
      body: pages[_index],

      /// 🔻 ADMIN BOTTOM NAV (DESIGN YOU WANT)
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: kPrimaryBlue,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.medical_services),
                label: 'Doctors',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_add_alt),
                label: 'Add',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.category),
                label: 'Categories',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people),
                label: 'Users',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.admin_panel_settings),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
