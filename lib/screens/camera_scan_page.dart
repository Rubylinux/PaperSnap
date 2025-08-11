import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:papersnap/models/document.dart';
import 'package:papersnap/screens/document_preview_page.dart';
import 'package:papersnap/screens/save_document_page.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math';

class CameraScanPage extends StatefulWidget {
  const CameraScanPage({super.key});

  @override
  State<CameraScanPage> createState() => _CameraScanPageState();
}

class _CameraScanPageState extends State<CameraScanPage> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isCapturing = false;
  FlashMode _currentFlashMode = FlashMode.off;
  final ScanSession _scanSession = ScanSession(
    scannedImages: [],
    sessionId: DateTime.now(),
  );
  
  // Document detection state
  List<Offset>? _detectedCorners;
  Timer? _stabilityTimer;
  DateTime _lastDetectionTime = DateTime.now();
  bool _isDocumentStable = false;
  double _stabilityProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      _showPermissionDeniedDialog();
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      _controller = CameraController(
        _cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      await _controller!.setFlashMode(_currentFlashMode);
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text('This app needs camera access to scan documents.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _captureImage({bool auto = false}) async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      // Capture the image
      final image = await _controller!.takePicture();

      final croppedImagePath = image.path; 

      _scanSession.addImage(croppedImagePath);

      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DocumentPreviewPage(
              imagePath: croppedImagePath,
              onRetake: () => Navigator.of(context).pop(),
              onKeep: () => Navigator.of(context).pop(),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Capture error: $e');
    }

    setState(() => _isCapturing = false);
  }

  Future<void> _finishScanning() async {
    if (_scanSession.isEmpty) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => SaveDocumentPage(scanSession: _scanSession),
      ),
    );

    if (result == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitialized
          ? _buildCameraView(theme)
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildCameraView(ThemeData theme) {
    return Stack(
      children: [
        // Camera preview
        Positioned.fill(
          child: CameraPreview(_controller!),
        ),
        
        // Top controls
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: _buildTopControls(theme),
        ),
        
        // Bottom controls
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 32,
          left: 0,
          right: 0,
          child: _buildBottomControls(theme),
        ),
      ],
    );
  }

  Widget _buildTopControls(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
        ),
        if (_scanSession.count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_scanSession.count} scanned',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        TextButton(
          onPressed: _scanSession.isEmpty ? null : _finishScanning,
          child: Text(
            'Done',
            style: TextStyle(
              color: _scanSession.isEmpty ? Colors.grey : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Recent scan thumbnail
          _buildRecentScanThumbnail(),
          
          // Capture button
          GestureDetector(
            onTap: () => _captureImage(),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                color: _isCapturing ? Colors.grey : Colors.transparent,
              ),
              child: _isCapturing
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Container(
                      margin: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          
          // Flash toggle
          GestureDetector(
            onTap: _toggleFlash,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _currentFlashMode == FlashMode.torch 
                    ? Colors.yellow.withOpacity(0.3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                border: _currentFlashMode == FlashMode.torch 
                    ? Border.all(color: Colors.yellow, width: 1)
                    : null,
              ),
              child: Icon(
                _currentFlashMode == FlashMode.torch
                    ? Icons.flash_on
                    : Icons.flash_off,
                color: _currentFlashMode == FlashMode.torch 
                    ? Colors.yellow 
                    : Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentScanThumbnail() {
    if (_scanSession.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.transparent, width: 2),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _viewRecentScan(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                File(_scanSession.scannedImages.last),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.white,
                      size: 24,
                    ),
                  );
                },
              ),
            ),
            if (_scanSession.count > 1)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_scanSession.count}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _viewRecentScan() {
    if (_scanSession.isEmpty) return;
    
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.9),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Recent scan preview
              Container(
                width: 200,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(_scanSession.scannedImages.last),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              Text(
                'Scan ${_scanSession.count} of ${_scanSession.count}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Retake button
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          _retakeLastScan();
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.red, width: 1),
                          ),
                          child: const Icon(
                            Icons.refresh,
                            color: Colors.red,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Retake',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                  
                  // Keep button
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.green, width: 1),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.green,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Keep',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                  
                  // View all button (if multiple scans)
                  if (_scanSession.count > 1)
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            _viewAllScans();
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.blue, width: 1),
                            ),
                            child: const Icon(
                              Icons.view_list,
                              color: Colors.blue,
                              size: 30,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'View All',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                ],
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
  
  void _retakeLastScan() {
    if (_scanSession.isEmpty) return;
    
    setState(() {
      _scanSession.removeImage(_scanSession.count - 1);
    });
  }
  
  void _viewAllScans() {
    // Navigate to a preview of all scanned images
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SaveDocumentPage(scanSession: _scanSession),
      ),
    );
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    try {
      _currentFlashMode = _currentFlashMode == FlashMode.torch 
          ? FlashMode.off 
          : FlashMode.torch;
      
      await _controller!.setFlashMode(_currentFlashMode);
      setState(() {});
    } catch (e) {
      debugPrint('Flash toggle error: $e');
      // Revert flash mode if there was an error
      _currentFlashMode = _currentFlashMode == FlashMode.torch 
          ? FlashMode.off 
          : FlashMode.torch;
    }
  }
}
