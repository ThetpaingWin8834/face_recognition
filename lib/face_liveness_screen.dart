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
        enableLandmarks: false,
      ),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

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
        _updateInstructionInverted(face);
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
  void _updateInstructionInverted(Face face) {
    final double? yaw = face.headEulerAngleY; // Yaw angle (head rotation)
    final double? leftEyeOpen =
        face.leftEyeOpenProbability; // Left eye open probability
    final double? rightEyeOpen =
        face.rightEyeOpenProbability; // Right eye open probability

    // Invert yaw for front camera (mirrored preview)
    final double? adjustedYaw =
        _cameraController!.description.lensDirection ==
            CameraLensDirection.front
        ? yaw != null
              ? -yaw
              : null // Invert yaw for front camera
        : yaw; // Keep yaw as is for rear camera

    // Step 0: Check if the face is straight
    if (_step == 0) {
      if (adjustedYaw != null && adjustedYaw.abs() < 10) {
        // Face is straight
        setState(() {
          _instruction = "Face verified. Turn your head to the left.";
          _step = 1; // Move to the next step
        });
      } else {
        setState(() {
          _instruction = "Please look straight.";
        });
      }
    }
    // Step 1: Wait for the user to turn their head to the left
    else if (_step == 1) {
      if (adjustedYaw != null && adjustedYaw < -15) {
        // Head is turned to the left
        setState(() {
          _instruction = "Great! Now turn your head to the right.";
          _step = 2; // Move to the next step
        });
      } else {
        setState(() {
          _instruction = "Please turn your head to the left.";
        });
      }
    }
    // Step 2: Wait for the user to turn their head to the right
    else if (_step == 2) {
      if (adjustedYaw != null && adjustedYaw > 15) {
        // Head is turned to the right
        setState(() {
          _instruction = "Perfect! Now blink your eyes.";
          _step = 3; // Move to the next step
        });
      } else {
        setState(() {
          _instruction = "Please turn your head to the right.";
        });
      }
    }
    // Step 3: Wait for the user to blink
    else if (_step == 3) {
      if (leftEyeOpen != null &&
          rightEyeOpen != null &&
          leftEyeOpen < 0.4 &&
          rightEyeOpen < 0.4) {
        // Both eyes are closed (blinking)
        setState(() {
          _instruction = "Success! Verification complete.";
          _isSuccess = true;
          _step = 4; // Final step
        });
      } else {
        setState(() {
          _instruction = "Please blink your eyes.";
        });
      }
    }
  }

  void _updateInstructionNonInverted(Face face) {
    final double? yaw = face.headEulerAngleY; // Yaw angle (head rotation)
    final double? leftEyeOpen =
        face.leftEyeOpenProbability; // Left eye open probability
    final double? rightEyeOpen =
        face.rightEyeOpenProbability; // Right eye open probability

    // Step 0: Check if the face is straight
    if (_step == 0) {
      if (yaw != null && yaw.abs() < 10) {
        // Face is straight
        setState(() {
          _instruction = "Face verified. Turn your head to the left.";
          _step = 1; // Move to the next step
        });
      } else {
        setState(() {
          _instruction = "Please look straight.";
        });
      }
    }
    // Step 1: Wait for the user to turn their head to the left
    else if (_step == 1) {
      if (yaw != null && yaw < -15) {
        // Head is turned to the left
        setState(() {
          _instruction = "Great! Now turn your head to the right.";
          _step = 2; // Move to the next step
        });
      } else {
        setState(() {
          _instruction = "Please turn your head to the left.";
        });
      }
    }
    // Step 2: Wait for the user to turn their head to the right
    else if (_step == 2) {
      if (yaw != null && yaw > 15) {
        // Head is turned to the right
        setState(() {
          _instruction = "Perfect! Now blink your eyes.";
          _step = 3; // Move to the next step
        });
      } else {
        setState(() {
          _instruction = "Please turn your head to the right.";
        });
      }
    }
    // Step 3: Wait for the user to blink
    else if (_step == 3) {
      if (leftEyeOpen != null &&
          rightEyeOpen != null &&
          leftEyeOpen < 0.4 &&
          rightEyeOpen < 0.4) {
        // Both eyes are closed (blinking)
        setState(() {
          _instruction = "Success! Verification complete.";
          _isSuccess = true;
          _step = 4; // Final step
        });
      } else {
        setState(() {
          _instruction = "Please blink your eyes.";
        });
      }
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
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
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
                  color: _isSuccess ? Colors.green : Colors.white,
                ),
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
      var rotationCompensation =
          {
            DeviceOrientation.portraitUp: 0,
            DeviceOrientation.landscapeLeft: 90,
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
