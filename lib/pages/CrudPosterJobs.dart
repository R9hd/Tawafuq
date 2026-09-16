
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tawafuq/pages/EditJobPoster.dart';
import 'package:tawafuq/pages/PostJobPage.dart';
import 'package:tawafuq/pages/ViewJobforAdmin.dart';
import 'package:tawafuq/pages/bars&drawers/AdminBar.dart';
import 'package:tawafuq/pages/bars&drawers/AdminDrawer.dart';

class Crudposterjobs extends StatefulWidget {
  const Crudposterjobs({super.key});

  @override
  State<Crudposterjobs> createState() => _CrudposterjobsState();
}

class _CrudposterjobsState extends State<Crudposterjobs> {
  int jobposterCount = 0;

  @override
  void initState() {
    super.initState();
    _jobposterCount();
  }

  Future<void> _jobposterCount() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('part_time_jobs').get();
      setState(() { jobposterCount = querySnapshot.size; });
    } catch (e) {
      print('Error fetching job count: $e');
    }
  }

  String searchQuery = '';
  Map<String, bool> selectedCheckboxes = {};
  List<String> selectedIds = [];

  void _deleteJobposter() async {
    try {
      for (String posterId in selectedIds) {
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('part_time_jobs')
            .where('jobId', isEqualTo: posterId)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          DocumentSnapshot userDoc = userSnapshot.docs.first;
          await FirebaseFirestore.instance
              .collection('part_time_jobs')
              .doc(userDoc.id)
              .delete()
              .then((_) {
            print('Job $posterId deleted.');
          }).catchError((error) {
            print('Error deleting job $posterId: $error');
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error deleting job: $posterId')));
          });
        } else {
          print('Job $posterId does not exist.');
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Job $posterId does not exist')));
        }
      }

      setState(() { selectedIds.clear(); selectedCheckboxes.clear(); });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jobs deleted successfully')));
    } catch (e) {
      print('Error deleting jobs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete jobs')));
    }
  }

  void _updateJobposter() async {
    List<Map<String, dynamic>> selectedJobs = [];

    try {
      for (String posterId in selectedIds) {
        QuerySnapshot jobSnapshot = await FirebaseFirestore.instance
            .collection('part_time_jobs')
            .where('jobId', isEqualTo: posterId)
            .get();

        if (jobSnapshot.docs.isNotEmpty) {
          DocumentSnapshot jobDoc = jobSnapshot.docs.first;
          selectedJobs.add({
            'jobId': jobDoc['jobId'],
            'jobTitle': jobDoc['jobTitle'],
            'jobDescription': jobDoc['jobDescription'],
            'jobLocation': jobDoc['jobLocation'],
            'jobSalary': jobDoc['jobSalary'],
            'jobType': jobDoc['jobType'],
          });
        } else {
          print("Job $posterId not found.");
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Job $posterId not found.")));
        }
      }

      if (selectedJobs.isNotEmpty) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => Editjobposter(jobData: selectedJobs)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No valid jobs selected.")));
      }
    } catch (e) {
      print("Error fetching jobs: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error fetching jobs.")));
    }
  }

  void _viewJobposter() async {
    List<Map<String, dynamic>> selectedJobs = [];

    try {
      for (String posterId in selectedIds) {
        QuerySnapshot jobSnapshot = await FirebaseFirestore.instance
            .collection('part_time_jobs')
            .where('jobId', isEqualTo: posterId)
            .get();

        if (jobSnapshot.docs.isNotEmpty) {
          DocumentSnapshot jobDoc = jobSnapshot.docs.first;
          selectedJobs.add({
            'jobId': jobDoc['jobId'],
            'jobTitle': jobDoc['jobTitle'],
            'jobDescription': jobDoc['jobDescription'],
            'jobLocation': jobDoc['jobLocation'],
            'jobSalary': jobDoc['jobSalary'],
            'jobType': jobDoc['jobType'],
          });
        } else {
          print("Job $posterId not found.");
        }
      }

      if (selectedJobs.isNotEmpty) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => Viewjobforadmin(selectedJobs: selectedJobs)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No valid jobs found.")));
      }
    } catch (e) {
      print("Error fetching jobs: $e");
    }
  }

  void _addJobposter() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => PostJobPage()));
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: const Adminbar(pageTitle: "Job Posters"),
      drawer: const Admindrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Stack(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(height: screenHeight * 0.22),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.020, vertical: screenHeight * 0.020),
                child: Container(
                  height: screenHeight * 0.15,
                  width: screenWidth * 0.85,
                  padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.009, vertical: screenHeight * 0.009),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(jobposterCount.toString(),
                          style: const TextStyle(color: Color(0xFF283E51),
                              fontWeight: FontWeight.bold, fontSize: 20)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.10),
                        child: const Text("Jobs",
                            style: TextStyle(color: Color(0xFFD76315), fontSize: 16)),
                      ),
                    ]),
                  ]),
                ),
              ),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(height: screenHeight * 0.52),
              Container(
                alignment: Alignment.bottomCenter,
                padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.010, vertical: screenHeight * 0.010),
                width: screenWidth * 0.88,
                height: screenHeight * 0.13,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      onChanged: (value) { setState(() { searchQuery = value; }); },
                      decoration: const InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        labelText: 'Search',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(height: screenHeight * 0.93),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('part_time_jobs')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Text("Error: ${snapshot.error}");
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    final jobs = snapshot.data!.docs;
                    List<DataRow> jobRows = [];

                    for (var job in jobs) {
                      var id = job['jobId'];
                      var title = job['jobTitle'];

                      if (!selectedCheckboxes.containsKey(id)) {
                        selectedCheckboxes[id] = false;
                      }

                      if (title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                          id.toString().contains(searchQuery)) {
                        jobRows.add(DataRow(cells: [
                          DataCell(Checkbox(
                            value: selectedCheckboxes[id],
                            onChanged: (bool? value) {
                              setState(() {
                                selectedCheckboxes[id] = value!;
                                if (value) { selectedIds.add(id); }
                                else { selectedIds.remove(id); }
                              });
                            },
                          )),
                          DataCell(Text(id.toString())),
                          DataCell(Text(title)),
                        ]));
                      }
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('')),
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Title')),
                        ],
                        rows: jobRows,
                      ),
                    );
                  },
                ),
              ),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(height: screenHeight * 1.3),
              ElevatedButton(
                onPressed: selectedCheckboxes.containsValue(true) ? _viewJobposter : null,
                child: const Text('View',
                    style: TextStyle(color: Color(0xFFD76315), fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: screenWidth * 0.05),
              ElevatedButton(
                onPressed: selectedCheckboxes.containsValue(true) ? _updateJobposter : null,
                child: const Text('Update',
                    style: TextStyle(color: Color(0xFFD76315), fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: screenWidth * 0.05),
              ElevatedButton(
                onPressed: selectedCheckboxes.containsValue(true) ? _deleteJobposter : null,
                child: const Text('Delete',
                    style: TextStyle(color: Color(0xFFD76315), fontWeight: FontWeight.bold)),
              ),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(height: screenHeight * 1.45),
              ElevatedButton(
                onPressed: _addJobposter,
                style: ElevatedButton.styleFrom(
                  shape: const BeveledRectangleBorder(),
                  backgroundColor: const Color(0xFF283E51),
                  padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.320, vertical: screenHeight * 0.015),
                ),
                child: const Text('Add Job Poster', style: TextStyle(color: Colors.white)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
