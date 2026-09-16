
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tawafuq/pages/bars&drawers/AdminDrawer.dart';

class Edituser extends StatefulWidget {
  const Edituser({super.key, required this.userData});
  final List<Map<String, dynamic>> userData;

  @override
  State<Edituser> createState() => _EdituserState();
}

class _EdituserState extends State<Edituser> {
  final List<TextEditingController> _fullNameControllers = [];
  final List<TextEditingController> _lastNameControllers = [];
  final List<TextEditingController> _emailControllers = [];
  final List<TextEditingController> _phoneNumberControllers = [];
  final List<TextEditingController> _joiningMonthControllers = [];
  final List<TextEditingController?> _licenseUrlControllers = [];
  final List<bool?> _licenseCheckedValues = [];
  final List<bool?> _companyApprovedValues = [];

  @override
  void initState() {
    super.initState();
    for (var user in widget.userData) {
      _fullNameControllers.add(TextEditingController(text: user['fullName'] ?? ''));
      _lastNameControllers.add(TextEditingController(text: user['lastName'] ?? ''));
      _emailControllers.add(TextEditingController(text: user['email'] ?? ''));
      _phoneNumberControllers.add(TextEditingController(text: user['phoneNumber'] ?? ''));
      _joiningMonthControllers.add(TextEditingController(text: user['joining month'] ?? ''));
      if (user['role'] == 'Recruiter') {
        _licenseUrlControllers.add(TextEditingController(text: user['licenseUrl'] ?? ''));
        _licenseCheckedValues.add(user['licenseChecked'] ?? false);
        _companyApprovedValues.add(user['companyApproved'] ?? false);
      } else {
        _licenseUrlControllers.add(null);
        _licenseCheckedValues.add(null);
        _companyApprovedValues.add(null);
      }
    }
  }

  @override
  void dispose() {
    for (var c in _fullNameControllers) {
      c.dispose();
    }
    for (var c in _lastNameControllers) {
      c.dispose();
    }
    for (var c in _emailControllers) {
      c.dispose();
    }
    for (var c in _phoneNumberControllers) {
      c.dispose();
    }
    for (var c in _joiningMonthControllers) {
      c.dispose();
    }
    for (var c in _licenseUrlControllers) { if (c != null) c.dispose(); }
    super.dispose();
  }

  void _saveUsers() async {
    List<Map<String, dynamic>> updatedUsers = [];

    for (int i = 0; i < widget.userData.length; i++) {
      Map<String, dynamic> updatedUser = {
        'fullName': _fullNameControllers[i].text,
        'lastName': _lastNameControllers[i].text,
        'email': _emailControllers[i].text,
        'phoneNumber': _phoneNumberControllers[i].text,
        'joining month': _joiningMonthControllers[i].text,
        'role': widget.userData[i]['role'],
        'id': widget.userData[i]['id'],
      };

      if (widget.userData[i]['role'] == 'Recruiter') {
        updatedUser['licenseUrl'] = _licenseUrlControllers[i]?.text ?? '';
        updatedUser['licenseChecked'] = _licenseCheckedValues[i] ?? false;
        updatedUser['companyApproved'] = _companyApprovedValues[i] ?? false;
      }

      updatedUsers.add(updatedUser);
    }

    try {
      for (var updatedUser in updatedUsers) {
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('id', isEqualTo: updatedUser['id'])
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          DocumentSnapshot userDoc = userSnapshot.docs.first;
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userDoc.id)
              .update(updatedUser);
        } else {
          print("User with ID ${updatedUser['id']} not found.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to find user: ${updatedUser['id']}")),
          );
        }
      }

      Navigator.pop(context, updatedUsers);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Users updated successfully!')),
      );
    } catch (e) {
      print("Error updating users: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update users: ${e.toString()}')),
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
          itemCount: widget.userData.length,
          itemBuilder: (context, index) {
            bool isRecruiter = widget.userData[index]['role'] == 'Recruiter';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: const Text("Full Name"),
                  subtitle: TextFormField(
                    controller: _fullNameControllers[index],
                    decoration: const InputDecoration(hintText: "Enter Full Name"),
                  ),
                ),
                const SizedBox(height: 16.0),
                ListTile(
                  title: const Text("Last Name"),
                  subtitle: TextFormField(
                    controller: _lastNameControllers[index],
                    decoration: const InputDecoration(hintText: "Enter Last Name"),
                  ),
                ),
                const SizedBox(height: 16.0),
                ListTile(
                  title: const Text("Email"),
                  subtitle: TextFormField(
                    controller: _emailControllers[index],
                    decoration: const InputDecoration(hintText: "Enter Email"),
                  ),
                ),
                const SizedBox(height: 16.0),
                ListTile(
                  title: const Text("Phone Number"),
                  subtitle: TextFormField(
                    controller: _phoneNumberControllers[index],
                    decoration: const InputDecoration(hintText: "Enter Phone Number"),
                  ),
                ),
                const SizedBox(height: 16.0),
                ListTile(
                  title: const Text("Joining Month"),
                  subtitle: TextFormField(
                    controller: _joiningMonthControllers[index],
                    decoration: const InputDecoration(hintText: "Enter Joining Month"),
                  ),
                ),
                const SizedBox(height: 16.0),
                if (isRecruiter) ...[
                  ListTile(
                    title: const Text("License URL"),
                    subtitle: TextFormField(
                      controller: _licenseUrlControllers[index],
                      decoration: const InputDecoration(hintText: "Enter License URL"),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  SwitchListTile(
                    title: const Text("License Checked"),
                    value: _licenseCheckedValues[index] ?? false,
                    onChanged: (newValue) {
                      setState(() { _licenseCheckedValues[index] = newValue; });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  SwitchListTile(
                    title: const Text("Company Approved"),
                    value: _companyApprovedValues[index] ?? false,
                    onChanged: (newValue) {
                      setState(() { _companyApprovedValues[index] = newValue; });
                    },
                  ),
                  const SizedBox(height: 32.0),
                ],
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveUsers,
        backgroundColor: Colors.green,
        child: const Icon(Icons.save),
      ),
    );
  }
}
