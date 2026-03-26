import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AdminEditDoctorScreen extends StatefulWidget {
  final String doctorId;
  final Map<String, dynamic> doctorData;
  final VoidCallback onOpenAvailability;

  const AdminEditDoctorScreen({
    super.key,
    required this.doctorId,
    required this.doctorData,
    required this.onOpenAvailability,
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
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _pickQrImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
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
        const SnackBar(content: Text('Doctor updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() => isLoading = false);
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
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 18),
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
    final String? photoUrl = widget.doctorData['photoUrl'];

    return Material(
      color: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Doctor',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: kDarkBlue,
                  ),
                ),

                const SizedBox(height: 20),

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
                          ? const Icon(Icons.camera_alt)
                          : null,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                _card(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nameCtrl,
                          decoration: _input('Name'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: expCtrl,
                          decoration: _input('Experience'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          decoration: _input('Price'),
                        ),
                      ),
                    ],
                  ),
                ),

                _card(
                  child: TextField(
                    controller: aboutCtrl,
                    maxLines: 4,
                    decoration: _input('About'),
                  ),
                ),

                _card(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('categories')
                        .orderBy('name')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      final categories = snapshot.data!.docs;

                      return Wrap(
                        spacing: 8,
                        children: categories.map((doc) {
                          final id = doc.id;
                          final name = doc['name'];
                          final selected =
                              selectedCategoryIds.contains(id);

                          return FilterChip(
                            label: Text(name),
                            selected: selected,
                            onSelected: (value) {
                              setState(() {
                                if (value) {
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
                ),

                _card(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickQrImage,
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: kSoftBlue,
                            borderRadius: BorderRadius.circular(10),
                            image: _qrImageFile != null
                                ? DecorationImage(
                                    image: FileImage(_qrImageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : widget.doctorData['qrImageUrl'] != null
                                    ? DecorationImage(
                                        image: NetworkImage(
                                            widget.doctorData['qrImageUrl']),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                          ),
                          child: _qrImageFile == null &&
                                  widget.doctorData['qrImageUrl'] == null
                              ? const Center(child: Text('Upload QR'))
                              : null,
                        ),
                      ),

                      const SizedBox(height: 10),

                      SwitchListTile(
                        value: activated,
                        onChanged: (value) {
                          setState(() {
                            activated = value;
                          });
                        },
                        title: const Text('Activate Doctor'),
                      ),
                    ],
                  ),
                ),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : save,
                        child: isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Save'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onOpenAvailability,
                        child: const Text('Availability'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}