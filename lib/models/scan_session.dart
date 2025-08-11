import 'package:flutter/material.dart';

class ScanSession {
  final List<String> scannedImages;
  final DateTime sessionId;

  ScanSession({required this.scannedImages, required this.sessionId});

  int get count => scannedImages.length;

  bool get isEmpty => scannedImages.isEmpty;

  void addImage(String imagePath) {
    scannedImages.add(imagePath);
  }

  void removeImage(int index) {
    scannedImages.removeAt(index);
  }
}
