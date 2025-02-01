import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatPage(
      {super.key, required this.receiverId, required this.receiverName});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController messageController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  Timer? typingTimer;

  User? user;
  String? chatId;
  bool isReceiverTyping = false;
  bool isReceiverOnline = false;
  Timestamp? lastSeen;

  @override
  void initState() {
    super.initState();
    user = auth.currentUser;
    chatId = getChatId(user!.uid, widget.receiverId);
    createChatIfNotExists();
    listenForTyping();
    listenForOnlineStatus();
    // listenForOnlineStatus();
  }

  @override
  void dispose() {
    typingTimer?.cancel(); // Cancel the typing timer when the page is disposed
    super.dispose();
  }

  //online status listening
  void listenForOnlineStatus() {
    firestore
        .collection('user')
        .doc(widget.receiverId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          isReceiverOnline = snapshot['online'] ?? false;
          lastSeen = snapshot['lastSeen'];
        });
      }
    });
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Last seen recently";
    DateTime dateTime = timestamp.toDate();
    return "Last seen at ${DateFormat.jm().format(dateTime)}";
  }

  String getChatId(String userId1, String userId2) {
    List<String> sortedIds = [userId1, userId2]..sort();
    return sortedIds.join('_');
  }

  Future<void> createChatIfNotExists() async {
    DocumentSnapshot chatDoc =
        await firestore.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) {
      await firestore.collection('chats').doc(chatId).set({
        'user1': user!.uid,
        'user2': widget.receiverId,
        'typing': {
          user!.uid: false,
          widget.receiverId: false
        }, // Initialize typing state
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // 🔹 Update Firestore When Typing
  void updateTypingStatus(bool isTyping) {
    firestore.collection('chats').doc(chatId).update({
      'typing.${user!.uid}': isTyping,
    });
  }

  // 🔹 Listen for Typing Indicator from Receiver
  void listenForTyping() {
    firestore.collection('chats').doc(chatId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        Map<String, dynamic>? data = snapshot.data();
        if (data != null && data['typing'] != null) {
          setState(() {
            isReceiverTyping = data['typing'][widget.receiverId] ?? false;
          });
        }
      }
    });
  }

  Future<void> sendMessage() async {
    if (messageController.text.isEmpty) return;

    await firestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': user!.uid,
      'text': messageController.text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    messageController.clear();
    updateTypingStatus(false);
  }

  Stream<QuerySnapshot> getMessages() {
    return firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.receiverName,
            ),
            Text(isReceiverOnline ? "Online" : formatTimestamp(lastSeen),
                style: TextStyle(
                    fontSize: 12,
                    color: isReceiverOnline ? Colors.green : Colors.black))
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getMessages(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    bool isMe = message['senderId'] == user!.uid;
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin:
                            EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.blue.shade600
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          message['text'],
                          style: TextStyle(
                              color: isMe ? Colors.white : Colors.black),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 🔹 Show Typing Indicator
          if (isReceiverTyping)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("${widget.receiverName} is typing...",
                    style: TextStyle(color: Colors.grey)),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (text) {
                      updateTypingStatus(true);
                      typingTimer?.cancel();
                      typingTimer = Timer(Duration(seconds: 1), () {
                        updateTypingStatus(false);
                      });
                    },
                  ),
                ),
                IconButton(
                  onPressed: sendMessage,
                  icon: Icon(Icons.send, color: Colors.blue.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
