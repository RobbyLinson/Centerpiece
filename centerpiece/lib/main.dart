import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Centerpiece',
      theme: ThemeData(
        primaryColor: Colors.green[700], // Olive green primary color
        scaffoldBackgroundColor: Colors.green[100], // Light green background
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text('Centerpiece', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'RobotoMono')),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            SizedBox(height: 20),
            RecordButton(),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton( //Transcription Archive
              icon: Icon(Icons.menu_book),
              onPressed: () {
              },
            ),
            IconButton( //Flashcards
              icon: Icon(Icons.library_books),
              onPressed: () {
              },
            ),
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
              },
            ),
            IconButton( //Chat/Email
              icon: Icon(Icons.chat_bubble_outline),
              onPressed: () {
              },
            ),
            IconButton( //Profile
              icon: Icon(Icons.person),
              onPressed: () {
                // Handle profile button press
              },
            ),
          ],
        ),
      ),
    );
  }
}

class RecordButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175.0, // Specify the width
      height: 175.0, // Specify the height
      child: FloatingActionButton(
        onPressed: () {
          // Recording functionality goes here
        },
        child: Icon(Icons.mic,
            size:
                50), // Specify the icon size if you want to make it larger too
        backgroundColor: Colors.green[700],
      ),
    );
  }
}
