import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants.dart';
import 'home_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Text(
              "Welcome to MIUI World \n by Suraj",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30),
            ),
            SizedBox(
                width: 300,
                child: TextField(
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    onSubmitted: (e) async {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => HomePage(folderNum: e,)));
                    },
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        label: Text("Folder Number")))),
          ],
        ),
      ),
    );
  }
}
