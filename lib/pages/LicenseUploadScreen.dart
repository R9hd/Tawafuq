
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';

import 'package:tawafuq/pages/RecruiterStatusPage.dart';

class LicenseUploadScreen extends StatefulWidget {
  final String userId;
  final String fullName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String companyName;

  const LicenseUploadScreen({super.key, 
    required this.userId,
    required this.fullName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.companyName,
  });

  @override
  _LicenseUploadScreenState createState() => _LicenseUploadScreenState();
}

class _LicenseUploadScreenState extends State<LicenseUploadScreen> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String? _licenseFileURL;

  Future<void> _uploadLicenseFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result == null || result.files.single.path == null) {
      Fluttertoast.showToast(
        msg: "No file selected",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    final filePath = result.files.single.path!;
    if (!File(filePath).existsSync()) {
      Fluttertoast.showToast(
        msg: "File not found at the selected path",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    try {
      final file = File(filePath);
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = _storage.ref().child('licenses/${widget.userId}/$fileName');

      UploadTask uploadTask = storageRef.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      final fileURL = await snapshot.ref.getDownloadURL();

      setState(() { _licenseFileURL = fileURL; });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set({
        'fullName': widget.fullName,
        'lastName': widget.lastName,
        'email': widget.email,
        'phoneNumber': widget.phoneNumber,
        'role': 'Recruiter',
        'id': widget.userId,
        'licenseUrl': _licenseFileURL,
        'licenseChecked': false,
        'companyApproved': false,
      }, SetOptions(merge: true));

      Fluttertoast.showToast(
        msg: "License uploaded and account created successfully.",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RecruiterStatusPage()),
      );
    } catch (e) {
      print("Error: $e");
      Fluttertoast.showToast(
        msg: "Error uploading license: ${e.toString()}",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload License"),
        backgroundColor: const Color(0xFF244855),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Please upload your company license to proceed.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _uploadLicenseFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFe64833),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                ),
                child: Text("Upload License"),
              ),
              if (_licenseFileURL != null)
                const Padding(
                  padding: EdgeInsets.only(top: 20.0),
                  child: Text(
                    "License uploaded successfully.",
                    style: TextStyle(color: Colors.green),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
