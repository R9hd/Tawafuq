
import 'package:flutter/material.dart';
import 'package:tawafuq/pages/bars&drawers/AdminDrawer.dart';
import '../job_card.dart';

class Viewjobforadmin extends StatelessWidget {
  const Viewjobforadmin({super.key, required this.selectedJobs});
  final List<Map<String, dynamic>> selectedJobs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const Admindrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF244855),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () { Navigator.pop(context); },
        ),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () { Scaffold.of(context).openEndDrawer(); },
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: ListView.builder(
        itemCount: selectedJobs.length,
        itemBuilder: (context, index) {
          final job = selectedJobs[index];
          return JobCard(
            jobTitle: job['jobTitle'],
            jobDescription: job['jobDescription'] ?? 'No description available',
            jobLocation: job['jobLocation'] ?? 'N/A',
            jobSalary: job['jobSalary'],
            jobType: job['jobType'] ?? 'On-site',
            jobId: job['jobId'],
          );
        },
      ),
    );
  }
}
