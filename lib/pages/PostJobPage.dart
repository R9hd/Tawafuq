
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class PostJobPage extends StatefulWidget {
  const PostJobPage({super.key});

  @override
  _PostJobPageState createState() => _PostJobPageState();
}

class _PostJobPageState extends State<PostJobPage> {
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _jobDescriptionController = TextEditingController();
  final TextEditingController _jobLocationController = TextEditingController();
  final TextEditingController _jobSalaryController = TextEditingController();

  String _selectedJobType = 'On-site';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    @override
    void dispose() {
      _jobTitleController.dispose();
      _jobDescriptionController.dispose();
      _jobLocationController.dispose();
      _jobSalaryController.dispose();
      super.dispose();
    }

  Future<void> _postJob() async {
    final jobTitle = _jobTitleController.text.trim();
    final jobDescription = _jobDescriptionController.text.trim();
    final jobLocation = _jobLocationController.text.trim();
    final jobSalary = _jobSalaryController.text.trim();

    if (jobTitle.isEmpty || jobDescription.isEmpty ||
        jobLocation.isEmpty || jobSalary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user logged in')),
        );
        return;
      }
      final recruiterId = currentUser.uid;

      final jobId = const Uuid().v4();

      await _firestore.collection('part_time_jobs').add({
        'jobId': jobId,
        'jobTitle': jobTitle,
        'jobDescription': jobDescription,
        'jobLocation': jobLocation,
        'jobSalary': jobSalary,
        'jobType': _selectedJobType,
        'recruiterId': recruiterId,
        'postedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job posted successfully!')),
      );

      _jobTitleController.clear();
      _jobDescriptionController.clear();
      _jobLocationController.clear();
      _jobSalaryController.clear();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post job: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Job'),
        backgroundColor: const Color(0xFF244855),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _jobTitleController,
                decoration: const InputDecoration(
                  labelText: 'Job Title', border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _jobDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Job Description', border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _jobLocationController,
                decoration: const InputDecoration(
                  labelText: 'Job Location', border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _jobSalaryController,
                decoration: const InputDecoration(
                  labelText: 'Salary', border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedJobType,
                decoration: const InputDecoration(
                  labelText: 'Job Type', border: OutlineInputBorder(),
                ),
                items: ['On-site', 'Remote'].map((String type) {
                  return DropdownMenuItem<String>(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) { setState(() { _selectedJobType = value!; }); },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _postJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD76315),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('Post Job'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
