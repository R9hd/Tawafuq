
import 'package:flutter/material.dart';

class Adminbar extends StatelessWidget implements PreferredSizeWidget {
  const Adminbar({super.key, required this.pageTitle});

  final String pageTitle;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return AppBar(
      toolbarHeight: screenHeight * 0.100,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Text(
        pageTitle,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
      ),
      elevation: 10.0,
      centerTitle: true,
      backgroundColor: const Color(0xFF283E51),
    );
  }
}
