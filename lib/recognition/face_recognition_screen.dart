import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FaceRecognitionScreen extends StatefulWidget {
  const FaceRecognitionScreen({super.key});

  @override
  State<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  CameraController? cameraController;
  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
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
    setState(() {});
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Recognition')),
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
