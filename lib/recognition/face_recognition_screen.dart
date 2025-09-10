import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tensorflow_face_verification/tensorflow_face_verification.dart';

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
    try {
      await loadCacheImg();
      await FaceVerification.init(
        modelPath: 'assets/tf_models/mobilefacenet.tflite',
      );
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
      imageStream
          .throttleTime(Duration(milliseconds: 300))
          .listen(processImage);
    } catch (e) {
      print(e);
    }
  }

  void processImage(CameraImage image) async {
    if (isProcessing) return;
    isProcessing = true;
    final convertedImg = cameraImageToJpeg(image);
    // FaceVerification.instance.verifySamePerson(input1, input2)
  
  }

  Uint8List cameraImageToJpeg(CameraImage image, {int quality = 90}) {
    img.Image? convertedImage;

    if (Platform.isIOS && image.format.group == ImageFormatGroup.bgra8888) {
      // iOS: BGRA8888 → RGB
      final width = image.width;
      final height = image.height;
      convertedImage = img.Image(width: width, height: height);

      final bytes = image.planes[0].bytes;

      int offset = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final b = bytes[offset];
          final g = bytes[offset + 1];
          final r = bytes[offset + 2];
          convertedImage.setPixelRgba(x, y, r, g, b, 255);
          offset += 4;
        }
      }
    } else if (Platform.isAndroid &&
        (image.format.group == ImageFormatGroup.yuv420 ||
            image.format.group == ImageFormatGroup.nv21)) {
      final width = image.width;
      final height = image.height;

      final yPlane = image.planes[0];
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];

      convertedImage = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final yp = yPlane.bytes[y * yPlane.bytesPerRow + x];
          final up = uPlane.bytes[(y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2)];
          final vp = vPlane.bytes[(y ~/ 2) * vPlane.bytesPerRow + (x ~/ 2)];

          final r = (yp + 1.402 * (vp - 128)).clamp(0, 255).toInt();
          final g = (yp - 0.344136 * (up - 128) - 0.714136 * (vp - 128))
              .clamp(0, 255)
              .toInt();
          final b = (yp + 1.772 * (up - 128)).clamp(0, 255).toInt();

          convertedImage.setPixelRgba(x, y, r, g, b, 255);
        }
      }
    } else {
      throw UnsupportedError(
        'Unsupported platform or image format: ${image.format.group}',
      );
    }

    return Uint8List.fromList(img.encodeJpg(convertedImage, quality: quality));
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
