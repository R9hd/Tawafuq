
import 'package:flutter/material.dart';
import 'package:tawafuq/pages/bars&drawers/AdminDrawer.dart';

class Vieworgforadmin extends StatelessWidget {
  final List<Map<String, dynamic>> companyData;
  const Vieworgforadmin({super.key, required this.companyData});

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
        itemCount: companyData.length,
        itemBuilder: (context, index) {
          final user = companyData[index];

          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Full Name: ${user['fullName'] ?? 'N/A'}'),
                  Text('Email: ${user['email'] ?? 'N/A'}'),
                  Text('Phone Number: ${user['phoneNumber'] ?? 'N/A'}'),
                  Text('Role: ${user['role'] ?? 'N/A'}'),
                  Text('Joining Month: ${user['joining month'] ?? 'N/A'}'),
                  Text('License URL: ${user['licenseUrl'] ?? 'N/A'}'),
                  Text('License Checked: ${user['licenseChecked'] ?? false}'),
                  Text('Company Approved: ${user['companyApproved'] ?? false}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
