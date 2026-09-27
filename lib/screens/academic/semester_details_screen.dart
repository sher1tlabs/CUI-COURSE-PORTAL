import 'package:flutter/material.dart';

class SemesterDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> semesterData;

  const SemesterDetailsScreen({super.key, required this.semesterData});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final courses = (semesterData['courses'] as List<dynamic>?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(semesterData['semester'] ?? 'Semester Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141414) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E5E5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Semester GPA',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${semesterData['gpa'] ?? '3.50'}',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E5E5),
                    ),
                    Column(
                      children: [
                        Text(
                          'Credit Hours',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${semesterData['creditHours'] ?? '16'} CH',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Enrolled Courses & Grades',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: courses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final course = courses[index];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E5E5),
                      ),
                    ),
                    color: isDark ? const Color(0xFF141414) : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white : Colors.black,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        course['code'] ?? '',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.black : Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${course['ch']} Credit Hours',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  course['title'] ?? '',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              course['grade'] ?? 'A',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
