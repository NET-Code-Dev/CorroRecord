// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

// ignore: use_key_in_widget_constructors
class ISOPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 0, 43, 92),
        title: Text('ISO/OVP'),
        centerTitle: true,
      ),
      body: Center(
        child: Text('Content for ISO/OVP Page'),
      ),
    );
  }
}
