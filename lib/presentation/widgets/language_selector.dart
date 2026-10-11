import 'package:flutter/material.dart';
import 'agro_icons.dart';

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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE6DF), width: 1.2),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: [
          _buildOption(
            context,
            localeCode: 'uz',
            label: "O'zbekcha",
            isSelected: currentLanguage == 'uz',
            theme: theme,
          ),
          _buildOption(
            context,
            localeCode: 'ru',
            label: 'Русский',
            isSelected: currentLanguage == 'ru',
            theme: theme,
          ),
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
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.white.withAlpha(140),
          borderRadius: BorderRadius.circular(13),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withAlpha(60),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AgroFlagBadge(code: localeCode, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1E293B),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
