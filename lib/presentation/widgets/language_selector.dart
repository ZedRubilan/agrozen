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
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withAlpha(40),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
