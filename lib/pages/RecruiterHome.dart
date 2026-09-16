
import 'package:flutter/material.dart';
import 'package:tawafuq/pages/PostJobPage.dart';
import 'package:tawafuq/pages/ViewApplicantsPage.dart';
import 'package:tawafuq/pages/bars&drawers/DrawerPage.dart';

class RecruiterHome extends StatelessWidget {
  const RecruiterHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: DrawerPage(),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4B79A1), Color(0xFF283E51)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Builder(
              builder: (BuildContext context) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () { Navigator.pop(context); },
                      ),
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () { Scaffold.of(context).openEndDrawer(); },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Hi! \nWelcome ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white, fontSize: 50,
                      fontWeight: FontWeight.bold, letterSpacing: 1.5,
                    ),
                  ),
                  Image.asset(
                    'assets/postjob.png',
                    width: 500,
                    height: 150,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => PostJobPage()));
                      },
                      icon: const Icon(Icons.computer, size: 35),
                      label: const Text('Post a Job',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Image.asset('assets/ppl.png', width: 500, height: 150),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => ViewApplicantsPage()));
                      },
                      icon: const Icon(Icons.people, size: 35),
                      label: const Text('View Applicants',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
