// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:face_recognition/helpers.dart';
import 'package:face_recognition/img_utils.dart';
import 'package:face_recognition/liveness_check/liveness_checker.dart';
import 'package:face_recognition/liveness_check/models/required_move.dart';
import 'package:flutter/material.dart';

import 'package:face_recognition/permission_checker.dart';
import 'package:flutter/services.dart';

class LivenessCheckScreen2 extends StatefulWidget {
  final List<RequiredMove> features;
  final ResolutionPreset resolutionPreset;
  const LivenessCheckScreen2({
    Key? key,
    required this.features,
    this.resolutionPreset = .high,
  }) : super(key: key);

  @override
  State<LivenessCheckScreen2> createState() => _LivenessCheckScreen2State();
}

class _LivenessCheckScreen2State extends State<LivenessCheckScreen2>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  late final livenessChecker = LivenessChecker(features: widget.features);
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
      _cameraController = CameraController(cameraDesc, widget.resolutionPreset,imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888);
      await _cameraController!.initialize();
      await livenessChecker.init(
        sensorOrientation: cameraDesc.sensorOrientation,
      );
      await _cameraController!.startImageStream(livenessChecker.onImageStream);
      
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
            ? Stack(
                children: [
                  CameraPreview(_cameraController!),
                  Positioned(
                    right: 36,
                    top: 36,
                    width: 150,
                    height: 250,
                    child: Transform.flip(
                      flipX: true,
                      child: Transform.rotate(
                        angle: -pi / 2,
                        child: Center(
                          child: ValueListenableBuilder(
                            valueListenable: livenessChecker.currentImageStream,
                            builder: (context, value, child) {
                              // printLog('bio');
                              if (value != null) {
                                
                                return Image.memory(
                                  value,
                                  fit: .contain,
                                  gaplessPlayback: true,
                                  // ImgUtils.convertToBytes(
                                  //   ImgUtils.convertCameraImageToImage(value!),
                                  // ),
                                );
                              }
                              return Container(color: Colors.amber,);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
