// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:face_recognition/helpers.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraPermissionChecker extends StatefulWidget {
  final Widget child;
  const CameraPermissionChecker({Key? key, required this.child})
    : super(key: key);

  @override
  State<CameraPermissionChecker> createState() =>
      _CameraPermissionCheckerState();
}

class _CameraPermissionCheckerState extends State<CameraPermissionChecker>
    with WidgetsBindingObserver {
  PermissionStatus? _status;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _checkPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    printLog(status.name);
    if (!mounted) return;
    setState(() {
      _status = status;
    });
  }

  Future<void> _requestPermission() async {
    if (_requesting) return;
    _requesting = true;

    final status = await Permission.camera.request();

    if (!mounted) return;
    setState(() {
      _status = status;
      _requesting = false;
    });
  }

  void _openSettings() {
    openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (_status == PermissionStatus.granted) {
      return widget.child;
    }

    if (_status == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final bool permanentlyDenied =
        _status == PermissionStatus.permanentlyDenied ||
        _status == PermissionStatus.restricted;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt, size: 72),
                const SizedBox(height: 24),
                Text(
                  permanentlyDenied
                      ? 'Camera permission permanently denied'
                      : 'Camera permission required',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  permanentlyDenied
                      ? 'Please enable camera permission from app settings to continue.'
                      : 'We need camera access to continue.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (!permanentlyDenied)
                  ElevatedButton(
                    onPressed: _requesting ? null : _requestPermission,
                    child: const Text('Grant Permission'),
                  ),
                if (permanentlyDenied)
                  ElevatedButton(
                    onPressed: _openSettings,
                    child: const Text('Open Settings'),
                  ),
                FilledButton(
                  onPressed: _checkPermission,
                  child: const Text('Check Permission'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
