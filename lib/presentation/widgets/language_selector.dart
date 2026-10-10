import 'package:flutter/material.dart';

class LanguageSelector extends StatelessWidget {
  final String currentLanguage;
  final ValueChanged<String>? onLanguageChanged;

  const LanguageSelector({
    super.key,
    this.currentLanguage = 'uz',
    this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF2EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE6DF), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(
            context,
            localeCode: 'uz',
            label: "O'zbekcha",
            isSelected: currentLanguage == 'uz',
            theme: theme,
          ),
          const SizedBox(width: 4),
          _buildOption(
            context,
            localeCode: 'ru',
            label: 'Русский',
            isSelected: currentLanguage == 'ru',
            theme: theme,
          ),
          const SizedBox(width: 4),
          _buildOption(
            context,
            localeCode: 'en',
            label: 'English',
            isSelected: currentLanguage == 'en',
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required String localeCode,
    required String label,
    required bool isSelected,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: () => onLanguageChanged?.call(localeCode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withAlpha(60),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ]
            : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF4A5D4E),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }
}
