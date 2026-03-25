import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';

/// Dialog for manual image cropping with 6:13 aspect ratio
class CropImageDialog extends StatefulWidget {
  final Uint8List imageData;
  final String title;

  const CropImageDialog({
    super.key,
    required this.imageData,
    this.title = 'Crop Image',
  });

  @override
  State<CropImageDialog> createState() => _CropImageDialogState();
}

class _CropImageDialogState extends State<CropImageDialog> {
  final _cropController = CropController();
  bool _isCropping = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Info text
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Drag corners to adjust crop area (6:13 phone ratio)',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Crop widget
            Expanded(
              child: _isCropping
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Processing...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    )
                  : Crop(
                      image: widget.imageData,
                      controller: _cropController,
                      onCropped: (croppedData) {
                        switch (croppedData) {
                          case CropSuccess(:final croppedImage):
                            Navigator.of(context).pop(croppedImage);
                            break;
                          case CropFailure(:final cause):
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Crop failed: $cause'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            break;
                        }
                      },
                      aspectRatio: 6 / 13, // Phone wallpaper ratio
                      withCircleUi: false,
                      baseColor: Theme.of(context).colorScheme.surface,
                      maskColor: Theme.of(context)
                          .colorScheme
                          .surface
                          .withOpacity(0.5),
                      radius: 0,
                      cornerDotBuilder: (size, edgeAlignment) {
                        return Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(size / 2),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed:
                      // _isCropping?
                      null,
                  // : () {
                  //     _cropController.cropCircle();
                  //   },
                  icon: const Icon(Icons.rotate_90_degrees_ccw),
                  label: const Text('Rotate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isCropping
                      ? null
                      : () {
                          setState(() => _isCropping = true);
                          _cropController.crop();
                          setState(() => _isCropping = false);
                        },
                  icon: const Icon(Icons.crop),
                  label: const Text('Crop Image'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Helper function to show crop dialog
Future<Uint8List?> showCropDialog(
  BuildContext context,
  Uint8List imageData, {
  String title = 'Crop Image',
}) async {
  return await showDialog<Uint8List>(
    context: context,
    barrierDismissible: false,
    builder: (context) => CropImageDialog(
      imageData: imageData,
      title: title,
    ),
  );
}
