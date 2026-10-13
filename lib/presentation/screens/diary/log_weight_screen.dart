import 'package:flutter/material.dart';
import 'log_entry_screen.dart';

class LogWeightScreen extends StatelessWidget {
  const LogWeightScreen({super.key});

  @override
  Widget build(BuildContext context) => const LogEntryScreen(kind: LogKind.weight);
}
