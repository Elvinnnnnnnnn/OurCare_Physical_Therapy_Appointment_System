import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/sidebar.dart';

import '../admin/admin_appointments_screen.dart';
import '../admin/admin_doctor_list.dart';
import '../admin/admin_add_doctor.dart';
import '../admin/admin_category_list.dart';
import '../admin/admin_users_tab.dart';
import '../admin/admin_profile_tab.dart';
import '../admin/admin_calendar_screen.dart';
import '../admin/admin_edit_doctor.dart';
import '../admin/admin_edit_doctor_availability.dart';
import '../admin/notifications_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int selectedIndex = 0;

  String? selectedDoctorId;
  Map<String, dynamic>? selectedDoctorData;

  static const Color kWhite = Color(0xFFFFFFFF);

  // ✅ OPEN EDIT DOCTOR
  void openEditDoctor(String id, Map<String, dynamic> data) {
    setState(() {
      selectedDoctorId = id;
      selectedDoctorData = data;
      selectedIndex = 7;
    });
  }

  // ✅ OPEN AVAILABILITY
  void openEditAvailability() {
    setState(() {
      selectedIndex = 8;
    });
  }

  // ✅ PAGE SWITCHER
  Widget getPage() {
    switch (selectedIndex) {
      case 0:
        return AdminDoctorList(
          onEdit: openEditDoctor,
        );

      case 1:
        return const AdminAppointmentsScreen();

      case 2:
        return const AdminAddDoctor();

      case 3:
        return const AdminCategoryList();

      case 4:
        return const AdminCalendarScreen();

      case 5:
        return const AdminUsersTab();

      case 6:
        return const AdminProfileTab();

      case 7:
        if (selectedDoctorData == null) {
          return const Center(child: Text('No therapist selected'));
        }
        return AdminEditDoctorScreen(
          doctorId: selectedDoctorId!,
          doctorData: selectedDoctorData!,
          onOpenAvailability: openEditAvailability,
        );

      case 8:
        if (selectedDoctorData == null) {
          return const Center(child: Text('No therapist selected'));
        }
        return AdminEditDoctorAvailability(
          doctorId: selectedDoctorId!,
          availability: selectedDoctorData!['availability'] ?? {},
        );
      
      case 9:
         return const NotificationsScreen();

      default:
        return const Center(child: Text('Dashboard'));
    }
  }

  String getTitle() {
    switch (selectedIndex) {
      case 0:
        return 'Therapist';
      case 1:
        return 'Appointments';
      case 2:
        return 'Add Therapist';
      case 3:
        return 'Categories';
      case 4:
        return 'Calendar';
      case 5:
        return 'Users';
      case 6:
        return 'Profile';
      case 7:
        return 'Edit Therapist';
      case 8:
        return 'Edit Availability';
      case 9:
        return 'Notifications';
      default:
        return 'Admin';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      body: Row(
        children: [
          Sidebar(
            selectedIndex: selectedIndex,
            onItemSelected: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
          ),

          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: getPage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          // LEFT TITLE
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getTitle(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Manage your system',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          // RIGHT ACTIONS
          Row(
            children: [
              _notificationIcon(),
              const SizedBox(width: 12),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.logout, size: 20),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _notificationIcon() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('read', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        int count = snapshot.data?.docs.length ?? 0;

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                setState(() {
                  selectedIndex = 9;
                });
              },
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
              ),
            ) 
          ],
        );
      },
    );
  }
}