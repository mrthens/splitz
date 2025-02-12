import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatPage({super.key, required this.receiverId, required this.receiverName});

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
  }

  // Listen for the online status of the receiver
  void listenForOnlineStatus() {
    firestore.collection('users').doc(widget.receiverId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          isReceiverOnline = snapshot['online'] ?? false;
          lastSeen = snapshot['lastSeen'];
        });
      }
    });
  }

  // Format timestamp for the "Last seen" status
  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Last seen recently";
    DateTime dateTime = timestamp.toDate();
    return "Last seen at ${DateFormat.jm().format(dateTime)}";
  }

  // Generate a unique chat ID based on the user IDs
  String getChatId(String userId1, String userId2) {
    List<String> sortedIds = [userId1, userId2]..sort();
    return sortedIds.join('_');
  }

  // Ensure the chat exists, if not create it
  Future<void> createChatIfNotExists() async {
    DocumentSnapshot chatDoc = await firestore.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) {
      await firestore.collection('chats').doc(chatId).set({
        'user1': user!.uid,
        'user2': widget.receiverId,
        'typing': {user!.uid: false, widget.receiverId: false}, // Initialize typing state
        'status': {
          user!.uid: 'sent', // Sender's status
          widget.receiverId: 'delivered', // Receiver's status
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Update typing status in Firestore
  void updateTypingStatus(bool isTyping) {
    firestore.collection('chats').doc(chatId).update({
      'typing.${user!.uid}': isTyping,
    });
  }

  // Listen for typing indicator from receiver
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

  // Mark message as "seen" for the receiver
  Future<void> markMessageAsSeen(String messageId) async {
    await firestore.collection('chats').doc(chatId).collection('messages').doc(messageId).update({
      'status.${widget.receiverId}': 'seen', // Mark message as 'seen' for receiver
    });
  }

  // Send a message with its initial status
  Future<void> sendMessage() async {
    if (messageController.text.isEmpty) return;

    // Create the message with the status map
    await firestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': user!.uid,
      'text': messageController.text,
      'timestamp': FieldValue.serverTimestamp(),
      'status': {
        user!.uid: 'sent', // sender's message status
        widget.receiverId: 'delivered', // receiver's message status
      }
    });

    messageController.clear();
    updateTypingStatus(false);
  }

  // Get the messages stream from Firestore
  Stream<QuerySnapshot> getMessages() {
    return firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Build message status (sent, delivered, seen)
  Widget buildMessageStatus(String messageId, String senderId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: firestore.collection('chats').doc(chatId).collection('messages').doc(messageId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }

        var message = snapshot.data!.data() as Map<String, dynamic>;
        String? status = message['status'][senderId];

        switch (status) {
          case 'sent':
            return Icon(Icons.check, size: 16); // Single check icon (sent)
          case 'delivered':
            return Icon(Icons.check_circle, size: 16); // Double check icon (delivered)
          case 'seen':
            return Icon(Icons.done_all, size: 16, color: Colors.blue); // Double blue check icon (seen)
          default:
            return SizedBox.shrink();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.receiverName),
            Text(
              isReceiverOnline ? "Online" : formatTimestamp(lastSeen),
              style: TextStyle(fontSize: 12, color: isReceiverOnline ? Colors.green : Colors.black),
            )
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
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue.shade600 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message['text'],
                              style: TextStyle(color: isMe ? Colors.white : Colors.black),
                            ),
                            if (isMe)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: buildMessageStatus(message.id, user!.uid), // Display status icon
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Show Typing Indicator
          if (isReceiverTyping)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("${widget.receiverName} is typing...", style: TextStyle(color: Colors.grey)),
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
