// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:face_recognition/helpers.dart';
import 'package:face_recognition/img_utils.dart';
import 'package:face_recognition/liveness_check/liveness_checker.dart';
import 'package:face_recognition/liveness_check/models/liveness_check_error.dart';
import 'package:face_recognition/liveness_check/models/required_move.dart';
import 'package:face_recognition/permission_checker.dart';

class LivenessCheckScreen extends StatefulWidget {
  final List<RequiredMove> features;
  final ResolutionPreset resolutionPreset;
  final Widget Function(CameraController controller)? previewBuilder;
  final Widget Function(LivenessCheckError error)? errorBuilder;
  final Widget Function()? loadingBuilder;

  const LivenessCheckScreen({
    Key? key,
    required this.features,
    this.resolutionPreset = .high,
    this.previewBuilder,
    this.errorBuilder,
    this.loadingBuilder,
  }) : super(key: key);

  @override
  State<LivenessCheckScreen> createState() => _LivenessCheckScreenState();
}

class _LivenessCheckScreenState extends State<LivenessCheckScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  AppLifecycleState _prevLifeCycleState = .resumed;
  bool _didHandleNotresumeState = true;
  late final livenessChecker = LivenessChecker(features: widget.features);
  bool _loading = true;
  LivenessCheckError? _error;
  int _maxRetryCount = 3;

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

  Future<void> _initCameraController() async {
    try {
      await _cameraController?.pausePreview();
      await _cameraController?.dispose();
      _cameraController = null;
      setState(() {
        _loading = true;
        _error = null;
      });
      final cameras = await availableCameras();
      final cameraDesc = cameras.firstWhere((camera) {
        return camera.lensDirection == .front;
      });
      _cameraController = CameraController(
        cameraDesc,
        widget.resolutionPreset,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await _cameraController!.initialize();
      await livenessChecker.init(
        sensorOrientation: cameraDesc.sensorOrientation,
      );
      await _cameraController!.startImageStream(livenessChecker.onImageStream);

      setState(() {});
    } catch (e) {
      _onError(
        InitializedError(message: 'Failed to initialize camera!', rawError: e),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _onError(LivenessCheckError error) async {
    if (error is InitializedError || _maxRetryCount > 0) {
      _maxRetryCount = --_maxRetryCount;
        printLog(error.toString());

      await _initCameraController();
    } else {
      setState(() {
        _error = error;
      });
    }
    // setState(() {
    //   _error = InitializedError(
    //     message: 'Failed to initialize camera!',
    //     rawError: e,
    //   );
    // });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == .resumed) {
      _prevLifeCycleState = .resumed;
      _didHandleNotresumeState = false;
      _onLifeCycleResumed();
    } else if (!_didHandleNotresumeState) {
      _didHandleNotresumeState = true;
      _onLifeCycleNotResumed();
    }
    // if(state == .resumed){
    //   if(_cameraController == null){
    //     _initCameraController();
    //   }else{
    //     _cameraController!.resumePreview();
    //   }
    // }
    // if(_cameraController == null){
    //   return;
    // }

    // final CameraController? cameraController = _cameraController;
    // // App state changed before we got the chance to initialize.
    // if (cameraController == null || !cameraController.value.isInitialized) {
    //   return;
    // }

    // if (state == AppLifecycleState.inactive) {
    //   cameraController.dispose();
    // } else if (state == AppLifecycleState.resumed) {
    //   _initCameraController();
    // }
  }

  void _onLifeCycleResumed() async {
    try {
      final controller = _cameraController;
      if (controller == null || !controller.value.isInitialized) {
        printLog('_onLifeCycleResumed');
        await _initCameraController();
        return;
      }
      setState(() {
        _loading = true;
      });
      await _cameraController!.resumePreview();
      if(!controller.value.isStreamingImages){
       await controller.startImageStream((image) {});

      }
    } catch (e) {
      printLog(e);
      _onError(
        InitializedError(message: 'Failed to initialize camera when resume!', rawError: e),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _onLifeCycleNotResumed() {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    controller.pausePreview();
    controller.stopImageStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraPermissionChecker(
        child: Builder(
          builder: (context) {
            if (_error != null) {
              return widget.errorBuilder?.call(_error!) ??
                  _DefaultErrorView(error: _error!);
            } else if (_loading) {
              return widget.loadingBuilder?.call() ?? _DefaultLoadingView();
            } else if (_cameraController != null) {
              return Stack(
                children: [
                  widget.previewBuilder?.call(_cameraController!) ??
                      CameraPreview(_cameraController!),
                ],
              );
            }
            return SizedBox.shrink();
          },
        ),

        // child: Scaffold(
        //   body:
        //       _cameraController != null && _cameraController!.value.isInitialized
        //       ? Stack(
        //           children: [
        //             CameraPreview(_cameraController!),
        //             Positioned(
        //               right: 36,
        //               top: 36,
        //               width: 150,
        //               height: 250,
        //               child: Transform.flip(
        //                 flipX: true,
        //                 child: Transform.rotate(
        //                   angle: -pi / 2,
        //                   child: Center(
        //                     child: ValueListenableBuilder(
        //                       valueListenable: livenessChecker.currentImageStream,
        //                       builder: (context, value, child) {
        //                         // printLog('bio');
        //                         if (value != null) {
        //                           return Image.memory(
        //                             value,
        //                             fit: .contain,
        //                             gaplessPlayback: true,
        //                             // ImgUtils.convertToBytes(
        //                             //   ImgUtils.convertCameraImageToImage(value!),
        //                             // ),
        //                           );
        //                         }
        //                         return Container(color: Colors.amber);
        //                       },
        //                     ),
        //                   ),
        //                 ),
        //               ),
        //             ),
        //           ],
        //         )
        //       : Center(child: CircularProgressIndicator()),
        // ),
      ),
    );
  }
}
// class _DefaultFullScreenPreview extends StatelessWidget {
//   final CameraController controller;
//   const _DefaultFullScreenPreview({
//     Key? key,
//     required this.controller,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//    return Stack(
//                 children: [
//                   CameraPreview(controller),
//                   Positioned(
//                     right: 36,
//                     top: 36,
//                     width: 150,
//                     height: 250,
//                     child: Transform.flip(
//                       flipX: true,
//                       child: Transform.rotate(
//                         angle: -pi / 2,
//                         child: Center(
//                           child: ValueListenableBuilder(
//                             valueListenable: livenessChecker.currentImageStream,
//                             builder: (context, value, child) {
//                               // printLog('bio');
//                               if (value != null) {
//                                 return Image.memory(
//                                   value,
//                                   fit: .contain,
//                                   gaplessPlayback: true,
//                                   // ImgUtils.convertToBytes(
//                                   //   ImgUtils.convertCameraImageToImage(value!),
//                                   // ),
//                                 );
//                               }
//                               return Container(color: Colors.amber);
//                             },
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               )
//   }
// }

class _DefaultLoadingView extends StatelessWidget {
  const _DefaultLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.amber,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _DefaultErrorView extends StatelessWidget {
  final LivenessCheckError error;
  const _DefaultErrorView({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(error.toString()));
  }
}
