import 'package:flutter/material.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../services/loan_service.dart';
import '../services/housing_service.dart';
import '../services/insurance_service.dart';
import 'vault_selection_modal.dart';

class SharedAddDocumentsScreen extends StatefulWidget {
  final String title;
  final String module;
  final String? itemId;
  final List<Map<String, dynamic>>? initialDocuments;
  final Widget? reminderCard;
  final String? notes;

  const SharedAddDocumentsScreen({
    super.key,
    required this.title,
    required this.module,
    this.itemId,
    this.initialDocuments,
    this.reminderCard,
    this.notes,
  });

  @override
  State<SharedAddDocumentsScreen> createState() =>
      _SharedAddDocumentsScreenState();
}

class _SharedAddDocumentsScreenState extends State<SharedAddDocumentsScreen> {
  List<Map<String, dynamic>> _documents = [];
  final ImagePicker _picker = ImagePicker();
  
  dynamic get _apiService {
    if (widget.module == 'housing') return HousingService();
    if (widget.module == 'insurance') return InsuranceService();
    return LoanService();
  }
  
  bool _isUploading = false;
  bool _isLoading = false;

  static const Color brandRed = Color(0xFFC61C36);

  @override
  void initState() {
    super.initState();
    if (widget.initialDocuments != null &&
        widget.initialDocuments!.isNotEmpty) {
      _documents = List.from(widget.initialDocuments!);
    } else {
      _fetchExistingDocuments();
    }
  }

  Future<void> _fetchExistingDocuments() async {
    setState(() => _isLoading = true);
    try {
      final List<dynamic> existing;
      if (widget.itemId != null) {
        existing = await _apiService.fetchDocumentsByRelated(
          widget.itemId!,
          widget.module,
        );
      } else {
        existing = await _apiService.fetchDocumentsByModule(widget.module);
      }
      setState(() {
        _documents = existing
            .map(
              (doc) => {
                'id': doc.id,
                'name': doc.displayName,
                'type': doc.mimeType.contains('pdf') ? 'pdf' : 'image',
                'date': doc.createdAt ?? DateTime.now(),
                'path': doc.path,
              },
            )
            .toList();
      });
    } catch (e) {
      debugPrint('Error fetching existing: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null) {
      File file = File(result.files.single.path!);
      await _uploadDocument(file, result.files.single.name);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.gallery) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        await _uploadDocument(file, result.files.single.name);
      }
    } else {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        File file = File(image.path);
        String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        String extension = image.path.split('.').last.toLowerCase();
        await _uploadDocument(file, 'IMG_$timestamp.$extension');
      }
    }
  }

  Future<void> _uploadDocument(File file, String fileName) async {
    setState(() => _isUploading = true);
    try {
      final documentFile = await _apiService.uploadDocument(
        file,
        relatedType: widget.module,
        relatedId: widget.itemId,
      );
      setState(() {
        _documents.add({
          'id': documentFile.id,
          'name': fileName,
          'type': fileName.split('.').last.toLowerCase(),
          'date': DateTime.now(),
          'path': documentFile.path,
        });
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteDocument(String docId, int index) async {
    if (widget.itemId != null) {
      // Unlink instead of delete
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove Document'),
          content: const Text(
            'Are you sure you want to remove this document from this section? It will still be available in your Vault.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove', style: TextStyle(color: brandRed)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() => _isLoading = true);
        try {
          await _apiService.linkDocumentsToRelated(
            [docId],
            '', // Unlink by setting relatedId to empty string
            '', // Unlink by setting relatedType to empty string
          );
          await _fetchExistingDocuments();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Document unlinked successfully')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to unlink: $e'),
                backgroundColor: brandRed,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isUploading = true);
      try {
        await _apiService.deleteDocument(docId);
        setState(() => _documents.removeAt(index));
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Document deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _renameDocument(
    String docId,
    int index,
    String currentName,
  ) async {
    if (widget.itemId != null) {
      _showVaultManagementOnlyMessage();
      return;
    }
    final TextEditingController controller = TextEditingController(
      text: currentName,
    );
    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter new name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != currentName) {
      setState(() => _isUploading = true);
      try {
        await _apiService.renameDocument(docId, newName);
        setState(() => _documents[index]['name'] = newName);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Document renamed')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Rename failed: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _selectFromVault() async {
    if (widget.itemId == null) return;

    final List<String>? selectedDocIds = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VaultSelectionModal(
        excludeRelatedId: widget.itemId,
      ),
    );

    if (selectedDocIds != null && selectedDocIds.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        await _apiService.linkDocumentsToRelated(
          selectedDocIds,
          widget.itemId!,
          widget.module,
        );
        await _fetchExistingDocuments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Documents linked successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to link documents: $e'),
              backgroundColor: brandRed,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showVaultManagementOnlyMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Documents can only be managed (renamed/deleted) in the Vault.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(_documents),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 24,
                      color: Color(0xFF111111),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'Add New Files',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111111),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _pickFile,
                                child: _buildUploadCard(
                                  icon: Icons.file_upload_outlined,
                                  label: 'Upload',
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _pickImage(ImageSource.gallery),
                                child: _buildUploadCard(
                                  icon: Icons.camera_alt_outlined,
                                  label: 'Image',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Documents',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111111),
                              ),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: _selectFromVault,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: brandRed),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.folder_shared_outlined,
                                          color: brandRed,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Select from Vault',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: brandRed,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _pickFile,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: brandRed),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.add_to_photos_outlined,
                                          color: brandRed,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Upload New',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: brandRed,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (widget.itemId != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: brandRed.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: brandRed.withValues(alpha: 0.1),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: brandRed, size: 20),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'These documents are safely stored in your Vault. You can link existing ones or upload new files here.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: brandRed,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: CircularProgressIndicator(color: brandRed),
                            ),
                          )
                        else if (_documents.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'No documents uploaded yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _documents.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, index) {
                              final doc = _documents[index];
                              return _buildDocumentCard(
                                icon: _getIconForType(doc['type']),
                                iconColor: _getColorForType(doc['type']),
                                title: doc['name'],
                                subtitle:
                                    doc['subtitle'] ??
                                    'Uploaded on ${DateFormat('MMM dd, yyyy').format(doc['date'])}',
                                onDelete:
                                    () => _deleteDocument(doc['id'], index),
                                onRename:
                                    widget.itemId != null
                                        ? null
                                        : () => _renameDocument(
                                          doc['id'],
                                          index,
                                          doc['name'],
                                        ),
                                onTap: () {
                                  String category = 'Vault';
                                  if (widget.module == 'housing') category = 'Housing / Living Costs';
                                  if (widget.module == 'loans') category = 'Loans';
                                  if (widget.module == 'insurance') category = 'Insurance';
                                  context.go('/vault', extra: category);
                                },
                              );
                            },
                          ),
                        const SizedBox(height: 28),
                        if (widget.reminderCard != null) ...[
                          const Text(
                            'Reminders',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111111),
                            ),
                          ),
                          const SizedBox(height: 12),
                          widget.reminderCard!,
                          const SizedBox(height: 28),
                        ],
                        if (widget.notes != null) ...[
                          const Text(
                            'Notes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111111),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFF0F0F0),
                              ),
                            ),
                            child: Text(
                              widget.notes!.isEmpty
                                  ? 'No notes provided.'
                                  : widget.notes!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF888888),
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ],
                    ),
                  ),
                  if (_isUploading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: const Center(
                        child: CircularProgressIndicator(color: brandRed),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Documents saved successfully!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    context.pop(_documents);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save Documents',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

  Widget _buildUploadCard({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: Column(
        children: [
          Icon(icon, color: brandRed, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111111),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onDelete,
    VoidCallback? onRename,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111111),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
        ),
        trailing: const SizedBox.shrink(),
      ),
    );
  }

  IconData _getIconForType(String type) {
    if (type == 'pdf') return Icons.picture_as_pdf;
    if (['jpg', 'jpeg', 'png'].contains(type)) return Icons.image;
    return Icons.description;
  }

  Color _getColorForType(String type) {
    if (type == 'pdf') return Colors.red;
    if (['jpg', 'jpeg', 'png'].contains(type)) return Colors.blue;
    return brandRed;
  }
}
