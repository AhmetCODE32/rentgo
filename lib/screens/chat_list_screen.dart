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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('MESAJLARIM', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: firestoreService.getChatRooms(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white24));
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.white.withOpacity(0.05)),
                  const SizedBox(height: 16),
                  const Text('HENÜZ MESAJINIZ YOK', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                ],
              ),
            );
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isPremium ? Colors.amber.withOpacity(0.2) : Colors.white.withOpacity(0.05)),
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
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF111111),
                    backgroundImage: otherUserPhoto != null ? CachedNetworkImageProvider(otherUserPhoto) : null,
                    child: otherUserPhoto == null ? Text(otherUserName[0].toUpperCase(), style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(otherUserName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                            Text(formattedTime, style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          chatData['vehicleTitle'] ?? 'İlan Hakkında',
                          style: TextStyle(color: isPremium ? Colors.amber : Colors.white24, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          chatData['lastMessage'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
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
