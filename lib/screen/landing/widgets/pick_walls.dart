import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../model/pixabay_wall_model.dart';
import '../../../provider/directory.dart';
import '../../../provider/pick_wall.dart';
import '../../../provider/wallpaper.dart';
import '../../../theme.dart';
import '../../../widgets/ui_widgets.dart';
import 'crop_walls.dart';

class PickWalls extends StatefulWidget {
  const PickWalls({super.key, required this.folderNum, required this.weekNum});
  final String folderNum;
  final String weekNum;

  @override
  State<PickWalls> createState() => _PickWallsState();
}

class _PickWallsState extends State<PickWalls> {
  final TextEditingController searchController = TextEditingController();
  int page = 1;

  final gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 4, crossAxisSpacing: 20, mainAxisSpacing: 20);

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      Provider.of<WallpaperProvider>(context, listen: false)
          .setWeekWallNum(widget.folderNum, widget.weekNum);

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
      body: Row(
        children: [
          Expanded(
            child: Consumer<PickWallProvider>(builder: (context, provider, _) {
              if (provider.isLoading!) {
                return Shimmer.fromColors(
                  baseColor: AppThemeData.accentColor,
                  highlightColor: Colors.white,
                  direction: ShimmerDirection.ltr,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: GridView.builder(
                        gridDelegate: gridDelegate,
                        itemBuilder: (context, _) => Container(
                              height: 330,
                              width: 300,
                              decoration: const BoxDecoration(
                                  color: Colors.black,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(30))),
                            )),
                  ),
                );
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
                      return PickWallPreview(
                        pageUrl: provider.walls[index].pageURL!,
                        url: provider.walls[index].webformatURL!,
                        downloadUrl: provider.walls[index].largeImageURL!,
                        tags: provider.walls[index].tags!,
                      );
                    },
                    itemCount: provider.walls.length),
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Consumer<DirectoryProvider>(builder: (context, provider, _) {
              return Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          "Downloaded",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 15),
                      UIWidgets.iconButton(
                          onPressed: () {
                            provider.setPreviewWallsPath(
                                folderNum: widget.folderNum);
                          },
                          icon: Icons.refresh)
                    ],
                  ),
                  Expanded(
                    child: SizedBox(
                      width: 300,
                      child: GridView.builder(
                          scrollDirection: Platform.isAndroid
                              ? Axis.horizontal
                              : Axis.vertical,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  childAspectRatio: 0.5,
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20),
                          itemCount: provider.previewWallsPath.length,
                          itemBuilder: (context, i) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(
                                        0, 5), // changes position of shadow
                                  ),
                                ],
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: FileImage(
                                    File(provider.previewWallsPath[i]!),
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 15),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Text(provider.previewWallsPath[i]!
                                      .split(Platform.pathSeparator)
                                      .last),
                                ),
                              ),
                            );
                          }),
                    ),
                  ),
                ],
              );
            }),
          )
        ],
      ),
    );
  }
}

class PickWallPreview extends StatefulWidget {
  const PickWallPreview({
    super.key,
    required this.url,
    required this.downloadUrl,
    required this.pageUrl,
    required this.tags,
  });

  final String url;
  final String downloadUrl;
  final String pageUrl;
  final String tags;

  @override
  State<PickWallPreview> createState() => _PickWallPreviewState();
}

class _PickWallPreviewState extends State<PickWallPreview> {
  bool showDownload = false;

  Future<void> _handleDownload() async {
    await showDialog(
      context: context,
      builder: (context) {
        return RenameWall(
            downloadUrl: widget.downloadUrl,
            pageUrl: widget.pageUrl,
            tags: widget.tags);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onExit: (event) {
        setState(() {
          showDownload = false;
        });
      },
      onHover: (event) {
        setState(() {
          showDownload = true;
        });
      },
      child: Container(
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
            image: Image.network(widget.url,
                loadingBuilder: (context, child, loadingProgress) =>
                    Shimmer.fromColors(
                        baseColor: AppThemeData.accentColor,
                        highlightColor: Colors.white,
                        direction: ShimmerDirection.ltr,
                        child: Container(
                          height: 330,
                          width: 300,
                          color: Colors.black,
                        ))).image,
          ),
        ),
        child: Offstage(
          offstage: !showDownload,
          child: Container(
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              alignment: Alignment.bottomRight,
              child: UIWidgets.iconButton(
                  icon: Icons.download, onPressed: _handleDownload)),
        ),
      ),
    );
  }
}
