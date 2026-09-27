import 'package:flutter/material.dart';
import '../../services/local_data_service.dart';
import '../../widgets/timetable_card.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final _dataService = LocalDataService();
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
  String _selectedDay = 'Monday';
  bool _isWeekView = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _dataService,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Timetable'),
            actions: [
              IconButton(
                icon: Icon(_isWeekView ? Icons.view_day_outlined : Icons.calendar_view_week_outlined),
                tooltip: _isWeekView ? 'Switch to Day View' : 'Switch to Week View',
                onPressed: () => setState(() => _isWeekView = !_isWeekView),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Day Selector Pills (if day view)
                if (!_isWeekView)
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141414) : const Color(0xFFF9FAFB),
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E5E5),
                        ),
                      ),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _days.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final day = _days[index];
                        final isSelected = _selectedDay == day;
                        return ChoiceChip(
                          label: Text(
                            day,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? (isDark ? Colors.black : Colors.white) : null,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: isDark ? Colors.white : Colors.black,
                          onSelected: (val) {
                            if (val) setState(() => _selectedDay = day);
                          },
                        );
                      },
                    ),
                  ),

                // Timetable Content
                Expanded(
                  child: _isWeekView
                      ? ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _days.length,
                          itemBuilder: (context, index) {
                            final day = _days[index];
                            final entries = _dataService.getTimetableForDay(day);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    children: [
                                      Text(
                                        day,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : Colors.black,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${entries.length} Classes',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (entries.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: Text(
                                      'No classes scheduled',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? const Color(0xFF737373) : const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  )
                                else
                                  ...entries.map((e) => TimetableCard(entry: e)),
                                const SizedBox(height: 12),
                              ],
                            );
                          },
                        )
                      : Builder(
                          builder: (context) {
                            final entries = _dataService.getTimetableForDay(_selectedDay);
                            if (entries.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.event_busy_outlined,
                                      size: 52,
                                      color: isDark ? const Color(0xFF555555) : const Color(0xFF9E9E9E),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No Classes on $_selectedDay',
                                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Enjoy your free time or check other days.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: entries.length,
                              itemBuilder: (context, index) {
                                return TimetableCard(entry: entries[index]);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
