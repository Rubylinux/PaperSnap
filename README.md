# PaperSnap - Document Scanner App Architecture

## Overview
PaperSnap is a Flutter-based document scanning app that replicates the iPhone's native document scanner functionality. The app provides automatic edge detection, multi-document scanning sessions, and flexible saving options (PDF or Photo).

## Core Features
1. **Document Scanning**: Camera-based scanning with automatic edge detection
2. **Multi-Document Sessions**: Scan multiple documents in one session
3. **Preview & Retake**: Review each scan before finalizing
4. **Flexible Save Options**: Save as PDF (multi-page) or Photo (single image)
5. **Document Management**: Local storage with recent documents dashboard

## Technical Architecture

### Dependencies
- `camera`: Camera access and image capture
- `image`: Image processing and manipulation
- `path_provider`: Local file system access
- `pdf`: PDF generation from images
- `shared_preferences`: Local data persistence
- `permission_handler`: Camera and storage permissions
- `edge_detection`: Document edge detection (fallback)
- `printing`: PDF handling utilities

### File Structure
```
lib/
├── models/
│   └── document.dart          # Document and ScanSession models
├── services/
│   └── document_storage.dart  # File management and PDF generation
├── screens/
│   ├── home_page.dart         # Main dashboard
│   ├── camera_scan_page.dart  # Camera scanning interface
│   ├── document_preview_page.dart # Individual scan preview
│   └── save_document_page.dart    # Save options and naming
├── widgets/
│   └── document_card.dart     # Document list item widget
├── main.dart                  # App entry point
└── theme.dart                # App theming and colors
```

### Key Workflows

#### 1. Document Scanning Session
```
Home → Camera → Preview → [Repeat] → Done → Save Options → Dashboard
```

#### 2. Data Flow
- **ScanSession**: Manages temporary scanned images during session
- **DocumentStorageService**: Handles file operations and persistence
- **ScannedDocument**: Persistent document model with metadata

#### 3. Save Logic
- **PDF Mode**: Combines all session images into multi-page PDF
- **Photo Mode**: 
  - Single image: Saves as JPG
  - Multiple images: Falls back to PDF format

### Storage Strategy
- **Local Storage**: All documents stored in app's documents directory
- **Thumbnails**: Generated for quick preview in dashboard
- **Metadata**: Saved in SharedPreferences as JSON
- **File Organization**: Organized by creation date and type

### UI Design Principles
- **Dark Theme**: Matches reference image with professional dark interface
- **Modern Material 3**: Uses latest Flutter design components
- **Accessibility**: High contrast colors and readable text sizes
- **Performance**: Optimized image handling and lazy loading

## Implementation Status
✅ Core architecture setup
✅ Camera integration with permissions
✅ Document models and storage service
✅ Home dashboard with recent documents
✅ Camera scanning interface with edge detection overlay
✅ Document preview and retake functionality
✅ Save options with PDF/Photo toggle
✅ Platform-specific permissions (Android/iOS)

## Future Enhancements
- OCR text extraction
- Cloud storage integration
- Document search and filtering
- Batch operations
- Enhanced edge detection algorithms
