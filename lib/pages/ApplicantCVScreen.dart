
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:tawafuq/pages/BookmarksPage.dart';
import 'package:tawafuq/pages/JobSeekerHome.dart';
import 'package:tawafuq/pages/bars&drawers/DrawerPage.dart';
import 'package:tawafuq/pages/part_time_jobs_page.dart';

class ApplicantCVScreen extends StatefulWidget {
  final bool isVoiceSystemEnabled;

  const ApplicantCVScreen({super.key, required this.isVoiceSystemEnabled});

  @override
  _ApplicantCVScreenState createState() => _ApplicantCVScreenState();
}

class _ApplicantCVScreenState extends State<ApplicantCVScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  String? _uploadedFileURL;
  File? _selectedFile;
  String? _userId;
  int _selectedIndex = 3;
  late bool _isVoiceSystemEnabled;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  int _currentFieldIndex = 0;
  final List<TextEditingController> _controllers = [];

  bool _isConfirmingSave = false;
  bool _fieldsCompleted = false;

  @override
  void initState() {
    super.initState();
    _isVoiceSystemEnabled = widget.isVoiceSystemEnabled;
    _userId = _auth.currentUser?.uid;
    _fetchCVData();
    _initializeSTT();

    _controllers.addAll([
      _fullNameController,
      _phoneNumberController,
      _ageController,
      _emailController,
      _cityController,
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isVoiceSystemEnabled) {
        _speakAndListen();
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() { _selectedIndex = index; });
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
        Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) => BookmarksPage(isVoiceSystemEnabled: _isVoiceSystemEnabled)));
        break;
      case 3:
        break;
    }
  }

  Future<void> _initializeSTT() async {
    bool available = await _speechToText.initialize(
      onError: (error) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error.errorMsg}')),
        );
      },
    );

    _speechToText.statusListener = (status) {
      if (status == 'done') {
        setState(() => _isListening = false);
        _moveToNextField();
      }
    };

    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
    }
  }

  Future<void> _fetchCVData() async {
    if (_userId == null) return;

    try {
      DocumentSnapshot snapshot =
          await _firestore.collection('applicant_cv').doc(_userId).get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _fullNameController.text = data['fullName'] ?? '';
          _phoneNumberController.text = data['phoneNumber'] ?? '';
          _ageController.text = data['age'] ?? '';
          _emailController.text = data['email'] ?? '';
          _cityController.text = data['city'] ?? '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching CV data: ${e.toString()}')),
      );
    }
  }

  Future<void> _speakAndListen() async {
    if (_fieldsCompleted || _isConfirmingSave) return;
    if (_currentFieldIndex >= _controllers.length) return;

    String getHintText(int index) {
      switch (index) {
        case 0:
          return "Please spaell your first name";
        case 1: return "Please enter your phone number";
        case 2: return "Please enter your age";
        case 3: return "Please enter your email address";
        case 4: return "Please spell your city";
        default: return "";
      }
    }

    String hintText = getHintText(_currentFieldIndex);
    await _flutterTts.speak(hintText);
    await Future.delayed(const Duration(seconds: 3));
    _startListening(_controllers[_currentFieldIndex]);
  }

  Future<void> _startListening(TextEditingController controller) async {
    if (!_isListening && await _speechToText.hasPermission) {
      setState(() => _isListening = true);

      await _speechToText.listen(
        onResult: (result) async {
          String recognizedWords = result.recognizedWords.trim().replaceAll(" ", "");

          if (recognizedWords.isNotEmpty) {
            if (_isConfirmingSave) {
              _speechToText.stop();
              setState(() => _isListening = false);
              return;
            }
            setState(() { controller.text = recognizedWords; });
            _speechToText.stop();
            setState(() => _isListening = false);
            _moveToNextField();
          } else if (!_speechToText.isListening) {
            if (_fieldsCompleted || _isConfirmingSave) {
              _speechToText.stop();
              setState(() => _isListening = false);
              return;
            }
            await _flutterTts.speak("I couldn't understand you. Please repeat.");
            await Future.delayed(const Duration(seconds: 10));
            _startListening(controller);
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 12),
        listenOptions: stt.SpeechListenOptions(partialResults: false),
      );

      _speechToText.errorListener = (error) async {
        if (_fieldsCompleted || _isConfirmingSave) {
          _speechToText.stop();
          setState(() => _isListening = false);
          return;
        }
        setState(() => _isListening = false);
        await _flutterTts.speak("There was an error. Please try again.");
        await Future.delayed(const Duration(seconds: 10));
        _startListening(controller);
      };
    }
  }

  void _moveToNextField() {
    if (_currentFieldIndex < _controllers.length &&
        _controllers[_currentFieldIndex].text.trim().isEmpty) {
      _flutterTts.speak("The input is empty. Please provide a valid response.");
      if (_isVoiceSystemEnabled) { _speakAndListen(); }
      return;
    }

    _currentFieldIndex++;

    if (_currentFieldIndex >= _controllers.length && !_fieldsCompleted) {
      _fieldsCompleted = true;
      _speechToText.stop();
      setState(() {
        _isListening = false;
        _isConfirmingSave = true;
      });
      _flutterTts.speak("You have completed all fields. Let's review them.").then((_) {
        _reviewAllFields();
      });
    } else if (_currentFieldIndex < _controllers.length) {
      if (_isVoiceSystemEnabled) { _speakAndListen(); }
    }
  }

  Future<void> _selectFile() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx']);
    if (result != null) {
      setState(() { _selectedFile = File(result.files.single.path!); });
      _uploadFile();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected')),
      );
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = _storage.ref().child('uploads/$fileName');
      UploadTask uploadTask = storageRef.putFile(_selectedFile!);
      TaskSnapshot snapshot = await uploadTask;
      final fileURL = await snapshot.ref.getDownloadURL();
      setState(() { _uploadedFileURL = fileURL; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File uploaded successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading file: ${e.toString()}')),
      );
    }
  }

  Future<void> _reviewAllFields() async {
    _isConfirmingSave = true;
    _isListening = false;

    for (int i = 0; i < _controllers.length; i++) {
      String fieldName = _getFieldLabel(i);
      String fieldValue = _controllers[i].text.isEmpty ? "Not provided" : _controllers[i].text;
      await _flutterTts.speak("$fieldName: $fieldValue.");
      await Future.delayed(const Duration(seconds: 3));
    }

    await _flutterTts.speak(
        "If you want to edit any field say the field name. If you don't want to edit, say 'no'. To go back, say 'back'.");
    await Future.delayed(const Duration(seconds: 10));

    _listenForEditOrConfirm();
  }

  String _getFieldLabel(int index) {
    switch (index) {
      case 0: return "name";
      case 1: return "phone number";
      case 2: return "age";
      case 3: return "email";
      case 4: return "city";
      default: return "";
    }
  }

  Future<void> _startListeningForFieldEdit(
      TextEditingController controller, String fieldName) async {
    if (!_isListening && await _speechToText.hasPermission) {
      setState(() => _isListening = true);
      try {
        await _speechToText.listen(
          onResult: (result) async {
            String recognizedWords = result.recognizedWords.trim().replaceAll(" ", "");
            if (recognizedWords.isNotEmpty) {
              setState(() { controller.text = recognizedWords; });
              await _flutterTts.speak("$fieldName updated successfully.");
              _speechToText.stop();
              setState(() => _isListening = false);
              _isConfirmingSave = false;
              await _reviewAllFields();
            } else {
              await _flutterTts.speak(
                  "I couldn't understand you. Please repeat the new value for $fieldName.");
              await Future.delayed(const Duration(seconds: 4));
              _startListeningForFieldEdit(controller, fieldName);
            }
          },
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 12),
          listenOptions: stt.SpeechListenOptions(partialResults: false),
        );

        _speechToText.errorListener = (error) async {
          print("STT Error: $error");
          await _flutterTts.speak("There was an error. Please try again.");
          await Future.delayed(const Duration(seconds: 4));
          _startListeningForFieldEdit(controller, fieldName);
        };
      } catch (e) {
        print("Error in STT: $e");
        await _flutterTts.speak("An unexpected error occurred. Please try again.");
        setState(() => _isListening = false);
      }
    }
  }

  Future<void> _listenForEditOrConfirm() async {
    if (!_isListening && await _speechToText.hasPermission) {
      setState(() => _isListening = true);
      try {
        await _speechToText.listen(
          onResult: (result) async {
            String userResponse = result.recognizedWords.toLowerCase().trim();

            if (userResponse.contains("confirm") || userResponse.contains("no")) {
              await _flutterTts.speak("Your data has been confirmed.");
              _speechToText.stop();
              setState(() { _isListening = false; _isConfirmingSave = false; });
              _saveCVData();
            } else if (userResponse.contains("back")) {
              await _flutterTts.speak("Navigating back to the previous page.");
              _speechToText.stop();
              setState(() => _isListening = false);
              Navigator.pop(context);
            } else {
              int? fieldIndex = _getFieldIndexFromName(userResponse);
              if (fieldIndex != null) {
                String fieldName = _getFieldLabel(fieldIndex);
                await _flutterTts.speak("Please provide the new value for $fieldName.");
                await Future.delayed(const Duration(seconds: 3));
                _startListeningForFieldEdit(_controllers[fieldIndex], fieldName);
              } else {
                await _flutterTts.speak("I did not understand. Please try again.");
                await Future.delayed(const Duration(seconds: 5));
                _listenForEditOrConfirm();
              }
            }
          },
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 12),
          listenOptions: stt.SpeechListenOptions(partialResults: true),
        );

        _speechToText.errorListener = (error) async {
          print("STT Error: $error");
          await _flutterTts.speak("There was an error. Please try again.");
          await Future.delayed(const Duration(seconds: 5));
          if (!_isListening) {
            setState(() => _isListening = false);
            _listenForEditOrConfirm();
          }
        };
      } catch (e) {
        print("Error in STT: $e");
        await _flutterTts.speak("An unexpected error occurred. Please try again.");
        setState(() => _isListening = false);
      }
    }
  }

  int? _getFieldIndexFromName(String fieldName) {
    fieldName = fieldName.toLowerCase().trim();
    switch (fieldName) {
      case "name": case "full name": return 0;
      case "phone number": case "phone": return 1;
      case "age": case "old": return 2;
      case "email": case "email address": return 3;
      case "city": case "country": return 4;
      default: return null;
    }
  }

  Future<void> _listenForSaveConfirmation() async {
    if (!_isListening && _isConfirmingSave && await _speechToText.hasPermission) {
      setState(() => _isListening = true);

      await _speechToText.listen(
        onResult: (result) async {
          String userResponse = result.recognizedWords.toLowerCase().trim();

          if (userResponse.contains("yes")) {
            await _flutterTts.speak("Your CV has been saved now.");
            _speechToText.stop();
            setState(() {
              _isListening = false;
              _isConfirmingSave = false;
              _fieldsCompleted = false;
            });
            _saveCVData();
          } else if (userResponse.contains("no")) {
            await _flutterTts.speak("You chose to leave the CV as is.");
            _speechToText.stop();
            setState(() {
              _isListening = false;
              _isConfirmingSave = false;
              _fieldsCompleted = false;
            });
          } else {
            await _handleInvalidResponse();
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 13),
        listenOptions: stt.SpeechListenOptions(partialResults: true),
      );

      _speechToText.errorListener = (error) async {
        await _handleInvalidResponse();
      };
    }
  }

  Future<void> _handleInvalidResponse() async {
    _speechToText.stop();
    setState(() => _isListening = false);
    if (_isConfirmingSave) {
      await _flutterTts.speak("I did not understand. Please say 'yes' or 'no'.");
      await Future.delayed(const Duration(seconds: 12));
      _listenForSaveConfirmation();
    }
  }

  Future<void> _saveCVData() async {
    print("Saving CV...");

    try {
      DocumentSnapshot snapshot =
          await _firestore.collection('applicant_cv').doc(_userId).get();

      if (snapshot.exists) {
        print("Updating existing CV.");
        await _firestore.collection('applicant_cv').doc(_userId).update({
          'fullName': _fullNameController.text.trim(),
          'phoneNumber': _phoneNumberController.text.trim(),
          'age': _ageController.text.trim(),
          'city': _cityController.text.trim(),
          'email': _emailController.text.trim(),
          'uploadedFileURL': _uploadedFileURL,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await _flutterTts.speak("Your CV has been updated successfully.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CV updated successfully.')),
        );
      } else {
        print("Creating new CV.");
        await _firestore.collection('applicant_cv').doc(_userId).set({
          'fullName': _fullNameController.text.trim(),
          'phoneNumber': _phoneNumberController.text.trim(),
          'age': _ageController.text.trim(),
          'city': _cityController.text.trim(),
          'email': _emailController.text.trim(),
          'uploadedFileURL': _uploadedFileURL,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _flutterTts.speak("Your CV has been saved successfully.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CV saved successfully.')),
        );
      }

      setState(() {
        _fieldsCompleted = false;
        _isConfirmingSave = false;
      });
    } catch (e) {
      print("Error saving CV: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving CV data: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: DrawerPage(),
      backgroundColor: const Color(0xFF244855),
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
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () { Navigator.pop(context); },
                      ),
                      Builder(
                        builder: (context) {
                          return IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white),
                            onPressed: () { Scaffold.of(context).openEndDrawer(); },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.transparent,
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Colors.grey, Colors.grey],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                        const Icon(Icons.person, size: 60, color: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _selectFile,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Upload CV File'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              _buildTextField(_fullNameController, Icons.person, 'Full Name'),
              const SizedBox(height: 20),
              _buildTextField(_phoneNumberController, Icons.phone, 'Phone Number'),
              const SizedBox(height: 20),
              _buildTextField(_ageController, Icons.calendar_today, 'Age'),
              const SizedBox(height: 20),
              _buildTextField(_emailController, Icons.email, 'Email'),
              const SizedBox(height: 20),
              _buildTextField(_cityController, Icons.location_city, 'City'),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveCVData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFe64833),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  child: const Text('Save CV'),
                ),
              ),
            ],
          ),
        ),
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

Widget _buildTextField(
    TextEditingController controller, IconData icon, String hint,
    [bool readOnly = false, VoidCallback? onTap]) {
  return TextFormField(
    controller: controller,
    readOnly: readOnly,
    onTap: onTap,
    decoration: InputDecoration(
      prefixIcon: Icon(icon),
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0)),
    ),
  );
}
