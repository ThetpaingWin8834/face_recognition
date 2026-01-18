import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

class ImgUtils {
  ImgUtils._();

  static Uint8List convertToBytes(img.Image image) {
    return img.encodeJpg(image);
  }

  static img.Image convertCameraImageToImage(CameraImage image) {
    if (Platform.isAndroid) {
      return _convertNV21(image);
    } else if (Platform.isIOS) {
      return _convertBGRA8888ToImage(image);
    } else {
      throw Exception('Unsupported');
    }
  }

  static img.Image _convertBGRA8888ToImage(CameraImage cameraImage) {
    final plane = cameraImage.planes[0];
    final width = cameraImage.width;
    final height = cameraImage.height;
    final bytes = plane.bytes;

    final image = img.Image(width: width, height: height);

    int byteIndex = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final b = bytes[byteIndex];
        final g = bytes[byteIndex + 1];
        final r = bytes[byteIndex + 2];
        final a = bytes[byteIndex + 3];
        image.setPixelRgba(x, y, r, g, b, a);
        byteIndex += 4;
      }
    }

    return image;
  }



  static img.Image _convertNV21GreyScale(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final img.Image outImg = img.Image(width: width, height: height);
    final bytes = image.planes[0].bytes;

    // Simple grayscale copy for demonstration
    int index = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final v = bytes[index++];
        outImg.setPixelRgba(x, y, v, v, v, 0xffffffff);
      }
    }
    return outImg;
  }

  static img.Image _convertNV21(CameraImage image) {
    final width = image.width.toInt();
    final height = image.height.toInt();

    Uint8List yuv420sp = image.planes[0].bytes;

    final outImg = img.Image(height: height, width: width);
    final int frameSize = width * height;

    for (int j = 0, yp = 0; j < height; j++) {
      int uvp = frameSize + (j >> 1) * width, u = 0, v = 0;
      for (int i = 0; i < width; i++, yp++) {
        int y = (0xff & yuv420sp[yp]) - 16;
        if (y < 0) y = 0;
        if ((i & 1) == 0) {
          v = (0xff & yuv420sp[uvp++]) - 128;
          u = (0xff & yuv420sp[uvp++]) - 128;
        }
        int y1192 = 1192 * y;
        int r = (y1192 + 1634 * v);
        int g = (y1192 - 833 * v - 400 * u);
        int b = (y1192 + 2066 * u);

        if (r < 0) {
          r = 0;
        } else if (r > 262143) {
          r = 262143;
        }

        if (g < 0) {
          g = 0;
        } else if (g > 262143) {
          g = 262143;
        }
        if (b < 0) {
          b = 0;
        } else if (b > 262143) {
          b = 262143;
        }

        outImg.setPixelRgb(
          i,
          j,
          ((r << 6) & 0xff0000) >> 16,
          ((g >> 2) & 0xff00) >> 8,
          (b >> 10) & 0xff,
        );
      }
    }
    return outImg;
  }
}
