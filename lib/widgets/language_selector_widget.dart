// lib/widgets/language_selector_widget.dart

import 'package:flutter/material.dart';
import '../models/language_model.dart';

/// Kaynak ve hedef dillerin seçildiği, tekrar kullanılabilir widget.
class LanguageSelectorWidget extends StatelessWidget {
  final List<Language> languages;
  final Language sourceLanguage;
  final Language targetLanguage;
  final Function(Language) onSourceChanged;
  final Function(Language) onTargetChanged;
  final VoidCallback onSwap;

  const LanguageSelectorWidget({
    super.key,
    required this.languages,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.onSourceChanged,
    required this.onTargetChanged,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: _buildDropdown(context, true)),
            IconButton(
              icon: const Icon(Icons.swap_horiz, size: 30),
              color: Theme.of(context).colorScheme.primary,
              onPressed: onSwap,
            ),
            Expanded(child: _buildDropdown(context, false)),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(BuildContext context, bool isSource) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<Language>(
        value: isSource ? sourceLanguage : targetLanguage,
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down),
        onChanged: (Language? newValue) {
          if (newValue != null) {
            if (isSource) {
              onSourceChanged(newValue);
            } else {
              onTargetChanged(newValue);
            }
          }
        },
        items:
            languages.map<DropdownMenuItem<Language>>((Language language) {
              return DropdownMenuItem<Language>(
                value: language,
                child: Center(
                  child: Text(
                    language.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
