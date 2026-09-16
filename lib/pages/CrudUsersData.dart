
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tawafuq/pages/CreateAccountScreen.dart';
import 'package:tawafuq/pages/Edituser.dart';
import 'package:tawafuq/pages/view_user_for_admin.dart';
import 'package:tawafuq/pages/bars&drawers/AdminBar.dart';
import 'package:tawafuq/pages/bars&drawers/AdminDrawer.dart';

class CrudUsersData extends StatefulWidget {
  const CrudUsersData({super.key});

  @override
  State<CrudUsersData> createState() => _CrudUsersData();
}

class _CrudUsersData extends State<CrudUsersData> {

  @override
  void initState() {
    super.initState();
    _jobseekersCount();
    _recruiterCount();
  }

  int recruiterCount = 0;
  int jobseekersCount = 0;

  Future<void> _jobseekersCount() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users').where('role', isEqualTo: 'Job Seeker').get();
      setState(() { jobseekersCount = querySnapshot.size; });
    } catch (e) {
      print('Error fetching jobseeker count: $e');
      
    }
  }

  Future<void> _recruiterCount() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users').where('role', isEqualTo: 'Recruiter').get();
      setState(() { recruiterCount = querySnapshot.size; });
    } catch (e) {
      print('Error fetching recruiter count: $e');
    }
  }

  String searchQuery = '';
  List<String> selectedUserIds = [];
  Map<String, bool> selectedCheckboxes = {};

  void _deleteUser() async {
    try {
      for (String userId in selectedUserIds) {
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('id', isEqualTo: userId)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          DocumentSnapshot userDoc = userSnapshot.docs.first;
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userDoc.id)
              .delete()
              .then((_) {

          }).catchError((error) {

            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error deleting user: $userId')));
          });
        } else {

          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('User $userId does not exist')));
        }
      }

      setState(() { selectedUserIds.clear(); selectedCheckboxes.clear(); });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Users deleted from Firestore. Firebase Auth records NOT deleted.')));
    } catch (e) {
      print('Error deleting users: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete users')));
    }
  }

  void _updateUser() async {
    List<Map<String, dynamic>> selectedUsers = [];

    try {
      for (String userId in selectedUserIds) {
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('id', isEqualTo: userId)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          DocumentSnapshot userDoc = userSnapshot.docs.first;
          selectedUsers.add({
            'id': userDoc['id'],
            'fullName': userDoc['fullName'],
            'lastName': userDoc['lastName'],
            'email': userDoc['email'],
            'phoneNumber': userDoc['phoneNumber'],
            'joining month': userDoc['joining month'],
            'role': userDoc['role'],
            if (userDoc['role'] == 'Recruiter') ...{
              'licenseUrl': userDoc['licenseUrl'],
              'licenseChecked': userDoc['licenseChecked'],
              'companyApproved': userDoc['companyApproved'],
            },
          });
        } else {
          print("User $userId not found.");
        }
      }

      if (selectedUsers.isNotEmpty) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => Edituser(userData: selectedUsers)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No valid users selected.")));
      }
    } catch (e) {
      print("Error fetching users: $e");
    }
  }

  void _viewUser() async {
    List<Map<String, dynamic>> selectedUsers = [];

    try {
      for (String userId in selectedUserIds) {
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('id', isEqualTo: userId)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          DocumentSnapshot userDoc = userSnapshot.docs.first;
          selectedUsers.add({
            'id': userDoc['id'],
            'fullName': userDoc['fullName'],
            'email': userDoc['email'],
            'phoneNumber': userDoc['phoneNumber'],
            'joining month': userDoc['joining month'],
            'role': userDoc['role'],
            if (userDoc['role'] == 'Recruiter') ...{
              'licenseUrl': userDoc['licenseUrl'],
              'licenseChecked': userDoc['licenseChecked'],
              'companyApproved': userDoc['companyApproved'],
            },
          });
        }
      }

      if (selectedUsers.isNotEmpty) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => ViewUserForAdmin(usersData: selectedUsers)));
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void _addUser() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) =>
            CreateAccountScreen(role: 'Job Seeker', isVoiceSystemEnabled: false)));
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: const Adminbar(pageTitle: "Users Data"),
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
                      Text(jobseekersCount.toString(),
                          style: const TextStyle(color: Color(0xFF283E51),
                              fontWeight: FontWeight.bold, fontSize: 20)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
                        child: const Text("Job Seekers",
                            style: TextStyle(color: Color(0xFFD76315), fontSize: 16)),
                      ),
                    ]),
                    Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(recruiterCount.toString(),
                          style: const TextStyle(color: Color(0xFF283E51),
                              fontWeight: FontWeight.bold, fontSize: 20)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
                        child: const Text("Recruiters",
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
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Text("Error: ${snapshot.error}");
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    final users = snapshot.data!.docs;
                    List<DataRow> userRows = [];

                    for (var user in users) {
                      var id = user['id'];
                      var name = user['fullName'];
                      var email = user['email'];
                      var role = user['role'];

                      if (!selectedCheckboxes.containsKey(id)) {
                        selectedCheckboxes[id] = false;
                      }

                      if (name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                          email.toLowerCase().contains(searchQuery.toLowerCase()) ||
                          id.toString().contains(searchQuery)) {
                        userRows.add(DataRow(cells: [
                          DataCell(Checkbox(
                            value: selectedCheckboxes[id],
                            onChanged: (bool? value) {
                              setState(() {
                                selectedCheckboxes[id] = value!;
                                if (value) { selectedUserIds.add(id); }
                                else { selectedUserIds.remove(id); }
                              });
                            },
                          )),
                          DataCell(Text(id.toString())),
                          DataCell(Text(name)),
                          DataCell(Text(email)),
                          DataCell(Text(role)),
                        ]));
                      }
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('')),
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Role')),
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
                onPressed: selectedCheckboxes.containsValue(true) ? _viewUser : null,
                child: const Text('View',
                    style: TextStyle(color: Color(0xFFD76315), fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: screenWidth * 0.05),
              ElevatedButton(
                onPressed: selectedCheckboxes.containsValue(true) ? _updateUser : null,
                child: const Text('Update',
                    style: TextStyle(color: Color(0xFFD76315), fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: screenWidth * 0.05),
              ElevatedButton(
                onPressed: selectedCheckboxes.containsValue(true) ? _deleteUser : null,
                child: const Text('Delete',
                    style: TextStyle(color: Color(0xFFD76315), fontWeight: FontWeight.bold)),
              ),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(height: screenHeight * 1.45),
              ElevatedButton(
                onPressed: _addUser,
                style: ElevatedButton.styleFrom(
                  shape: const BeveledRectangleBorder(),
                  backgroundColor: const Color(0xFF283E51),
                  padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.320, vertical: screenHeight * 0.015),
                ),
                child: const Text('Add User', style: TextStyle(color: Colors.white)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
