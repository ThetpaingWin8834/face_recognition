import 'package:face_recognition/face_liveness_screen.dart';
import 'package:face_recognition/liveness_check/liveness_check_screen.dart';
import 'package:face_recognition/liveness_check/liveness_check_screen2.dart';
import 'package:face_recognition/liveness_check/models/required_move.dart';
import 'package:face_recognition/recognition/face_recognition_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Recognition',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: LivenessCheckScreen(features: RequiredMove.values),
    );
  }
}
