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
  File? _qrImageFile;

  final ImagePicker _picker = ImagePicker();
  List<String> selectedCategoryIds = [];

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

    selectedCategoryIds =
      List<String>.from(widget.doctorData['categoryIds'] ?? []);
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
      maxWidth: 1080,
      maxHeight: 1080,
    );

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _pickQrImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (picked != null) {
      setState(() {
        _qrImageFile = File(picked.path);
      });
    }
  }

  Future<String?> _uploadPhoto() async {
    if (_imageFile == null) return widget.doctorData['photoUrl'];

    final ref = FirebaseStorage.instance
        .ref()
        .child('doctors')
        .child('${widget.doctorId}.jpg');

    await ref.putFile(_imageFile!);
    return await ref.getDownloadURL();
  }

  Future<String?> _uploadQrImage() async {
    if (_qrImageFile == null) {
      return widget.doctorData['qrImageUrl'];
    }

    final ref = FirebaseStorage.instance
        .ref()
        .child('doctor_qr')
        .child('${widget.doctorId}_qr.jpg');

    await ref.putFile(_qrImageFile!);
    return await ref.getDownloadURL();
  }

  Future<void> save() async {
    setState(() => isLoading = true);

    try {

      final photoUrl = await _uploadPhoto();
      final qrUrl = await _uploadQrImage();

      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(widget.doctorId)
          .update({
        'name': nameCtrl.text.trim(),
        'experience': expCtrl.text.trim(),
        'aboutMe': aboutCtrl.text.trim(),
        'categoryIds': selectedCategoryIds,
        'activated': activated,
        'photoUrl': photoUrl,
        'consultationPrice': int.tryParse(priceCtrl.text.trim()) ?? 0,
        'currency': 'PHP',
        'qrImageUrl': qrUrl,
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.doctorData['userId'])
          .update({
        'fullName': nameCtrl.text.trim(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Therapist updated')),
      );

      Navigator.pop(context);

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() => isLoading = false);
  }

  InputDecoration _input(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF7F9FC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: kPrimaryBlue, width: 1.4),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    expCtrl.dispose();
    aboutCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final String? photoUrl = widget.doctorData['photoUrl'];

    return Scaffold(
      backgroundColor: kWhite,

      appBar: AppBar(
        title: const Text(
          'Edit Therapist',
          style: TextStyle(
            color: kDarkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kWhite,
        elevation: 0.6,
        iconTheme: const IconThemeData(color: kDarkBlue),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: kSoftBlue,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : photoUrl != null
                        ? NetworkImage(photoUrl)
                        : null,
                child: _imageFile == null && photoUrl == null
                    ? const Icon(
                        Icons.camera_alt,
                        color: kDarkBlue,
                        size: 28,
                      )
                    : null,
              ),
            ),
          ),

          const SizedBox(height: 24),

          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  'Therapist Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kDarkBlue,
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: nameCtrl,
                  decoration: _input('Therapist Name', 'Enter therapist name'),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: expCtrl,
                  decoration: _input('Experience', 'Years of experience'),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _input(
                    'Consultation Price',
                    'Enter price in PHP',
                  ),
                ),
              ],
            ),
          ),

          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  'About Therapist',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kDarkBlue,
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: aboutCtrl,
                  maxLines: 4,
                  decoration: _input('Description', 'About the Therapist'),
                ),
              ],
            ),
          ),

          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  'Categories',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kDarkBlue,
                  ),
                ),

                const SizedBox(height: 10),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('categories')
                      .orderBy('name')
                      .snapshots(),
                  builder: (context, snapshot) {

                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final categories = snapshot.data!.docs;

                    return Column(
                      children: categories.map((doc) {

                        final id = doc.id;
                        final name = doc['name'];
                        final selected = selectedCategoryIds.contains(id);

                        return CheckboxListTile(
                          value: selected,
                          title: Text(name),

                          onChanged: (value) {

                            setState(() {

                              if (value == true) {
                                selectedCategoryIds.add(id);
                              } else {
                                selectedCategoryIds.remove(id);
                              }

                            });

                          },
                        );

                      }).toList(),
                    );

                  },
                ),
              ],
            ),
          ),

          _card(
            child: Column(
              children: [

                GestureDetector(
                  onTap: _pickQrImage,
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: kSoftBlue,
                      borderRadius: BorderRadius.circular(12),
                      image: _qrImageFile != null
                          ? DecorationImage(
                              image: FileImage(_qrImageFile!),
                              fit: BoxFit.cover,
                            )
                          : widget.doctorData['qrImageUrl'] != null
                              ? DecorationImage(
                                  image: NetworkImage(
                                    widget.doctorData['qrImageUrl'],
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                    ),
                    child: _qrImageFile == null &&
                            widget.doctorData['qrImageUrl'] == null
                        ? const Center(
                            child: Text(
                              'Tap to upload GCash QR',
                              style: TextStyle(color: kDarkBlue),
                            ),
                          )
                        : null,
                  ),
                ),

                const SizedBox(height: 14),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: activated,
                  activeColor: kPrimaryBlue,
                  title: const Text(
                    'Activate Therapist Account',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: kDarkBlue,
                    ),
                  ),
                  subtitle: Text(
                    activated
                        ? 'Therapist can log in and receive appointments'
                        : 'Therapist account is disabled',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      activated = value;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading ? null : save,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryBlue,
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

          const SizedBox(height: 12),

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
                color: kDarkBlue.withOpacity(.4),
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

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}