import 'package:flutter/material.dart';
import 'log_entry_screen.dart';

class LogFeedScreen extends StatelessWidget {
  const LogFeedScreen({super.key});

  @override
  Widget build(BuildContext context) => const LogEntryScreen(kind: LogKind.feed);
}
