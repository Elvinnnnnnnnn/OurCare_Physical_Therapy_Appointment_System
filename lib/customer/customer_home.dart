import 'package:flutter/material.dart';

import 'customer_home_tab.dart';
import 'customer_messages_tab.dart';
import 'customer_schedule_tab.dart';
import 'customer_profile_tab.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../shared/incoming_call_screen.dart';
import 'dart:async';

class CustomerHome extends StatefulWidget {
  final int initialIndex;

  const CustomerHome({super.key, this.initialIndex = 0});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  late int _currentIndex;

  // Brand colors
  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kSoftBlue = Color(0xFFB3EBF2);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);

  final List<Widget> _pages = const [
    CustomerHomeTab(),
    CustomerMessagesTab(),
    CustomerScheduleTab(),
    CustomerProfileTab(),
  ];

  StreamSubscription? callListener;
  bool isIncomingShown = false;
  final Set<String> handledCalls = {};

  void listenIncomingCalls() {
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

  callListener?.cancel();

  callListener = FirebaseFirestore.instance
    .collection('calls')
    .where('receiverId', isEqualTo: currentUserId)
    .where('status', isEqualTo: 'calling')
    .snapshots()
    .listen((snapshot) {
    for (var doc in snapshot.docs) {
      final data = doc.data();

      final status = data['status'];

        if (
          status != 'calling' ||
          isIncomingShown ||
          handledCalls.contains(doc.id)
        ) {
          continue;
        }

        handledCalls.add(doc.id);
        isIncomingShown = true;

            final callerName = data['callerName'] ?? "Unknown";
            final chatId = data['chatId'] ?? "";

            if (chatId.isEmpty) {
              print("ERROR: chatId is null");
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => IncomingCallScreen(
                  callId: doc.id,
                  callerName: callerName,
                  chatId: chatId,
                  callerPhoto: data['callerPhoto'],
                  callerId: data['callerId'],
                ),
              ),
            ).then((_) {
        isIncomingShown = false;

        Future.delayed(const Duration(seconds: 2), () {
          handledCalls.remove(doc.id);
        });
      });
    }
  });
}

@override
void dispose() {
  callListener?.cancel();
  super.dispose();
}

  @override
    void initState() {
      super.initState();
      _currentIndex = widget.initialIndex;

      listenIncomingCalls(); // ADD THIS
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite, // 👈 WHITE BACKGROUND
      body: _pages[_currentIndex],

      /// SOFT FLOATING NAV BAR
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: kSoftBlue, // 👈 B3EBF2 NAV BACKGROUND
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
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: kPrimaryBlue,
            unselectedItemColor: kDarkBlue.withOpacity(0.6),
            showSelectedLabels: true,
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat),
                label: 'Messages',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: 'Schedule',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
