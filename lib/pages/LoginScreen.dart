
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:tawafuq/MyButton';
import 'package:tawafuq/auth_services.dart';
import 'package:tawafuq/pages/AdminHome.dart';
import 'package:tawafuq/pages/ApplicantCVScreen.dart';
import 'dart:async';

import 'package:tawafuq/pages/CreateAccountScreen.dart';
import 'package:tawafuq/pages/JobSeekerHome.dart';
import 'package:tawafuq/pages/MyTextField.dart';
import 'package:tawafuq/pages/RecruiterStatusPage.dart';
import 'package:tawafuq/pages/bars&drawers/DrawerPage.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  final bool isVoiceSystemEnabled;

  const LoginScreen({super.key, required this.role, required this.isVoiceSystemEnabled});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final Color secondary = const Color(0xFFe64833);

  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  final bool _isPasswordVisible = false;
  late bool _isVoiceSystemEnabled;

  @override
  void initState() {
    super.initState();
    _isVoiceSystemEnabled = widget.isVoiceSystemEnabled;

    if (widget.role == 'Job Seeker' && _isVoiceSystemEnabled) {
      _askLoginOrSignup();
    } else {
      _isVoiceSystemEnabled = false;
    }
  }

  Future<void> _askLoginOrSignup() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak(
        "Do you want to log in or create an account? Please say 'log in' or 'create an account'.");
    _flutterTts.setCompletionHandler(() {
      _startListeningForChoice();
    });
  }

  void _startListeningForChoice() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print("Speech status: $status"),
      onError: (error) => print("Speech error: $error"),
    );

    if (available) {
      setState(() => _isListening = true);

      Timer? silenceTimer;

      _speech.listen(
        onResult: (result) {
          String recognizedText = result.recognizedWords.toLowerCase();
          print("Recognized text: $recognizedText");

          silenceTimer?.cancel();

          if (recognizedText.contains("login")) {
            _speech.stop();
            _flutterTts.speak("Okay, let's log in.");
            _flutterTts.setCompletionHandler(() {
              _listenForEmail();
            });
          } else if (recognizedText.contains("create an account")) {
            _speech.stop();
            _flutterTts.speak("Alright, let's create an account.");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateAccountScreen(
                  role: widget.role,
                  isVoiceSystemEnabled: available,
                ),
              ),
            );
          } else {
            print("Unrecognized response.");
            _speech.stop();
            _flutterTts.speak(
                "I didn't catch that. Do you want to log in or create an account?");
            _flutterTts.setCompletionHandler(() {
              _startListeningForChoice();
            });
          }
        },
        listenFor: const Duration(seconds: 10),
        listenOptions: stt.SpeechListenOptions(partialResults: false),
      );

      silenceTimer = Timer(const Duration(seconds: 10), () {
        print("No response detected.");
        _speech.stop();
        _flutterTts.speak(
            "I didn't hear anything. Do you want to log in or create an account?");
        _flutterTts.setCompletionHandler(() {
          _startListeningForChoice();
        });
      });
    } else {
      print("Speech recognition not available");
    }
  }

  void _listenForEmail() async {
    await _speech.stop();
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      await _flutterTts.speak(
          "Please spell out your email address, one character at a time, or say it fully.");
      _flutterTts.setCompletionHandler(() {
        _speech.listen(
          onResult: (result) async {
            String recognizedText = result.recognizedWords.toLowerCase();
            print("Recognized email: $recognizedText");

            recognizedText = recognizedText
                .replaceAll(" at ", "@")
                .replaceAll(" dot ", ".")
                .replaceAll(" ", "");

            _emailController.text = recognizedText;
            print("Email: ${_emailController.text}");

            await _speech.stop();
            await _flutterTts.speak("Email received: ${_emailController.text}. Now, ");
            _flutterTts.setCompletionHandler(() {
              _listenForPassword();
            });
          },
          listenFor: const Duration(seconds: 60),
          listenOptions: stt.SpeechListenOptions(partialResults: false),
        );
      });
    } else {
      print("Speech recognition not available for email.");
    }
  }

  void _listenForPassword() async {
    await _speech.stop();
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      await _flutterTts.speak(
          "Please say your password. For special characters, say exclamation mark, or underscore.");
      _flutterTts.setCompletionHandler(() {
        _speech.listen(
          onResult: (result) async {
            String recognizedText = result.recognizedWords.toLowerCase();
            print("Recognized password: $recognizedText");

            recognizedText = recognizedText
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

            _passwordController.text = recognizedText;
            print("Password set");

            await _speech.stop();
            await _flutterTts.speak("Password received. Logging you in now.");
            _flutterTts.setCompletionHandler(() {
              _signin();
            });
          },
          listenFor: const Duration(seconds: 60),
          listenOptions: stt.SpeechListenOptions(partialResults: false),
        );
      });
    } else {
      print("Speech recognition not available for password.");
    }
  }

  final AuthServices _auth = AuthServices();

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _emailforresetController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _emailController.dispose();
    _emailforresetController.dispose();
    super.dispose();
  }

  void _signin() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(
        msg: "All Fields Should be Filled",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        gravity: ToastGravity.TOP,
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 3,
        fontSize: 16,
      );
      return;
    }

    try {
      User? user = await _auth.signinWithEmailandPass(email, password);
      if (user != null) {

        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final role = doc.data()?['role'];

        if (role == 'Admin') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Adminhome()),
            (route) => false,
          );
        } else if (role == 'Recruiter') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const RecruiterStatusPage()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => JobSeekerHome(
                  applicantName: '', isVoiceSystemEnabled: _isVoiceSystemEnabled),
            ),
            (route) => false,
          );
        }

        Fluttertoast.showToast(
          msg: "Logged in Succussfully",
          backgroundColor: Colors.green,
          textColor: Colors.white,
          gravity: ToastGravity.TOP,
          toastLength: Toast.LENGTH_SHORT,
          timeInSecForIosWeb: 3,
          fontSize: 16,
        );
      } else {
        Fluttertoast.showToast(
          msg: "Email or Password is Incorrect",
          backgroundColor: Colors.red,
          textColor: Colors.white,
          gravity: ToastGravity.TOP,
          toastLength: Toast.LENGTH_SHORT,
          timeInSecForIosWeb: 3,
          fontSize: 16,
        );
        return;
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "An Error Occurred",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        gravity: ToastGravity.TOP,
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 3,
        fontSize: 16,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor = Theme.of(context).colorScheme.primary;
    Color secondary = Theme.of(context).colorScheme.secondary;
    Color tertiary = Theme.of(context).colorScheme.tertiary;
    Color inversePrimary = Theme.of(context).colorScheme.inversePrimary;

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Image.asset(
                "lib/images/researcher.png",
                height: screenHeight * 0.30,
                width: screenWidth * 0.50,
                fit: BoxFit.contain,
              ),
              Text(
                "مرحبا بك",
                style: TextStyle(
                  color: inversePrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.025),
              MyTextField(
                controller: _emailController,
                hintText: 'الإيميل',
                obscureText: false,
              ),
              SizedBox(height: screenHeight * 0.020),
              MyTextField(
                controller: _passwordController,
                hintText: 'كلمة المرور',
                obscureText: true,
              ),
              SizedBox(height: screenHeight * 0.010),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.075),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              title: const Center(
                                child: Text(
                                  "ادخل بريدك الجامعي",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              content: TextField(
                                controller: _emailforresetController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: "البريد الجامعي",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              actions: <Widget>[
                                Center(
                                  child: TextButton(
                                    onPressed: () async {
                                      if (_emailforresetController.text.isNotEmpty) {
                                        bool isValidEmail =
                                            await checkEmailInCollections(
                                                _emailforresetController.text);
                                        if (isValidEmail == false) {
                                          Fluttertoast.showToast(
                                            msg: "البريد الجامعي غير صحيح",
                                            backgroundColor: Colors.red,
                                            textColor: Colors.white,
                                            gravity: ToastGravity.TOP,
                                            toastLength: Toast.LENGTH_SHORT,
                                            timeInSecForIosWeb: 3,
                                            fontSize: 16,
                                          );
                                          return;
                                        }

                                        try {
                                          await FirebaseAuth.instance
                                              .sendPasswordResetEmail(
                                                  email: _emailforresetController.text);
                                          Navigator.of(context).pop();
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20.0),
                                                ),
                                                title: const Center(
                                                  child: Text(
                                                    "تم ارسال رابط تحديث كلمة المرور الى بريدك الجامعي",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 18.0,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                actions: <Widget>[
                                                  Center(
                                                    child: TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                      },
                                                      child: const Text(
                                                        "حسناً",
                                                        style: TextStyle(
                                                          fontSize: 16.0,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        } catch (e) {
                                          Navigator.of(context).pop();
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20.0),
                                                ),
                                                title: const Center(
                                                  child: Text(
                                                    "حدث خطأ، الرجاء المحاولة مرة أخرى",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 18.0,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                actions: <Widget>[
                                                  Center(
                                                    child: TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                      },
                                                      child: const Text(
                                                        "حسناً",
                                                        style: TextStyle(
                                                          fontSize: 16.0,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        }
                                      }
                                    },
                                    child: const Text(
                                      "إرسال",
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Text(
                        "نسيت كلمة المرور؟",
                        style: TextStyle(
                          color: secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.020),
              MyButton(buttonTitle: "تسجيل الدخول", onTap: _signin),
              SizedBox(height: screenHeight * 0.035),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(thickness: 0.5, color: secondary),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.10),
                      child: Text(
                        'مستخدم جديد؟',
                        style: TextStyle(color: secondary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Divider(thickness: 0.75, color: secondary),
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.025),

            ],
          ),
        ),
      ),
    );
  }

  Future<bool> checkEmailInCollections(String email) async {
    final usersCollection = FirebaseFirestore.instance.collection('users');

    final snapshot = await usersCollection
        .where('email', isEqualTo: email.toLowerCase())
        .get();

    return snapshot.docs.isNotEmpty;
  }
}
