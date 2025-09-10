import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

class FaceRecognitionScreen extends StatefulWidget {
  const FaceRecognitionScreen({super.key});

  @override
  State<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  CameraController? cameraController;
  File? cacheImage;
  final imageStream = BehaviorSubject<CameraImage>();
  bool isProcessing = false;
  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    cameraController?.dispose();
    imageStream.close();
    super.dispose();
  }

  void initialize() async {
    await loadCacheImg();
    final cameras = await availableCameras();
    final cameraDesc = cameras.firstWhere(
      (e) => e.lensDirection == CameraLensDirection.front,
    );
    cameraController = CameraController(
      cameraDesc,
      ResolutionPreset.high,
      imageFormatGroup: Platform.isIOS
          ? ImageFormatGroup.bgra8888
          : ImageFormatGroup.nv21,
    );
    await cameraController!.initialize();
    cameraController!.startImageStream((image) {
      imageStream.add(image);
    });
    setState(() {});
    imageStream.throttleTime(Duration(milliseconds: 300)).listen(processImage);
  }

  void processImage(CameraImage image) async {
    if (isProcessing) return;
    
  }

  Future<void> loadCacheImg() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.absolute.path}/temp.png';
    final file = File(path);

    setState(() {
      cacheImage = file;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recognition'),
        actions: [
          if (cacheImage != null)
            CircleAvatar(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Image.file(
                  cacheImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return SizedBox.shrink();
                  },
                ),
              ),
            ),
          SizedBox(width: 24),

          IconButton(
            onPressed: () async {
              final file = await ImagePicker().pickImage(
                source: ImageSource.camera,
              );
              if (file != null) {
                setState(() {
                  cacheImage = File(file.path);
                });
              }
            },
            icon: Icon(Icons.add_a_photo),
          ),
          SizedBox(width: 24),
        ],
      ),
      body: cameraController == null
          ? Center(child: CircularProgressIndicator.adaptive())
          : SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: cameraController!.value.previewSize!.height,
                  height: cameraController!.value.previewSize!.width,
                  child: AspectRatio(
                    aspectRatio: _isLandscape()
                        ? cameraController!.value.aspectRatio
                        : 1 / cameraController!.value.aspectRatio,
                    child: CameraPreview(cameraController!),
                  ),
                ),
              ),
            ),
    );
  }

  bool _isLandscape() {
    return <DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ].contains(_getApplicableOrientation());
  }

  DeviceOrientation _getApplicableOrientation() {
    return cameraController!.value.isRecordingVideo
        ? cameraController!.value.recordingOrientation!
        : (cameraController!.value.previewPauseOrientation ??
              cameraController!.value.lockedCaptureOrientation ??
              cameraController!.value.deviceOrientation);
  }
}
