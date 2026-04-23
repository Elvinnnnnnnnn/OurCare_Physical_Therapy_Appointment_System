import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'video_call_screen.dart';
import 'package:audioplayers/audioplayers.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callId;
  final String callerName;
  final String chatId;
  final String? callerPhoto;
  final String callerId;

  const IncomingCallScreen({
    super.key,
    required this.callId,
    required this.callerName,
    required this.chatId,
    this.callerPhoto,
    required this.callerId,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  final AudioPlayer _player = AudioPlayer();

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF001C99), Color(0xFF1562E2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              /// AVATAR
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.callerId)
                    .snapshots(),
                builder: (context, snapshot) {

                  if (!snapshot.hasData || snapshot.data!.data() == null) {
                    return Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white24,
                          child: Text(
                            widget.callerName[0].toUpperCase(),
                            style: const TextStyle(fontSize: 32, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.callerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;

                  final name = data['fullName'] ?? widget.callerName;
                  final photo = data['photoUrl'];

                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: photo != null
                            ? NetworkImage(photo)
                            : null,
                        child: photo == null
                            ? Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(fontSize: 32, color: Colors.white),
                              )
                            : null,
                      ),

                      const SizedBox(height: 20),

                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 10),

              const Text(
                "Incoming call...",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),

              const SizedBox(height: 10),
                const Text(
                  "Video Call",
                  style: TextStyle(color: Colors.white54),
                ),

              const SizedBox(height: 40),

              /// BUTTONS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [

                  /// DECLINE
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.red,
                        child: IconButton(
                          icon: const Icon(Icons.call_end, color: Colors.white, size: 28),
                          onPressed: () async {
                            await _stopRingtone();

                            await FirebaseFirestore.instance
                              .collection('calls')
                              .doc(widget.callId)
                              .delete();

                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text("Decline", style: TextStyle(color: Colors.white))
                    ],
                  ),

                  /// ACCEPT
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.green,
                        child: IconButton(
                          icon: const Icon(Icons.call, color: Colors.white, size: 28),
                          onPressed: () async {
                            await _stopRingtone();

                            try {
                              await FirebaseFirestore.instance
                                .collection('calls')
                                .doc(widget.callId)
                                .update({'status': 'accepted'});
                            } catch (e) {
                              print("CALL ALREADY REMOVED");
                            }

                            final doc = await FirebaseFirestore.instance
                                .collection('calls')
                                .doc(widget.callId)
                                .get();

                            final data = doc.data();
                            final channelName = data?['channelName'];

                            if (channelName == null) return;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VideoCallScreen(
                                  channelName: channelName,
                                  callId: widget.callId,
                                  chatId: widget.chatId,
                                  isCaller: false,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text("Accept", style: TextStyle(color: Colors.white))
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
void initState() {
  super.initState();
  _playRingtone();
  _listenCallStatus();
}

void _listenCallStatus() {
  FirebaseFirestore.instance
    .collection('calls')
    .doc(widget.callId)
    .snapshots()
    .listen((doc) {

      if (!doc.exists) {
        _stopRingtone();

        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }

      final data = doc.data();
      if (data == null) return;

      final status = data['status'];

      if (status == 'ended' || status == 'declined') {
        _stopRingtone();

        if (mounted) {
          Navigator.pop(context);
        }
      }
    });
}

  Future<void> _playRingtone() async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('audio/ringtone.mp3'));
  }

  Future<void> _stopRingtone() async {
    await _player.stop();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }


}