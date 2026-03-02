import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PaymentScreen extends StatefulWidget {
  final String paymentId;

  const PaymentScreen({super.key, required this.paymentId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool loading = false;
  final TextEditingController _amountController = TextEditingController();

  File? _screenshotFile;
  final ImagePicker _picker = ImagePicker();

  Map<String, dynamic>? paymentData;
  Map<String, dynamic>? doctorData;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final paymentDoc = await FirebaseFirestore.instance
        .collection('payments')
        .doc(widget.paymentId)
        .get();

    paymentData = paymentDoc.data();

    // ✅ AUTO FILL AMOUNT HERE
    if (paymentData != null) {
      _amountController.text =
          paymentData?['amount']?.toString() ?? '';

      final doctorDoc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(paymentData!['doctorId'])
          .get();

      doctorData = doctorDoc.data();
    }

    setState(() {});
  }

  Future<void> pickScreenshot() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null) {
      setState(() {
        _screenshotFile = File(picked.path);
      });
    }
  }

  Future<String?> uploadScreenshot() async {
    if (_screenshotFile == null) return null;

    final ref = FirebaseStorage.instance
        .ref()
        .child('payment_screenshots')
        .child('${widget.paymentId}.jpg');

    await ref.putFile(_screenshotFile!);
    return await ref.getDownloadURL();
  }

  Future<void> confirmPayment() async {
  if (_amountController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter amount')),
    );
    return;
  }

  final double enteredAmount =
      double.tryParse(_amountController.text) ?? 0;

  if (enteredAmount <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid amount')),
    );
    return;
  }

  if (_screenshotFile == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please upload screenshot')),
    );
    return;
  }

  setState(() => loading = true);

  final paymentDoc = await FirebaseFirestore.instance
      .collection('payments')
      .doc(widget.paymentId)
      .get();

  final data = paymentDoc.data();
  if (data == null) {
    setState(() => loading = false);
    return;
  }

  final screenshotUrl = await uploadScreenshot();
  if (screenshotUrl == null) {
    setState(() => loading = false);
    return;
  }

  final userSnap = await FirebaseFirestore.instance
      .collection('users')
      .doc(data['userId'])
      .get();

  final userData = userSnap.data();

  await FirebaseFirestore.instance
      .collection('payments')
      .doc(widget.paymentId)
      .update({
    'status': 'for_verification',
    'submittedAt': FieldValue.serverTimestamp(),
    'screenshotUrl': screenshotUrl,
    'amountPaid': enteredAmount,
  });

  await FirebaseFirestore.instance.collection('appointments').add({
    'userId': data['userId'],
    'patientName': userData?['fullName'] ?? 'Unknown',
    'patientEmail': userData?['email'] ?? '',
    'doctorId': data['doctorId'],
    'doctorName': data['doctorName'],
    'categoryName': data['categoryName'],
    'amountPaid': enteredAmount,
    'currency': data['currency'],
    'date': data['date'],
    'time': data['time'],
    'status': 'pending',
    'paymentStatus': 'for_verification',
    'paymentId': widget.paymentId,
    'createdAt': FieldValue.serverTimestamp(),
  });

  setState(() => loading = false);

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Payment submitted')),
  );

  Navigator.pop(context);
  Navigator.pop(context);
}

  @override
  Widget build(BuildContext context) {
    if (paymentData == null || doctorData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),

              /// TITLE
              const Text(
                "Scan to Pay",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Amount: ₱${paymentData!['amount']}",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 20),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Enter Amount to Pay",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Enter amount",
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white12,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// QR CARD
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: doctorData!['qrImageUrl'] != null
                    ? Image.network(
                        doctorData!['qrImageUrl'],
                        height: 300,
                        fit: BoxFit.contain,
                      )
                    : const SizedBox(
                        height: 200,
                        child: Center(
                          child: Text("No QR available"),
                        ),
                      ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Open GCash app and scan this QR",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 40),

              /// UPLOAD SECTION
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Upload Payment Screenshot",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    GestureDetector(
                      onTap: pickScreenshot,
                      child: Container(
                        height: 170,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(16),
                          image: _screenshotFile != null
                              ? DecorationImage(
                                  image: FileImage(_screenshotFile!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _screenshotFile == null
                            ? const Center(
                                child: Text(
                                  "Tap to upload",
                                  style: TextStyle(color: Colors.white54),
                                ),
                              )
                            : null,
                      ),
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading ? null : confirmPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Submit Payment",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}