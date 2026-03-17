import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_appointments_screen.dart';
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

  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kSoftBlue = Color(0xFFB3EBF2);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);

  final List<Widget> pages = const [
    AdminDoctorList(),
    AdminAppointmentsScreen(),
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

      /// ❌ TOP NAVBAR REMOVED

      body: pages[_index],

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: kSoftBlue,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(26),
              topRight: Radius.circular(26),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: kPrimaryBlue,
            unselectedItemColor: kDarkBlue.withOpacity(0.6),
            showSelectedLabels: true,
            showUnselectedLabels: false,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.medical_services),
                label: 'Doctors',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month),
                label: 'Appointments',
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