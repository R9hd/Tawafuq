
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:tawafuq/pages/WelcomeScreen.dart';

class Firstscreen extends StatefulWidget {
  const Firstscreen({super.key});

  @override
  State<Firstscreen> createState() => _FirstscreenState();
}

class _FirstscreenState extends State<Firstscreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isVoiceSystemEnabled = true;

  @override
  void initState() {
    super.initState();
    if (_isVoiceSystemEnabled) {
      _speakOnPageLoad();
    }
  }

  void _repeatProcess() {
    if (_isVoiceSystemEnabled) {
      print("Repeating the process...");
      Future.delayed(const Duration(seconds: 3), () {
        _speakOnPageLoad();
      });
    }
  }

  Future<void> _speakOnPageLoad() async {
    if (!_isVoiceSystemEnabled) return;

    print("Speaking welcome message...");
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);

    await _flutterTts.speak(
        "Welcome to Tawafuq, your go-to platform for part-time job opportunities.");

    await Future.delayed(const Duration(seconds: 5));

    if (_isVoiceSystemEnabled) {
      print("Speaking question...");
      await _flutterTts.speak("Do you want to get started?");
      Future.delayed(const Duration(seconds: 2), () {
        if (_isVoiceSystemEnabled) _startListening();
      });
    }
  }

  void _startListening() async {
    if (!_isVoiceSystemEnabled) return;

    print("Initializing speech recognition...");
    bool available = await _speech.initialize();
    if (available) {
      print("Speech recognition initialized. Listening...");
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          String recognizedText = result.recognizedWords.toLowerCase();
          print("Recognized text: $recognizedText");

          if (recognizedText.contains('yes')) {
            print("User said 'yes'.");
            _speech.stop();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WelcomeScreen(
                  isVoiceSystemEnabled: _isVoiceSystemEnabled,
                ),
              ),
            );
          } else if (recognizedText.isEmpty) {
            print("No input detected.");
            _speech.stop();
            _repeatProcess();
          } else {
            print("Unrecognized response.");
            _speech.stop();
            _repeatProcess();
          }
        },
        listenFor: const Duration(seconds: 20),
        onDevice: true,
      );
    } else {
      print("Speech recognition not available.");
      _repeatProcess();
    }
  }

  void _toggleVoiceSystem() {
    setState(() {
      _isVoiceSystemEnabled = !_isVoiceSystemEnabled;
      if (!_isVoiceSystemEnabled) {
        print("Voice system turned off.");
        _flutterTts.stop();
        _speech.stop();
      } else {
        print("Voice system turned on.");
        _speakOnPageLoad();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 200,
                ),
                const SizedBox(height: 40),
                const Text(
                  'Welcome to Tawafuq',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your go-to platform\nfor part-time job opportunities',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WelcomeScreen(
                          isVoiceSystemEnabled: _isVoiceSystemEnabled,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_right_alt, color: Colors.red),
                      SizedBox(width: 10),
                      Text(
                        'GET STARTED',
                        style: TextStyle(color: Colors.red, fontSize: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isVoiceSystemEnabled ? Icons.volume_up : Icons.volume_off,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _toggleVoiceSystem,
                      child: Text(
                        _isVoiceSystemEnabled
                            ? 'Turn off the Voice System'
                            : 'Turn on the Voice System',
                        style: const TextStyle(
                          color: Colors.white70,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
