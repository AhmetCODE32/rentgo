import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/core/firestore_service.dart';
import 'package:rentgo/models/notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('BİLDİRİMLER', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (user != null)
            TextButton(
              onPressed: () => firestoreService.markAllNotificationsAsRead(user.uid),
              child: const Text('HEPSİNİ OKU', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Lütfen giriş yapın.'))
          : StreamBuilder(
              stream: firestoreService.getNotifications(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white10));
                
                final notifications = snapshot.data?.docs ?? [];

                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none_rounded, size: 80, color: Colors.white.withOpacity(0.05)),
                        const SizedBox(height: 16),
                        const Text('BİLDİRİMİNİZ YOK', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index].data();
                    return _NotificationCard(notification: notif, docId: notifications[index].id, userId: user.uid);
                  },
                );
              },
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final String docId;
  final String userId;

  const _NotificationCard({required this.notification, required this.docId, required this.userId});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.message: icon = Icons.chat_bubble_rounded; color = Colors.blueAccent; break;
      case NotificationType.booking: icon = Icons.calendar_month_rounded; color = Colors.greenAccent; break;
      case NotificationType.premium: icon = Icons.workspace_premium_rounded; color = Colors.amber; break;
      default: icon = Icons.notifications_rounded; color = Colors.white24;
    }

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.transparent : const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: notification.isRead ? Colors.white.withOpacity(0.03) : color.withOpacity(0.2)),
        ),
        child: ListTile(
          onTap: () {
            context.read<FirestoreService>().markNotificationAsRead(userId, docId);
            // Burada notification.type'a göre ilgili sayfaya yönlendirme yapılabilir.
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.w900, 
              fontSize: 13, 
              letterSpacing: 0.5,
              decoration: notification.isRead ? TextDecoration.none : null
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(notification.body, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
              const SizedBox(height: 8),
              Text(
                DateFormat('dd MMM, HH:mm').format(notification.createdAt),
                style: const TextStyle(color: Colors.white10, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          trailing: notification.isRead 
            ? null 
            : Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        ),
      ),
    );
  }
}
