

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:splitz/layouts/auth/login_page.dart';
import 'package:splitz/layouts/dash/calculator_page.dart';
import 'package:splitz/layouts/dash/chats/chat_list_page.dart';
import 'package:splitz/layouts/dash/chats/chat_page.dart';
import 'package:splitz/layouts/dash/setting_page.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

  int selectedIndex = 0;

  String appBarName = 'Chats';

  void updateAppBarTitle(String title){
    setState(() {
      appBarName = title;
    });
  }

  final List<Widget> Pages = [ChatListPage(), CalculatorPage(), SettingPage()];

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
    updateAppBarTitle(["Chats","Calculator","setting"][index]);
  }

  void onDrawerItemTapped(int index) {
    Navigator.pop(context);
    onItemTapped(index);
  }

  String? currentUsername;
  String? currentEmail;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  void logout() async {
    try {
      firebaseAuth.signOut();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => LoginPage()));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to logout : $e")));
    }
  }

  void fetchUserData() {
  if (user != null) {
    firebaseFirestore.collection('users').doc(user!.uid).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          currentUsername = snapshot['username'];
          currentEmail = snapshot['email'];
        });
      }
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarName),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
               "Username: ${currentUsername ?? 'Loading...'}",
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                "Email: ${currentEmail ?? 'Loading...'}",
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              currentAccountPicture: CircleAvatar(child: Text("${currentUsername?[0]}"),),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade600,
                    Colors.blue.shade300
                  ], // Gradient effect
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            ListTile(
              onTap: () => onDrawerItemTapped(0),
              leading: Icon(Icons.chat),
              title: Text("Chats",
                  style: TextStyle(
                      color: Colors.black, )),
            ),
            Divider(),
            ListTile(
              onTap: () => onDrawerItemTapped(1),
              leading: Icon(Icons.calculate),
              title: Text("calculator",
                  style: TextStyle(
                      color: Colors.black,)),
            ),
            Divider(),
            ListTile(
              onTap: () => onDrawerItemTapped(2),
              leading: Icon(Icons.settings),
              title: Text("setting",
                  style: TextStyle(
                      color: Colors.black, )),
            ),
            Divider(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15),
              margin: EdgeInsets.only(top: 70),
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: logout,
                label: Text("LogOut",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
                icon: Icon(Icons.logout),
                style: ButtonStyle(
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0), // Shape
                      ),
                    ),
                    backgroundColor: WidgetStateProperty.resolveWith(
                        (Set<WidgetState> States) {
                      if (States.contains(WidgetState.pressed)) {
                        return Colors.white;
                      }
                      return Colors.blue.shade600;
                    })),
              ),
            )
          ],
        ),
      ),
      body: Pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.chat,color: Colors.black,), label: 'Chats'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calculate,color: Colors.black,), label: 'Calculator'),
          BottomNavigationBarItem(icon: Icon(Icons.settings,color: Colors.black,), label: 'Settings')
        ],
        currentIndex: selectedIndex,
        onTap: onItemTapped,
      ),
    );
  }
}
