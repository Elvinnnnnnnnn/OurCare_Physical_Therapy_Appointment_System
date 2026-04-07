import 'dart:typed_data';
import 'dart:io'; 
import 'package:flutter/foundation.dart';
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
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  List<String> _selectedCategoryIds = [];

  bool _isLoading = false;

  Uint8List? _imageBytes;
  Uint8List? _qrBytes;

  File? _imageFile;
  File? _qrFile;

  final ImagePicker _picker = ImagePicker();

  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);
  static const Color kSoftBlue = Color(0xFFB3EBF2);

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() => _imageBytes = bytes);
      } else {
        setState(() => _imageFile = File(picked.path));
      }
    }
  }

  Future<void> _pickQrImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() => _qrBytes = bytes);
      } else {
        setState(() => _qrFile = File(picked.path));
      }
    }
  }

 Future<String?> _uploadImage(String email) async {
  if (_imageFile == null && _imageBytes == null) return null;

  final ref = FirebaseStorage.instance
      .ref()
      .child('doctors/${DateTime.now().millisecondsSinceEpoch}_$email.jpg');

  if (kIsWeb) {
    await ref.putData(_imageBytes!);
  } else {
    await ref.putFile(_imageFile!);
  }

  return await ref.getDownloadURL();
}

  Future<String?> _uploadQrImage(String email) async {
  if (_qrFile == null && _qrBytes == null) return null;

  final ref = FirebaseStorage.instance
      .ref()
      .child('doctor_qr/${DateTime.now().millisecondsSinceEpoch}_$email.jpg');

  if (kIsWeb) {
    await ref.putData(_qrBytes!);
  } else {
    await ref.putFile(_qrFile!);
  }

  return await ref.getDownloadURL();
}

  Future<void> _saveDoctor() async {

    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _experienceController.text.isEmpty ||
        _aboutController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _selectedCategoryIds.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim().toLowerCase();

      final photoUrl = await _uploadImage(email);
      final qrUrl = await _uploadQrImage(email);

      final callable = FirebaseFunctions.instance
          .httpsCallable('adminCreateDoctor');

      final rawPhone = _phoneController.text.trim();
      final phone = '+63${rawPhone.replaceAll(RegExp(r'^0'), '')}';

      await callable.call({
        'fullName': _nameController.text.trim(),
        'email': email,
        'phone': phone,
        'password': _passwordController.text.trim(),
        'experience': _experienceController.text.trim(),
        'aboutMe': _aboutController.text.trim(),
        'categoryIds': _selectedCategoryIds,
        'photoUrl': photoUrl,
        'qrImageUrl': qrUrl,
        'consultationPrice': int.parse(_priceController.text.trim()),
        'currency': 'PHP',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor added')),
        );

        _nameController.clear();
        _emailController.clear();
        _experienceController.clear();
        _aboutController.clear();
        _priceController.clear();
        _passwordController.clear(); // ✅ HERE
        _selectedCategoryIds.clear();

        setState(() {
          _imageFile = null;
          _qrFile = null;
        });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => _isLoading = false);
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF7F9FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  @override
    Widget build(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(30),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                Expanded(
                  child: SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        /// LEFT SIDE (IMAGES)
                        Expanded(
                          flex: 2,
                          child: _card(
                            child: Column(
                              children: [

                                /// PROFILE IMAGE
                                GestureDetector(
                                  onTap: _pickImage,
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 50,
                                        backgroundColor: kSoftBlue,
                                        backgroundImage: kIsWeb
                                            ? (_imageBytes != null ? MemoryImage(_imageBytes!) : null)
                                            : (_imageFile != null ? FileImage(_imageFile!) : null),
                                        child: (_imageFile == null && _imageBytes == null)
                                            ? const Icon(Icons.camera_alt, size: 28)
                                            : null,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text('Upload Profile'),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                /// QR IMAGE
                                GestureDetector(
                                  onTap: _pickQrImage,
                                  child: Container(
                                    height: 140,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: kSoftBlue,
                                      borderRadius: BorderRadius.circular(12),
                                      image: kIsWeb
                                          ? (_qrBytes != null
                                              ? DecorationImage(
                                                  image: MemoryImage(_qrBytes!),
                                                  fit: BoxFit.cover,
                                                )
                                              : null)
                                          : (_qrFile != null
                                              ? DecorationImage(
                                                  image: FileImage(_qrFile!),
                                                  fit: BoxFit.cover,
                                                )
                                              : null),
                                    ),
                                    child: (_qrFile == null && _qrBytes == null)
                                        ? const Center(
                                            child: Text('Upload QR Code'),
                                          )
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 20),

                        /// RIGHT SIDE (FORM)
                        Expanded(
                          flex: 5,
                          child: _card(
                            child: Column(
                              children: [

                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _nameController,
                                        decoration: _input('Name'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: _emailController,
                                        decoration: _input('Email'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.number,
                                        decoration: _input('Phone').copyWith(
                                          prefixText: '+63 ',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),

                                    /// ✅ ADD THIS
                                    Expanded(
                                      child: TextField(
                                        controller: _passwordController,
                                        obscureText: true,
                                        decoration: _input('Password'),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _experienceController,
                                        decoration: _input('Experience'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: _priceController,
                                        keyboardType: TextInputType.number,
                                        decoration: _input('Price'),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                TextField(
                                  controller: _aboutController,
                                  maxLines: 4,
                                  decoration: _input('About Therapist'),
                                ),

                                const SizedBox(height: 14),

                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: const Text(
                                    'Categories',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('categories')
                                      .snapshots(),
                                  builder: (context, snapshot) {

                                    if (!snapshot.hasData) {
                                      return const CircularProgressIndicator();
                                    }

                                    final categories = snapshot.data!.docs;

                                    return Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: categories.map((doc) {

                                        final id = doc.id;
                                        final name = doc['name'];
                                        final selected =
                                            _selectedCategoryIds.contains(id);

                                        return FilterChip(
                                          label: Text(name),
                                          selected: selected,
                                          selectedColor:
                                              kPrimaryBlue.withOpacity(0.2),
                                          onSelected: (value) {
                                            setState(() {
                                              if (value) {
                                                _selectedCategoryIds.add(id);
                                              } else {
                                                _selectedCategoryIds.remove(id);
                                              }
                                            });
                                          },
                                        );

                                      }).toList(),
                                    );
                                  },
                                ),

                                const SizedBox(height: 20),

                                /// SAVE BUTTON
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: SizedBox(
                                    height: 45,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kPrimaryBlue,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 30),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed:
                                          _isLoading ? null : _saveDoctor,
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                        'Save Therapist',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
}