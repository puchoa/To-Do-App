import 'package:flutter/material.dart';


class MainScreen extends StatelessWidget {
  String secretMessage;

  MainScreen(this.secretMessage);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Confidential"),
      ),
      body: Text(secretMessage),
    );
  }
}