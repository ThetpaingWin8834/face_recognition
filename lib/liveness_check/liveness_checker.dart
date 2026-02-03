import 'dart:developer';
import 'dart:isolate';

import 'package:camera/camera.dart' show CameraImage;
import 'package:face_recognition/helpers.dart';
import 'package:face_recognition/img_utils.dart';
import 'package:face_recognition/liveness_check/liveness_check_screen.dart';
import 'package:face_recognition/liveness_check/models/required_move.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

class LivenessChecker {
  late final FaceDetector faceDetector;
  final bool debugFaceMeshShow;
  late InputImageRotation _rotation;
  late InputImageFormat _format;
  final currentImageStream = ValueNotifier<Uint8List?>(null);


  ///must call init
  LivenessChecker({
    required List<RequiredMove> features,
    this.debugFaceMeshShow = kDebugMode,
  }) : faceDetector = FaceDetector(
         options: FaceDetectorOptions(
           performanceMode: FaceDetectorMode
               .fast, // Use fast performance mode for quicker detection, ideal for real-time applications where speed is crucial
           enableClassification: features.contains(
             RequiredMove.eyeBlink,
           ), // Enable classification to detect facial expressions like eye blinks, which is essential for liveness checks
           enableContours:
               false, // Contour detection is disabled to optimize performance since detailed face contours are not required
           enableLandmarks:
               features.contains(RequiredMove.turnLeft) ||
               features.contains(
                 RequiredMove.turnRight,
               ), // Enable landmarks detection to identify key facial points necessary for detecting head turns to the left
           enableTracking:
               true, // Enable face tracking to maintain consistent detection of the face across multiple frames
         ),
       );
       bool _isprocessing = false;
  late Isolate _workerIsolate;
  late SendPort _workerSendPort;
  late ReceivePort _receivePort;
  Future<void> init({
    // most android camera image rotate 270 degree to image internally.most ios is 90
    required int sensorOrientation,
  }) async {
    _rotation = InputImageRotationValue.fromRawValue(sensorOrientation)!;
    // _receivePort = ReceivePort();
    // _workerIsolate = await Isolate.spawn(imageWorker, _receivePort.sendPort);

    // _workerSendPort =
    //     await _receivePort.first; // first message is SendPort from worker
  }

  // Worker isolate entry
  void imageWorker(SendPort mainSendPort) {
    final port = ReceivePort();
    mainSendPort.send(port.sendPort);

    port.listen((dynamic message) {
      final CameraImage cameraImage = message['cameraImage'];
      final SendPort reply = message['replyPort'];

      final img.Image image = ImgUtils.convertCameraImageToImage(cameraImage);
      final Uint8List jpgBytes = img.encodeJpg(image);
      reply.send(jpgBytes);
    });
  }

  void onImageStream(CameraImage image) async{
    if(_isprocessing)return;
    try {
      _isprocessing = true;
    currentImageStream.value = await tof(image);
    // final img = ImgUtils.convertCameraImageToImage(image);
    //   currentImageStream.value= ImgUtils.convertToBytes(img);
      
    } catch (e) {
      _log(e);
    }finally{
      _isprocessing = false;
    }
  }
  Future<Uint8List> tof(CameraImage image)async{
    final s =await Isolate.run(() {
      final img = ImgUtils.convertCameraImageToImage(image);
      return ImgUtils.convertToBytes(img);
    },);
    return s;
  }
  void _log(dynamic d){
    final stacktrace = StackTrace.current;
  final stackLines = stacktrace.toString().split('\n');
  final callerInfo = stackLines.length > 1 ? stackLines[1] : 'Unknown';
  final mtag = callerInfo.split('(').first.trim();
  
  log('LivenessChecker[$mtag] -> $d');
  }
}
