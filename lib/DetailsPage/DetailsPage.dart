import 'package:flutter/material.dart';

import 'SubjectsBar.dart';

class DetailsPage extends StatefulWidget {
  @override
  _DetailsPageState createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {

  @override
  void initState() {
    super.initState();
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(16.0), // Add padding here
      child: Center(
        child: SubjectsBar(),
      ),
    ),
  );
}}