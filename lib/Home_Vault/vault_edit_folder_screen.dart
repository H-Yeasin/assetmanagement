import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Home_Dashboard/widgets.dart';
import '../services/loan_service.dart';
import '../Loan_Screen/models/document_model.dart';

class VaultEditFolderScreen extends StatefulWidget {
  final String folderName;
  final String folderId;

  const VaultEditFolderScreen({
    super.key,
    required this.folderName,
    required this.folderId,
  });

  @override
  State<VaultEditFolderScreen> createState() => _VaultEditFolderScreenState();
}

class _VaultEditFolderScreenState extends State<VaultEditFolderScreen> {
  late TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.folderName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (!_isSaving) context.pop();
                    },
                    child: const Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20), // balance
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Folder Name Label ──
                    const Text(
                      'Folder Name',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Text Field ──
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111111),
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFDDDDDD),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFDDDDDD),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: brandRed, width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── File List with Delete ──
                    FutureBuilder<List<DocumentFile>>(
                      future: _fetchFolderDocuments(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: brandRed),
                          );
                        }
                        final allDocs = snapshot.data ?? [];
                        final docs = allDocs
                            .where((d) => d.folderId == widget.folderId)
                            .toList();

                        if (docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                'No documents found in this folder.',
                                style: TextStyle(color: Color(0xFF888888)),
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final isPdf =
                                doc.mimeType == 'application/pdf' ||
                                doc.displayName.endsWith('.pdf');
                            return _EditFileRow(
                              fileName: doc.displayName,
                              fileInfo:
                                  '${doc.size != null ? (doc.size / 1024).toStringAsFixed(1) : "0"} KB',
                              fileType: isPdf ? 'pdf' : 'image',
                              onDelete: () => _deleteDocument(doc.id),
                              onEdit: () =>
                                  _editDocumentName(doc.id, doc.displayName),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ── Save & Continue Button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isSaving ? null : _saveChanges,
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save & Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<DocumentFile>> _fetchFolderDocuments() async {
    return LoanService().fetchDocumentsByModule('loans');
  }

  Future<void> _deleteDocument(String id) async {
    // Show confirmation dialog before deleting
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: const Text(
          'Are you sure you want to delete this file? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSaving = true);
      try {
        await LoanService().deleteDocument(id);
        if (mounted) {
          // Trigger a re-build so FutureBuilder fetches again
          setState(() => _isSaving = false);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete file: $e')));
        }
      }
    }
  }

  Future<void> _saveChanges() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    if (newName == widget.folderName) {
      context.pop(); // No change needed
      return;
    }

    setState(() => _isSaving = true);
    try {
      await LoanService().renameDocument(widget.folderId, newName);
      if (mounted) {
        // We pop and ideally we would notify the caller about the new name.
        // For simplicity we just return to previous screen. Wait, we should pop twice?
        // Or pop back to vault main screen.
        context.pop();
        context.pop();
        // We pop twice because subfolder screen has the old name in its state/arguments.
        // It's easiest to go back to VaultCategoryScreen.
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to rename folder: $e')));
      }
    }
  }

  Future<void> _editDocumentName(String id, String currentName) async {
    final TextEditingController editController = TextEditingController(
      text: currentName,
    );

    final bool? save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit File Name'),
        content: TextField(
          controller: editController,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: brandRed, width: 1.5),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Save', style: TextStyle(color: brandRed)),
          ),
        ],
      ),
    );

    if (save == true) {
      final newName = editController.text.trim();
      if (newName.isNotEmpty && newName != currentName) {
        setState(() => _isSaving = true);
        try {
          await LoanService().renameDocument(id, newName);
          if (mounted) {
            setState(() => _isSaving = false);
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to rename file: $e')),
            );
          }
        }
      }
    }
  }
}

// ── Edit File Row (with edit and delete icons) ───────────────────────────────
class _EditFileRow extends StatelessWidget {
  final String fileName;
  final String fileInfo;
  final String fileType;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _EditFileRow({
    required this.fileName,
    required this.fileInfo,
    required this.fileType,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: const Color(0xFFF0F0F0))),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: fileType == 'pdf'
                    ? const Color(0xFFFFF0F2)
                    : const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: fileType == 'pdf'
                  ? Image.asset(
                      'assets/images/pdficon.png',
                      width: 22,
                      height: 22,
                    )
                  : const Icon(
                      Icons.image_rounded,
                      color: Color(0xFF2196F3),
                      size: 22,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fileInfo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.all(6),
                child: const Icon(
                  Icons.edit,
                  color: Color(0xFF888888),
                  size: 20,
                ),
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  'assets/images/update_delete.png',
                  width: 32,
                  height: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
