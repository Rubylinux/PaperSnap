import 'package:flutter/material.dart';
import 'package:papersnap/models/document.dart';
import 'package:papersnap/services/document_storage.dart';
import 'dart:io';

class SaveDocumentPage extends StatefulWidget {
  final ScanSession scanSession;

  const SaveDocumentPage({
    super.key,
    required this.scanSession,
  });

  @override
  State<SaveDocumentPage> createState() => _SaveDocumentPageState();
}

class _SaveDocumentPageState extends State<SaveDocumentPage> {
  final TextEditingController _nameController = TextEditingController();
  final DocumentStorageService _storage = DocumentStorageService();
  DocumentType _selectedType = DocumentType.pdf;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = 'Scanned Document ${DateTime.now().day}-${DateTime.now().month}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveDocument() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a document name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final fileName = _nameController.text.trim();
      String filePath;
      
      if (_selectedType == DocumentType.pdf) {
        filePath = await _storage.savePdfFromImages(widget.scanSession.scannedImages, fileName);
      } else {
        filePath = await _storage.saveImageFromSession(widget.scanSession.scannedImages, fileName);
      }

      final thumbnailPath = await _storage.createThumbnail(widget.scanSession.scannedImages.first);

      final document = ScannedDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: fileName,
        filePath: filePath,
        createdAt: DateTime.now(),
        type: _selectedType,
        pageCount: widget.scanSession.count,
        thumbnailPath: thumbnailPath,
      );

      await _storage.saveDocument(document);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${document.name} saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Save Document'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDocumentPreview(theme),
            const SizedBox(height: 32),
            _buildDocumentName(theme),
            const SizedBox(height: 24),
            _buildTypeSelector(theme),
            const Spacer(),
            _buildSaveButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentPreview(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainer,
      ),
      child: widget.scanSession.scannedImages.isNotEmpty
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(widget.scanSession.scannedImages.first),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                if (widget.scanSession.count > 1)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.scanSession.count} pages',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : Icon(
              Icons.document_scanner_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
    );
  }

  Widget _buildDocumentName(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Document Name',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'Enter document name',
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainer,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Save As',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTypeOption(
                theme,
                type: DocumentType.pdf,
                icon: Icons.picture_as_pdf_outlined,
                label: 'PDF',
                subtitle: 'Multi-page document',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeOption(
                theme,
                type: DocumentType.photo,
                icon: Icons.image_outlined,
                label: 'Photo',
                subtitle: widget.scanSession.count == 1 ? 'Single image' : 'PDF (multiple pages)',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeOption(
    ThemeData theme, {
    required DocumentType type,
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    final isSelected = _selectedType == type;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : theme.colorScheme.surfaceContainer,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveDocument,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: theme.colorScheme.onPrimary,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.save_outlined,
                    color: theme.colorScheme.onPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Save Document',
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
}