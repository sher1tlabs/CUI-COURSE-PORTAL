import 'package:flutter/material.dart';
import '../../services/local_data_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _dataService = LocalDataService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _dataService,
      builder: (context, _) {
        final notifications = _dataService.notifications;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifications'),
            actions: [
              TextButton(
                onPressed: () => _dataService.markAllNotificationsAsRead(),
                child: Text(
                  'Mark all read',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
          body: notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 48,
                        color: isDark ? const Color(0xFF666666) : const Color(0xFF9E9E9E),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You\'re all caught up.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    final isRead = notif['isRead'] as bool;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isRead
                              ? (isDark ? const Color(0xFF262626) : const Color(0xFFE5E5E5))
                              : (isDark ? Colors.white54 : Colors.black87),
                          width: isRead ? 1 : 1.4,
                        ),
                      ),
                      color: isDark ? const Color(0xFF141414) : Colors.white,
                      child: InkWell(
                        onTap: () => _dataService.markNotificationAsRead(notif['id']),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 6, right: 12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isRead
                                      ? Colors.transparent
                                      : (isDark ? Colors.white : Colors.black),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          notif['title'],
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                                            color: isDark ? Colors.white : Colors.black,
                                          ),
                                        ),
                                        Text(
                                          notif['time'],
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      notif['message'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF4B5563),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
