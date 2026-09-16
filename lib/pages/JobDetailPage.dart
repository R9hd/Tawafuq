
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tawafuq/job_card.dart';

class JobDetailPage extends StatelessWidget {
  final JobCard job;

  const JobDetailPage({super.key, required this.job});

  Future<void> _applyToJob(BuildContext context) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to apply for the job')),
      );
      return;
    }

    String userId = user.uid;

    try {
      await FirebaseFirestore.instance.collection('job_applications').add({
        'userId': userId,
        'jobTitle': job.jobTitle,
        'jobId': job.jobId,
        'appliedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully applied to ${job.jobTitle}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to apply for job: $e')),
      );
    }
  }

  Future<void> _bookmarkJob(BuildContext context) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to bookmark the job')),
      );
      return;
    }

    String userId = user.uid;

    try {
      await FirebaseFirestore.instance.collection('bookmarks').add({
        'userId': userId,
        'jobTitle': job.jobTitle,
        'jobDescription': job.jobDescription,
        'jobLocation': job.jobLocation,
        'jobType': job.jobType,
        'jobSalary': job.jobSalary,
        'bookmarkedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${job.jobTitle} bookmarked!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to bookmark job: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(job.jobTitle),
        backgroundColor: const Color(0xFF244855),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job.jobTitle,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(job.jobDescription, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('Job Type: ${job.jobType}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('job Location: ${job.jobLocation}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('job Salary: ${job.jobSalary} SAR',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _applyToJob(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD76315),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Apply to Job'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _bookmarkJob(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD76315),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Icon(Icons.bookmark),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
