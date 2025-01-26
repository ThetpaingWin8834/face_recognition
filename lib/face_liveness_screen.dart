import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/services.dart';

class FaceLivenessScreen extends StatefulWidget {
  @override
  _FaceLivenessScreenState createState() => _FaceLivenessScreenState();
}

class _FaceLivenessScreenState extends State<FaceLivenessScreen> {
  CameraController? _cameraController;
  late FaceDetector _faceDetector;
  bool _isProcessing = false;
  bool _isSuccess = false;
  String _instruction = "Look straight";
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();

    _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
            enableClassification: true,
            enableTracking: false,
            enableContours: false,
            performanceMode: FaceDetectorMode.accurate,
            enableLandmarks: false));
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      _cameraController = CameraController(frontCamera, ResolutionPreset.high,
          enableAudio: false, imageFormatGroup: ImageFormatGroup.nv21);

      await _cameraController!.initialize();
      if (!mounted) return;

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

      setState(() {});
      _startImageStream();
    } catch (e) {
      print("Failed to initialize camera: $e");
    }
  }

  void _startImageStream() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    _cameraController!.startImageStream((CameraImage image) {
      if (_isProcessing) return;
      _isProcessing = true;
      _processImage(image);
    });
  }

  Future<void> _processImage(CameraImage image) async {
    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);
      if (faces.isNotEmpty) {
        final face = faces.first;
        _updateInstruction(face);
      } else {
        setState(() {
          i++;
          _instruction = "$i No face detected";
        });
      }
      _isProcessing = false;
    } catch (e) {
      _isProcessing = false;

      print(e);
    }
  }

  int i = 0;

  void _updateInstruction(Face face) {
    final double? yaw = face.headEulerAngleY;
    final double? leftEyeOpen = face.leftEyeOpenProbability;
    final double? rightEyeOpen = face.rightEyeOpenProbability;

    if (_step == 0 && yaw != null && yaw.abs() < 10) {
      setState(() {
        _instruction = "Turn left";
        _step = 1;
      });
    } else if (_step == 1 && yaw != null && yaw < -15) {
      setState(() {
        _instruction = "Turn right";
        _step = 2;
      });
    } else if (_step == 2 && yaw != null && yaw > 15) {
      setState(() {
        _instruction = "Blink your eyes";
        _step = 3;
      });
    } else if (_step == 3 &&
        leftEyeOpen != null &&
        rightEyeOpen != null &&
        leftEyeOpen < 0.4 &&
        rightEyeOpen < 0.4) {
      setState(() {
        _instruction = "Success!";
        _isSuccess = true;
        _step = 4;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void restart() {
    setState(() {
      _isSuccess = false;
      _instruction = "Look straight";
      _step = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text("TPW'S Face Liveness Detection :3")),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "TPW'S Face Liveness Detection :3",
          style: TextStyle(fontSize: 15),
        ),
        actions: [IconButton(onPressed: restart, icon: Icon(Icons.sync))],
      ),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: 0,
              top: 0,
              right: 0,
              left: 0,
              child: CameraPreview(_cameraController!),
            ),
            if (!_isSuccess)
              Container(
                width: double.infinity,
                color: Colors.black.withOpacity(0.5),
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _instruction,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            if (_isSuccess)
              Container(
                width: double.infinity,
                color: Colors.black.withOpacity(0.5),
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Verification Successful!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
              ),
            // if (_isSuccess)
            //   Padding(
            //     padding: const EdgeInsets.all(16.0),
            //     child: Text(
            //       "Verification Successful!",
            //       style: TextStyle(fontSize: 24, color: Colors.green),
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = {
            DeviceOrientation.portraitUp: 0,
            DeviceOrientation.landscapeLeft: 90
          }[_cameraController!.value.deviceOrientation] ??
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
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }
}
