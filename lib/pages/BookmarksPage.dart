
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tawafuq/job_card.dart';
import 'package:tawafuq/pages/ApplicantCVScreen.dart';
import 'package:tawafuq/pages/JobDetailPage.dart';
import 'package:tawafuq/pages/JobSeekerHome.dart';
import 'package:tawafuq/pages/part_time_jobs_page.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class BookmarksPage extends StatefulWidget {
  final bool isVoiceSystemEnabled;

  const BookmarksPage({super.key, required this.isVoiceSystemEnabled});

  @override
  _BookmarksPageState createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  List<JobCard> _bookmarkedJobs = [];
  int _selectedIndex = 2;
  late bool _isVoiceSystemEnabled;

  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _isVoiceSystemEnabled = widget.isVoiceSystemEnabled;

    _fetchBookmarkedJobs();
    if (_isVoiceSystemEnabled) {
      _announceNavigationOptions();
      _readBookmarkedJobs(0);
    }
  }

  Future<void> _readBookmarkedJobs(int index) async {
    if (_bookmarkedJobs.isEmpty) {
      await _flutterTts.speak("You have no bookmarked jobs.");
      return;
    }
    if (index >= _bookmarkedJobs.length) {
      await _flutterTts.speak("You have reached the end of the bookmarked jobs.");
      return;
    }

    final job = _bookmarkedJobs[index];
    await _flutterTts.speak(
        "Bookmark ${index + 1}. Title: ${job.jobTitle}. Would you like to hear more details, delete this bookmark, or skip to the next one? Say details, delete, or next.");
    await _flutterTts.awaitSpeakCompletion(true);
    _listenForJobAction(index);
  }

  void _listenForJobAction(int index) async {
    final available = await _speech.initialize();
    if (!available) return;
    _speech.listen(
      onResult: (result) async {
        String action = result.recognizedWords.toLowerCase();

        if (action.contains("details")) {
          _speech.stop();
          final job = _bookmarkedJobs[index];
          await _flutterTts.speak(
              "Details for ${job.jobTitle}. Description: ${job.jobDescription}. Location: ${job.jobLocation}. Salary: ${job.jobSalary}.");
          await _flutterTts.awaitSpeakCompletion(true);
          _readBookmarkedJobs(index + 1);
        } else if (action.contains("delete")) {
          _speech.stop();
          await _deleteBookmark(_bookmarkedJobs[index].jobId);
          await _readBookmarkedJobs(index);
        } else if (action.contains("next")) {
          _speech.stop();
          _readBookmarkedJobs(index + 1);
        } else {
          _speech.stop();
          await _flutterTts.speak("Unrecognized command. Please say details, delete, or next.");
          await _flutterTts.awaitSpeakCompletion(true);
          _listenForJobAction(index);
        }
      },
      listenFor: const Duration(seconds: 30),
    );
  }

  Future<void> _announceNavigationOptions() async {
    await _flutterTts.speak(
        "You are on the Bookmarks page. You can navigate to Home, Search, or Profile. Say the name of the page to navigate.");
    await _flutterTts.awaitSpeakCompletion(true);
    _startListeningForNavigationOrContent();
  }

  void _startListeningForNavigationOrContent() {
    _speech.listen(
      onResult: (result) async {
        String command = result.recognizedWords.toLowerCase();

        if (command.contains("read")) {
          _speech.stop();
          _readBookmarkedJobs(0);
        } else if (command.contains("home")) {
          _speech.stop();
          Navigator.pushReplacement(context, MaterialPageRoute(
              builder: (context) => JobSeekerHome(
                  applicantName: '', isVoiceSystemEnabled: _isVoiceSystemEnabled)));
        } else if (command.contains("search")) {
          _speech.stop();
          Navigator.pushReplacement(context, MaterialPageRoute(
              builder: (context) => PartTimeJobsPage(isVoiceSystemEnabled: _isVoiceSystemEnabled)));
        } else if (command.contains("profile")) {
          _speech.stop();
          Navigator.pushReplacement(context, MaterialPageRoute(
              builder: (context) => ApplicantCVScreen(isVoiceSystemEnabled: _isVoiceSystemEnabled)));
        } else if (command.contains("bookmarks")) {
          _speech.stop();
          await _flutterTts.speak("You are already on the Bookmarks page.");
          await _flutterTts.awaitSpeakCompletion(true);
          _startListeningForNavigationOrContent();
        } else {
          _speech.stop();
        }
      },
      listenFor: const Duration(seconds: 30),
    );
  }

  Future<void> _fetchBookmarkedJobs() async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;

      if (user != null) {
        String userId = user.uid;

        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('bookmarks')
            .where('userId', isEqualTo: userId)
            .get();

        List<JobCard> fetchedJobs = querySnapshot.docs.map((doc) {
          return JobCard(
            jobTitle: doc['jobTitle'],
            jobDescription: doc['jobDescription'],
            jobLocation: doc['jobLocation'],
            jobType: doc['jobType'],
            jobSalary: doc['jobSalary'],
            jobId: doc.id,
          );
        }).toList();

        setState(() { _bookmarkedJobs = fetchedJobs; });

        if (fetchedJobs.isNotEmpty && _isVoiceSystemEnabled) {
          await _readJobsAloud(0);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user is logged in')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching bookmarked jobs: $e')),
      );
    }
  }

  Future<void> _deleteBookmark(String jobId) async {
    try {
      await FirebaseFirestore.instance.collection('bookmarks').doc(jobId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bookmark deleted!')),
      );
      _fetchBookmarkedJobs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete bookmark: $e')),
      );
    }
  }

  Future<void> _readJobsAloud(int index) async {
    if (index >= _bookmarkedJobs.length) {
      await _flutterTts.speak("You have reached the end of your bookmarked jobs.");
      return;
    }

    final job = _bookmarkedJobs[index];
    await _flutterTts.speak(
        "Job ${index + 1}. Title: ${job.jobTitle}. Do you want me to read the details? Please say yes or no.");
    await _flutterTts.awaitSpeakCompletion(true);
    _startListeningForResponse(index, job);
  }

  void _startListeningForResponse(int index, JobCard job) {
    _speech.listen(
      onResult: (result) async {
        String recognizedText = result.recognizedWords.toLowerCase();

        if (recognizedText.contains("yes")) {
          _speech.stop();
          await _flutterTts.speak(
              "Details for ${job.jobTitle}. Description: ${job.jobDescription}. Location: ${job.jobLocation}. Salary: ${job.jobSalary}.");
          await _flutterTts.awaitSpeakCompletion(true);
          await _flutterTts.speak(
              "Would you like to apply for this job, delete it, or skip? Say apply, delete, or next.");
          await _flutterTts.awaitSpeakCompletion(true);
          _startListeningForAction(index, job);
        } else if (recognizedText.contains("no")) {
          _speech.stop();
          if (_isVoiceSystemEnabled) { await _readJobsAloud(index + 1); }
        } else {
          _speech.stop();
          await _flutterTts.speak("Unrecognized response. Skipping to the next job.");
          if (_isVoiceSystemEnabled) { await _readJobsAloud(index + 1); }
        }
      },
      listenFor: const Duration(seconds: 30),
    );
  }

  void _startListeningForAction(int index, JobCard job) {
    _speech.listen(
      onResult: (result) async {
        String action = result.recognizedWords.toLowerCase();

        if (action.contains("apply")) {
          _speech.stop();
          Navigator.push(context, MaterialPageRoute(
              builder: (context) => JobDetailPage(job: job)));
        } else if (action.contains("delete")) {
          _speech.stop();
          await _deleteBookmark(job.jobId);
          if (_isVoiceSystemEnabled) { await _readJobsAloud(index); }
        } else if (action.contains("next")) {
          _speech.stop();
          if (_isVoiceSystemEnabled) { await _readJobsAloud(index + 1); }
        } else {
          _speech.stop();
          await _flutterTts.speak("Unrecognized command. Skipping to the next job.");
          if (_isVoiceSystemEnabled) { await _readJobsAloud(index + 1); }
        }
      },
      listenFor: const Duration(seconds: 30),
    );
  }

  void _onItemTapped(int index) async {
    if (index == _selectedIndex) return;
    setState(() { _selectedIndex = index; });

    if (_isVoiceSystemEnabled) {
      final tabs = ["Home", "Search", "Bookmarks", "Profile"];
      final label = index < tabs.length ? tabs[index] : "Unknown";
      await _flutterTts.speak("Navigating to $label tab.");
      await _flutterTts.awaitSpeakCompletion(true);
    }

    switch (index) {
      case 0:
        Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) => JobSeekerHome(
                applicantName: '', isVoiceSystemEnabled: _isVoiceSystemEnabled)));
        break;
      case 1:
        Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) => PartTimeJobsPage(isVoiceSystemEnabled: _isVoiceSystemEnabled)));
        break;
      case 2:
        break;
      case 3:
        Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) => ApplicantCVScreen(isVoiceSystemEnabled: _isVoiceSystemEnabled)));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        backgroundColor: const Color(0xFF244855),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () { Navigator.pop(context); },
        ),
      ),
      body: _bookmarkedJobs.isEmpty
          ? const Center(
              child: Text('No bookmarks yet.',
                  style: TextStyle(color: Colors.grey, fontSize: 18)))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _bookmarkedJobs.length,
              itemBuilder: (context, index) {
                final job = _bookmarkedJobs[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Text(job.jobTitle),
                    subtitle: Text(job.jobDescription),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () { _deleteBookmark(job.jobId); },
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) => JobDetailPage(job: job)));
                    },
                  ),
                );
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF283E51),
        selectedItemColor: const Color(0xFFD76315),
        unselectedItemColor: const Color(0xFFD76315),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Bookmarks'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
