import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:exif/exif.dart';
import 'package:face_recognition/exif_helpers.dart';
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
      enableTracking: true,
      enableContours: true,
      performanceMode: FaceDetectorMode.accurate,
      enableLandmarks: true,
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
      // imageStream
      //     .throttleTime(Duration(milliseconds: 300))
      //     .listen(processImage);
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
    await Future.delayed(Duration(seconds: 2));
    final dir = await getTemporaryDirectory();
    final path = '${dir.absolute.path}/temp.png';
    final file = File(path);
    existingEmbeding = await getEmbedFromFile(file);
    printLog(existingEmbeding == null);
    isProcessing = false;

    // if (existingEmbeding == null) {
    //   isProcessing = false;
    //   return;
    // }
    // final newEmbeding = await getEmbedding(image);
    // if (newEmbeding == null) {
    //   isProcessing = false;

    //   return;
    // }
    // final similarity = cosineSimilarity(existingEmbeding!, newEmbeding);
    // printLog(similarity);
    // isProcessing = false;

    // final convertedImg = cameraImageToJpeg(image);
    // FaceVerification.instance.verifySamePerson(input1, input2)
  }

  Future<List<double>?> getEmbedFromFile(File file) async {
    try {
      if (interpreter == null) return null;

      // 1. Read & decode
      // final bytes = await file.readAsBytes();
      // final image = img.decodeImage(bytes)!;

      // // // 2. Correct orientation using EXIF
      // final exif = await readExifFromBytes(bytes);
      // final orientation = exif['Image Orientation']?.values.firstAsInt() ?? 1;
      // img.Image rotated;
      // switch (orientation) {
      //   case 3:
      //     rotated = img.copyRotate(image, angle: 180);
      //     break;
      //   case 6:
      //     rotated = img.copyRotate(image, angle: 90);
      //     break;
      //   case 8:
      //     rotated = img.copyRotate(image, angle: -90);
      //     break;
      //   default:
      //     rotated = image;
      // }

      // // // 3. Run MLKit face detection
      // final inputImage = InputImage.fromBytes(
      //   bytes: rotated.getBytes(), // raw RGBA
      //   metadata: InputImageMetadata(
      //     size: Size(rotated.width.toDouble(), rotated.height.toDouble()),
      //     rotation: InputImageRotation.rotation0deg, // already rotated
      //     format: InputImageFormat.bgra8888,
      //     bytesPerRow: rotated.width * 4,
      //   ),
      // );

      // final faces = await faceDetector.processImage(inputImage);
      // if (faces.isEmpty) {
      //   printLog("No face detected");
      //   return null;
      // }
      // final face = faces.first;

      // // 4. Crop face
      // final cropRect = face.boundingBox;
      // final cropped = img.copyCrop(
      //   rotated,
      //   x: cropRect.left.toInt().clamp(0, rotated.width - 1),
      //   y: cropRect.top.toInt().clamp(0, rotated.height - 1),
      //   width: cropRect.width.toInt().clamp(1, rotated.width),
      //   height: cropRect.height.toInt().clamp(1, rotated.height),
      // );

      // // 5. Resize to 112×112
      // final resized = img.copyResize(cropped, width: 112, height: 112);

      // // 6. Convert to Float32 input
      // final input = _imageToByteListFloat32(resized);

      // // 7. Allocate output & run inference safely
      // final outputBuffer = List.generate(1, (_) => List.filled(192, 0.0));
      // interpreter!.run(input.reshape([1, 112, 112, 3]), outputBuffer);

      // return List<double>.from(outputBuffer.first);
    } catch (e, s) {
      printLog(e, s: s);
      return null;
    }
  }

  void printExifTags(Map<int, img.IfdValue> rawExif) {
    printLog('=== EXIF TAGS FOUND ===');

    rawExif.forEach((tagId, value) {
      final tagName = ExifTags.getTagName(tagId);
      final category = ExifTags.getTagCategory(tagId);

      if (tagName != null) {
        printLog(
          '0x${tagId.toRadixString(16).toUpperCase().padLeft(4, '0')} '
          '[$category] $tagName: $value',
        );
      } else {
        printLog(
          '0x${tagId.toRadixString(16).toUpperCase().padLeft(4, '0')} '
          '[Unknown]: $value',
        );
      }
    });
  }

  // Process and display EXIF data
  void displayExifInfo(Map<int, dynamic> rawExif) {
    final processed = ExifTagProcessor.processExifData(rawExif);

    printLog('=== PROCESSED EXIF DATA ===');
    processed.forEach((key, value) {
      printLog('$key: $value');
    });
  }

  Future<Uint8List> normalizedBytes(File file) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes)!;
    final exif = await readExifFromBytes(bytes);
    final tag = exif['Orientation'];

    // for (var entry in exif.entries) {
    //   print(entry.key);
    // }
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
    // final faces = await faceDetector.processImage(image);

    // if (faces.isEmpty) {
    //   printLog('No face detected.');
    //   return null;
    // } else {
    //   // printLog('detected faces ${faces.length}');
    // }

    // final face = faces.first;
    // final img.Image? originalImage = img.decodeImage(image.bytes!);

    // if (originalImage == null) return null;

    // final croppedImage = img.copyCrop(
    //   originalImage,
    //   x: face.boundingBox.left.toInt(),
    //   y: face.boundingBox.top.toInt(),
    //   width: face.boundingBox.width.toInt(),
    //   height: face.boundingBox.height.toInt(),
    // );

    // final resizedImage = img.copyResize(croppedImage, width: 112, height: 112);
    // // final input = _imageToByteListFloat32(resizedImage);

    // final output = List<double>.filled(192, 0).reshape([1, 192]);
    // interpreter!.run(input, output);
    // return output.first.cast<double>();
  }

  Future<List<double>?> getEmbedding(CameraImage image) async {
    if (interpreter == null) return null;

    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) {
      return null;
    }
    // return await _processImage(inputImage);
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
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return Stack(
                      children: [
                        Image.file(
                          cacheImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return SizedBox.shrink();
                          },
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.close),
                        ),
                      ],
                    );
                  },
                );
              },
              child: CircleAvatar(
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
              final croppedImg = await processPickedImage(file);
              if (croppedImg != null) {
                setState(() {
                  cacheImage = croppedImg;
                });
              }

              // cacheImage = File(file.path);
              // final dir = await getTemporaryDirectory();
              // final path = '${dir.absolute.path}/temp.png';
              // file.saveTo(path);

              // // existingEmbeding = await getEmbedFromFile(cacheImage!);
              // // if (existingEmbeding == null) {
              // //   return;
              // // }
              // setState(() {});
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
                  width: cameraController!.value.previewSize?.height,
                  height: cameraController!.value.previewSize?.width,
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

  /// Processes an [XFile] from ImagePicker, rotates to 0°, detects face, crops it,
  /// saves the cropped face to a temporary file, and returns the saved [File].
  Future<File?> processPickedImage(XFile pickedFile) async {
    try {
      // // 1. Read & decode
      // final bytes = await pickedFile.readAsBytes();
      // final image = img.decodeImage(bytes);
      // if (image == null) return null;

      // // 2. Correct orientation to 0°
      // final exif = await readExifFromBytes(bytes);
      // final orientation = exif['Image Orientation']?.values.firstAsInt() ?? 1;
      // img.Image rotated;
      // switch (orientation) {
      //   case 3:
      //     rotated = img.copyRotate(image, angle: 180);
      //     break;
      //   case 6:
      //     rotated = img.copyRotate(image, angle: 90);
      //     break;
      //   case 8:
      //     rotated = img.copyRotate(image, angle: -90);
      //     break;
      //   default:
      //     rotated = image;
      // }

      // // 3. Face detection
      // final inputImage = InputImage.fromBytes(
      //   bytes: rotated.getBytes(),
      //   metadata: InputImageMetadata(
      //     size: Size(rotated.width.toDouble(), rotated.height.toDouble()),
      //     rotation: InputImageRotation.rotation0deg,
      //     format: InputImageFormat.bgra8888,
      //     bytesPerRow: rotated.width * 4,
      //   ),
      // );
      final fileBytes = await pickedFile.readAsBytes();
      final decoded = img.decodeImage(fileBytes);
      final baked = img.bakeOrientation(decoded!);
      final newBytes = img.encodeJpg(baked);
      final tempDir = await getTemporaryDirectory();
      final savedPath = '${tempDir.path}/face_cropped.jpg';
      final savedFile = File(savedPath);
      await savedFile.writeAsBytes(newBytes);
      final inputImage = InputImage.fromFile(savedFile);
      printLog(inputImage.metadata);
      final faces = await faceDetector.processImage(inputImage);
      if (faces.isEmpty) {
        printLog("No face detected");
        return null;
      }
      final face = faces.first;
      final cropRect = face.boundingBox;
      printLog(cropRect);
      final x = cropRect.left.toInt().clamp(0, decoded.width - 1);
      final y = cropRect.top.toInt().clamp(0, decoded.height - 1);
      final width = cropRect.width.toInt().clamp(1, decoded.width - x);
      final height = cropRect.height.toInt().clamp(1, decoded.height - y);
      final croppedFace = img.copyCrop(
        decoded,
        x: x,
        y: y,
        width: width,
        height: height,
      );
      final resizedFace = img.copyResize(croppedFace, width: 112, height: 112);

      final croppedFile = File(savedPath);
      await croppedFile.writeAsBytes(img.encodeJpg(resizedFace));
      return croppedFile;
      // Clamp crop rect to image boundaries
      // final x = cropRect.left.toInt().clamp(0, rotated.width - 1);
      // final y = cropRect.top.toInt().clamp(0, rotated.height - 1);
      // final w = cropRect.width.toInt().clamp(1, rotated.width - x);
      // final h = cropRect.height.toInt().clamp(1, rotated.height - y);
      // final cropped = img.copyCrop(rotated, x: x, y: y, width: w, height: h);

      // // 4. Save cropped face to temp file
      // final tempDir = await getTemporaryDirectory();
      // final croppedPath = '${tempDir.path}/cropped_face.jpg';
      // final croppedFile = File(croppedPath);
      // await croppedFile.writeAsBytes(img.encodeJpg(cropped));
      // return croppedFile;
    } catch (e, s) {
      printLog(e, s: s);
      return null;
    }
  }

  DeviceOrientation _getApplicableOrientation() {
    return cameraController!.value.isRecordingVideo
        ? cameraController!.value.recordingOrientation!
        : (cameraController!.value.previewPauseOrientation ??
              cameraController!.value.lockedCaptureOrientation ??
              cameraController!.value.deviceOrientation);
  }
}
