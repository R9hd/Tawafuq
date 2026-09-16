
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tawafuq/pages/bars&drawers/AdminDrawer.dart';

class Editjobposter extends StatefulWidget {
  const Editjobposter({super.key, required this.jobData});
  final List<Map<String, dynamic>> jobData;

  @override
  State<Editjobposter> createState() => _EditjobposterState();
}

class _EditjobposterState extends State<Editjobposter> {
  final List<TextEditingController> _titleControllers = [];
  final List<TextEditingController> _descriptionControllers = [];
  final List<TextEditingController> _locationControllers = [];
  final List<TextEditingController> _salaryControllers = [];
  final List<String> _jobTypes = [];

  @override
  void initState() {
    super.initState();
    for (var job in widget.jobData) {
      _titleControllers.add(TextEditingController(text: job['jobTitle'] ?? ''));
      _descriptionControllers.add(TextEditingController(text: job['jobDescription'] ?? ''));
      _locationControllers.add(TextEditingController(text: job['jobLocation'] ?? ''));
      _salaryControllers.add(TextEditingController(text: job['jobSalary'] ?? ''));
      _jobTypes.add(job['jobType'] ?? 'On-site');
    }
  }

  @override
  void dispose() {
    for (var c in _titleControllers) {
      c.dispose();
    }
    for (var c in _descriptionControllers) {
      c.dispose();
    }
    for (var c in _locationControllers) {
      c.dispose();
    }
    for (var c in _salaryControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _saveJobs() async {
    List<Map<String, dynamic>> updatedJobs = [];

    for (int i = 0; i < widget.jobData.length; i++) {
      updatedJobs.add({
        'jobTitle': _titleControllers[i].text,
        'jobDescription': _descriptionControllers[i].text,
        'jobLocation': _locationControllers[i].text,
        'jobSalary': _salaryControllers[i].text,
        'jobType': _jobTypes[i],
        'jobId': widget.jobData[i]['jobId'],
      });
    }

    try {
      for (var updatedJob in updatedJobs) {
        QuerySnapshot jobSnapshot = await FirebaseFirestore.instance
            .collection('part_time_jobs')
            .where('jobId', isEqualTo: updatedJob['jobId'])
            .get();

        if (jobSnapshot.docs.isNotEmpty) {
          DocumentSnapshot jobDoc = jobSnapshot.docs.first;
          await FirebaseFirestore.instance
              .collection('part_time_jobs')
              .doc(jobDoc.id)
              .update({
            'jobTitle': updatedJob['jobTitle'],
            'jobDescription': updatedJob['jobDescription'],
            'jobLocation': updatedJob['jobLocation'],
            'jobSalary': updatedJob['jobSalary'],
            'jobType': updatedJob['jobType'],
            'postedAt': FieldValue.serverTimestamp(),
          });
        } else {
          print("Job poster with ID ${updatedJob['jobId']} not found.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to find job poster with ID: ${updatedJob['jobId']}")),
          );
        }
      }

      Navigator.pop(context, updatedJobs);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job posters updated successfully!')),
      );
    } catch (e) {
      print("Error updating job posters: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update job posters: ${e.toString()}')),
      );
    }
  }

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
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: widget.jobData.length,
          itemBuilder: (context, index) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: const Text("Job Title"),
                  subtitle: TextFormField(
                    controller: _titleControllers[index],
                    decoration: const InputDecoration(hintText: "Enter Job Title"),
                  ),
                ),
                const SizedBox(height: 16.0),
                ListTile(
                  title: const Text("Job Description"),
                  subtitle: TextFormField(
                    controller: _descriptionControllers[index],
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: "Enter Job Description"),
                  ),
                ),
                const SizedBox(height: 16.0),
                ListTile(
                  title: const Text("Job Location"),
                  subtitle: TextFormField(
                    controller: _locationControllers[index],
                    decoration: const InputDecoration(hintText: "Enter Job Location"),
                  ),
                ),
                const SizedBox(height: 16.0),
                ListTile(
                  title: const Text("Job Salary"),
                  subtitle: TextFormField(
                    controller: _salaryControllers[index],
                    decoration: const InputDecoration(hintText: "Enter Job Salary"),
                  ),
                ),
                const SizedBox(height: 16.0),
                ListTile(
                  title: const Text("Job Type"),
                  subtitle: DropdownButton<String>(
                    value: _jobTypes[index],
                    items: ['On-site', 'Remote'].map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() { _jobTypes[index] = newValue!; });
                    },
                  ),
                ),
                const SizedBox(height: 32.0),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveJobs,
        backgroundColor: Colors.green,
        child: const Icon(Icons.save),
      ),
    );
  }
}
