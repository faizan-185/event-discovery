import 'package:event_discovery/screens/Auth/forget_password.dart';
import 'package:event_discovery/screens/Dashboard/home.dart';
import 'package:flutter/material.dart';
// import 'package:event_discovery/screens/Auth/reset_password.dart';
import 'package:event_discovery/screens/Auth/signup.dart';
// import 'package:event_discovery/screens/Dashboard/home.dart';
import 'package:event_discovery/screens/Auth/onboarding.dart';
import 'package:event_discovery/utils/theme.dart';
import 'package:event_discovery/widgets/login_options.dart';
import 'package:event_discovery/widgets/primary_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_discovery/models/user.dart';


class LogInScreen extends StatefulWidget {
  const LogInScreen({super.key});

  @override
  State<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? _email, _password;

  bool loading = false;
  bool _isObscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: kDefaultPadding,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 120,
              ),
              Text(
                'LocalSavvy',
                style: titleText,
              ),
              const SizedBox(
                height: 5,
              ),
              Row(
                children: [
                  Text(
                    "Don't have an account?",
                    style: subTitle,
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SignUpScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Sign Up',
                      style: textButton.copyWith(
                        decoration: TextDecoration.underline,
                        decorationThickness: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: TextFormField(
                          readOnly: loading,
                          obscureText: false,
                          validator: (String? value) =>
                          value!.isEmpty ? 'Email is required' : null,
                          onSaved: (value) => _email = value!,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'Email',
                            hintStyle: TextStyle(color: kTextFieldColor),
                            focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: kPrimaryColor),
                                borderRadius: BorderRadius.all(Radius.circular(10))
                            ),
                            border: OutlineInputBorder(
                                borderSide: BorderSide(color: kPrimaryColor),
                                borderRadius: BorderRadius.all(Radius.circular(10))
                            ),
                          ),
                        )
                    ),
                    TextFormField(
                      readOnly: loading,
                      obscureText: _isObscure,
                      validator: (String? value) =>
                      value!.isEmpty ? 'Password is required' : null,
                      onSaved: (value) => _password = value!,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: const TextStyle(color: kTextFieldColor),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: kPrimaryColor),
                            borderRadius: BorderRadius.all(Radius.circular(10))
                        ),
                        border: OutlineInputBorder(
                            borderSide: BorderSide(color: kPrimaryColor),
                            borderRadius: BorderRadius.all(Radius.circular(10))
                        ),
                        suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _isObscure = !_isObscure;
                              });
                            },
                            icon: _isObscure
                                ? const Icon(
                              Icons.visibility_off,
                              color: kTextFieldColor,
                            )
                                : const Icon(
                              Icons.visibility,
                              color: kPrimaryColor,
                            )),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ResetPasswordScreen()));
                },
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: kZambeziColor,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                    decorationThickness: 1,
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              PrimaryButton(
                buttonText: loading ? const Center(child: CircularProgressIndicator(color: kWhiteColor,),) : Text(
                  'Login',
                  style: textButton.copyWith(color: kWhiteColor),
                ),
                onClick: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    try {
                      setState(() {
                        loading = true;
                      });
                      UserCredential userCredential =
                      await _auth.signInWithEmailAndPassword(
                          email: _email!, password: _password!);
                      setState(() {
                        loading = false;
                      });
                      DocumentReference documentReference = firestore.collection('users').doc(userCredential.user!.uid);
                      DocumentSnapshot documentSnapshot = await documentReference.get();
                      if (documentSnapshot.exists) {
                        MyUser.uid = userCredential.user!.uid;
                        MyUser.firstName = documentSnapshot.get('first_name');
                        MyUser.lastName = documentSnapshot.get('last_name');
                        MyUser.address = documentSnapshot.get('address');
                        MyUser.dob = documentSnapshot.get('dob');
                        MyUser.phone = documentSnapshot.get('phone');
                        MyUser.profileUrl = documentSnapshot.get('profile_url');
                        MyUser.gender = documentSnapshot.get('gender');
                        MyUser.city = documentSnapshot.get('city');
                        MyUser.state = documentSnapshot.get('state');
                        MyUser.country = documentSnapshot.get('country');
                        MyUser.zip = documentSnapshot.get('zip');
                        MyUser.email = documentSnapshot.get('email');
                        MyUser.bio = documentSnapshot.get('bio');
                        try{
                          MyUser.events = documentSnapshot.get('events')?? [];
                        }
                        catch(e){
                          MyUser.events = [];
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Home(),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OnboardingScreen(),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(errorSnackBar("Invalid Credentials!"));
                      FocusScope.of(context).requestFocus(FocusNode());
                      setState(() {
                        loading = false;
                      });
                    }
                  }
                },
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                'Or log in with:',
                style: subTitle.copyWith(color: kBlackColor),
              ),
              const SizedBox(
                height: 20,
              ),
              LoginOption(),
            ],
          ),
        ),
      ),
    );
  }
}
