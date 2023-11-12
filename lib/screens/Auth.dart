import 'dart:io';

import 'package:chatapp/widgets/userImagePicker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final formKey = GlobalKey<FormState>();
  var _isLoggedin = true;
  var enteredEmail = "";
  var enteredPassword = "";
  File? enteredImage;
  var isAuthenticating = false;
  var enteredUserName = "";

  void _submit() async {
    final isValid = formKey.currentState!.validate();
    if (!isValid || (!_isLoggedin && enteredImage == null)) {
      return;
    }
    formKey.currentState!.save();
    try {
      setState(() {
        isAuthenticating = true;
      });
      if (_isLoggedin) {
        final userCredential = await _firebase.signInWithEmailAndPassword(
            email: enteredEmail, password: enteredPassword);
      } else {
        final userCredential = await _firebase.createUserWithEmailAndPassword(
          email: enteredEmail,
          password: enteredPassword,
        );
        final storageRef = FirebaseStorage.instance
            .ref()
            .child("user_images")
            .child("${userCredential.user!.uid}.jpg");
        await storageRef.putFile(enteredImage!);
        final imageUrl = await storageRef.getDownloadURL();
        FirebaseFirestore.instance
            .collection("users")
            .doc(userCredential.user!.uid)
            .set({
          "username": enteredUserName,
          "email": enteredEmail,
          "image_url": imageUrl,
        });
      }
    } on FirebaseAuthException catch (error) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? "Authentication failed"),
        ),
      );
      setState(() {
        isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: 30,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                width: 200,
                child: Image.asset("assets/images/chat.png"),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_isLoggedin)
                            UserImagePicker(
                              onPickImage: (pickImage) {
                                enteredImage = pickImage;
                              },
                            ),
                          TextFormField(
                            decoration: const InputDecoration(
                              label: Text(
                                "Email Address",
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  !value.contains("@") ||
                                  value.contains(" ") ||
                                  value.trim().startsWith("@")) {
                                return "Please Enter a valid Email Address";
                              } else {
                                return null;
                              }
                            },
                            onSaved: (value) {
                              enteredEmail = value!;
                            },
                          ),
                          if (!_isLoggedin)
                            TextFormField(
                              decoration: const InputDecoration(
                                label: Text(
                                  "User name",
                                ),
                              ),
                              enableSuggestions: false,
                              validator: (value) {
                                if (value == null || value.trim().length < 4) {
                                  return "Username should be at least 4 characters";
                                } else {
                                  return null;
                                }
                              },
                              onSaved: (value) {
                                enteredUserName = value!;
                              },
                            ),
                          TextFormField(
                            decoration: const InputDecoration(
                              label: Text(
                                "Password",
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().length < 6) {
                                return "Password must be at least 6 Characters";
                              } else {
                                return null;
                              }
                            },
                            onSaved: (value) {
                              enteredPassword = value!;
                            },
                            obscureText: true,
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          if (isAuthenticating)
                            const CircularProgressIndicator(),
                          if (!isAuthenticating)
                            ElevatedButton(
                              onPressed: _submit,
                              child: Text(
                                _isLoggedin ? "Login" : "Sign Up",
                              ),
                            ),
                          if (!isAuthenticating)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLoggedin = !_isLoggedin;
                                });
                              },
                              child: _isLoggedin
                                  ? const Text(
                                      "Create an Account",
                                    )
                                  : const Text(
                                      "I already have an account",
                                    ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
