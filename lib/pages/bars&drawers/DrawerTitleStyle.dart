
import 'package:flutter/material.dart';

class Drawertitlestyle extends StatelessWidget {
  const Drawertitlestyle({
    super.key,
    required this.icon,
    required this.onTap,
    required this.text,
  });

  final void Function()? onTap;
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    Color darkgreen = Theme.of(context).colorScheme.primary;

    return ListTile(
      title: Text(
        text,
        style: TextStyle(color: darkgreen, fontWeight: FontWeight.bold),
      ),
      leading: Icon(icon, color: darkgreen),
      onTap: onTap,
    );
  }
}
