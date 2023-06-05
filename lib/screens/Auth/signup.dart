import 'package:flutter/material.dart';
import 'package:event_discovery/screens/Auth/login.dart';
import 'package:event_discovery/screens/Auth/onboarding.dart';
import 'package:event_discovery/utils/theme.dart';
import 'package:event_discovery/widgets/custom_snackbar.dart';
import 'package:event_discovery/widgets/login_options.dart';
import 'package:event_discovery/widgets/primary_button.dart';
import 'package:firebase_auth/firebase_auth.dart';


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _email, _password;

  bool loading = false;
  bool _isObscure = true;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 120,
            ),
            Padding(
              padding: kDefaultPadding,
              child: Text(
                'Create Account',
                style: titleText,
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Padding(
              padding: kDefaultPadding,
              child: Row(
                children: [
                  Text(
                    'Already a member?',
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
                              builder: (context) => const LogInScreen()));
                    },
                    child: Text(
                      'Log In',
                      style: textButton.copyWith(
                        decoration: TextDecoration.underline,
                        decorationThickness: 1,
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: kDefaultPadding,
              child: Form(
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
                        border: const OutlineInputBorder(
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
            ),
            const SizedBox(
              height: 50,
            ),
            Padding(
              padding: kDefaultPadding,
              child: PrimaryButton(
                buttonText: loading ? const Center(child: CircularProgressIndicator(color: kWhiteColor,),) : Text(
                  'Sign Up',
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
                      await _auth.createUserWithEmailAndPassword(
                          email: _email!, password: _password!);
                      setState(() {
                        loading = false;
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OnboardingScreen(),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(errorSnackBar("User with this email already exists!"));
                      FocusScope.of(context).requestFocus(FocusNode());
                      setState(() {
                        loading = false;
                      });
                    }
                  }
                },
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: kDefaultPadding,
              child: Text(
                'Or log in with:',
                style: subTitle.copyWith(color: kBlackColor),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: kDefaultPadding,
              child: LoginOption(),
            ),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}
