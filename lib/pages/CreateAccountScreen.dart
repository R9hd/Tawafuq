
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:io';
import 'package:tawafuq/pages/AdminHome.dart';
import 'package:tawafuq/pages/ApplicantCVScreen.dart';
import 'package:tawafuq/pages/LicenseUploadScreen.dart';

class CreateAccountScreen extends StatefulWidget {
  final String role;
  final bool isVoiceSystemEnabled;

  const CreateAccountScreen({super.key, required this.role, required this.isVoiceSystemEnabled});

  @override
  _CreateAccountScreenState createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  late String _selectedRole;
  late bool _isVoiceSystemEnabled = true;

  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  String? _licenseFileURL;
  String _isDisabled = 'No';

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.role;

    if (_selectedRole == 'Job Seeker' && widget.isVoiceSystemEnabled) {
      _isVoiceSystemEnabled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _guideUserToFillForm();
      });
    } else {
      _isVoiceSystemEnabled = false;
    }
  }

  Future<void> _guideUserToFillForm() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak("Welcome to the account creation page.");
    _listenForFullName();
  }

  void _listenForFullName() async {
    await _speech.stop();
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      await _flutterTts.speak("Please say your full name.");
      await Future.delayed(const Duration(seconds: 1));
      _speech.listen(
        onResult: (result) async {
          String recognizedText = result.recognizedWords.replaceAll(" ", "");
          if (recognizedText.isEmpty) {
            await _flutterTts.speak("I didn't catch that. Please try again.");
            await Future.delayed(const Duration(seconds: 1));
            _listenForFullName();
            return;
          }
          _fullNameController.text = recognizedText;
          print("Full Name: ${_fullNameController.text}");
          await _flutterTts.speak("You said: ${_fullNameController.text}. ");
          await Future.delayed(const Duration(seconds: 1));
          await _speech.stop();
          _listenForLastName();
        },
        listenFor: const Duration(seconds: 60),
        partialResults: false,
      );
    } else {
      print("Speech recognition not available for full name.");
    }
  }

  void _listenForLastName() async {
    await _speech.stop();
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      await _flutterTts.speak("Please say your last name.");
      await Future.delayed(const Duration(seconds: 1));
      _speech.listen(
        onResult: (result) async {
          String recognizedText = result.recognizedWords.replaceAll(" ", "");
          if (recognizedText.isEmpty) {
            await _flutterTts.speak("I didn't catch that. Please try again.");
            await Future.delayed(const Duration(seconds: 1));
            _listenForLastName();
            return;
          }
          _lastNameController.text = recognizedText;
          print("Last Name: ${_lastNameController.text}");
          await _flutterTts.speak("You said: ${_lastNameController.text}. ");
          await Future.delayed(const Duration(seconds: 1));
          await _speech.stop();
          _listenForEmail();
        },
        listenFor: const Duration(seconds: 60),
        partialResults: false,
      );
    } else {
      print("Speech recognition not available for last name.");
    }
  }

  void _listenForPassword() async {
    await _speech.stop();
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      await _flutterTts.speak(
          "Please say your password. For special characters, say exclamation mark or underscore.");
      await Future.delayed(const Duration(seconds: 1));
      _speech.listen(
        onResult: (result) async {
          String recognizedText = result.recognizedWords
              .toLowerCase()
              .replaceAll("exclamationmark", "!")
              .replaceAll("exclamation mark", "!")
              .replaceAll("underscore", "_")
              .replaceAll("one", "1")
              .replaceAll("two", "2")
              .replaceAll("three", "3")
              .replaceAll("four", "4")
              .replaceAll("for", "4")
              .replaceAll("five", "5")
              .replaceAll("six", "6")
              .replaceAll("seven", "7")
              .replaceAll("eight", "8")
              .replaceAll("nine", "9")
              .replaceAll("zero", "0")
              .replaceAll("-", "")
              .replaceAll(" ", "");
          if (recognizedText.isEmpty) {
            await _flutterTts.speak("I didn't catch that. Please try again.");
            await Future.delayed(const Duration(seconds: 1));
            _listenForPassword();
            return;
          }
          _passwordController.text = recognizedText;
          print("Password set");

          await _flutterTts.speak("You said: ${_passwordController.text}. ");
          await Future.delayed(const Duration(seconds: 1));
          await _speech.stop();
          _listenForConfirmPassword();
        },
        listenFor: const Duration(seconds: 60),
        partialResults: false,
      );
    } else {
      print("Speech recognition not available for password.");
    }
  }

  void _listenForEmail() async {
    await _speech.stop();
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      await _flutterTts.speak(
          "Please spell out your email address, one character at a time, or say it fully.");
      await Future.delayed(const Duration(seconds: 1));
      _speech.listen(
        onResult: (result) async {
          String recognizedText = result.recognizedWords
              .toLowerCase()
              .replaceAll("at", "@")
              .replaceAll(" dot ", ".")
              .replaceAll(" ", "");
          if (recognizedText.isEmpty) {
            await _flutterTts.speak("I didn't catch that. Please try again.");
            await Future.delayed(const Duration(seconds: 1));
            _listenForEmail();
            return;
          }
          _emailController.text = recognizedText;
          print("Email: ${_emailController.text}");
          await _flutterTts.speak("You said: ${_emailController.text}. ");
          await Future.delayed(const Duration(seconds: 1));
          await _speech.stop();
          _listenForPassword();
        },
        listenFor: const Duration(seconds: 60),
        partialResults: false,
      );
    } else {
      print("Speech recognition not available for email.");
    }
  }

  void _listenForConfirmPassword() async {
    await _speech.stop();
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      await _flutterTts.speak("Please confirm your password.");
      await Future.delayed(const Duration(seconds: 1));
      _speech.listen(
        onResult: (result) async {
          String recognizedText = result.recognizedWords
              .toLowerCase()
              .replaceAll("exclamationmark", "!")
              .replaceAll("exclamation mark", "!")
              .replaceAll("underscore", "_")
              .replaceAll("one", "1")
              .replaceAll("two", "2")
              .replaceAll("three", "3")
              .replaceAll("four", "4")
              .replaceAll("for", "4")
              .replaceAll("five", "5")
              .replaceAll("six", "6")
              .replaceAll("seven", "7")
              .replaceAll("eight", "8")
              .replaceAll("nine", "9")
              .replaceAll("zero", "0")
              .replaceAll("-", "")
              .replaceAll(" ", "");

          if (recognizedText.isEmpty) {
            await _flutterTts.speak("I didn't catch that. Please try again.");
            await Future.delayed(const Duration(seconds: 1));
            _listenForConfirmPassword();
            return;
          }

          _confirmPasswordController.text = recognizedText;
          print("Confirmed Password set");

          if (_confirmPasswordController.text != _passwordController.text) {
            await _flutterTts.speak("The passwords do not match. Please try again.");
            await Future.delayed(const Duration(seconds: 1));
            _listenForConfirmPassword();
            return;
          }

          await _flutterTts.speak("Passwords match.");
          await Future.delayed(const Duration(seconds: 1));
          await _speech.stop();
          _listenForPhoneNumber();
        },
        listenFor: const Duration(seconds: 60),
        partialResults: false,
      );
    } else {
      print("Speech recognition not available for confirm password.");
    }
  }

  void _listenForPhoneNumber() async {
    await _speech.stop();
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      await _flutterTts.speak("Please say your phone number, digit by digit.");
      await Future.delayed(const Duration(seconds: 1));
      _speech.listen(
        onResult: (result) async {
          String recognizedText = result.recognizedWords
              .toLowerCase()
              .replaceAll("one", "1").replaceAll("two", "2")
              .replaceAll("three", "3").replaceAll("four", "4")
              .replaceAll("for", "4").replaceAll("five", "5")
              .replaceAll("six", "6").replaceAll("seven", "7")
              .replaceAll("eight", "8").replaceAll("nine", "9")
              .replaceAll("zero", "0").replaceAll("-", "")
              .replaceAll(" ", "");
          if (recognizedText.isEmpty) {
            await _flutterTts.speak("I didn't catch that. Please try again.");
            await Future.delayed(const Duration(seconds: 1));
            _listenForPhoneNumber();
            return;
          }
          _phoneNumberController.text = recognizedText;
          print("Phone Number: ${_phoneNumberController.text}");
          await Future.delayed(const Duration(seconds: 1));
          await _speech.stop();
          _listenForDisabilityStatus();
        },
        listenFor: const Duration(seconds: 60),
        partialResults: false,
      );
    } else {
      print("Speech recognition not available for phone number.");
    }
  }

  void _listenForDisabilityStatus() async {
    await _speech.stop();
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      await _flutterTts.speak("Do you have a disability? Please say Yes or No.");
      await Future.delayed(const Duration(seconds: 1));
      _speech.listen(
        onResult: (result) async {
          String recognizedText = result.recognizedWords.toLowerCase().trim();
          if (recognizedText.isEmpty ||
              (!recognizedText.contains("yes") && !recognizedText.contains("no"))) {
            await _flutterTts.speak("I didn't catch that. Please say Yes or No.");
            await Future.delayed(const Duration(seconds: 1));
            _listenForDisabilityStatus();
            return;
          }
          _isDisabled = recognizedText.contains("yes") ? "Yes" : "No";
          print("Disability Status: $_isDisabled");
          await _flutterTts.speak("You said: $_isDisabled. If this is correct, we will proceed.");
          await Future.delayed(const Duration(seconds: 1));
          await _speech.stop();
          await _createAccount(context);
        },
        listenFor: const Duration(seconds: 60),
        partialResults: false,
      );
    } else {
      print("Speech recognition not available for disability status.");
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneNumberController.dispose();
    _companyNameController.dispose();
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  Future<void> _createAccount(BuildContext context) async {
    final fullName = _fullNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final phoneNumber = _phoneNumberController.text.trim();

    if (fullName.isEmpty || lastName.isEmpty || email.isEmpty ||
        password.isEmpty || confirmPassword.isEmpty || phoneNumber.isEmpty) {
      Fluttertoast.showToast(
        msg: "All fields must be filled",
        backgroundColor: Colors.red, textColor: Colors.white,
        gravity: ToastGravity.TOP, toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 3, fontSize: 16,
      );
      return;
    }

    if (password != confirmPassword) {
      Fluttertoast.showToast(
        msg: "Passwords do not match",
        backgroundColor: Colors.red, textColor: Colors.white,
        gravity: ToastGravity.TOP, toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 3, fontSize: 16,
      );
      return;
    }

    if (password.length < 8) {
      Fluttertoast.showToast(
        msg: "Password must be at least 8 characters long",
        backgroundColor: Colors.red, textColor: Colors.white,
        gravity: ToastGravity.TOP, toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 3, fontSize: 16,
      );
      return;
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );

      String? userId = userCredential.user?.uid;

      if (_selectedRole == 'Recruiter') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LicenseUploadScreen(
              userId: userId!, fullName: fullName, lastName: lastName,
              email: email, phoneNumber: phoneNumber,
              companyName: _companyNameController.text.trim(),
            ),
          ),
        );
        return;
      }

      DateTime now = DateTime.now();
      String formattedMonth = DateFormat('MMMM').format(now);

      await _firestore.collection('users').doc(userId).set({
        'fullName': fullName, 'lastName': lastName, 'email': email,
        'phoneNumber': phoneNumber, 'role': _selectedRole, 'id': userId,
        'companyName': _selectedRole == 'Recruiter'
            ? _companyNameController.text.trim() : null,
        'licenseUrl': _licenseFileURL,
        'licenseChecked': false, 'companyApproved': false,
        'joining month': formattedMonth, 'disabilityStatus': _isDisabled,
      });

      Fluttertoast.showToast(
        msg: "Account created successfully. Please wait for admin approval.",
        backgroundColor: Colors.green, textColor: Colors.white,
        gravity: ToastGravity.TOP, toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 3, fontSize: 16,
      );

      if (_selectedRole == 'Job Seeker') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ApplicantCVScreen(isVoiceSystemEnabled: _isVoiceSystemEnabled),
          ),
        );
      } else if (_selectedRole == 'Admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Adminhome()),
        );
      }
    } catch (e) {
      String errorMessage;
      if (e is FirebaseAuthException) {
        if (e.code == 'weak-password') {
          errorMessage = "Password should be at least 6 characters.";
        } else if (e.code == 'email-already-in-use') {
          errorMessage = "The email address is already in use.";
        } else if (e.code == 'invalid-email') {
          errorMessage = "The email address is invalid.";
        } else {
          errorMessage = e.message ?? "An unknown error occurred.";
        }
      } else {
        errorMessage = "An unknown error occurred.";
      }
      Fluttertoast.showToast(
        msg: "Error: $errorMessage",
        backgroundColor: Colors.red, textColor: Colors.white,
        gravity: ToastGravity.TOP, toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 3, fontSize: 16,
      );
    }
  }

  Future<void> _uploadLicenseFile(String? userId) async {
    if (userId == null) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null) {
      try {
        final file = File(result.files.single.path!);
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final storageRef = _storage.ref().child('licenses/$userId/$fileName');
        UploadTask uploadTask = storageRef.putFile(file);
        TaskSnapshot snapshot = await uploadTask;
        final fileURL = await snapshot.ref.getDownloadURL();
        setState(() { _licenseFileURL = fileURL; });
        Fluttertoast.showToast(msg: "License uploaded successfully",
            backgroundColor: Colors.green, textColor: Colors.white,
            gravity: ToastGravity.TOP, toastLength: Toast.LENGTH_SHORT,
            timeInSecForIosWeb: 3, fontSize: 16);
      } catch (e) {
        Fluttertoast.showToast(msg: "Error uploading license: ${e.toString()}",
            backgroundColor: Colors.red, textColor: Colors.white,
            gravity: ToastGravity.TOP, toastLength: Toast.LENGTH_SHORT,
            timeInSecForIosWeb: 3, fontSize: 16);
      }
    } else {
      Fluttertoast.showToast(msg: "No license file selected",
          backgroundColor: Colors.red, textColor: Colors.white,
          gravity: ToastGravity.TOP, toastLength: Toast.LENGTH_SHORT,
          timeInSecForIosWeb: 3, fontSize: 16);
    }
  }

  void _toggleVoiceSystem() {
    if (_selectedRole != 'Job Seeker') {
      Fluttertoast.showToast(
        msg: "Voice system is available only for Job Seekers.",
        backgroundColor: Colors.orange, textColor: Colors.white,
        gravity: ToastGravity.TOP, toastLength: Toast.LENGTH_SHORT, fontSize: 16,
      );
      return;
    }
    setState(() {
      _isVoiceSystemEnabled = !_isVoiceSystemEnabled;
      if (!_isVoiceSystemEnabled) {
        print("Voice system turned off.");
        _flutterTts.stop(); _speech.stop();
      } else {
        print("Voice system turned on.");
        _guideUserToFillForm();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
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
                    ],
                  ),
                ),
              ),
              const Text(
                'CREATE YOUR \nACCOUNT',
                textAlign: TextAlign.left,
                style: TextStyle(color: Colors.white, fontSize: 40),
              ),
              const SizedBox(height: 20),
              _buildTextField(controller: _fullNameController, icon: Icons.person, hintText: 'First Name'),
              const SizedBox(height: 20),
              _buildTextField(controller: _lastNameController, icon: Icons.person_outline, hintText: 'Last Name'),
              const SizedBox(height: 20),
              _buildTextField(controller: _emailController, icon: Icons.email, hintText: 'Email'),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  filled: true, fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.lock, color: Color(0xFF143850)),
                  hintText: 'Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: const Color(0xFF143850)),
                    onPressed: () { setState(() { _isPasswordVisible = !_isPasswordVisible; }); },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  filled: true, fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF143850)),
                  hintText: 'Confirm Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off, color: const Color(0xFF143850)),
                    onPressed: () { setState(() { _isConfirmPasswordVisible = !_isConfirmPasswordVisible; }); },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(controller: _phoneNumberController, icon: Icons.phone, hintText: 'Phone Number'),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.only(left: 10.0, bottom: 5.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Disability Status', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              DropdownButtonFormField<String>(
                value: _isDisabled,
                items: ['No', 'Yes'].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) { setState(() { _isDisabled = newValue!; }); },
                decoration: InputDecoration(
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0)),
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () { _createAccount(context); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFe64833),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  child: Text('Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF143850)),
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0)),
      ),
    );
  }
}
