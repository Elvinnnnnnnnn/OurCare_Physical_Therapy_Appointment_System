import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AdminCategoryList extends StatelessWidget {
  const AdminCategoryList({super.key});

  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kPrimaryBlue = Color(0xFF1562E2);
  static const Color kSoftBlue = Color(0xFFB3EBF2);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

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
                          const SizedBox(height: 14),
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

        /// FLOATING ADD BUTTON
        Positioned(
          bottom: 20,
          right: 80,
          child: FloatingActionButton(
            backgroundColor: kPrimaryBlue,
            onPressed: () {
              _showAddDialog(context);
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  /// ADD CATEGORY DIALOG
  void _showAddDialog(BuildContext context) {

    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    File? pickedImage;
    final picker = ImagePicker();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {

          return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// TITLE
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Create New Service',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Services help patients understand what care they need.',
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 20),

                  /// IMAGE PICKER
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await picker.pickImage(
                          source: ImageSource.gallery,
                        );

                        if (picked != null) {
                          setState(() {
                            pickedImage = File(picked.path);
                          });
                        }
                      },
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: kSoftBlue,
                        backgroundImage: pickedImage != null
                            ? FileImage(pickedImage!)
                            : null,
                        child: pickedImage == null
                            ? const Icon(Icons.camera_alt, size: 26)
                            : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// SERVICE NAME
                  const Text(
                    'Service Name',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 6),

                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. Sports PT',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  /// DESCRIPTION
                  const Text(
                    'Service Description',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 6),

                  TextField(
                    controller: descCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Explain what this service is for',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {

                        final name = nameCtrl.text.trim();
                        final normalized = name.toLowerCase();

                        if (name.isEmpty) return;

                        final existing = await FirebaseFirestore.instance
                            .collection('categories')
                            .where('nameLower', isEqualTo: normalized)
                            .get();

                        if (existing.docs.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Service already exists'),
                            ),
                          );
                          return;
                        }

                        String? imageUrl;

                        if (pickedImage != null) {
                          final ref = FirebaseStorage.instance
                              .ref()
                              .child('categories/${DateTime.now().millisecondsSinceEpoch}.jpg');

                          await ref.putFile(pickedImage!);
                          imageUrl = await ref.getDownloadURL();
                        }

                        await FirebaseFirestore.instance
                            .collection('categories')
                            .add({
                          'name': name,
                          'nameLower': normalized,
                          'description': descCtrl.text.trim(),
                          'imageUrl': imageUrl ?? '',
                        });

                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Save Service',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          );
        },
      ),
    );
  }
}

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

  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kSoftBlue = Color(0xFFB3EBF2);

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Row(
        children: [

          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: kSoftBlue,
              borderRadius: BorderRadius.circular(10),
              image: (imageUrl != null && imageUrl!.isNotEmpty)
                ? DecorationImage(
                    image: NetworkImage(imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
            ),
            child: (imageUrl == null || imageUrl!.isEmpty)
              ? const Icon(Icons.medical_services)
              : null,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (description.isNotEmpty)
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          /// 3 DOT MENU
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'edit') {
                _showEditDialog(context);
              } else if (value == 'delete') {
                _deleteCategory(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('Edit'),
              ),
              const PopupMenuItem(
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

  void _deleteCategory(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('categories')
        .doc(categoryId)
        .delete();
  }

  void _showEditDialog(BuildContext context) {

    final nameCtrl = TextEditingController(text: name);
    final descCtrl = TextEditingController(text: description);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('categories')
                  .doc(categoryId)
                  .update({
                'name': nameCtrl.text.trim(),
                'nameLower': nameCtrl.text.trim().toLowerCase(),
                'description': descCtrl.text.trim(),
              });

              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}