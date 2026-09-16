
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewApplicantsPage extends StatefulWidget {
  const ViewApplicantsPage({super.key});

  @override
  _ViewApplicantsPageState createState() => _ViewApplicantsPageState();
}

class _ViewApplicantsPageState extends State<ViewApplicantsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<String>> _fetchRecruiterJobIds() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    try {
      QuerySnapshot jobsSnapshot = await _firestore
          .collection('part_time_jobs')
          .where('recruiterId', isEqualTo: currentUser.uid)
          .get();
      return jobsSnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error fetching recruiter jobs: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchApplicants(List<String> recruiterJobIds) async {
    if (recruiterJobIds.isEmpty) return [];

    try {
      QuerySnapshot applicationsSnapshot = await _firestore
          .collection('job_applications')
          .where('jobId', whereIn: recruiterJobIds)
          .get();

      List<Map<String, dynamic>> applicantsData = [];

      for (var doc in applicationsSnapshot.docs) {
        final applicationData = doc.data() as Map<String, dynamic>;

        if (applicationData['userId'] != null) {
          DocumentSnapshot userSnapshot = await _firestore
              .collection('users')
              .doc(applicationData['userId'])
              .get();

          Map<String, dynamic> userData =
              userSnapshot.data() as Map<String, dynamic>? ?? {};

          applicantsData.add({
            'jobId': applicationData['jobId'] ?? 'N/A',
            'jobTitle': applicationData['jobTitle'] ?? 'N/A',
            'appliedAt': (applicationData['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            'fullName': userData['fullName'] ?? 'N/A',
            'email': userData['email'] ?? 'N/A',
            'phoneNumber': userData['phoneNumber'] ?? 'N/A',
            'uploadedFileURL': userData['uploadedFileURL'] ?? '',
            'userId': applicationData['userId'],
            'applicationId': doc.id,
          });
        }
      }
      return applicantsData;
    } catch (e) {
      print('Error fetching applicants: $e');
      return [];
    }
  }

  Future<void> _acceptApplicant(String applicationId, String jobId,
      String jobTitle, String jobSeekerId) async {
    try {
      await _firestore.collection('job_applications').doc(applicationId).update({
        'status': 'Accepted',
      });

      await _firestore.collection('job_offers').add({
        'jobSeekerId': jobSeekerId,
        'jobId': jobId,
        'jobTitle': jobTitle,
        'status': 'Accepted',
        'companyName': _auth.currentUser?.displayName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Applicant accepted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting applicant: $e')),
      );
    }
  }

  Future<void> _rejectApplicant(String applicationId) async {
    try {
      await _firestore.collection('job_applications').doc(applicationId).update({
        'status': 'Rejected',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Applicant rejected successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting applicant: $e')),
      );
    }
  }

  Future<void> _openCvUrl(String uploadedFileURL) async {
    if (uploadedFileURL.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CV URL is empty')),
      );
      return;
    }
    try {
      final encodedUrl = Uri.encodeFull(uploadedFileURL);
      if (await canLaunch(encodedUrl)) {
        await launch(encodedUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open CV URL')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error opening CV')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Applicants'),
        backgroundColor: const Color(0xFF244855),
      ),
      body: FutureBuilder<List<String>>(
        future: _fetchRecruiterJobIds(),
        builder: (context, jobIdsSnapshot) {
          if (jobIdsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (jobIdsSnapshot.hasError) {
            return const Center(child: Text('Error fetching jobs for recruiter'));
          }
          if (!jobIdsSnapshot.hasData || jobIdsSnapshot.data!.isEmpty) {
            return const Center(child: Text('No jobs found for this recruiter.'));
          }

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchApplicants(jobIdsSnapshot.data!),
            builder: (context, applicantsSnapshot) {
              if (applicantsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (applicantsSnapshot.hasError) {
                return const Center(child: Text('Error fetching applicants'));
              }
              if (!applicantsSnapshot.hasData || applicantsSnapshot.data!.isEmpty) {
                return const Center(child: Text('No applicants found for these jobs.'));
              }

              final applicants = applicantsSnapshot.data!;

              return SingleChildScrollView(
                child: Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      itemCount: applicants.length,
                      itemBuilder: (context, index) {
                        final applicant = applicants[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(applicant['fullName'] ?? 'Unnamed Applicant'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Job Title: ${applicant['jobTitle']}'),
                                Text('Email: ${applicant['email']}'),
                                Text('Phone: ${applicant['phoneNumber']}'),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _openCvUrl(applicant['uploadedFileURL']),
                                  icon: const Icon(Icons.file_open),
                                  label: const Text('View CV', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF244855)),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: () => _acceptApplicant(
                                    applicant['applicationId'], applicant['jobId'],
                                    applicant['jobTitle'], applicant['userId'],
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF244855),
                                    minimumSize: const Size(80, 36),
                                  ),
                                  child: Text('Accept', style: TextStyle(color: Colors.white)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _rejectApplicant(applicant['applicationId']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    minimumSize: const Size(80, 36),
                                  ),
                                  child: Text('Reject', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
