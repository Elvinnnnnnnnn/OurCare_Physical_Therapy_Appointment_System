import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final String callId;
  final bool isCaller;
  final String chatId;

const VideoCallScreen({
  super.key,
  required this.channelName,
  required this.callId,
  required this.chatId,
  required this.isCaller,
});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late final RtcEngine _engine;
  int? remoteUid;
  int? agoraUid;

  final String appId = "3532611675814c0e842a7c9b0be6de3c";

  StreamSubscription? callSub;

  bool isMuted = false;
  bool isCameraOff = false;
  bool isInitialized = false;
  bool callConnected = false;

  String? activeChannel;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await requestPermissions();
    listenCallStatus();
  }

  Future<void> requestPermissions() async {
  await [Permission.camera, Permission.microphone].request();
}

  void listenCallStatus() {
    callSub = FirebaseFirestore.instance
      .collection('calls')
      .doc(widget.callId)
      .snapshots()
      .listen((doc)  {
      if (!doc.exists) {
        print("CALL DOCUMENT DELETED");

        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }

      final data = doc.data()!;
      final status = data['status'];
      activeChannel = data['channelName'];

      print("CALL STATUS: $status");
      print("FIRESTORE CHANNEL: $activeChannel");

      if (status == 'accepted' && !isInitialized && activeChannel != null) {
        print("CALL ACCEPTED, STARTING AGORA");
        initAgora();
      }

      if (!mounted) return;

      if (status == 'declined') {
      Navigator.pop(context);
    }
      
    });
  }

  Future<void> initAgora() async {
    if (isInitialized) return;

    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: appId));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          print("JOIN SUCCESS");
        },
        onUserJoined: (connection, uid, elapsed) {
          print("REMOTE USER JOINED: $uid");
          setState(() {
            remoteUid = uid;
            callConnected = true;
          });
        },
        onUserOffline: (connection, uid, reason) async {
          print("REMOTE USER LEFT");

          await FirebaseFirestore.instance
            .collection('calls')
            .doc(widget.callId)
            .delete();

          if (mounted) {
            Navigator.pop(context);
          }
        },
      ),
    );

    await _engine.enableVideo();
    await _engine.enableLocalVideo(true);
    await _engine.startPreview();

    final userId = FirebaseAuth.instance.currentUser!.uid;
    agoraUid = DateTime.now().millisecondsSinceEpoch % 1000000;

    print("FINAL CHANNEL USED: $activeChannel");
    print("MY UID: $agoraUid");

    if (activeChannel == null) {
      print("ERROR: CHANNEL IS NULL");
      return;
    }

    await _engine.enableAudio();
    await _engine.enableLocalAudio(true);

    await _engine.joinChannel(
      token: "",
      channelId: activeChannel!,
      uid: agoraUid!,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
        publishMediaPlayerVideoTrack: false,
        publishMediaPlayerAudioTrack: false,
      ),
    );

    setState(() {
      isInitialized = true;
    });
  }

  Future<void> sendCallMessage(String text) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'text': text,
      'type': 'call',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

 @override
void dispose() {
  callSub?.cancel();

  _endCallCleanup();

  if (isInitialized) {
    _engine.leaveChannel();
    _engine.release();
  }

  super.dispose();
}

Future<void> _endCallCleanup() async {
  try {
    await FirebaseFirestore.instance
      .collection('calls')
      .doc(widget.callId)
      .delete();
  } catch (e) {
    print("CALL ALREADY DELETED");
  }
}

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
    onWillPop: () async {
      if (callConnected) {
        await sendCallMessage("Call ended");
      } else {
        await sendCallMessage("Missed call");
      }
      return true;
    },
    child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
              children: [
                /// REMOTE VIDEO OR WAITING TEXT
                Center(
                  child: (remoteUid != null)
                    ? StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('calls')
                            .doc(widget.callId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox();
                          }

                          if (!snapshot.hasData || snapshot.data!.data() == null) {
                            return const SizedBox();
                          }

                          final data = snapshot.data!.data() as Map<String, dynamic>;

                          final isRemoteCameraOff =
                              data['cameraOff_$remoteUid'] ?? false;

                          if (isRemoteCameraOff) {
                            return const Center(
                              child: Icon(
                                Icons.videocam_off,
                                color: Colors.white,
                                size: 80,
                              ),
                            );
                          }

                          if (!isInitialized) {
                              return const SizedBox();
                            }

                          return AgoraVideoView(
                            controller: VideoViewController.remote(
                              rtcEngine: _engine,
                              canvas: VideoCanvas(uid: remoteUid),
                              connection: RtcConnection(
                                channelId: activeChannel!,
                              ),
                            ),
                          );
                        },
                      )
                  : FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                      .collection('calls')
                      .doc(widget.callId)
                      .get(),
                    builder: (context, snapshot) {

                      if (!snapshot.hasData || snapshot.data!.data() == null) {
                        return const CircularProgressIndicator(color: Colors.white);
                      }

                      final data = snapshot.data!.data() as Map<String, dynamic>;

                      final name = widget.isCaller
                        ? data['receiverName']
                        : data['callerName'];

                      final photo = widget.isCaller
                        ? data['receiverPhoto']
                        : data['callerPhoto'];

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          CircleAvatar(
                            radius: 60,
                            backgroundImage: photo != null ? NetworkImage(photo) : null,
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
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            "Calling...",
                            style: TextStyle(color: Colors.white70),
                          ),

                          const SizedBox(height: 30),

                          CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.red,
                            child: IconButton(
                              icon: const Icon(Icons.call_end, color: Colors.white),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                  .collection('calls')
                                  .doc(widget.callId)
                                  .delete();

                                await sendCallMessage("Call cancelled");

                                if (mounted) Navigator.pop(context);
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  )
                ),

                /// LOCAL PREVIEW (TOP LEFT)
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    width: 120,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black,
                    ),
                    child: (!isInitialized || isCameraOff)
                      ? const Center(
                          child: Icon(
                            Icons.videocam_off,
                            color: Colors.white,
                            size: 30,
                          ),
                        )
                      : AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: _engine,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        ),
                  ),
                ),

                /// CONTROL BUTTONS
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [

                        /// MUTE
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: Icon(
                              isMuted ? Icons.mic_off : Icons.mic,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              setState(() {
                                isMuted = !isMuted;
                              });
                              _engine.enableLocalAudio(!isMuted);
                            },
                          ),
                        ),

                        /// END CALL
                        CircleAvatar(
                          backgroundColor: Colors.red,
                          radius: 28,
                          child: IconButton(
                            icon: const Icon(Icons.call_end, color: Colors.white),
                            onPressed: () async {
                              if (!mounted) return;
                              if (!callConnected) return;
                              /// 🔴 UPDATE CALL STATUS FIRST
                              await FirebaseFirestore.instance
                                .collection('calls')
                                .doc(widget.callId)
                                .delete();

                              /// 📝 CHAT MESSAGE
                              if (callConnected) {
                                await sendCallMessage("Call ended");
                              } else {
                                await sendCallMessage("Missed call");
                              }

                              Navigator.pop(context);
                            }
                          ),
                        ),

                        /// SWITCH CAMERA
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: const Icon(Icons.cameraswitch, color: Colors.black),
                            onPressed: () {
                              _engine.switchCamera();
                            },
                          ),
                        ),

                        /// CAMERA ON/OFF
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: Icon(
                              isCameraOff ? Icons.videocam_off : Icons.videocam,
                              color: Colors.black,
                            ),
                            onPressed: () async {
                              if (agoraUid == null) return; // 🛑 STOP if null

                              setState(() {
                                isCameraOff = !isCameraOff;
                              });

                              try {
                                if (isCameraOff) {
                                  await _engine.muteLocalVideoStream(true);
                                  await _engine.stopPreview();

                                  await FirebaseFirestore.instance
                                    .collection('calls')
                                    .doc(widget.callId)
                                    .update({'cameraOff_$agoraUid': true});

                                } else {
                                  await _engine.muteLocalVideoStream(false);
                                  await _engine.startPreview();

                                  await FirebaseFirestore.instance
                                    .collection('calls')
                                    .doc(widget.callId)
                                    .update({'cameraOff_$agoraUid': false});
                                }
                              } catch (e) {
                                print("CALL ENDED, SKIP CAMERA UPDATE");
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          remoteUid == null ? "Connecting..." : "In Call",
                          style: TextStyle(
                            color: remoteUid == null ? Colors.orange : Colors.green,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
      )
    );
  }
}