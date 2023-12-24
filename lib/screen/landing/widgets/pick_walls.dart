import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../model/pixabay_wall_model.dart';
import '../../../provider/pick_wall.dart';
import '../../../theme.dart';
import '../../../widgets/ui_widgets.dart';

class PickWalls extends StatefulWidget {
  const PickWalls({super.key});

  @override
  State<PickWalls> createState() => _PickWallsState();
}

class _PickWallsState extends State<PickWalls> {
  final TextEditingController searchController = TextEditingController();
  int page = 1;

  final gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
      childAspectRatio: 0.5,
      crossAxisCount: 8,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20);

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      Provider.of<PickWallProvider>(context, listen: false).getWallsFromAPI(1);
    });
    super.initState();
  }

  void getWall({int newPage = 1}) {
    Provider.of<PickWallProvider>(context, listen: false)
      ..setSearch = searchController.text
      ..getWallsFromAPI(page);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<PickWallProvider>(builder: (context, provider, _) {
          return Text(provider.search == "" ? "Pixabay" : provider.search);
        }),
        centerTitle: true,
        scrolledUnderElevation: 0,
        actions: [
          UIWidgets.iconButton(
              onPressed: () {
                if (page > 1) {
                  page--;
                  getWall(newPage: page);
                }
              },
              icon: Icons.chevron_left_rounded),
          UIWidgets.iconButton(
              onPressed: () {
                page++;
                getWall(newPage: page);
              },
              icon: Icons.chevron_right_rounded),
          const SizedBox(width: 20),
          SizedBox(
            width: 250,
            height: 45,
            child: TextField(
                keyboardType: TextInputType.number,
                controller: searchController,
                onSubmitted: (_) => getWall(newPage: 1),
                decoration: InputDecoration(
                    isDense: true,
                    floatingLabelAlignment: FloatingLabelAlignment.center,
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(200))),
                    suffixIcon: UIWidgets.iconButton(
                        onPressed: () => getWall(newPage: 1),
                        icon: Icons.search),
                    label: const Text("Search..."))),
          ),
          const SizedBox(width: 20),
          Consumer<PickWallProvider>(builder: (context, provider, _) {
            return PopupMenuButton(
                surfaceTintColor: Colors.transparent,
                color: Theme.of(context).scaffoldBackgroundColor,
                tooltip: 'Type',
                icon: Row(
                  children: [
                    Text(provider.imageType.name),
                    const Icon(Icons.arrow_drop_down)
                  ],
                ),
                itemBuilder: (context) => PixabayImageType.values
                    .map((type) => PopupMenuItem(
                          value: type,
                          child: Text(type.name),
                        ))
                    .toList(),
                onSelected: (value) {
                  provider.setImageType = value;
                  getWall(newPage: 1);
                });
          }),
          const SizedBox(width: 20),
        ],
      ),
      body: Consumer<PickWallProvider>(builder: (context, provider, _) {
        if (provider.isLoading!) {
          return GridView.builder(
              gridDelegate: gridDelegate,
              itemBuilder: (context, _) => Shimmer.fromColors(
                  baseColor: AppThemeData.accentColor,
                  highlightColor: Colors.white,
                  direction: ShimmerDirection.ltr,
                  child: const SizedBox(
                    height: 330,
                    width: 300,
                  )));
        }
        if (provider.walls.isEmpty) {
          return Center(
            child: Text(
              "No Walls Available from Pixabay",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(15.0),
          child: GridView.builder(
              gridDelegate: gridDelegate,
              itemBuilder: (context, index) {
                return Container(
                    decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 5), // changes position of shadow
                    ),
                  ],
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: Image.network(provider.walls[index].webformatURL!,
                        loadingBuilder: (context, child, loadingProgress) =>
                            Shimmer.fromColors(
                                baseColor: AppThemeData.accentColor,
                                highlightColor: Colors.white,
                                direction: ShimmerDirection.ltr,
                                child: Container(
                                  height: 330,
                                  width: 300,
                                  color: Theme.of(context).colorScheme.primary,
                                ))).image,
                  ),
                ));
              },
              itemCount: provider.walls.length),
        );
      }),
    );
  }
}
