
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tawafuq/pages/AdminHome.dart';
import 'package:tawafuq/pages/CrudPosterJobs.dart';
import 'package:tawafuq/pages/CrudSignedUpOrg.dart';
import 'package:tawafuq/pages/CrudUsersData.dart';
import 'package:tawafuq/pages/WelcomeScreen.dart';
import 'package:tawafuq/pages/bars&drawers/DrawerTitleStyle.dart';

class Admindrawer extends StatelessWidget {
  const Admindrawer({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Drawer(
        width: screenWidth * 0.8,
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF283E51)),
              child: Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.010),
                child: const Icon(Icons.addchart_rounded, size: 40.0, color: Colors.white),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.025,
                  vertical: screenHeight * 0.025),
              child: const Divider(
                color: Colors.white,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.025),
              child: Drawertitlestyle(
                icon: Icons.home_outlined,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const Adminhome()));
                },
                text: 'Home',
              ),
            ),
            SizedBox(height: screenHeight * 0.020),
            Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.025),
              child: Drawertitlestyle(
                icon: Icons.campaign_outlined,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const Crudsigneduporg()));
                },
                text: 'Review Companies licence',
              ),
            ),
            SizedBox(height: screenHeight * 0.020),
            Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.025),
              child: Drawertitlestyle(
                icon: Icons.file_copy_outlined,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const CrudUsersData()));
                },
                text: 'CRUD Users data',
              ),
            ),
            SizedBox(height: screenHeight * 0.020),
            Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.025),
              child: Drawertitlestyle(
                icon: Icons.app_registration_outlined,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const Crudposterjobs()));
                },
                text: 'CRUD Job posters data',
              ),
            ),
            SizedBox(height: screenHeight * 0.020),
            Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.025),
              child: Drawertitlestyle(
                icon: Icons.logout_outlined,
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) =>
                          const WelcomeScreen(isVoiceSystemEnabled: false)));
                },
                text: 'Log out',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
