import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const Color bgColor = Color(0xFFF7F9FC);
  static const Color activeColor = Color(0xFF1562E2);
  static const Color textColor = Color(0xFF2D3748);
  static const Color inactiveColor = Color(0xFF718096);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: bgColor,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Admin Panel',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),

          const SizedBox(height: 30),

          _item(Icons.medical_services, 'Doctors', 0),
          _item(Icons.calendar_month, 'Appointments', 1),
          _item(Icons.person_add, 'Add Doctor', 2),
          _item(Icons.category, 'Categories', 3),
          _item(Icons.calendar_today, 'Calendar', 4),
          _item(Icons.people, 'Users', 5),
          _item(Icons.admin_panel_settings, 'Profile', 6),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String title, int index) {
    final bool isActive = selectedIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onItemSelected(index),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : inactiveColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? activeColor : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}