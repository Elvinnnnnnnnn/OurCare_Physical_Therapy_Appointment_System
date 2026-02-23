import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AdminAddDoctor extends StatefulWidget {
  const AdminAddDoctor({super.key});

  @override
  State<AdminAddDoctor> createState() => _AdminAddDoctorState();
}

class _AdminAddDoctorState extends State<AdminAddDoctor> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedCategoryName;

  bool _isLoading = false;

  File? _qrFile;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // 🎨 Admin colors
  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);
  static const Color kGreyText = Color(0xFF6B7280);
  static const Color kSoftBlue = Color(0xFFB3EBF2);

  /// ✅ DEFAULT AVAILABILITY (UNCHANGED)
  Map<String, dynamic> _defaultAvailability() {
    return {
      'monday': [
      ],
      'tuesday': [
      ],
      'wednesday': [
      ],
      'thursday': [
      ],
      'friday': [
      ],
      'saturday': [],
      'sunday': [],
    };
  }

  /// ======================
  /// PICK IMAGE
  /// ======================
  Future<void> _pickImage() async {
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

  Future<void> _pickQrImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (picked != null) {
      setState(() {
        _qrFile = File(picked.path);
      });
    }
  }

  /// ======================
  /// UPLOAD IMAGE
  /// ======================
  Future<String?> _uploadImage(String email) async {
    if (_imageFile == null) return null;

    final ref = FirebaseStorage.instance
        .ref()
        .child('doctors')
        .child('${DateTime.now().millisecondsSinceEpoch}_$email.jpg');

    await ref.putFile(_imageFile!);
    return await ref.getDownloadURL();
  }

  Future<String?> _uploadQrImage(String email) async {
    if (_qrFile == null) return null;

    final ref = FirebaseStorage.instance
        .ref()
        .child('doctor_qr')
        .child('${DateTime.now().millisecondsSinceEpoch}_$email.jpg');

    await ref.putFile(_qrFile!);
    return await ref.getDownloadURL();
  }

  /// ======================
  /// SAVE DOCTOR
  /// ======================
  Future<void> _saveDoctor() async {
    if (_nameController.text.trim().isEmpty ||
      _experienceController.text.trim().isEmpty ||
      _emailController.text.trim().isEmpty ||
      _aboutController.text.trim().isEmpty ||
      _priceController.text.trim().isEmpty ||
      _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim().toLowerCase();
      final photoUrl = await _uploadImage(email);
      final qrUrl = await _uploadQrImage(email);

      final functions = FirebaseFunctions.instanceFor(
        region: 'us-central1',
      );

      final callable = functions.httpsCallable('adminCreateDoctor');

      await callable.call({
        'fullName': _nameController.text.trim(),
        'email': email,
        'experience': _experienceController.text.trim(),
        'aboutMe': _aboutController.text.trim(),
        'categoryId': _selectedCategoryId,
        'categoryName': _selectedCategoryName,
        'photoUrl': photoUrl,
        'qrImageUrl': qrUrl,
        'consultationPrice': int.parse(_priceController.text.trim()),
        'currency': 'PHP',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor added successfully')),
      );

      _nameController.clear();
      _experienceController.clear();
      _emailController.clear();
      _aboutController.clear();
      _selectedCategoryId = null;
      _selectedCategoryName = null;
      _imageFile = null;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12, color: kGreyText),
      border: const OutlineInputBorder(),
      isDense: true,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _experienceController.dispose();
    _emailController.dispose();
    _aboutController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        title: const Text('Add Doctor'),
        backgroundColor: kWhite,
        elevation: 0.8,
        foregroundColor: kDarkBlue,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          /// PHOTO
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 46,
                backgroundColor: kSoftBlue,
                backgroundImage:
                    _imageFile != null ? FileImage(_imageFile!) : null,
                child: _imageFile == null
                    ? const Icon(Icons.camera_alt,
                        color: kDarkBlue, size: 28)
                    : null,
              ),
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: GestureDetector(
              onTap: _pickQrImage,
              child: Container(
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  color: kSoftBlue,
                  borderRadius: BorderRadius.circular(16),
                  image: _qrFile != null
                      ? DecorationImage(
                          image: FileImage(_qrFile!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _qrFile == null
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code, size: 28, color: kDarkBlue),
                            SizedBox(height: 6),
                            Text(
                              'Upload GCash QR',
                              style: TextStyle(
                                fontSize: 11,
                                color: kDarkBlue,
                              ),
                            ),
                          ],
                        ),
                      )
                    : null,
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// INFO
          TextField(
            controller: _nameController,
            decoration: _input('Doctor Name'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _emailController,
            decoration: _input('Email Address'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _experienceController,
            decoration: _input('Experience'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: _input('Consultation Price (PHP)'),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _aboutController,
            maxLines: 4,
            decoration: _input('About Doctor'),
          ),
          const SizedBox(height: 20),

          /// CATEGORY
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

              return DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: _input('Select Category'),
                items: categories.map((doc) {
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text(doc['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  final selectedDoc =
                      categories.firstWhere((doc) => doc.id == value);
                  setState(() {
                    _selectedCategoryId = value;
                    _selectedCategoryName = selectedDoc['name'];
                  });
                },
              );
            },
          ),

          const SizedBox(height: 24),

          /// SAVE
          ElevatedButton(
            onPressed: _isLoading ? null : _saveDoctor,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Save Doctor',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }
}
