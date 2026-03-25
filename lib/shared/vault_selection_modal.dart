import 'package:flutter/material.dart';
import '../Loan_Screen/models/document_model.dart';
import '../services/loan_service.dart';
import '../Home_Dashboard/widgets.dart'; // For brandRed

class VaultSelectionModal extends StatefulWidget {
  final String? excludeRelatedId;
  const VaultSelectionModal({super.key, this.excludeRelatedId});

  @override
  State<VaultSelectionModal> createState() => _VaultSelectionModalState();
}

class _VaultSelectionModalState extends State<VaultSelectionModal> {
  final LoanService _loanService = LoanService();
  String _selectedCategory = 'All';
  List<DocumentFile> _allDocuments = [];
  final Set<String> _selectedDocIds = {};
  bool _isLoading = true;

  final List<String> _categories = ['All', 'Loans', 'Housing', 'Insurance', 'Documents'];

  @override
  void initState() {
    super.initState();
    _loadVaultDocuments();
  }

  Future<void> _loadVaultDocuments() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _loanService.fetchDocumentsByModule('loans'),
        _loanService.fetchDocumentsByModule('housing'),
        _loanService.fetchDocumentsByModule('insurance'),
        _loanService.fetchDocumentsByModule('documents'),
      ]);

      setState(() {
        _allDocuments = results.expand((x) => x).toList();
        // Remove folders and already linked documents if needed
        _allDocuments = _allDocuments.where((doc) {
          if (doc.mimeType == 'application/vnd.anick-giroux.folder') return false;
          if (widget.excludeRelatedId != null && doc.relatedId == widget.excludeRelatedId) return false;
          return true;
        }).toList();
        
        _allDocuments.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load Vault: $e'), backgroundColor: brandRed),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  List<DocumentFile> get _filteredDocuments {
    if (_selectedCategory == 'All') return _allDocuments;
    String module = _selectedCategory.toLowerCase();
    if (module == 'housing') module = 'housing'; // normalize
    return _allDocuments.where((doc) => doc.module == module).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select from Vault',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Color(0xFF111111)),
                ),
              ],
            ),
          ),

          // Categories
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? brandRed : const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? brandRed : const Color(0xFFEEEEEE),
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF888888),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Document List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: brandRed))
                : _filteredDocuments.isEmpty
                    ? const Center(
                        child: Text(
                          'No documents found in this category.',
                          style: TextStyle(color: Color(0xFF888888)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _filteredDocuments.length,
                        itemBuilder: (context, index) {
                          final doc = _filteredDocuments[index];
                          final isSelected = _selectedDocIds.contains(doc.id);
                          final isPdf = doc.mimeType == 'application/pdf' || doc.filename.endsWith('.pdf');

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedDocIds.remove(doc.id);
                                } else {
                                  _selectedDocIds.add(doc.id);
                                }
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? brandRed.withValues(alpha: 0.04) 
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? brandRed : const Color(0xFFEEEEEE),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // File Icon
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isPdf ? const Color(0xFFFFF0F2) : const Color(0xFFE3F2FD),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: isPdf 
                                        ? Image.asset('assets/images/pdficon.png', width: 20)
                                        : const Icon(Icons.image_rounded, color: Color(0xFF2196F3), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  
                                  // File Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          doc.displayName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF111111),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${(doc.size / 1024).toStringAsFixed(1)} KB • ${(doc.module ?? "Vault").toUpperCase()}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF888888),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Checkbox
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: isSelected ? brandRed : Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isSelected ? brandRed : const Color(0xFFDDDDDD),
                                      ),
                                    ),
                                    child: isSelected 
                                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Action Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandRed,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFF8F8F8),
                  disabledForegroundColor: const Color(0xFFBBBBBB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: _selectedDocIds.isEmpty 
                    ? null 
                    : () => Navigator.pop(context, _selectedDocIds.toList()),
                child: Text(
                  _selectedDocIds.isEmpty 
                      ? 'Select Documents' 
                      : 'Link ${_selectedDocIds.length} ${_selectedDocIds.length == 1 ? 'Document' : 'Documents'}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
