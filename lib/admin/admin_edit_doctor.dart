import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'admin_edit_doctor_availability.dart';

class AdminEditDoctorScreen extends StatefulWidget {
  final String doctorId;
  final Map<String, dynamic> doctorData;

  const AdminEditDoctorScreen({
    super.key,
    required this.doctorId,
    required this.doctorData,
  });

  @override
  State<AdminEditDoctorScreen> createState() =>
      _AdminEditDoctorScreenState();
}

class _AdminEditDoctorScreenState extends State<AdminEditDoctorScreen> {
  late TextEditingController nameCtrl;
  late TextEditingController expCtrl;
  late TextEditingController aboutCtrl;
  late TextEditingController priceCtrl;

  bool isLoading = false;
  late bool activated;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // 🎨 Admin colors
  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);
  static const Color kGreyText = Color(0xFF6B7280);
  static const Color kSoftBlue = Color(0xFFB3EBF2);

  @override
    void initState() {
      super.initState();
      nameCtrl = TextEditingController(text: widget.doctorData['name']);
      expCtrl = TextEditingController(text: widget.doctorData['experience']);
      aboutCtrl = TextEditingController(text: widget.doctorData['aboutMe']);
      priceCtrl = TextEditingController(
        text: (widget.doctorData['consultationPrice'] ?? 0).toString(),
      );
      activated = widget.doctorData['activated'] ?? false;
  }


  /// ======================
  /// PICK PHOTO
  /// ======================
  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  /// ======================
  /// UPLOAD PHOTO
  /// ======================
  Future<String?> _uploadPhoto() async {
    if (_imageFile == null) return widget.doctorData['photoUrl'];

    final ref = FirebaseStorage.instance
        .ref()
        .child('doctors')
        .child('${widget.doctorId}.jpg');

    await ref.putFile(_imageFile!);
    return await ref.getDownloadURL();
  }

  Future<void> save() async {
    setState(() => isLoading = true);

    final photoUrl = await _uploadPhoto();

    await FirebaseFirestore.instance
        .collection('doctors')
        .doc(widget.doctorId)
        .update({
      'name': nameCtrl.text.trim(),
      'experience': expCtrl.text.trim(),
      'aboutMe': aboutCtrl.text.trim(),
      'activated': activated,
      'photoUrl': photoUrl,
      'consultationPrice': int.tryParse(priceCtrl.text.trim()) ?? 0,
      'currency': 'PHP',
    });

    setState(() => isLoading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Doctor updated')),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    expCtrl.dispose();
    aboutCtrl.dispose();
    priceCtrl.dispose(); 
    super.dispose();
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: kDarkBlue,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? photoUrl = widget.doctorData['photoUrl'];

    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        title: const Text('Edit Doctor'),
        backgroundColor: kWhite,
        elevation: 0.8,
        foregroundColor: kDarkBlue,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          /// 🖼️ PHOTO (NEW)
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: CircleAvatar(
                radius: 48,
                backgroundColor: kSoftBlue,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : photoUrl != null
                        ? NetworkImage(photoUrl)
                        : null,
                child: _imageFile == null && photoUrl == null
                    ? const Icon(Icons.camera_alt,
                        color: kDarkBlue, size: 28)
                    : null,
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// BASIC INFO
          _sectionTitle('Doctor Information'),

          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Doctor Name',
                  style: TextStyle(fontSize: 12, color: kGreyText),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Enter doctor name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Experience',
                  style: TextStyle(fontSize: 12, color: kGreyText),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Consultation Price (PHP)',
                  style: TextStyle(fontSize: 12, color: kGreyText),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter price',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),

                const SizedBox(height: 6),
                TextField(
                  controller: expCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Years of experience',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),

          /// ABOUT
          _sectionTitle('About Doctor'),

          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Description',
                  style: TextStyle(fontSize: 12, color: kGreyText),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: aboutCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'About the doctor',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),

          /// ACCOUNT STATUS
          _sectionTitle('Account Status'),

          _card(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Activate Doctor Account',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: kDarkBlue,
                ),
              ),
              subtitle: Text(
                activated
                    ? 'Doctor can log in and receive appointments'
                    : 'Doctor account is disabled',
                style: const TextStyle(fontSize: 12),
              ),
              value: activated,
              activeColor: kPrimaryBlue,
              onChanged: (value) {
                setState(() {
                  activated = value;
                });
              },
            ),
          ),

          const SizedBox(height: 10),

          /// SAVE BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : save,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryBlue,
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ),

          const SizedBox(height: 20),

          /// AVAILABILITY BUTTON
          OutlinedButton.icon(
            icon: const Icon(Icons.schedule),
            label: const Text('Edit Availability'),
            style: OutlinedButton.styleFrom(
              foregroundColor: kDarkBlue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              side: BorderSide(
                color: kDarkBlue.withOpacity(0.4),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminEditDoctorAvailability(
                    doctorId: widget.doctorId,
                    availability:
                        widget.doctorData['availability'] ?? {},
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
