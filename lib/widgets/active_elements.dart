import 'package:flutter/material.dart';
import 'package:miui_icon_generator/constants.dart';
import 'package:provider/provider.dart';

import '../provider/element.dart';

class ActiveElements extends StatelessWidget {
  const ActiveElements({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ElementProvider>(context);
    return SizedBox(
      width: 230,
      child: Column(
        children: [
          Column(
            children: [
              if (MIUIConstants.isDesktop)
                Text(
                  "Active Elements",
                  style: Theme.of(context).textTheme.bodyLarge!,
                ),
              if (MIUIConstants.isDesktop) const SizedBox(height: 20),
              Expanded(
                  child: ListView.builder(
                      itemCount: provider.elementList.length,
                      itemBuilder: (context, i) {
                        final element = provider.elementList[i];
                        final eleProvider =
                            Provider.of<ElementProvider>(context, listen: true);
                        final bool isSelected =
                            eleProvider.activeType == element.type;
                        return Material(
                          type: MaterialType.transparency,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 10, right: 10, bottom: 10.0),
                            child: ListTile(
                              selected: isSelected,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25)),
                              title: Text(
                                element.name!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                  onPressed: () {
                                    eleProvider
                                        .removeElementFromList(element.type!);
                                  },
                                  icon: const Icon(Icons.delete)),
                              onTap: () {},
                              horizontalTitleGap: 0,
                            ),
                          ),
                        );
                      }))
            ],
          ),
        ],
      ),
    );
  }
}
