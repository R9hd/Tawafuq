
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signupWithEmailandPass(String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == "email-already-in-use") {
        Fluttertoast.showToast(
          msg: "The email is already used",
          backgroundColor: Colors.red,
          textColor: Colors.white,
          gravity: ToastGravity.TOP,
          toastLength: Toast.LENGTH_SHORT,
          timeInSecForIosWeb: 3,
          fontSize: 16,
        );
      } else {
        Fluttertoast.showToast(
          msg: "An Error Occurred : ${e.code}",
          backgroundColor: Colors.red,
          textColor: Colors.white,
          gravity: ToastGravity.TOP,
          toastLength: Toast.LENGTH_SHORT,
          timeInSecForIosWeb: 3,
          fontSize: 16,
        );
      }
    }
    return null;
  }

  Future<User?> signinWithEmailandPass(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(
        msg: "An Error Occurred : ${e.code}",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        gravity: ToastGravity.TOP,
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 3,
        fontSize: 16,
      );
      print("An Error Occurred");
    }
    return null;
  }

  Future<void> signOut() async => await _auth.signOut();
}
