import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../Home_Dashboard/widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/housing_service.dart';
import 'models/housing_cost_model.dart';

class HousingAddDocumentsScreen extends StatefulWidget {
  final HousingCost? cost;
  final List<Map<String, dynamic>>? initialDocuments;
  const HousingAddDocumentsScreen({
    super.key,
    this.cost,
    this.initialDocuments,
  });

  @override
  State<HousingAddDocumentsScreen> createState() =>
      _HousingAddDocumentsScreenState();
}

class _HousingAddDocumentsScreenState extends State<HousingAddDocumentsScreen> {
  List<Map<String, dynamic>> _documents = [];
  final ImagePicker _picker = ImagePicker();
  final HousingService _apiService = HousingService();
  bool _isUploading = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDocuments != null && widget.initialDocuments!.isNotEmpty) {
      _documents = List.from(widget.initialDocuments!);
    } else {
      _fetchExistingDocuments();
    }
  }

  Future<void> _fetchExistingDocuments() async {
    setState(() => _isLoading = true);
    try {
      final existing = await _apiService.fetchDocumentsByModule('housing');
      setState(() {
        _documents = existing.map((doc) => {
          'id': doc.id,
          'name': doc.displayName,
          'type': doc.mimeType.contains('pdf') ? 'pdf' : 'image',
          'date': doc.createdAt ?? DateTime.now(),
          'path': doc.path,
        }).toList();
      });
    } catch (e) {
      debugPrint('Error fetching existing: $e');
    } finally {
      setState(() => _isLoading = false);
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
    final XFile? image = await _picker.pickImage(source: source);

    if (image != null) {
      File file = File(image.path);
      await _uploadDocument(file, image.name);
    }
  }

  Future<void> _uploadDocument(File file, String fileName) async {
    setState(() => _isUploading = true);
    try {
      final documentFile = await _apiService.uploadDocument(
        file,
        relatedType: 'housing',
        relatedId: widget.cost?.id,
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
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isUploading = true);
      try {
        await _apiService.deleteDocument(docId);
        setState(() {
          _documents.removeAt(index);
        });
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != currentName) {
      setState(() => _isUploading = true);
      try {
        await _apiService.renameDocument(docId, newName);
        setState(() {
          _documents[index]['name'] = newName;
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD), // Very light background
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, _documents),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 24,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Add Documents',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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

            // ── Body ──
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // ── Add New Files ──
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

                        // ── Documents Section Header ──
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
                            GestureDetector(
                              onTap: _pickFile,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFC61C36),
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.add,
                                      color: Color(0xFFC61C36),
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Add Documents',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFFC61C36),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
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
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final doc = _documents[index];
                              return _buildDocumentCard(
                                icon: _getIconForType(doc['type']),
                                iconColor: _getColorForType(doc['type']),
                                title: doc['name'],
                                subtitle:
                                    doc['subtitle'] ??
                                    'Uploaded on ${DateFormat('MMM dd, yyyy').format(doc['date'])}',
                                onDelete: () =>
                                    _deleteDocument(doc['id'], index),
                                onRename: () => _renameDocument(
                                  doc['id'],
                                  index,
                                  doc['name'],
                                ),
                                onTap: () async {
                                  if (doc['path'] != null) {
                                    final url = Uri.parse(doc['path']);
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(
                                        url,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    }
                                  }
                                },
                              );
                            },
                          ),

                        const SizedBox(height: 28),

                        // ── Reminders Section ──
                        const Text(
                          'Reminders',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111111),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildReminderCard(),

                        const SizedBox(height: 28),

                        // ── Notes Section ──
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
                            border: Border.all(color: const Color(0xFFF0F0F0)),
                          ),
                          child: Text(
                            widget.cost?.notes ?? 'No notes provided.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF888888),
                              height: 1.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                  if (_isUploading)
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(
                        child: CircularProgressIndicator(color: brandRed),
                      ),
                    ),
                ],
              ),
            ),

            // ── Save Button ──
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _documents),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC61C36),
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
          Icon(icon, color: const Color(0xFFC61C36), size: 28),
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
            color: iconColor.withOpacity(0.1),
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
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Color(0xFF111111)),
          onSelected: (value) {
            if (value == 'rename') onRename?.call();
            if (value == 'delete') onDelete?.call();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'rename', child: Text('Rename')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard() {
    final cost = widget.cost;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFC61C36).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFFC61C36),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Reminders',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cost?.dueDate != null
                      ? DateFormat('MMMM dd, yyyy').format(cost!.dueDate!)
                      : 'N/A',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Text(
                  NumberFormat.simpleCurrency(
                    decimalDigits: 2,
                  ).format(cost?.amount ?? 0),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111111),
                  ),
                ),
              ),
              if (cost?.autoPay ?? false)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Paid automatically',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ),
            ],
          ),
        ],
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
    return const Color(0xFFC61C36);
  }
}
