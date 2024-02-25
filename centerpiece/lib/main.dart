import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

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
        fontFamily: 'RobotoMono',
        primaryColor: Colors.green[700], // Olive green primary color
        scaffoldBackgroundColor:
            Color.fromARGB(255, 233, 242, 233), // Light green background
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
                    const PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.key),
                        title: Text('Key Points'),
                      ),
                    ),
                    const PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.accessibility_new_rounded),
                        title: Text('Speech'),
                      ),
                    ),
                    const PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.amp_stories_sharp),
                        title: Text('Flash Cards'),
                      ),
                    ),
                    const PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.book),
                        title: Text('Further Reading'),
                      ),
                    ),
                  ],
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {},
            ),
            IconButton(
              //Chat/Email
              icon: Icon(Icons.chat_bubble_outline),
              onPressed: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => GroupScreen()));
              },
            ),
            IconButton(
              //Profile
              icon: Icon(Icons.person),
              onPressed: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => UserScreen()));
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
                            content: Container(
                              height: MediaQuery.of(context).size.height *
                                  0.5, // 50% of screen height
                              width: MediaQuery.of(context)
                                  .size
                                  .width, // Screen width
                              child: SingleChildScrollView(
                                child:
                                    Text(item.summary), // The transcript text
                              ),
                            ),
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
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text('Transcript'),
                                        content: Container(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.5, // 50% of screen height
                                          width: MediaQuery.of(context)
                                              .size
                                              .width, // Screen width
                                          child: SingleChildScrollView(
                                            child: Text(item
                                                .message), // The transcript text
                                          ),
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            child: Text('Close'),
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .pop(); // Close the dialog
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
                    const PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.key),
                        title: Text('Key Points'),
                      ),
                    ),
                    const PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.accessibility_new_rounded),
                        title: Text('Speech'),
                      ),
                    ),
                    const PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.amp_stories_sharp),
                        title: Text('Flash Cards'),
                      ),
                    ),
                    const PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.book),
                        title: Text('Further Reading'),
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
              onPressed: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => GroupScreen()));
              },
            ),
            IconButton(
              //Profile
              icon: Icon(Icons.person),
              onPressed: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => UserScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class Group {
  String name;

  Group(this.name);
}

class GroupScreen extends StatefulWidget {
  @override
  _GroupScreenState createState() => _GroupScreenState();
}

List<Group> groups = [];

class _GroupScreenState extends State<GroupScreen> {
  void _createNewGroup() async {
    String? groupName = await _asyncInputDialog(context);
    if (groupName != null && groupName.isNotEmpty) {
      setState(() {
        groups.add(Group(groupName));
      });
    }
  }

  Future<String?> _asyncInputDialog(BuildContext context) async {
    String groupName = '';
    return showDialog<String>(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Group Name'),
          content: Row(
            children: [
              Expanded(
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(labelText: 'Group Name'),
                  onChanged: (value) {
                    groupName = value;
                  },
                ),
              )
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Return null when cancelled
              },
            ),
            TextButton(
              child: Text('Create'),
              onPressed: () {
                Navigator.of(context).pop(groupName); // Return the group name
              },
            ),
          ],
        );
      },
    );
  }

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
      body: ListView.builder(
        itemCount: groups.length,
        itemBuilder: (context, index) {
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(10.0), // Rounded corners for the Card
            ),
            elevation: 4.0, // Shadow effect for the Card
            margin: EdgeInsets.all(8.0), // Space around the Card
            child: ListTile(
              title: Text(groups[index].name),
              trailing: Wrap(
                spacing: 12, // Space between buttons
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        groups.removeAt(index);
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.group),
                    onPressed: () {
                      // Join group functionality
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewGroup,
        tooltip: 'Create New Group',
        child: Icon(Icons.add),
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
                    const PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.key),
                        title: Text('Key Points'),
                      ),
                    ),
                    const PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.accessibility_new_rounded),
                        title: Text('Speech'),
                      ),
                    ),
                    const PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.amp_stories_sharp),
                        title: Text('Flash Cards'),
                      ),
                    ),
                    const PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.book),
                        title: Text('Further Reading'),
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
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => UserScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class UserScreen extends StatefulWidget {
  @override
  _UserScreenState createState() => _UserScreenState();
}

bool _autoDeleteTranscripts = false;

class _UserScreenState extends State<UserScreen> {
  // Initial state of the switch

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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: 20), // Spacing from the top
          Column(
            mainAxisSize: MainAxisSize.min, // Use the minimum space necessary
            children: <Widget>[
              CircleAvatar(
                radius: 50, // Size of the avatar
                backgroundImage: AssetImage(
                    'images/stockphoto.jpg'), // Your image asset path
              ),
              SizedBox(height: 8), // Provide some vertical spacing
              Text(
                'John Centerpiece', // Replace with a dynamic username variable if needed
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20), // Spacing from the top
          // Settings ListTile wrapped in a Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 4.0,
            margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                // Handle settings tap
              },
            ),
          ),
          // Auto Delete Transcripts SwitchListTile wrapped in a Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 4.0,
            margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: SwitchListTile(
              title: Text('Auto Delete Transcripts'),
              value:
                  _autoDeleteTranscripts, // Make sure this variable is defined in your State class
              onChanged: (bool value) {
                setState(() {
                  _autoDeleteTranscripts = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Color.fromARGB(255, 146, 202, 161), // Button color
              ),
              onPressed: () {
                // Add logout functionality here
              },
              child:
                  Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),

          if (Platform.isWindows) // Quit Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 146, 202, 161),
              ),
              onPressed: () {
                exit(0);
                // Close the app
              },
              child:
                  Text('Quit', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
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
                    const PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.key),
                        title: Text('Key Points'),
                      ),
                    ),
                    const PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.accessibility_new_rounded),
                        title: Text('Speech'),
                      ),
                    ),
                    const PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.amp_stories_sharp),
                        title: Text('Flash Cards'),
                      ),
                    ),
                    const PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.book),
                        title: Text('Further Reading'),
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
              onPressed: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => GroupScreen()));
              },
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

class RecordButton extends StatefulWidget {
  @override
  _RecordButtonState createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton> {
  bool _isRecording = false;
  Timer? _timer;
  int _dotIndex = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startBlinking() {
    const duration = Duration(milliseconds: 500);
    _timer = Timer.periodic(duration, (Timer timer) {
      setState(() {
        _dotIndex = (_dotIndex + 1) % 3; // Cycle through dots
      });
    });
  }

  void _stopBlinking() {
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175.0,
      height: 175.0,
      child: FloatingActionButton(
        onPressed: () {
          if (_isRecording) {
            // Send stop_transcription API call
            http.get(Uri.parse('http://127.0.0.1:5000/stop_transcription'));
            _stopBlinking();
          } else {
            // Send start_transcription API call
            http.get(Uri.parse('http://127.0.0.1:5000/start_transcription'));
            _startBlinking();
          }
          // Toggle the recording state
          setState(() {
            _isRecording = !_isRecording;
          });
        },
        backgroundColor:
            _isRecording ? Colors.red : Color.fromARGB(255, 146, 202, 161),
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 500),
          child: _isRecording
              ? Row(
                  key: UniqueKey(),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _dotIndex == 0
                        ? Dot(size: 15, color: Colors.white)
                        : SizedBox(width: 20),
                    _dotIndex == 1
                        ? Dot(size: 15, color: Colors.white)
                        : SizedBox(width: 20),
                    _dotIndex == 2
                        ? Dot(size: 15, color: Colors.white)
                        : SizedBox(width: 20),
                  ],
                )
              : Icon(Icons.mic, size: 50),
        ),
      ),
    );
  }
}

class Dot extends StatelessWidget {
  final double size;
  final Color color;

  const Dot({Key? key, required this.size, required this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
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
