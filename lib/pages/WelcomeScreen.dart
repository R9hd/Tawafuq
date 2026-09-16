
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:tawafuq/pages/LoginScreen.dart';

class WelcomeScreen extends StatefulWidget {
  final bool isVoiceSystemEnabled;

  const WelcomeScreen({super.key, required this.isVoiceSystemEnabled});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String _selectedRole = '';

  late bool _isVoiceSystemEnabled;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void dispose() {
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _isVoiceSystemEnabled = widget.isVoiceSystemEnabled;
    _requestPermissions();
    if (_isVoiceSystemEnabled) {
      _speakOnPageLoad();
    }
  }

  void _requestPermissions() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    } else {
      Fluttertoast.showToast(
        msg: "Mic Access Needed",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        gravity: ToastGravity.TOP,
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 3,
        fontSize: 16,
      );
    }
  }

  Future<void> _speakOnPageLoad() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);

    String textToRead = "Are you a job seeker?";
    await _flutterTts.speak(textToRead);

    _flutterTts.setCompletionHandler(() {
      _startListening();
    });
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.toLowerCase().contains('yes')) {
              _selectedRole = 'Job Seeker';
          
            _navigateToLoginSignup(context, _selectedRole);
          }
          if(result.recognizedWords.toLowerCase().contains('no')){
            _selectedRole = 'Recruter';
            _navigateToLoginSignup(context, _selectedRole);
          }
            
        },
      );
    }
  }

  void _toggleVoiceSystem() {
    setState(() {
      _isVoiceSystemEnabled = !_isVoiceSystemEnabled;
      if (!_isVoiceSystemEnabled) {
        _flutterTts.stop();
        _speech.stop();
      } else {
        _speakOnPageLoad();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B79A1),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4B79A1), Color(0xFF283E51)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', height: 200),
              const SizedBox(height: 40),
              const Text(
                'Select Your Role',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF7F7F7),
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Please select your role to continue',
                style: TextStyle(
                  fontSize: 20,
                  color: Color(0xFFF7F7F7),
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
            
                    _navigateToLoginSignup(context, 'Job Seeker');
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFFe64833),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: Text('Job Seeker'),
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
     
                    _navigateToLoginSignup(context, 'Recruiter');
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFFe64833),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: const Text('Recruiter'),
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
   
                    _navigateToLoginSignup(context, 'Admin');
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFFe64833),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: const Text('Admin'),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToLoginSignup(BuildContext context, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(
          role: role,
          isVoiceSystemEnabled: _isVoiceSystemEnabled,
        ),
      ),
    );
  }
}
