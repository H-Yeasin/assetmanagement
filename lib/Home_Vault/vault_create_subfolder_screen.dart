import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Home_Dashboard/widgets.dart';
import '../services/loan_service.dart';
import '../services/vault_session_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class VaultCreateSubfolderScreen extends StatefulWidget {
  final String categoryName;

  const VaultCreateSubfolderScreen({super.key, required this.categoryName});

  @override
  State<VaultCreateSubfolderScreen> createState() =>
      _VaultCreateSubfolderScreenState();
}

class _VaultCreateSubfolderScreenState
    extends State<VaultCreateSubfolderScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  final List<File> _pendingFiles = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createFolder() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      String module = 'loans';
      if (widget.categoryName.contains('Housing')) module = 'housing';
      if (widget.categoryName.contains('Insurance')) module = 'insurance';
      if (widget.categoryName.contains('Document')) module = 'documents';

      final folder = await LoanService().createFolder(name, module);

      // Upload pending files to the newly created folder
      for (final file in _pendingFiles) {
        await LoanService().uploadDocument(
          file,
          module: module,
          folderId: folder.id,
        );
      }

      if (mounted) {
        context.pop(); // Go back to category screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create folder: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showImageSourcePicker() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      VaultSessionManager.instance.expectExternalActivity();
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _pendingFiles.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      VaultSessionManager.instance.expectExternalActivity();
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          for (var path in result.paths) {
            if (path != null) {
              _pendingFiles.add(File(path));
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
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
                    onTap: () => context.pop(),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Create Subfolder',
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
                    const SizedBox(height: 16),

                    // ── Folder Name ──
                    const Text(
                      'Folder Name',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: _nameController,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111111),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Notary',
                        hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
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

                    const SizedBox(height: 32),

                    // ── Add New Files ──
                    const Text(
                      'Add New Files',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: 'assets/images/upload.png',
                            label: 'Upload',
                            onTap: _isLoading ? () {} : _pickFile,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.camera_alt_outlined,
                            label: 'Take photo',
                            onTap: _isLoading ? () {} : _showImageSourcePicker,
                          ),
                        ),
                      ],
                    ),

                    if (_pendingFiles.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Selected Files',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._pendingFiles.map((file) {
                        final fileName = file.path.split('/').last;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.insert_drive_file,
                            color: brandRed,
                          ),
                          title: Text(
                            fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _pendingFiles.remove(file);
                              });
                            },
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // ── Create Subfolder Button ──
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
                  onPressed: _isLoading ? null : _createFolder,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Create Subfolder',
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
}

// ── Action Card (Upload / Take Photo) ────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final dynamic icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          children: [
            icon is IconData
                ? Icon(icon as IconData, color: brandRed, size: 28)
                : Image.asset(icon as String, width: 28, height: 28),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111111),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
