import 'package:flutter/material.dart';
import 'package:papersnap/models/document.dart';
import 'dart:io';

class DocumentCard extends StatefulWidget {
  final ScannedDocument document;
  final VoidCallback onTap;
  final Function(String) onRename;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onPasswordToggle;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    required this.onRename,
    required this.onShare,
    required this.onDelete,
    required this.onPasswordToggle,
  });

  @override
  State<DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<DocumentCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildThumbnail(theme),
                ),
                Expanded(
                  flex: 2,
                  child: _buildDocumentInfo(theme),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: _buildMoreButton(theme),
            ),
            if (widget.document.isPasswordProtected)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lock,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(12).copyWith(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: widget.document.thumbnailPath != null && File(widget.document.thumbnailPath!).existsSync()
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(widget.document.thumbnailPath!),
                fit: BoxFit.cover,
              ),
            )
          : Center(
              child: Icon(
                widget.document.type == DocumentType.pdf 
                    ? Icons.picture_as_pdf_outlined
                    : Icons.image_outlined,
                color: theme.colorScheme.primary,
                size: 32,
              ),
            ),
    );
  }

  Widget _buildDocumentInfo(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.document.name,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.document.type == DocumentType.pdf 
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.document.type.name.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: widget.document.type == DocumentType.pdf 
                        ? Colors.red[600]
                        : Colors.green[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.document.pageCount > 1) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.document.pageCount} pages',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(widget.document.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreButton(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PopupMenuButton<String>(
        onSelected: _handleMenuAction,
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.more_vert,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          size: 20,
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'rename',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, color: Colors.blue[600], size: 18),
                const SizedBox(width: 12),
                const Text('Rename'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'share',
            child: Row(
              children: [
                Icon(Icons.share_outlined, color: Colors.green[600], size: 18),
                const SizedBox(width: 12),
                const Text('Share'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'password',
            child: Row(
              children: [
                Icon(
                  widget.document.isPasswordProtected ? Icons.lock_open_outlined : Icons.lock_outlined,
                  color: Colors.orange[600],
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(widget.document.isPasswordProtected ? 'Remove Password' : 'Add Password'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.red[600], size: 18),
                const SizedBox(width: 12),
                const Text('Delete'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'rename':
        _showRenameDialog();
        break;
      case 'share':
        widget.onShare();
        break;
      case 'password':
        widget.onPasswordToggle();
        break;
      case 'delete':
        widget.onDelete();
        break;
    }
  }

  void _showRenameDialog() {
    final controller = TextEditingController(text: widget.document.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Document Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onRename(controller.text.trim());
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}