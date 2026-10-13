import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/farm_store.dart';
import '../ui/components.dart';

/// Tickable list of a batch day's tasks. Ticks are saved per batch day, so
/// the Today tab and the 42-day plan always show the same state.
class TaskChecklistCard extends StatefulWidget {
  final int day;
  final List<String> tasks;

  const TaskChecklistCard({super.key, required this.day, required this.tasks});

  @override
  State<TaskChecklistCard> createState() => _TaskChecklistCardState();
}

class _TaskChecklistCardState extends State<TaskChecklistCard> {
  Set<int> _done = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant TaskChecklistCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.day != widget.day) _load();
  }

  Future<void> _load() async {
    final done = await TaskChecklist.load(widget.day);
    if (!mounted) return;
    setState(() => _done = done);
  }

  Future<void> _toggle(int index) async {
    final next = {..._done};
    if (!next.remove(index)) next.add(index);
    setState(() => _done = next);
    await TaskChecklist.save(widget.day, next);
  }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.tasks;
    final doneCount = _done.where((i) => i < tasks.length).length;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.sm,
              AppSpace.lg,
              AppSpace.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppProgressBar(
                    value: tasks.isEmpty ? 0 : doneCount / tasks.length,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Text('$doneCount/${tasks.length}', style: AppText.label),
              ],
            ),
          ),
          for (var i = 0; i < tasks.length; i++)
            _TaskRow(
              text: tasks[i],
              done: _done.contains(i),
              onTap: () => _toggle(i),
            ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final String text;
  final bool done;
  final VoidCallback onTap;

  const _TaskRow({required this.text, required this.done, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: done,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.curve,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: done ? AppColors.primary : AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done ? AppColors.primary : AppColors.inkMuted,
                    width: 1.6,
                  ),
                ),
                child: done
                    ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(
                  text,
                  style: AppText.body.copyWith(
                    color: done ? AppColors.inkMuted : AppColors.ink,
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
