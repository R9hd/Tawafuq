
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tawafuq/pages/ViewOrgforAdmin.dart';
import 'package:tawafuq/pages/bars&drawers/AdminBar.dart';
import 'package:tawafuq/pages/bars&drawers/AdminDrawer.dart';
import 'package:url_launcher/url_launcher.dart';

class Crudsigneduporg extends StatefulWidget {
  const Crudsigneduporg({super.key});

  @override
  State<Crudsigneduporg> createState() => _CrudsigneduporgState();
}

class _CrudsigneduporgState extends State<Crudsigneduporg> {
  @override
  void initState() {
    super.initState();
    _companiesCount();
  }

  int companiesCount = 0;

  Future<void> _companiesCount() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Recruiter')
          .where('companyApproved', isEqualTo: true)
          .get();
      setState(() { companiesCount = querySnapshot.size; });
    } catch (e) {
      print('Error fetching company count: $e');
    }
  }

  String searchQuery = '';
  Map<String, bool> selectedCheckboxes = {};
  List<String> selectedIds = [];
  Map<String, String> _phoneNumbers = {};

  void _refuseCompanies() async {
    try {
      for (String posterId in selectedIds) {
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('id', isEqualTo: posterId)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          DocumentSnapshot userDoc = userSnapshot.docs.first;
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userDoc.id)
              .delete()
              .then((_) {
            print('Company $posterId deleted.');
          }).catchError((error) {
            print('Error deleting $posterId: $error');
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error deleting company: $posterId')));
          });
        } else {
          print('Company $posterId does not exist.');
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Company $posterId does not exist')));
        }
      }

      setState(() { selectedIds.clear(); selectedCheckboxes.clear(); });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Companies rejected successfully')));
    } catch (e) {
      print('Error rejecting companies: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to reject companies')));
    }
  }

  void _acceptCompanies() async {
    try {
      for (String userId in selectedIds) {
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('id', isEqualTo: userId)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          DocumentSnapshot userDoc = userSnapshot.docs.first;
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userDoc.id)
              .update({'companyApproved': true, 'licenseChecked': true})
              .then((_) {
            print('Company $userId approved.');
          }).catchError((error) {
            print('Error approving $userId: $error');
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error approving company: $userId')));
          });
        } else {
          print('Company $userId does not exist.');
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Company $userId does not exist')));
        }
      }

      setState(() { selectedIds.clear(); selectedCheckboxes.clear(); });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Companies approved successfully')));
    } catch (e) {
      print('Error approving companies: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to approve companies')));
    }
  }

  void _viewCompanies(String userId) async {
    List<Map<String, dynamic>> selectedOrgs = [];

    try {
      for (String id in selectedIds) {
        QuerySnapshot orgSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('id', isEqualTo: id)
            .where('role', isEqualTo: 'Recruiter')
            .get();

        if (orgSnapshot.docs.isNotEmpty) {
          DocumentSnapshot orgDoc = orgSnapshot.docs.first;
          selectedOrgs.add({
            'id': orgDoc['id'],
            'fullName': orgDoc['fullName'],
            'email': orgDoc['email'],
            'phoneNumber': orgDoc['phoneNumber'],
            'joining month': orgDoc['joining month'],
            'licenseChecked': orgDoc['licenseChecked'],
            'companyApproved': orgDoc['companyApproved'],
            'licenseUrl': orgDoc['licenseUrl'],
          });
        } else {
          print("Org $selectedOrgs not found.");
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Poster with ID: $selectedOrgs not found.")));
        }
      }

      if (selectedOrgs.isNotEmpty) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => Vieworgforadmin(companyData: selectedOrgs)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No valid companies found.")));
      }
    } catch (e) {
      print("Error fetching companies: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error fetching companies.")));
    }
  }

  void _callCompany(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: const Adminbar(pageTitle: "Companies license"),
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
                      Text(
                        companiesCount.toString(),
                        style: const TextStyle(color: Color(0xFF283E51),
                            fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.10),
                        child: const Text("Companies",
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
            Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              SizedBox(height: screenHeight * 0.62),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(height: screenHeight * 0.93),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'Recruiter')
                      .where('companyApproved', isEqualTo: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Text("Error: ${snapshot.error}");
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    final orgs = snapshot.data!.docs;
                    List<DataRow> userRows = [];

                    for (var org in orgs) {
                      var id = org['id'];
                      var name = org['fullName'];
                      var lic = org['licenseUrl'];
                      _phoneNumbers[id] = org['phoneNumber'] ?? '';

                      if (!selectedCheckboxes.containsKey(id)) {
                        selectedCheckboxes[id] = false;
                      }

                      if (name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                          id.toString().contains(searchQuery) ||
                          lic.toLowerCase().contains(searchQuery.toLowerCase())) {
                        userRows.add(DataRow(cells: [
                          DataCell(Checkbox(
                            value: selectedCheckboxes[id],
                            onChanged: (bool? value) {
                              setState(() {
                                selectedCheckboxes[id] = value!;
                                if (value) {
                                  selectedIds.add(id);
                                } else {
                                  selectedIds.remove(id);
                                }
                              });
                            },
                          )),
                          DataCell(Text(id)),
                          DataCell(Text(name)),
                          DataCell(
                            InkWell(
                              child: const Text('Download File',
                                  style: TextStyle(color: Colors.blue,
                                      decoration: TextDecoration.underline)),
                              onTap: () async {
                                if (lic == null || lic.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('File URL is missing')));
                                  return;
                                }

                                try {
                                  if (await requestStoragePermission()) {
                                    final directory = Directory('/storage/emulated/0/Download');
                                    final filePath = '${directory.path}/${Uri.parse(lic).pathSegments.last}';
                                    await Dio().download(
                                      lic, filePath,
                                      onReceiveProgress: (received, total) {
                                        if (total != -1) {
                                          print('${(received / total * 100).toStringAsFixed(0)}%');
                                        }
                                      },
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('File downloaded to $filePath')));
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Storage permission denied')));
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error downloading file: $e')));
                                }
                              },
                            ),
                          ),
                        ]));
                      }
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('')),
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('USER')),
                          DataColumn(label: Text('LICENSE')),
                        ],
                        rows: userRows,
                      ),
                    );
                  },
                ),
              ),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(height: screenHeight * 1.3),
              ElevatedButton(
                onPressed: selectedCheckboxes.containsValue(true)
                    ? () {
                        _viewCompanies(selectedCheckboxes.keys.firstWhere(
                            (key) => selectedCheckboxes[key] == true));
                      }
                    : null,
                child: const Text('View',
                    style: TextStyle(color: Color(0xFFD76315), fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: screenWidth * 0.13),
              ElevatedButton(
                onPressed: selectedCheckboxes.containsValue(true)
                    ? () { _acceptCompanies(); }
                    : null,
                child: const Text('Accept',
                    style: TextStyle(color: Color(0xFFD76315), fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: screenWidth * 0.10),
              ElevatedButton(
                onPressed: selectedCheckboxes.containsValue(true)
                    ? _refuseCompanies : null,
                child: const Text('Reject',
                    style: TextStyle(color: Color(0xFFD76315), fontWeight: FontWeight.bold)),
              ),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(height: screenHeight * 1.45),
              ElevatedButton(
                onPressed: () {
                  if (selectedIds.length == 1) {
                    final phone = _phoneNumbers[selectedIds.first] ?? '';
                    if (phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No phone number for this company')));
                    } else {
                      _callCompany(phone);
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Select one company to contact')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: const BeveledRectangleBorder(),
                  backgroundColor: const Color(0xFF283E51),
                  padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.320, vertical: screenHeight * 0.015),
                ),
                child: const Text('Contact company', style: TextStyle(color: Colors.white)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) { await openAppSettings(); return false; }
    return false;
  }
}
