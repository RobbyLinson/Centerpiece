import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(MyApp());
}

class BlinkingCursorTitle extends StatefulWidget {
  final String text;
  final TextStyle textStyle;

  BlinkingCursorTitle({Key? key, required this.text, required this.textStyle})
      : super(key: key);

  @override
  _BlinkingCursorTitleState createState() => _BlinkingCursorTitleState();
}

class _BlinkingCursorTitleState extends State<BlinkingCursorTitle>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration:
          const Duration(milliseconds: 600), // Half of the desired blink rate
      vsync: this,
    )..repeat(reverse: true); // Start blinking animation
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (BuildContext context, Widget? child) {
        final showCursor = _animationController.value < 0.5;
        return Text(
          '${widget.text}${showCursor ? '_' : ' '}', // Toggle between underscore and space
          style: widget.textStyle,
        );
      },
    );
  }
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
        title: BlinkingCursorTitle(
          text: 'Centerpiece',
          textStyle: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            fontFamily: 'RobotoMono',
          ),
        ),
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
            IconButton(
              //Transcription Archive
              icon: Icon(Icons.menu_book),
              onPressed: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => LibraryScreen()));
              },
            ),
            IconButton(
              //Summaries
              icon: Icon(Icons.library_books),
              onPressed: () {
                showMenu(
                  context: context,
                  constraints: BoxConstraints(minHeight: 1000),
                  position: RelativeRect.fromLTRB(0, 0, 0, 0),
                  items: <PopupMenuEntry>[
                    PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.home),
                        title: Text('Home'),
                      ),
                    ),
                    PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.settings),
                        title: Text('Settings'),
                      ),
                    ),
                    PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.info),
                        title: Text('About'),
                      ),
                    ),
                  ],
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => HomeScreen()));
              },
            ),
            IconButton(
              //Chat/Email
              icon: Icon(Icons.chat_bubble_outline),
              onPressed: () {},
            ),
            IconButton(
              //Profile
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

class LibraryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: BlinkingCursorTitle(
          text: 'Centerpiece',
          textStyle: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            fontFamily: 'RobotoMono',
          ),
        ),
      ),
      body: FutureBuilder<List<GlossaryItem>>(
        future: getTitlesFromJsonFiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            // Display buttons with titles
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                GlossaryItem item = snapshot.data![index];
                // Check if the current item is "Example glossary" to set a taller height
                double buttonHeight =
                    item.title == "Example glossary" ? 100.0 : 60.0;
                return Container(
                  height: buttonHeight, // Use the height variable here
                  margin: EdgeInsets.only(
                      bottom: 8.0), // Add some space between buttons
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity,
                          buttonHeight), // Button gets its height from the variable
                      padding: EdgeInsets.symmetric(
                          vertical:
                              16), // Optional: add padding for visual enhancement
                      // You can add more style customization here if needed
                    ),
                    onPressed: () {
                      // Show the AlertDialog when the button is clicked
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text(item.title),
                            content: Text(item.summary),
                            actions: <Widget>[
                              TextButton(
                                child: Text('Close'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: Text('Transcript'),
                                onPressed: () {
                                  // Display the message item from the glossary
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text('Transcript'),
                                        content: SingleChildScrollView(
                                          child: Text(item.message),
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            child: Text('Close'),
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .pop(); // Close the transcript dialog
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Text(item.title),
                  ),
                );
              },
            );
          }
        },
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              //Transcription Archive
              icon: Icon(Icons.menu_book),
              onPressed: () {},
            ),
            IconButton(
              //Summaries
              icon: Icon(Icons.library_books),
              onPressed: () {
                showMenu(
                  context: context,
                  constraints: BoxConstraints(minHeight: 1000),
                  position: RelativeRect.fromLTRB(0, 0, 0, 0),
                  items: <PopupMenuEntry>[
                    PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.home),
                        title: Text('Home'),
                      ),
                    ),
                    PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.settings),
                        title: Text('Settings'),
                      ),
                    ),
                    PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.info),
                        title: Text('About'),
                      ),
                    ),
                  ],
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => HomeScreen()));
              },
            ),
            IconButton(
              //Chat/Email
              icon: Icon(Icons.chat_bubble_outline),
              onPressed: () {},
            ),
            IconButton(
              //Profile
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

Future<List<GlossaryItem>> getTitlesFromJsonFiles() async {
  List<GlossaryItem> glossaryItems = [];
  int fileIndex = 1;

  while (true) {
    String filePath = 'assets/summaries/$fileIndex.json';

    try {
      String content = await rootBundle.loadString(filePath);
      var jsonData = jsonDecode(content);

      // Extract the title, summary, and message
      String title = jsonData['title'];
      String summary = jsonData['summary'];
      String message = jsonData['message'];

      glossaryItems
          .add(GlossaryItem(title: title, summary: summary, message: message));
      fileIndex++;
    } catch (e) {
      // When a file is not found, an exception is thrown. Break the loop here.
      break;
    }
  }
  return glossaryItems;
}

class GlossaryItem {
  final String title;
  final String summary;
  final String message;

  GlossaryItem(
      {required this.title, required this.summary, required this.message});
}
