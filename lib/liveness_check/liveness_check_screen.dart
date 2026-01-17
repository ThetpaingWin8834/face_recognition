// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:face_recognition/permission_checker.dart';
import 'package:flutter/services.dart';

class LivenessCheckScreen extends StatefulWidget {
  final List<RequiredMove> features;
  final ResolutionPreset resolutionPreset;
  const LivenessCheckScreen({
    Key? key,
    required this.features,
    this.resolutionPreset = .high,
  }) : super(key: key);

  @override
  State<LivenessCheckScreen> createState() => _LivenessCheckScreenState();
}

class _LivenessCheckScreenState extends State<LivenessCheckScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCameraController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dispose();
    super.dispose();
  }

  void _dispose() {
    _cameraController?.dispose();
    _cameraController = null;
  }

  void _initCameraController() async {
    try {
      final cameras = await availableCameras();
      final cameraDesc = cameras.firstWhere((camera) {
        return camera.lensDirection == .front;
      });
      _cameraController = CameraController(cameraDesc, widget.resolutionPreset);
      await _cameraController!.initialize();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          duration: Duration(days: 1),
          action: SnackBarAction(
            label: 'Close',
            onPressed: () {
              SystemNavigator.pop();
            },
          ),
        ),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCameraController();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CameraPermissionChecker(
      child: Scaffold(
        body:
            _cameraController != null && _cameraController!.value.isInitialized
            ? CameraPreview(_cameraController!)
            : Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

enum RequiredMove {
  turnLeft,
  turnRight,
  eyeBlink;

  String displayMessage() {
    return switch (this) {
      RequiredMove.turnLeft => 'Turn Your Face To LEFT',
      RequiredMove.turnRight => 'Turn Your Face To RIGHT',
      RequiredMove.eyeBlink => 'Blink Your EYES',
    };
  }
}
