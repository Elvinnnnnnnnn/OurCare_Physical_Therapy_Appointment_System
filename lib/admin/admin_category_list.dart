import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'admin_add_category.dart';

class AdminCategoryList extends StatelessWidget {
  const AdminCategoryList({super.key});

  // 🎨 Brand colors
  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kDarkBlue = Color(0xFF001C99);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,

      /// ➕ ADD SERVICE BUTTON
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminAddCategory(),
            ),
          );
        },
      ),

      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // ✅ FAB SAFE SPACE
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            const Text(
              'Services',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kDarkBlue,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Manage clinic services',
              style: TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 20),

            /// SERVICE LIST
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('categories')
                    .orderBy('name')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final categories = snapshot.data!.docs;

                  if (categories.isEmpty) {
                    return const Center(
                      child: Text('No services found'),
                    );
                  }

                  return ListView.separated(
                    itemCount: categories.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final data =
                          category.data() as Map<String, dynamic>;

                      return _CategoryCard(
                        categoryId: category.id,
                        name: data['name'],
                        description: data['description'] ?? '',
                        imageUrl: data['imageUrl'],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ======================
/// SERVICE CARD
/// ======================
class _CategoryCard extends StatelessWidget {
  final String categoryId;
  final String name;
  final String description;
  final String? imageUrl;

  const _CategoryCard({
    required this.categoryId,
    required this.name,
    required this.description,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          /// IMAGE
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFB3EBF2),
            backgroundImage:
                imageUrl != null ? NetworkImage(imageUrl!) : null,
            child: imageUrl == null
                ? const Icon(Icons.medical_services,
                    color: Color(0xFF001C99))
                : null,
          ),

          const SizedBox(width: 14),

          /// NAME + DESCRIPTION
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),

          /// MENU
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _editService(
                  context,
                  categoryId,
                  name,
                  description,
                  imageUrl,
                );
              }
              if (value == 'delete') {
                _deleteService(context, categoryId);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'edit',
                child: Text('Edit'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ======================
  /// EDIT SERVICE (NAME + MEANING + PHOTO)
  /// ======================
  void _editService(
    BuildContext context,
    String categoryId,
    String currentName,
    String currentDesc,
    String? currentImage,
  ) {
    final nameCtrl = TextEditingController(text: currentName);
    final descCtrl = TextEditingController(text: currentDesc);

    File? pickedImage;
    final picker = ImagePicker();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Service'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picked = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 75,
                      );
                      if (picked != null) {
                        setState(() {
                          pickedImage = File(picked.path);
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(0xFFB3EBF2),
                      backgroundImage: pickedImage != null
                          ? FileImage(pickedImage!)
                          : currentImage != null
                              ? NetworkImage(currentImage)
                                  as ImageProvider
                              : null,
                      child: pickedImage == null &&
                              currentImage == null
                          ? const Icon(Icons.camera_alt)
                          : null,
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Service Name',
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Service Meaning / Description',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newName = nameCtrl.text.trim();
                  final normalized = newName.toLowerCase();

                  /// 🔒 DUPLICATE CHECK
                  final existing = await FirebaseFirestore.instance
                      .collection('categories')
                      .where('nameLower', isEqualTo: normalized)
                      .get();

                  final duplicate = existing.docs.any(
                    (doc) => doc.id != categoryId,
                  );

                  if (duplicate) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Service name already exists'),
                      ),
                    );
                    return;
                  }

                  String? imageUrl = currentImage;

                  if (pickedImage != null) {
                    final ref = FirebaseStorage.instance
                        .ref()
                        .child('categories')
                        .child(
                            '${DateTime.now().millisecondsSinceEpoch}.jpg');

                    await ref.putFile(pickedImage!);
                    imageUrl = await ref.getDownloadURL();
                  }

                  await FirebaseFirestore.instance
                      .collection('categories')
                      .doc(categoryId)
                      .update({
                    'name': newName,
                    'nameLower': normalized,
                    'description': descCtrl.text.trim(),
                    'imageUrl': imageUrl,
                  });

                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// ======================
  /// DELETE SERVICE (SAFE)
  /// ======================
  Future<void> _deleteService(
    BuildContext context,
    String categoryId,
  ) async {
    final doctors = await FirebaseFirestore.instance
        .collection('doctors')
        .where('categoryId', isEqualTo: categoryId)
        .limit(1)
        .get();

    if (doctors.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot delete service.\nDoctors are still assigned.',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Service'),
        content: const Text(
          'Are you sure you want to delete this service?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('categories')
                  .doc(categoryId)
                  .delete();

              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
