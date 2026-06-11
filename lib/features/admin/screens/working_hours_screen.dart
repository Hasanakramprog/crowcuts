import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../../core/theme/app_typography.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/providers/barber_provider.dart';
import '../../../data/models/models.dart';

/// Admin — Working Hours Editor per barber with real save
class WorkingHoursScreen extends ConsumerStatefulWidget {
  final String barberId;

  const WorkingHoursScreen({super.key, required this.barberId});

  @override
  ConsumerState<WorkingHoursScreen> createState() =>
      _WorkingHoursScreenState();
}

class _WorkingHoursScreenState extends ConsumerState<WorkingHoursScreen> {
  List<DaySchedule> _schedules = [];
  bool _initialized = false;
  bool _isSaving = false;
  List<DateTime> _daysOff = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _loadSchedule();
      _initialized = true;
    }
  }

  void _loadSchedule() {
    final barber = ref.read(barberProvider(widget.barberId));
    if (barber != null) {
      _schedules = barber.schedule.weeklySchedule
          .map((s) => s.copyWith())
          .toList();
      _daysOff = List.from(barber.schedule.daysOff);
    }
  }

  void _save() {
    setState(() => _isSaving = true);

    final schedule = WorkSchedule(
      weeklySchedule: _schedules,
      daysOff: _daysOff,
    );

    ref.read(barbersProvider.notifier).updateSchedule(widget.barberId, schedule);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule saved successfully'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    });
  }

  void _addDayOff() {
    showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.goldPrimary,
            ),
          ),
          child: child!,
        );
      },
    ).then((date) {
      if (date != null) {
        setState(() {
          // Remove time component
          final dayOnly = DateTime(date.year, date.month, date.day);
          if (!_daysOff.any((d) =>
              d.year == dayOnly.year &&
              d.month == dayOnly.month &&
              d.day == dayOnly.day)) {
            _daysOff.add(dayOnly);
          }
        });
      }
    });
  }

  void _removeDayOff(DateTime date) {
    setState(() {
      _daysOff.removeWhere((d) =>
          d.year == date.year && d.month == date.month && d.day == date.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final barber = ref.watch(barberProvider(widget.barberId));
    final workingDays = _schedules.where((s) => s.isWorking).length;
    final totalWeekHours = _schedules.fold<int>(0, (sum, s) {
      if (!s.isWorking) return sum;
      final startMin = s.startTime.hour * 60 + s.startTime.minute;
      final endMin = s.endTime.hour * 60 + s.endTime.minute;
      return sum + (endMin - startMin) ~/ 60;
    });

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text('${barber?.name ?? 'Barber'} — Hours'),
      ),
      body: Column(
        children: [
          // Stats
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              children: [
                _MiniStat('$workingDays', 'Working days',
                    AppColors.successGreen),
                const SizedBox(width: 8),
                _MiniStat(
                    '${_daysOff.length}', 'Days off', AppColors.warningAmber),
                const SizedBox(width: 8),
                _MiniStat('${totalWeekHours}h', 'Week total',
                    AppColors.goldPrimary),
              ],
            ),
          ),

          // Day schedule editor
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              itemCount: _schedules.length + 1, // +1 for days off section
              itemBuilder: (context, index) {
                if (index < _schedules.length) {
                  final schedule = _schedules[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _DayScheduleEditor(
                      schedule: schedule,
                      onChanged: (updated) {
                        setState(() {
                          _schedules[index] = updated;
                        });
                      },
                    ),
                  ).animate().fadeIn(
                      duration: 300.ms, delay: (index * 60).ms);
                } else {
                  return _buildDaysOffSection();
                }
              },
            ),
          ),

          // Save button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: AppButton(
                label: 'Save Schedule',
                isLoading: _isSaving,
                onPressed: _save,
                width: double.infinity,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysOffSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: context.colors.borderDefault),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.beach_access_outlined,
                size: 18, color: AppColors.warningAmber),
            const SizedBox(width: 8),
            Text('Days Off', style: AppTypography.heading2),
            const Spacer(),
            TextButton.icon(
              onPressed: _addDayOff,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_daysOff.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: context.colors.textMuted),
                const SizedBox(width: 8),
                Text('No days off set. Tap "Add" to block specific dates.',
                    style: AppTypography.caption.copyWith(
                        color: context.colors.textMuted)),
              ],
            ),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _daysOff.map((date) {
              final months = [
                'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
              ];
              return Chip(
                label: Text(
                  '${months[date.month - 1]} ${date.day}, ${date.year}',
                  style: AppTypography.caption.copyWith(fontSize: 12),
                ),
                onDeleted: () => _removeDayOff(date),
                backgroundColor: AppColors.warningAmber.withAlpha(20),
                deleteIconColor: AppColors.warningAmber,
                side: const BorderSide(
                    color: AppColors.warningAmber, width: 0.5),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MiniStat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(40), width: 0.5),
        ),
        child: Column(
          children: [
            Text(value,
                style: AppTypography.heading2.copyWith(
                    color: color, fontSize: 16)),
            Text(label,
                style: AppTypography.caption.copyWith(
                    color: context.colors.textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _DayScheduleEditor extends StatefulWidget {
  final DaySchedule schedule;
  final ValueChanged<DaySchedule> onChanged;

  const _DayScheduleEditor({
    required this.schedule,
    required this.onChanged,
  });

  @override
  State<_DayScheduleEditor> createState() => _DayScheduleEditorState();
}

class _DayScheduleEditorState extends State<_DayScheduleEditor> {
  late bool _isWorking;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late int _interval;

  @override
  void initState() {
    super.initState();
    _isWorking = widget.schedule.isWorking;
    _startTime = widget.schedule.startTime;
    _endTime = widget.schedule.endTime;
    _interval = widget.schedule.slotIntervalMinutes;
  }

  void _showIntervalPicker() {
    final preset = [15, 20, 30, 45, 60, 90];
    final customCtrl = TextEditingController(text: _interval.toString());

    showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: const Row(
          children: [
            Icon(Icons.schedule, size: 20, color: AppColors.goldPrimary),
            SizedBox(width: 8),
            Text('Slot Interval',
                style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Minutes per appointment slot',
                style: AppTypography.caption.copyWith(
                    color: context.colors.textMuted)),
            const SizedBox(height: 12),
            // Preset chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: preset.map((val) {
                final selected = _interval == val;
                return GestureDetector(
                  onTap: () {
                    setState(() => _interval = val);
                    _notify();
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.goldPrimary
                          : context.colors.surface2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? AppColors.goldPrimary
                            : context.colors.borderDefault,
                      ),
                    ),
                    child: Text(
                      '${val}min',
                      style: AppTypography.body.copyWith(
                        color: selected
                            ? context.colors.background
                            : AppColors.textPrimary,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // Custom input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: customCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Custom (min)',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    final val = int.tryParse(customCtrl.text);
                    if (val != null && val > 0) {
                      setState(() => _interval = val);
                      _notify();
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Set',
                      style: TextStyle(color: AppColors.goldPrimary)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _notify() {
    widget.onChanged(widget.schedule.copyWith(
      isWorking: _isWorking,
      startTime: _startTime,
      endTime: _endTime,
      slotIntervalMinutes: _interval,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isWeekend = widget.schedule.weekday >= 6;

    return AppCard(
      border: Border.all(
        color: _isWorking
            ? AppColors.successGreen.withAlpha(30)
            : context.colors.borderDefault,
        width: 0.5,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Day name
              SizedBox(
                width: 52,
                child: Text(
                  widget.schedule.weekdayName,
                  style: AppTypography.bodyBold.copyWith(
                    color: isWeekend
                        ? context.colors.textMuted
                        : (context.isDark ? AppColors.goldPrimary : context.colors.textPrimary),
                  ),
                ),
              ),

              // Toggle
              SizedBox(
                height: 32,
                child: Switch(
                  value: _isWorking,
                  onChanged: (v) {
                    setState(() => _isWorking = v);
                    _notify();
                  },
                  activeColor: AppColors.goldPrimary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),

              if (_isWorking) ...[
                const SizedBox(width: 4),
                // Slot interval — tappable to edit
                GestureDetector(
                  onTap: () => _showIntervalPicker(),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.goldDim.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: context.colors.borderGold, width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule,
                            size: 10, color: AppColors.goldPrimary),
                        const SizedBox(width: 3),
                        Text(
                          '${_interval}min',
                          style: AppTypography.caption.copyWith(
                            fontSize: 10,
                            color: AppColors.goldPrimary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.edit,
                            size: 8, color: AppColors.goldPrimary),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),

          if (_isWorking) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _startTime,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.goldPrimary,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (time != null) {
                        setState(() => _startTime = time);
                        _notify();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        color: context.colors.surface2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.login_rounded,
                              size: 14, color: AppColors.successGreen),
                          const SizedBox(height: 2),
                          Text(
                            _startTime.format(context),
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('—',
                      style: AppTypography.caption.copyWith(
                          color: context.colors.textMuted, fontSize: 20)),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _endTime,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.goldPrimary,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (time != null) {
                        setState(() => _endTime = time);
                        _notify();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        color: context.colors.surface2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.logout_rounded,
                              size: 14, color: AppColors.errorRed),
                          const SizedBox(height: 2),
                          Text(
                            _endTime.format(context),
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
