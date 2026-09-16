
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:tawafuq/pages/ApplicantCVScreen.dart';
import 'package:tawafuq/pages/BookmarksPage.dart';
import 'package:tawafuq/pages/ViewJobOffersPage.dart';
import 'package:tawafuq/pages/bars&drawers/DrawerPage.dart';
import 'package:tawafuq/pages/part_time_jobs_page.dart';

class JobSeekerHome extends StatefulWidget {
  final String applicantName;
  final bool isVoiceSystemEnabled;

  const JobSeekerHome({super.key, required this.applicantName, required this.isVoiceSystemEnabled});

  @override
  _JobSeekerHomeState createState() => _JobSeekerHomeState();
}

class _JobSeekerHomeState extends State<JobSeekerHome> {
  int _selectedIndex = 0;
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  late bool _isVoiceSystemEnabled;

  @override
  void initState() {
    super.initState();
    _isVoiceSystemEnabled = widget.isVoiceSystemEnabled;
    if (_isVoiceSystemEnabled) {
      _askUserChoice();
    }
  }

  Future<void> _askUserChoice() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak(
        "Do you want to search for a job or view job offers? Please say 'search' or 'offers'.");
    await _flutterTts.awaitSpeakCompletion(true);
    _startListeningForChoice();
  }

  void _startListeningForChoice() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) async {
          String recognizedText = result.recognizedWords.toLowerCase();
          if (recognizedText.contains("search")) {
            _speech.stop();
            await _flutterTts.speak("Navigating to search for a job.");
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => PartTimeJobsPage(
                    isVoiceSystemEnabled: _isVoiceSystemEnabled)));
          } else if (recognizedText.contains("offers")) {
            _speech.stop();
            await _flutterTts.speak("Navigating to view job offers.");
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => ViewJobOffersPage(
                    isVoiceSystemEnabled: _isVoiceSystemEnabled)));
          } else {
            _speech.stop();
            await _flutterTts.speak("I didn't catch that. Please say 'search' or 'offers'.");
            await _flutterTts.awaitSpeakCompletion(true);
            _startListeningForChoice();
          }
        },
        listenFor: const Duration(seconds: 10),
        partialResults: false,
      );
    } else {
      print("Speech recognition not available.");
      await _flutterTts.speak(
          "Voice recognition is currently unavailable. Please use the buttons to navigate.");
    }
  }

  void _onItemTapped(int index) {
    setState(() { _selectedIndex = index; });

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => PartTimeJobsPage(
                isVoiceSystemEnabled: _isVoiceSystemEnabled)));
        break;
      case 2:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => BookmarksPage(
                isVoiceSystemEnabled: _isVoiceSystemEnabled)));
        break;
      case 3:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => ApplicantCVScreen(
                isVoiceSystemEnabled: _isVoiceSystemEnabled)));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: DrawerPage(),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4B79A1), Color(0xFF283E51)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Builder(
              builder: (BuildContext context) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () { Navigator.pop(context); },
                      ),
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () { Scaffold.of(context).openEndDrawer(); },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  const Text('Hi! Welcome',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 50,
                        fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                  Text(widget.applicantName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 28,
                        fontWeight: FontWeight.w500)),
                  Image.asset('assets/search.png',
                    width: 500, height: 150),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => PartTimeJobsPage(
                                isVoiceSystemEnabled: _isVoiceSystemEnabled)));
                      },
                      icon: const Icon(Icons.search, size: 35),
                      label: const Text('Search for a Job',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF44336),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Image.asset('assets/jobo.webp', width: 500, height: 150),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => ViewJobOffersPage(
                                isVoiceSystemEnabled: _isVoiceSystemEnabled)));
                      },
                      icon: const Icon(Icons.list_alt, size: 35),
                      label: const Text('View Job Offers',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(canvasColor: const Color(0xFF283E51)),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Bookmarks'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFFD76315),
          unselectedItemColor: const Color(0xFFD76315),
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
