import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_page.dart';

class LandingPage extends StatelessWidget {
  LandingPage({super.key});

  final TextEditingController? folderNumController = TextEditingController();
  final TextEditingController? weekNumController = TextEditingController();

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
                height: 400,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextField(
                        keyboardType: TextInputType.number,
                        controller: folderNumController,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            label: Text("Folder Number"))),
                    TextField(
                        keyboardType: TextInputType.number,
                        controller: weekNumController,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            label: Text("Week Number"))),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pinkAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 23, horizontal: 35)),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HomePage(
                                        folderNum: folderNumController!.text,
                                        weekNum: weekNumController!.text,
                                      )));
                        },
                        child: const Text("Let's Go"))
                  ],
                )),
          ],
        ),
      ),
    );
  }
}
