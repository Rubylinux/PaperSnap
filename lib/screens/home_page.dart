import 'package:flutter/material.dart';
import 'package:papersnap/models/document.dart';
import 'package:papersnap/services/document_storage.dart';
import 'package:papersnap/screens/camera_scan_page.dart';
import 'package:papersnap/widgets/document_card.dart';
import 'package:papersnap/services/auth_service.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

enum DocumentFilter { all, pdf, photo }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DocumentStorageService _storage = DocumentStorageService();
  List<ScannedDocument> _documents = [];
  List<ScannedDocument> _filteredDocuments = [];
  int _documentCount = 0;
  bool _isLoading = true;
  DocumentFilter _currentFilter = DocumentFilter.all;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      final documents = await _storage.getRecentDocuments();
      final count = await _storage.getDocumentCount();
      setState(() {
        _documents = documents;
        _filteredDocuments = _filterDocuments(documents);
        _documentCount = count;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<ScannedDocument> _filterDocuments(List<ScannedDocument> documents) {
    switch (_currentFilter) {
      case DocumentFilter.pdf:
        return documents.where((doc) => doc.type == DocumentType.pdf).toList();
      case DocumentFilter.photo:
        return documents.where((doc) => doc.type == DocumentType.photo).toList();
      case DocumentFilter.all:
      default:
        return documents;
    }
  }

  void _setFilter(DocumentFilter filter) {
    setState(() {
      _currentFilter = filter;
      _filteredDocuments = _filterDocuments(_documents);
    });
  }

  void _handleSwipeGesture(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    const minVelocity = 500.0;
    
    if (velocity.dx.abs() < minVelocity) return;
    
    if (velocity.dx > 0) {
      // Swiping right - go to previous filter
      _switchToPreviousFilter();
    } else {
      // Swiping left - go to next filter  
      _switchToNextFilter();
    }
  }

  void _switchToPreviousFilter() {
    switch (_currentFilter) {
      case DocumentFilter.all:
        _setFilter(DocumentFilter.photo);
        break;
      case DocumentFilter.pdf:
        _setFilter(DocumentFilter.all);
        break;
      case DocumentFilter.photo:
        _setFilter(DocumentFilter.pdf);
        break;
    }
  }

  void _switchToNextFilter() {
    switch (_currentFilter) {
      case DocumentFilter.all:
        _setFilter(DocumentFilter.pdf);
        break;
      case DocumentFilter.pdf:
        _setFilter(DocumentFilter.photo);
        break;
      case DocumentFilter.photo:
        _setFilter(DocumentFilter.all);
        break;
    }
  }

  Future<void> _navigateToScan() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const CameraScanPage()),
    );

    if (result == true) {
      _loadDocuments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 32),
              _buildDocumentCounter(theme),
              const SizedBox(height: 32),
              _buildNewScanButton(theme),
              const SizedBox(height: 40),
              _buildRecentDocumentsSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'PaperSnap',
          style: theme.textTheme.displaySmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentCounter(ThemeData theme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildFilterButton(
              theme,
              DocumentFilter.all,
              Icons.description_outlined,
              'All Documents',
              _documents.length,
            ),
            _buildFilterButton(
              theme,
              DocumentFilter.pdf,
              Icons.picture_as_pdf_outlined,
              'PDF Files',
              _documents.where((d) => d.type == DocumentType.pdf).length,
            ),
            _buildFilterButton(
              theme,
              DocumentFilter.photo,
              Icons.image_outlined,
              'Photos',
              _documents.where((d) => d.type == DocumentType.photo).length,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Document Saved',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(
    ThemeData theme,
    DocumentFilter filter,
    IconData icon,
    String label,
    int count,
  ) {
    final isActive = _currentFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setFilter(filter),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.15)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewScanButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _navigateToScan,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.document_scanner_outlined,
              color: theme.colorScheme.onPrimary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'New Scan',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDocumentsSection(ThemeData theme) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Documents',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GestureDetector(
              onPanEnd: _handleSwipeGesture,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredDocuments.isEmpty
                      ? _buildEmptyState(theme)
                      : _buildDocumentsGrid(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.document_scanner_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No documents yet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the scan button to capture your first\ndocument',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsGrid(ThemeData theme) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _filteredDocuments.length,
      itemBuilder: (context, index) {
        final document = _filteredDocuments[index];
        return DocumentCard(
          document: document,
          onTap: () => _openDocument(document),
          onRename: (newName) => _renameDocument(document, newName),
          onShare: () => _shareDocument(document),
          onDelete: () => _deleteDocument(document),
          onPasswordToggle: () => _togglePassword(document),
        );
      },
    );
  }

  void _openDocument(ScannedDocument document) {
    // TODO: Implement document viewer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ${document.name}')),
    );
  }

  Future<void> _renameDocument(ScannedDocument document, String newName) async {
    try {
      await _storage.renameDocument(document, newName);
      _loadDocuments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document renamed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to rename document: $e')),
        );
      }
    }
  }

  Future<void> _shareDocument(ScannedDocument document) async {
    try {
      await Share.shareXFiles(
        [XFile(document.filePath)],
        text: 'Sharing document: ${document.name}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share document: $e')),
        );
      }
    }
  }

  Future<void> _togglePassword(ScannedDocument document) async {
    if (document.isPasswordProtected) {
      _removePassword(document);
    } else {
      _addPassword(document);
    }
  }

  Future<void> _addPassword(ScannedDocument document) async {
    final password = await _showPasswordDialog('Add Password', 'Enter a password to protect this document:');
    if (password != null && password.isNotEmpty) {
      final hashedPassword = AuthService.hashPassword(password);
      final updatedDocument = document.copyWith(
        isPasswordProtected: true,
        passwordHash: hashedPassword,
      );
      await _storage.updateDocument(updatedDocument);
      _loadDocuments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password protection enabled')),
        );
      }
    }
  }

  Future<void> _removePassword(ScannedDocument document) async {
    final authenticated = await AuthService.authenticateForPasswordRemoval();
    if (authenticated) {
      final updatedDocument = document.copyWith(
        isPasswordProtected: false,
        passwordHash: null,
      );
      await _storage.updateDocument(updatedDocument);
      _loadDocuments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password protection removed')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication failed')),
        );
      }
    }
  }

  Future<String?> _showPasswordDialog(String title, String message) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Set Password'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDocument(ScannedDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${document.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storage.deleteDocument(document);
      _loadDocuments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted')),
        );
      }
    }
  }
}