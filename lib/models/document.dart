import 'dart:io';

enum DocumentType { pdf, photo }

class ScannedDocument {
  final String id;
  final String name;
  final String filePath;
  final DateTime createdAt;
  final DocumentType type;
  final int pageCount;
  final String? thumbnailPath;
  final bool isPasswordProtected;
  final String? passwordHash;

  ScannedDocument({
    required this.id,
    required this.name,
    required this.filePath,
    required this.createdAt,
    required this.type,
    this.pageCount = 1,
    this.thumbnailPath,
    this.isPasswordProtected = false,
    this.passwordHash,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'filePath': filePath,
    'createdAt': createdAt.toIso8601String(),
    'type': type.name,
    'pageCount': pageCount,
    'thumbnailPath': thumbnailPath,
    'isPasswordProtected': isPasswordProtected,
    'passwordHash': passwordHash,
  };

  factory ScannedDocument.fromJson(Map<String, dynamic> json) => ScannedDocument(
    id: json['id'],
    name: json['name'],
    filePath: json['filePath'],
    createdAt: DateTime.parse(json['createdAt']),
    type: DocumentType.values.firstWhere((e) => e.name == json['type']),
    pageCount: json['pageCount'] ?? 1,
    thumbnailPath: json['thumbnailPath'],
    isPasswordProtected: json['isPasswordProtected'] ?? false,
    passwordHash: json['passwordHash'],
  );

  bool get exists => File(filePath).existsSync();

  ScannedDocument copyWith({
    String? id,
    String? name,
    String? filePath,
    DateTime? createdAt,
    DocumentType? type,
    int? pageCount,
    String? thumbnailPath,
    bool? isPasswordProtected,
    String? passwordHash,
  }) => ScannedDocument(
    id: id ?? this.id,
    name: name ?? this.name,
    filePath: filePath ?? this.filePath,
    createdAt: createdAt ?? this.createdAt,
    type: type ?? this.type,
    pageCount: pageCount ?? this.pageCount,
    thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    isPasswordProtected: isPasswordProtected ?? this.isPasswordProtected,
    passwordHash: passwordHash ?? this.passwordHash,
  );
}

class ScanSession {
  final List<String> scannedImages;
  final DateTime sessionId;

  ScanSession({
    required this.scannedImages,
    required this.sessionId,
  });

  void addImage(String imagePath) {
    scannedImages.add(imagePath);
  }

  void removeImage(int index) {
    if (index >= 0 && index < scannedImages.length) {
      scannedImages.removeAt(index);
    }
  }

  bool get isEmpty => scannedImages.isEmpty;
  int get count => scannedImages.length;
}