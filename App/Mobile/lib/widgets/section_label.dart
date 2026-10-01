import 'package:flutter/material.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(
      title,
      style: const TextStyle(
        color: Color(0xFF9AA7BA),
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    ),
  );
}
