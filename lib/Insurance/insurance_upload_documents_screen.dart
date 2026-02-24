import 'package:flutter/material.dart';
import '../Home_Dashboard/widgets.dart';

class InsuranceUploadDocumentsScreen extends StatelessWidget {
  const InsuranceUploadDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: brandRed), onPressed: () => Navigator.pop(context)),
        title: const Text('Add documents', style: TextStyle(color: Color(0xFF111111), fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Center(
              child: Image.asset('assets/images/icon/doccument.png', width: 120, height: 120, errorBuilder: (c, e, s) => const Icon(Icons.description, size: 100, color: Colors.grey)),
            ),
            const SizedBox(height: 40),
            const Text(
              'Snap a picture of your document or\nupload it directly from your phone.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
            ),
            const Spacer(),
            _buildOption(context, 'Take Photo', Icons.camera_alt_outlined),
            const SizedBox(height: 16),
            _buildOption(context, 'Upload Documents', Icons.file_upload_outlined),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, String label, IconData icon) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFBFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: brandRed, size: 24),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111111))),
          ],
        ),
      ),
    );
  }
}
