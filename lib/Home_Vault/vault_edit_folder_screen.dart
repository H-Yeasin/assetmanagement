import 'package:flutter/material.dart';
import '../Home_Dashboard/widgets.dart';

class VaultEditFolderScreen extends StatefulWidget {
  final String folderName;

  const VaultEditFolderScreen({super.key, required this.folderName});

  @override
  State<VaultEditFolderScreen> createState() => _VaultEditFolderScreenState();
}

class _VaultEditFolderScreenState extends State<VaultEditFolderScreen> {
  late TextEditingController _nameController;

  // Dummy file list
  final List<Map<String, String>> _files = [
    {'name': 'Property_Deed.pdf', 'info': '2.4 MB', 'type': 'pdf'},
    {'name': 'ID_Front.jpg', 'info': 'Jan 08 2024 • 2.4 MB', 'type': 'image'},
  ];

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
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF111111)),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: brandRed, width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── File List with Delete ──
                    ...List.generate(_files.length, (index) {
                      final file = _files[index];
                      return _EditFileRow(
                        fileName: file['name']!,
                        fileInfo: file['info']!,
                        fileType: file['type']!,
                        onDelete: () {
                          setState(() {
                            _files.removeAt(index);
                          });
                        },
                      );
                    }),

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
                  onPressed: () {
                    // Placeholder — save logic later
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Save & Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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

// ── Edit File Row (with delete icon) ─────────────────────────────────────────
class _EditFileRow extends StatelessWidget {
  final String fileName;
  final String fileInfo;
  final String fileType;
  final VoidCallback onDelete;

  const _EditFileRow({
    required this.fileName,
    required this.fileInfo,
    required this.fileType,
    required this.onDelete,
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
                  ? Image.asset('assets/images/pdficon.png', width: 22, height: 22)
                  : const Icon(Icons.image_rounded, color: Color(0xFF2196F3), size: 22),
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
