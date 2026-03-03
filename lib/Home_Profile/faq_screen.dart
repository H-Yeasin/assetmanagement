import 'package:flutter/material.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final List<_FaqData> _items = const [
    _FaqData(
      question: 'What is FFP Vault?',
      answer:
          'FFP Vault is a personal organization and financial clarity app. It helps you track your payments, store important documents securely, and stay in control, without spreadsheets, calendars, or scattered files and documents.',
    ),
    _FaqData(
      question: 'Who is FFP Vault for?',
      answer:
          'FFP Vault is for anyone who wants to take control of their personal finances, stay organized, and ensure their important documents are always accessible.',
    ),
    _FaqData(
      question: 'What can I do with FFP Vault?',
      answer:
          'You can organize tasks, track expenses, manage documents securely, and get a clear overview of your financial health.',
    ),
    _FaqData(
      question: 'Is FFP Vault a banking app?',
      answer:
          'No, FFP Vault is not a bank. It is an organizational tool that helps you manage and track your financial commitments independently.',
    ),
    _FaqData(
      question: 'How secure is my data?',
      answer:
          'We use industry-standard encryption to ensure your data is secure. You can also enable PIN or fingerprint locks for added privacy.',
    ),
    _FaqData(
      question: 'Why store documents in the Vault?',
      answer:
          'Storing documents in the Vault keeps them safe, organized, and available whenever you need them, securely locked behind your app PIN.',
    ),
    _FaqData(
      question: 'Can I upgrade later?',
      answer:
          'Yes, you can upgrade your plan at any time to access premium features and additional storage space.',
    ),
  ];

  final Set<int> _expanded = {
    0,
  }; // First item expanded by default based on screenshot

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 18,
            color: Color(0xFF111111),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'FAQ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: _items.length,
          itemBuilder: (context, i) {
            final _FaqData item = _items[i];
            final isOpen = _expanded.contains(i);

            return _FaqListItem(
              item: item,
              isOpen: isOpen,
              onTap: () {
                setState(() {
                  if (isOpen) {
                    _expanded.remove(i);
                  } else {
                    _expanded.add(i);
                  }
                });
              },
            );
          },
        ),
      ),
    );
  }
}

class _FaqListItem extends StatelessWidget {
  final _FaqData item;
  final bool isOpen;
  final VoidCallback onTap;

  const _FaqListItem({
    required this.item,
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    item.question,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF222222),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: const Color(0xFF555555),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        if (isOpen) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 16, right: 16),
            child: Text(
              item.answer,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF777777),
                height: 1.5,
              ),
            ),
          ),
        ],
        const Divider(height: 1, color: Color(0xFFEBEBEB)),
      ],
    );
  }
}

class _FaqData {
  final String question;
  final String answer;
  const _FaqData({required this.question, required this.answer});
}
