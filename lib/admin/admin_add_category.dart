import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AdminAddCategory extends StatefulWidget {
  const AdminAddCategory({super.key});

  @override
  State<AdminAddCategory> createState() => _AdminAddCategoryState();
}

class _AdminAddCategoryState extends State<AdminAddCategory> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController =
      TextEditingController(); // ✅ NEW

  bool _isLoading = false;

  // 🎨 Brand colors
  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);
  static const Color kSoftBlue = Color(0xFFB3EBF2);

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  /// ======================
  /// SAVE CATEGORY
  /// ======================
  Future<void> _saveCategory() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service name is required')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final normalized = name.toLowerCase();

      /// 🔒 DUPLICATE CHECK
      final existing = await FirebaseFirestore.instance
          .collection('categories')
          .where('nameLower', isEqualTo: normalized)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('Service already exists');
      }

      final imageUrl = await _uploadImage(name);

      await FirebaseFirestore.instance.collection('categories').add({
        'name': name,
        'nameLower': normalized, // 🔑 IMPORTANT
        'description': '',
        'imageUrl': imageUrl,
        'createdAt': Timestamp.now(),
      });

      _nameController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service added successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => _isLoading = false);
  }

  /// ======================
  /// PICK IMAGE
  /// ======================
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  /// ======================
  /// UPLOAD IMAGE
  /// ======================
  Future<String?> _uploadImage(String categoryName) async {
    if (_imageFile == null) return null;

    final ref = FirebaseStorage.instance
        .ref()
        .child('categories')
        .child(
          '${DateTime.now().millisecondsSinceEpoch}_$categoryName.jpg',
        );

    await ref.putFile(_imageFile!);
    return await ref.getDownloadURL();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose(); // ✅ NEW
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: kSoftBlue.withOpacity(0.35),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// HEADER
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: kDarkBlue),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Create New Service',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kDarkBlue,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),
                    const Text(
                      'Services help patients understand what care they need.',
                      style: TextStyle(color: Colors.black54),
                    ),

                    const SizedBox(height: 24),

                    /// IMAGE PICKER
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 42,
                          backgroundColor: kSoftBlue,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : null,
                          child: _imageFile == null
                              ? const Icon(Icons.camera_alt,
                                  color: kDarkBlue)
                              : null,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// SERVICE NAME
                    const Text(
                      'Service Name',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: kDarkBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration:
                          _inputDecoration('e.g. Sports PT'),
                    ),

                    const SizedBox(height: 16),

                    /// SERVICE DESCRIPTION (NEW)
                    const Text(
                      'Service Description',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: kDarkBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: _inputDecoration(
                        'Explain what this service is for',
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed:
                            _isLoading ? null : _saveCategory,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Save Service',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
