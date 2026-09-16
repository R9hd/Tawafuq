
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tawafuq/pages/RecruiterHome.dart';

class RecruiterStatusPage extends StatefulWidget {
  const RecruiterStatusPage({super.key});

  @override
  _RecruiterStatusPageState createState() => _RecruiterStatusPageState();
}

class _RecruiterStatusPageState extends State<RecruiterStatusPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isApproved = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkApprovalStatus();
  }

  Future<void> _checkApprovalStatus() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (userDoc.exists) {
        setState(() {
          _isApproved = userDoc['companyApproved'] ?? false;
          _isLoading = false;
        });

        if (_isApproved) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => RecruiterHome()),
          );
        }
      } else {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval Status'),
        backgroundColor: const Color(0xFF244855),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _isApproved
                ? const Text(
                    'You are approved! Redirecting...',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hourglass_empty, size: 80, color: Colors.grey),
                      SizedBox(height: 20),
                      Text('Waiting for admin approval.', style: TextStyle(fontSize: 18)),
                      SizedBox(height: 10),
                      Text('Please check back later.',
                          style: TextStyle(fontSize: 14, color: Colors.grey)),
                      SizedBox(height: 30),
                    ],
                  ),
      ),
    );
  }
}
