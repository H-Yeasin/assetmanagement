import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../Home_Dashboard/widgets.dart';
import '../Loan_Screen/models/document_model.dart';
import 'vault_category_widgets.dart';

/// Mixin that provides all bottom-sheet menus and the confirmation dialog
/// used by VaultCategoryScreen.
///
/// Requires the host state to expose:
///   - `void showUploadOptions()`
///   - `void pickImage(ImageSource source)`
///   - `void uploadFile()`
///   - `Future<void> deleteFolder(DocumentFile folder, List<DocumentFile> allDocs)`
///   - `Future<void> renameFile(DocumentFile doc)`
///   - `Future<void> deleteFile(DocumentFile doc)`
///   - `Future<void> downloadDocument(DocumentFile doc)`
///   - `Future<void> shareDocument(DocumentFile doc)`
///   - `Future<void> reloadDocuments()`
///   - `String get categoryName`
mixin VaultCategoryDialogsMixin<T extends StatefulWidget> on State<T> {
  // ── Abstract contracts the host state must satisfy ────────────────────────
  void showUploadOptions();
  Future<void> reloadDocuments();
  Future<void> deleteFolder(DocumentFile folder, List<DocumentFile> allDocs);
  Future<void> renameFile(DocumentFile doc);
  Future<void> deleteFile(DocumentFile doc);
  Future<void> downloadDocument(DocumentFile doc);
  Future<void> shareDocument(DocumentFile doc);
  void pickImage(ImageSource source);
  void uploadFile();
  String get categoryName;

  // ── Folder context-menu ──────────────────────────────────────────────────
  void showFolderMenu(DocumentFile folder, List<DocumentFile> allDocs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            VaultMenuOption(
              icon: Icons.edit_outlined,
              label: 'Rename',
              onTap: () async {
                Navigator.pop(sheetContext);
                final result = await context.push<String>(
                  '/vault-edit-folder',
                  extra: {
                    'folderName': folder.displayName,
                    'folderId': folder.id,
                    'categoryName': categoryName,
                  },
                );
                if (result != null && mounted) {
                  await reloadDocuments();
                  showMessage('Folder renamed successfully.');
                }
              },
            ),
            VaultMenuOption(
              icon: 'assets/images/black_delete.png',
              label: 'Delete',
              color: brandRed,
              onTap: () async {
                Navigator.pop(sheetContext);
                await deleteFolder(folder, allDocs);
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  // ── File context-menu ────────────────────────────────────────────────────
  void showFileMenu(DocumentFile doc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            VaultMenuOption(
              icon: Icons.edit_outlined,
              label: 'Rename',
              onTap: () async {
                Navigator.pop(sheetContext);
                await renameFile(doc);
              },
            ),
            VaultMenuOption(
              icon: 'assets/images/black_delete.png',
              label: 'Delete',
              onTap: () async {
                Navigator.pop(sheetContext);
                await deleteFile(doc);
              },
            ),
            VaultMenuOption(
              icon: 'assets/images/black_download.png',
              label: 'Download',
              onTap: () async {
                Navigator.pop(sheetContext);
                await downloadDocument(doc);
              },
            ),
            VaultMenuOption(
              icon: 'assets/images/black_share.png',
              label: 'Share/Send',
              onTap: () async {
                Navigator.pop(sheetContext);
                await shareDocument(doc);
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  // ── "+" FAB bottom sheet ─────────────────────────────────────────────────
  void showCategoryActions() {
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
                leading: const Icon(Icons.upload_file),
                title: const Text('Upload File'),
                onTap: () {
                  Navigator.pop(context);
                  showUploadOptions();
                },
              ),
              ListTile(
                leading: const Icon(Icons.create_new_folder),
                title: const Text('Create Folder'),
                onTap: () async {
                  Navigator.pop(context);
                  await context.push(
                    '/vault-create-subfolder',
                    extra: categoryName,
                  );
                  if (mounted) await reloadDocuments();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Upload source picker ─────────────────────────────────────────────────
  void showUploadOptionsSheet() {
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
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('Upload Document'),
                onTap: () {
                  Navigator.pop(context);
                  uploadFile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Image source picker ──────────────────────────────────────────────────
  void showImageSourcePicker() {
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
                  pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Confirmation dialog ──────────────────────────────────────────────────
  Future<bool?> confirm({required String title, required String message}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // ── Snackbar helper ──────────────────────────────────────────────────────
  void showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? brandRed : null,
      ),
    );
  }
}
