

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:splitz/layouts/auth/login_page.dart';
import 'package:splitz/layouts/dash/calculator_page.dart';
import 'package:splitz/layouts/dash/chats/chat_list_page.dart';
import 'package:splitz/layouts/dash/group/groups.dart';


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

  final List<Widget> Pages = [ChatListPage(),group(), CalculatorPage(), SettingPage()];

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
    updateAppBarTitle(["Chats","Group","Calculator","Setting"][index]);
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
      bottomNavigationBar: Container(
        margin: EdgeInsets.only(bottom: 1), // Wrap GNav in a Container for styling
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(20), // Optional: Add rounded corners
    color: Colors.white, // Optional: Set background color
    boxShadow: [ // Optional: Add a shadow
      BoxShadow(
        color: Colors.grey.withOpacity(0.2),
        blurRadius: 5,
        spreadRadius: 2,
        offset: Offset(0, 3), // changes position of shadow
      ),
    ],
  ),
   padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
   child: GNav(
    rippleColor: Colors.purple[300]!, // Splash color
    hoverColor: Colors.grey[800]!, // Hover color
    gap: 8, // Space between icons/text
    activeColor: Colors.black, // Active icon and text color
    iconSize: 24, // Size of the icons
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Padding within the GNav
    duration: Duration(milliseconds: 50), // Navigation transition duration
    tabBackgroundColor: Colors.purple[400]!, // Selected tab background color
    color: Colors.blue.shade600,
     tabs: [
      GButton(icon: Icons.chat_rounded,text: 'Chats',),
      GButton(icon: Icons.group_rounded,text: 'Group',),
      GButton(icon: Icons.calculate_rounded,text: 'Group',),
      GButton(icon: Icons.settings_rounded,text: 'Settings',),


    ],
    selectedIndex: selectedIndex,
        onTabChange: onItemTapped,),
        
      ),
    );
  }
}



/* BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.chat,color: Colors.black,), label: 'Chats'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calculate,color: Colors.black,), label: 'Calculator'),
          BottomNavigationBarItem(icon: Icon(Icons.settings,color: Colors.black,), label: 'Settings')
        ], */
