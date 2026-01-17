import 'package:camera/camera.dart';
import 'package:face_recognition/helpers.dart';
import 'package:image/image.dart' as img;

abstract class LivenessChecker {
  void onImageStream(CameraImage image) {
     printLog('streaming');
     
  }

}

class DefaultLivenessChecker extends LivenessChecker {
  @override
  void onImageStream(CameraImage image) {
    // super.onImageStream(image);
    // printLog('streaming');
    //
  }
}
