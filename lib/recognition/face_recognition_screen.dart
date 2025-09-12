import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:exif/exif.dart';
import 'package:face_recognition/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tensorflow_face_verification/tensorflow_face_verification.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

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
  List<double>? existingEmbeding;
  Interpreter? interpreter;
  final faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableTracking: false,
      enableContours: false,
      performanceMode: FaceDetectorMode.accurate,
      enableLandmarks: false,
    ),
  );
  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    cameraController?.dispose();
    faceDetector.close();
    imageStream.close();
    super.dispose();
  }

  void initialize() async {
    try {
      // await FaceVerification.init(
      //   modelPath: 'assets/tf_models/mobilefacenet.tflite',
      // );
      // final buffer = await getBuffer('assets/tf_models/mobilefacenet.tflite');
      interpreter = await Interpreter.fromAsset(
        'assets/tf_models/mobilefacenet.tflite',
      );
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
      imageStream
          .throttleTime(Duration(milliseconds: 300))
          .listen(processImage);
    } catch (e) {
      printLog(e);
    }
  }

  Future<Uint8List> getBuffer(String filePath) async {
    final rawAssetFile = await rootBundle.load(filePath);
    final rawBytes = rawAssetFile.buffer.asUint8List();
    return rawBytes;
  }

  void processImage(CameraImage image) async {
    if (isProcessing) return;
    isProcessing = true;
    printLog('processing');
    // if (existingEmbeding == null) {
    //   isProcessing = false;
    //   return;
    // }
    final newEmbeding = await getEmbedding(image);
    if (newEmbeding == null) {
      printLog('new embed null');
      isProcessing = false;

      return;
    }
    // final similarity = cosineSimilarity(existingEmbeding!, newEmbeding!);
    // printLog(similarity);
    isProcessing = false;

    // final convertedImg = cameraImageToJpeg(image);
    // FaceVerification.instance.verifySamePerson(input1, input2)
  }

  Future<List<double>?> getEmbedFromFile(File file) async {
    try {
      printLog('laoding cache embed ${interpreter == null}');
      if (interpreter == null) return null;

      printLog(file.path);
      // final bytes =await file.readAsBytes();
      final bytes = await normalizedBytes(file);
      final image = img.decodeImage(bytes)!;
      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888, // or nv21 if needed
          bytesPerRow: image.width * 4,
        ),
      );
      printLog(inputImage.type);
      printLog(inputImage.bytes!.length);

      return await _processImage(inputImage);
    } catch (e, s) {
      printLog(e, s: s);
      return null;
    }
  }

  Future<Uint8List> normalizedBytes(File file) async {
    final bytes = file.readAsBytesSync();
    final image = img.decodeImage(bytes)!;
    final exif = await readExifFromBytes(bytes);
    final tag = exif['orientation'];
    printLog(tag);
    img.Image oriented = image;
    if (tag != null) {
      switch (tag.tag) {
        case 3:
          oriented = img.copyRotate(image, angle: 180);
          break;
        case 6:
          oriented = img.copyRotate(image, angle: 90);
          break;
        case 8:
          oriented = img.copyRotate(image, angle: -90);
          break;
      }
    }

    return Uint8List.fromList(img.encodeJpg(oriented));
  }

  Future<List<double>?> _processImage(InputImage image) async {
    final faces = await faceDetector.processImage(image);

    if (faces.isEmpty) {
      printLog('No face detected.');
      return null;
    } else {
      // printLog('detected faces ${faces.length}');
    }

    final face = faces.first;
    final img.Image? originalImage = img.decodeImage(image.bytes!);

    if (originalImage == null) return null;

    final croppedImage = img.copyCrop(
      originalImage,
      x: face.boundingBox.left.toInt(),
      y: face.boundingBox.top.toInt(),
      width: face.boundingBox.width.toInt(),
      height: face.boundingBox.height.toInt(),
    );

    final resizedImage = img.copyResize(croppedImage, width: 112, height: 112);
    final input = _imageToByteListFloat32(resizedImage);

    final output = List<double>.filled(192, 0).reshape([1, 192]);
    interpreter!.run(input, output);
    return output.first.cast<double>();
  }

  Future<List<double>?> getEmbedding(CameraImage image) async {
    if (interpreter == null) return null;

    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) {
      return null;
    }
    return await _processImage(inputImage);
  }

  static double cosineSimilarity(
    List<double> embedding1,
    List<double> embedding2,
  ) {
    if (embedding1.length != embedding2.length) {
      throw Exception('Embeddings must have the same length.');
    }

    double dotProduct = 0.0;
    double magnitude1 = 0.0;
    double magnitude2 = 0.0;

    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      magnitude1 += embedding1[i] * embedding1[i];
      magnitude2 += embedding2[i] * embedding2[i];
    }

    magnitude1 = sqrt(magnitude1);
    magnitude2 = sqrt(magnitude2);

    if (magnitude1 == 0.0 || magnitude2 == 0.0) {
      return 0.0;
    }

    return dotProduct / (magnitude1 * magnitude2);
  }

  Float32List _imageToByteListFloat32(img.Image image) {
    final inputSize = 112;
    final float32List = Float32List(inputSize * inputSize * 3);
    final buffer = float32List.buffer;
    final ByteData byteData = ByteData.view(buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        final pixel = image.getPixel(j, i);
        byteData.setFloat32(pixelIndex * 4, (pixel.r / 255.0));
        pixelIndex++;
        byteData.setFloat32(pixelIndex * 4, (pixel.g / 255.0));
        pixelIndex++;
        byteData.setFloat32(pixelIndex * 4, (pixel.b / 255.0));
        pixelIndex++;
      }
    }
    return float32List;
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

  Future<void> saveCache(File file) async {
    final dir = await getTemporaryDirectory();
    // final path = '${dir.absolute.path}/temp.png';

    // await file.copy(path);
  }

  Future<void> loadCacheImg() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.absolute.path}/temp.png';
    final file = File(path);
    existingEmbeding = await getEmbedFromFile(file);
    printLog('loaed cache ${existingEmbeding == null}');
    setState(() {
      cacheImage = file;
    });
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          {
            DeviceOrientation.portraitUp: 0,
            DeviceOrientation.landscapeLeft: 90,
          }[cameraController!.value.deviceOrientation] ??
          0;

      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return null;
    // final format = InputImageFormatValue.fromRawValue(image.format.raw);
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: Platform.isIOS
            ? InputImageFormat.bgra8888
            : InputImageFormat.nv21,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
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
              if (file == null) {
                return;
              }
              cacheImage = File(file.path);
              final dir = await getTemporaryDirectory();
              final path = '${dir.absolute.path}/temp.png';
              file.saveTo(path);

              existingEmbeding = await getEmbedFromFile(cacheImage!);
              if (existingEmbeding == null) {
                return;
              }
              setState(() {});
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
