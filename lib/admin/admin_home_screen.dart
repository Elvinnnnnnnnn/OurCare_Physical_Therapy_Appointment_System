import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_appointments_screen.dart';
import 'admin_doctor_list.dart';
import 'admin_add_doctor.dart';
import 'admin_category_list.dart';
import 'admin_users_tab.dart';
import 'admin_profile_tab.dart';
import 'admin_calendar_screen.dart';

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
    AdminCalendarScreen(),
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
        return 'Appointments';
      case 2:
        return 'Add Doctor';
      case 3:
        return 'Categories';
      case 4:
        return 'Calendar';
      case 5:
        return 'Users';
      case 6:
        return 'Profile';
      default:
        return 'Admin';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,

      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kDarkBlue),
        title: Align(
          alignment: Alignment.centerRight,
          child: Text(
            _title(),
            style: const TextStyle(
              color: kDarkBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

      drawer: _buildDrawer(),

      body: pages[_index],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.7,
      child: Container(
        color: kWhite,
        child: SafeArea(
          child: ListView(
            children: [

              const SizedBox(height: 20),

              _drawerItem(Icons.medical_services, 'Doctors', 0),
              _drawerItem(Icons.calendar_month, 'Appointments', 1),
              _drawerItem(Icons.person_add_alt, 'Add Doctor', 2),
              _drawerItem(Icons.category, 'Categories', 3),
              _drawerItem(Icons.calendar_today, 'Calendar', 4),
              _drawerItem(Icons.people, 'Users', 5),
              _drawerItem(Icons.admin_panel_settings, 'Profile', 6),

            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon, color: kPrimaryBlue),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: kDarkBlue,
        ),
      ),
      onTap: () {
        setState(() => _index = index);
        Navigator.pop(context); // close drawer
      },
    );
  }
}