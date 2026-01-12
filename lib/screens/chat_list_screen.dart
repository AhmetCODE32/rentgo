import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/core/firestore_service.dart';
import 'package:rentgo/screens/chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    if (user == null) return const Scaffold(body: Center(child: Text('Giriş yapmalısınız.')));

    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Mesajlarım', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: firestoreService.getChatRooms(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: Colors.white.withAlpha(20)),
                  const SizedBox(height: 16),
                  const Text('Henüz bir mesajlaşmanız yok.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chatData = chats[index].data();
              final roomId = chats[index].id;
              final users = List<String>.from(chatData['users'] ?? []);
              final otherUserId = users.firstWhere((id) => id != user.uid, orElse: () => '');

              return _ChatCard(
                roomId: roomId,
                chatData: chatData,
                otherUserId: otherUserId,
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  final String roomId;
  final Map<String, dynamic> chatData;
  final String otherUserId;

  const _ChatCard({required this.roomId, required this.chatData, required this.otherUserId});

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    final lastMessageTime = (chatData['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now();
    final formattedTime = _getFormattedDate(lastMessageTime);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: firestoreService.getUserProfileStream(otherUserId),
      builder: (context, snapshot) {
        final otherUser = snapshot.data?.data() ?? {};
        final bool isPremium = otherUser['isPremium'] ?? false;
        final otherUserName = otherUser['displayName'] ?? 'Kullanıcı';
        final otherUserPhoto = otherUser['photoURL'];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isPremium ? Colors.amber.withOpacity(0.2) : Colors.white.withAlpha(10)),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    roomId: roomId,
                    vehicleId: chatData['vehicleId'] ?? '',
                    vehicleTitle: chatData['vehicleTitle'] ?? '',
                    vehicleImage: chatData['vehicleImage'] ?? '',
                    ownerId: List<String>.from(chatData['users'] ?? []).first,
                    otherUserId: otherUserId,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // PROFİL RESMİ + PRO ÇERÇEVE
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isPremium ? Colors.amber : Colors.transparent, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.blueAccent.withAlpha(30),
                          backgroundImage: otherUserPhoto != null ? CachedNetworkImageProvider(otherUserPhoto) : null,
                          child: otherUserPhoto == null ? Text(otherUserName[0].toUpperCase(), style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)) : null,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: isPremium ? Colors.amber : Colors.blueAccent, shape: BoxShape.circle),
                          child: Icon(isPremium ? Icons.workspace_premium : Icons.directions_car, size: 10, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(otherUserName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                if (isPremium) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.workspace_premium, color: Colors.amber, size: 14),
                                ],
                              ],
                            ),
                            Text(formattedTime, style: TextStyle(color: Colors.white.withAlpha(50), fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          chatData['vehicleTitle'] ?? 'Araç İlanı',
                          style: TextStyle(color: isPremium ? Colors.amber.withOpacity(0.8) : Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          chatData['lastMessage'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 14),
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
    );
  }

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return DateFormat('HH:mm').format(date);
    if (diff.inDays == 1) return 'Dün';
    return DateFormat('dd.MM').format(date);
  }
}
