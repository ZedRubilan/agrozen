import 'package:flutter/material.dart';
import 'log_entry_screen.dart';

class LogMortalityScreen extends StatelessWidget {
  const LogMortalityScreen({super.key});

  @override
  Widget build(BuildContext context) => const LogEntryScreen(kind: LogKind.deaths);
}
