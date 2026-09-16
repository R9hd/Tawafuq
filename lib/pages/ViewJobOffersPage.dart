
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ViewJobOffersPage extends StatefulWidget {
  final bool isVoiceSystemEnabled;

  const ViewJobOffersPage({super.key, required this.isVoiceSystemEnabled});

  @override
  _ViewJobOffersPageState createState() => _ViewJobOffersPageState();
}

class _ViewJobOffersPageState extends State<ViewJobOffersPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _jobOffers = [];
  bool _isLoading = true;

  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  late bool _isVoiceSystemEnabled;

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
    _fetchJobOffers();
  }

  Future<void> _fetchJobOffers() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        QuerySnapshot querySnapshot = await _firestore
            .collection('job_offers')
            .where('jobSeekerId', isEqualTo: currentUser.uid)
            .get();

        setState(() {
          _jobOffers = querySnapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
          _isLoading = false;
        });

        if (_jobOffers.isEmpty && _isVoiceSystemEnabled) {
          await _flutterTts.speak(
              "There are no job offers available. Would you like to go back?");
          await _flutterTts.awaitSpeakCompletion(true);
          _startListeningToGoBack();
        } else if (_jobOffers.isNotEmpty && _isVoiceSystemEnabled) {
          await _readJobOfferDetails(0);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _readJobOfferDetails(int index) async {
    if (index >= _jobOffers.length) {
      if (_isVoiceSystemEnabled) {
        await _flutterTts.speak("You have reached the end of the job offers.");
        return;
      }
    }

    final jobOffer = _jobOffers[index];
    String jobTitle = jobOffer['jobTitle'] ?? 'Unknown Job Title';
    String companyName = jobOffer['companyName'] ?? 'Unknown Company';
    String status = jobOffer['status'] ?? 'Pending';

    await _flutterTts.speak(
        "Job Offer ${index + 1}. Title: $jobTitle. Company: $companyName. Status: $status.");
    await _flutterTts.awaitSpeakCompletion(true);

    await _flutterTts
        .speak("For more information, we will contact you through email.");
    await _flutterTts.awaitSpeakCompletion(true);

    await _flutterTts.speak(
        "Would you like to go back or re-read this offer? Please say 'back' or 'read again' for reading next offer say 'next'.");
    await _flutterTts.awaitSpeakCompletion(true);

    _startListeningForResponse(index);
  }

  void _startListeningForResponse(int index) async {
    if (!_isVoiceSystemEnabled) return;
    bool available = await _speech.initialize();

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) async {
          String recognizedText = result.recognizedWords.toLowerCase();

          if (recognizedText.contains("back")) {
            _speech.stop();
            await _flutterTts.speak("Going back to the previous page.");
            Navigator.pop(context);
          } else if (recognizedText.contains("read again")) {
            _speech.stop();
            await _readJobOfferDetails(index);
          } else if (recognizedText.contains("next")) {
            _speech.stop();
            await _flutterTts.speak("Reading the next job offer");
            await _readJobOfferDetails(index + 1);
          } else {
            _speech.stop();
            await _flutterTts
                .speak("Unrecognized response. Repeating the question.");
            await _flutterTts.awaitSpeakCompletion(true);
            _startListeningForResponse(index);
          }
        },
        listenFor: const Duration(seconds: 10),
        partialResults: false,
      );
    } else {
      await _flutterTts.speak("Voice recognition is currently unavailable.");
    }
  }

  void _startListeningToGoBack() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) async {
          String recognizedText = result.recognizedWords.toLowerCase();
          if (recognizedText.contains("yes")) {
            _speech.stop();
            await _flutterTts.speak("Going back to the previous page.");
            Navigator.pop(context);
          } else if (recognizedText.contains("no")) {
            _speech.stop();
            await _flutterTts.speak("Staying on the current page.");
          } else {
            _speech.stop();
            await _flutterTts
                .speak("Unrecognized response. Repeating the question.");
            await _flutterTts.awaitSpeakCompletion(true);
            _startListeningToGoBack();
          }
        },
        listenFor: const Duration(seconds: 10),
        partialResults: false,
      );
    } else {
      await _flutterTts.speak("Voice recognition is currently unavailable.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Job Offers'),
        backgroundColor: const Color(0xFF244855),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _jobOffers.isEmpty
              ? const Center(
                  child: Text('No job offers available.',
                      style: TextStyle(fontSize: 18)))
              : ListView.builder(
                  itemCount: _jobOffers.length,
                  itemBuilder: (context, index) {
                    final jobOffer = _jobOffers[index];
                    final status = jobOffer['status'] ?? 'Pending';
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: Icon(
                              Icons.work,
                              color: status == 'Rejected'
                                  ? Colors.red
                                  : const Color(0xFF4B79A1),
                            ),
                            title: Text(
                              jobOffer['jobTitle'] ?? 'Unknown Job Title',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: status == 'Rejected'
                                    ? Colors.red
                                    : Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              jobOffer['companyName'] ?? 'Unknown Company',
                              style: TextStyle(
                                  color: status == 'Rejected'
                                      ? Colors.red
                                      : Colors.black),
                            ),
                            trailing: Text(
                              status,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: status == 'Rejected'
                                    ? Colors.red
                                    : status == 'Accepted'
                                        ? Colors.green
                                        : Colors.orange,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Text(
                              'For more information, we will contact you through email.',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
