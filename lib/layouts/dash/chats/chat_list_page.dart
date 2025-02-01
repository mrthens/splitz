import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting time
import 'chat_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  User? user;

  @override
  void initState() {
    super.initState();
    user = auth.currentUser;
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Last seen recently";
    DateTime dateTime = timestamp.toDate();
    return "Last seen at ${DateFormat.jm().format(dateTime)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var userData = users[index].data() as Map<String, dynamic>;
              String userId = users[index].id;
              String username = userData['username'] ?? 'Unknown User';
              bool isOnline = userData['online'] ?? false;
              Timestamp? lastSeen = userData['lastSeen'];

              if (userId == user!.uid) return SizedBox.shrink();

              return ListTile(
                title: Text(username),
                subtitle: Text(isOnline ? "Online" : formatTimestamp(lastSeen)),
                leading: Stack(
                  children: [
                    CircleAvatar(child: Text(username[0])),
                    if (isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          backgroundColor: Colors.green,
                          radius: 5,
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        receiverId: userId,
                        receiverName: username,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
