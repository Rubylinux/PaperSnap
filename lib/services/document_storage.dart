import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'package:papersnap/models/document.dart';

class DocumentStorageService {
  static const String _documentsKey = 'saved_documents';

  Future<Directory> get _documentsDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final docsDir = Directory('${appDir.path}/scanned_documents');
    if (!await docsDir.exists()) {
      await docsDir.create(recursive: true);
    }
    return docsDir;
  }

  Future<List<ScannedDocument>> getRecentDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final documentsJson = prefs.getStringList(_documentsKey) ?? [];
    
    final documents = documentsJson
        .map((json) => ScannedDocument.fromJson(jsonDecode(json)))
        .where((doc) => doc.exists)
        .toList();
    
    documents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return documents;
  }

  Future<void> saveDocument(ScannedDocument document) async {
    final prefs = await SharedPreferences.getInstance();
    final documentsJson = prefs.getStringList(_documentsKey) ?? [];
    
    documentsJson.add(jsonEncode(document.toJson()));
    await prefs.setStringList(_documentsKey, documentsJson);
  }

  Future<String> savePdfFromImages(List<String> imagePaths, String fileName) async {
    final pdf = pw.Document();
    final docsDir = await _documentsDirectory;
    
    for (final imagePath in imagePaths) {
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);
      
      if (decodedImage != null) {
        final pdfImage = pw.MemoryImage(imageBytes);
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => pw.Center(
              child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
            ),
          ),
        );
      }
    }

    final fileName_cleaned = fileName.replaceAll(RegExp(r'[^\w\s-.]'), '');
    final pdfPath = '${docsDir.path}/${fileName_cleaned}.pdf';
    final pdfFile = File(pdfPath);
    await pdfFile.writeAsBytes(await pdf.save());
    
    return pdfPath;
  }

  Future<String> saveImageFromSession(List<String> imagePaths, String fileName) async {
    final docsDir = await _documentsDirectory;
    
    if (imagePaths.length == 1) {
      final sourceFile = File(imagePaths.first);
      final fileName_cleaned = fileName.replaceAll(RegExp(r'[^\w\s-.]'), '');
      final destPath = '${docsDir.path}/${fileName_cleaned}.jpg';
      await sourceFile.copy(destPath);
      return destPath;
    } else {
      return await savePdfFromImages(imagePaths, fileName);
    }
  }

  Future<String> createThumbnail(String imagePath) async {
    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(imageBytes);
    
    if (originalImage != null) {
      final thumbnail = img.copyResize(originalImage, width: 150);
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: 80);
      
      final docsDir = await _documentsDirectory;
      final thumbnailPath = '${docsDir.path}/thumbnails';
      final thumbnailDir = Directory(thumbnailPath);
      
      if (!await thumbnailDir.exists()) {
        await thumbnailDir.create(recursive: true);
      }
      
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final thumbnailFile = File('$thumbnailPath/$fileName.jpg');
      await thumbnailFile.writeAsBytes(thumbnailBytes);
      
      return thumbnailFile.path;
    }
    
    return imagePath;
  }

  Future<void> deleteDocument(ScannedDocument document) async {
    final file = File(document.filePath);
    if (await file.exists()) {
      await file.delete();
    }
    
    if (document.thumbnailPath != null) {
      final thumbnail = File(document.thumbnailPath!);
      if (await thumbnail.exists()) {
        await thumbnail.delete();
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final documentsJson = prefs.getStringList(_documentsKey) ?? [];
    documentsJson.removeWhere((json) {
      final doc = ScannedDocument.fromJson(jsonDecode(json));
      return doc.id == document.id;
    });
    await prefs.setStringList(_documentsKey, documentsJson);
  }

  Future<int> getDocumentCount() async {
    final documents = await getRecentDocuments();
    return documents.length;
  }

  Future<List<ScannedDocument>> getDocumentsByType(DocumentType? type) async {
    final allDocuments = await getRecentDocuments();
    if (type == null) return allDocuments;
    return allDocuments.where((doc) => doc.type == type).toList();
  }

  Future<void> updateDocument(ScannedDocument document) async {
    await deleteDocument(document);
    await saveDocument(document);
  }

  Future<String> renameDocument(ScannedDocument document, String newName) async {
    final file = File(document.filePath);
    final directory = file.parent.path;
    final extension = document.type == DocumentType.pdf ? '.pdf' : '.jpg';
    final cleanName = newName.replaceAll(RegExp(r'[^\w\s-.]'), '');
    final newPath = '$directory/${cleanName}$extension';
    
    if (await file.exists()) {
      await file.rename(newPath);
    }
    
    final updatedDocument = document.copyWith(
      name: newName,
      filePath: newPath,
    );
    
    await updateDocument(updatedDocument);
    return newPath;
  }
}