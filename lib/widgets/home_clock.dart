import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/font.dart';

class HomeClockWidget extends StatelessWidget {
  const HomeClockWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FontProvider>(builder: (context, provider, _) {
      return SizedBox(
        width: 200,
        child: Column(
          children: [
            InkWell(
              onTap: () {},
              child: const SizedBox(
                width: 200,
                child: Column(
                  children: [
                    Text(
                      "02:36",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          height: 1,
                          fontWeight: FontWeight.w500),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      "08-02-2022",
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    Text(
                      "Tuesday",
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
