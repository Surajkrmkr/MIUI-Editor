import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../provider/icon.dart';
import '../provider/module.dart';

class ModuleWidget extends StatelessWidget {
  const ModuleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 75,
          width: 150,
          decoration: BoxDecoration(
              color:
                  Provider.of<IconProvider>(context, listen: true).accentColor,
              borderRadius: BorderRadius.circular(20)),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(
                Icons.wifi,
                color: Colors.white,
                size: 30,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Subhangi 6G",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "connected",
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  )
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Screenshot(
                controller: Provider.of<ModuleProvider>(context, listen: false)
                    .dialerPngController!,
                child: CircleAvatar(
                    backgroundColor:
                        Provider.of<IconProvider>(context, listen: true)
                            .accentColor,
                    child: const Icon(
                      Icons.phone,
                      color: Colors.white,
                    )),
              ),
              const SizedBox(
                width: 20,
              ),
              Screenshot(
                controller: Provider.of<ModuleProvider>(context, listen: false)
                    .contactPngController!,
                child: CircleAvatar(
                    backgroundColor:
                        Provider.of<IconProvider>(context, listen: true)
                            .accentColor,
                    child: const Icon(
                      Icons.person_sharp,
                      color: Colors.white,
                    )),
              )
            ],
          ),
        )
      ],
    );
  }
}
