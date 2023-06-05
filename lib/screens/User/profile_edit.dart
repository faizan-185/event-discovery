import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:event_discovery/models/user.dart';
import 'package:event_discovery/screens/User/profile_view.dart';
import 'package:event_discovery/widgets/loader.dart';
import 'package:event_discovery/utils/theme.dart';
import '../../widgets/my_drawer.dart';
import 'dart:io';


class EditProfile extends StatefulWidget {
  final Map<String, dynamic> user;
  final String uid;
  const EditProfile({Key? key, required this.uid, required this.user}) : super(key: key);

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final ImagePicker picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseStorage storage = FirebaseStorage.instance;
  User? updateUser = FirebaseAuth.instance.currentUser;
  TextEditingController _firstName = TextEditingController();
  TextEditingController _lastName = TextEditingController();
  TextEditingController _phone = TextEditingController();
  TextEditingController _address = TextEditingController();
  TextEditingController _city = TextEditingController();
  TextEditingController _state = TextEditingController();
  TextEditingController _country = TextEditingController();
  TextEditingController _zip = TextEditingController();
  TextEditingController _dob = TextEditingController(text: "");
  TextEditingController _bio = TextEditingController(text: "");
  late String _profileUrl, _coverUrl;

  String _gender = "Male";
  var items = [
    'Male',
    'Female',
    'Other'
  ];

  bool loading = false;
  CroppedFile? _croppedProfile;
  DateTime selectedDate = DateTime.now();



  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(DateTime.now().year - 60),
        lastDate: DateTime.now());
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _dob.text = "${selectedDate.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> _cropImage(pickedFile, type) async {
    if (pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile!.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Edit Image',
              toolbarColor: kPrimaryColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          IOSUiSettings(
            title: 'Cropper',
          ),
          WebUiSettings(
            context: context,
            presentStyle: CropperPresentStyle.dialog,
            boundary: const CroppieBoundary(
              width: 520,
              height: 520,
            ),
            viewPort:
            const CroppieViewPort(width: 480, height: 480, type: 'circle'),
            enableExif: true,
            enableZoom: true,
            showZoomer: true,
          ),
        ],
      );
      if (croppedFile != null) {
        if (type == "profile") {
          setState(() {
            _croppedProfile = croppedFile;
          });
        } else {
          setState(() {
          });
        }
      }
    }
  }


  @override
  void initState() {
    super.initState();
    setState(() {
      _gender = widget.user['gender'];
      _firstName.text = widget.user['first_name'];
      _lastName.text = widget.user['last_name'];
      _phone.text = widget.user['phone'];
      _address.text = widget.user['address'];
      _city.text = widget.user['city'];
      _state.text = widget.user['state'];
      _country.text = widget.user['country'];
      _zip.text = widget.user['zip'];
      _dob.text = widget.user['dob'];
      _bio.text = widget.user['bio'];
      selectedDate = DateTime.parse(widget.user['dob']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(),
      appBar: AppBar(
        title: Text("Edit Profile", style: title1Text,),
        backgroundColor: kBackgroundColor,
        elevation: 1,
        iconTheme: const IconThemeData(
            color: kPrimaryColor,
            size: 30
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if(_formKey.currentState!.validate()) {
                showLoadingDialog(context);
                _formKey.currentState!.save();
                if (_croppedProfile!= null)
                {
                  Reference storageReference = storage.ref().child('profile_photos/${DateTime.now().millisecondsSinceEpoch}.png');
                  UploadTask uploadTask = storageReference.putFile(File(_croppedProfile!.path));
                  await uploadTask.then((TaskSnapshot taskSnapshot) async {
                    String downloadUrl = await storageReference.getDownloadURL();
                    setState(() {
                      _profileUrl = downloadUrl;
                    });
                  }).catchError((error) {
                    // Handle errors when uploading the profile photo
                  });
                }
                else
                {
                  setState(() {
                    _profileUrl = widget.user['profile_url'];
                  });
                }
                DocumentReference documentReference = firestore.collection('users').doc(widget.uid);
                await documentReference.set({
                  'first_name': _firstName.text,
                  'last_name': _lastName.text,
                  'phone': _phone.text,
                  'address': _address.text,
                  'dob': _dob.text,
                  'profile_url': _profileUrl,
                  'gender': _gender,
                  'city': _city.text,
                  'country': _country.text,
                  'state': _state.text,
                  'zip': _zip.text,
                  'bio': _bio.text,
                  'email': MyUser.email
                }).then((value) {
                  setState(() {
                    MyUser.uid = widget.uid;
                    MyUser.firstName = _firstName.text;
                    MyUser.lastName = _lastName.text;
                    MyUser.address = _address.text;
                    MyUser.dob = _dob.text;
                    MyUser.phone = _phone.text;
                    MyUser.profileUrl = _profileUrl;
                    MyUser.gender = _gender;
                    MyUser.city = _city.text;
                    MyUser.country = _country.text;
                    MyUser.state = _state.text;
                    MyUser.zip = _zip.text;
                    MyUser.email = MyUser.email;
                    MyUser.bio = _bio.text;
                  });
                  // Profile data was successfully uploaded
                }).catchError((error) {
                  // Handle errors when uploading profile data
                });
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewProfile(uid: widget.uid),
                  ),
                );
              }
            },
            child: Text("Save", style: textButton,),
          )
        ],
      ),
      body: loading ? Center(child: CircularProgressIndicator(color: kPrimaryColor,),) : SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              Container(
                decoration: BoxDecoration(
                    border: Border.all(color: kPrimaryColor, width: 4),
                    shape: BoxShape.circle
                ),
                child: Center(
                  child: CircleAvatar(
                    radius: 80,
                    backgroundImage: widget.user['profile_url']!= "" && _croppedProfile == null ? NetworkImage(widget.user['profile_url']) : _croppedProfile!=null && widget.user['profile_url']== "" ? FileImage(File(_croppedProfile!.path)) : _croppedProfile!=null && widget.user['profile_url']!= "" ? FileImage(File(_croppedProfile!.path)) : const AssetImage("images/dummy_user.png") as ImageProvider,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return Wrap(
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.image, color: kPrimaryColor,),
                                      title: const Text('Gallery',),
                                      onTap: () async {
                                        final profile = await picker.pickImage(source: ImageSource.gallery);
                                        if (profile != null)
                                        {
                                          _cropImage(profile, 'profile');
                                          Navigator.pop(context);
                                        }
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.camera, color: kPrimaryColor,),
                                      title: const Text('Camera'),
                                      onTap: () async {
                                        final profile = await picker.pickImage(source: ImageSource.camera);
                                        if (profile != null)
                                        {
                                          _cropImage(profile, 'profile');
                                          Navigator.pop(context);
                                        }
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: TextFormField(
                              controller: _bio,
                              readOnly: loading,
                              obscureText: false,
                              validator: (String? value) =>
                              value!.isEmpty ? 'Description is required' : null,
                              keyboardType: TextInputType.name,
                              decoration: const InputDecoration(
                                labelText: "Description",
                                labelStyle: TextStyle(color: kPrimaryColor),
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
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: TextFormField(
                              controller: _firstName,
                              readOnly: loading,
                              obscureText: false,
                              validator: (String? value) =>
                              value!.isEmpty ? 'First name is required' : null,
                              keyboardType: TextInputType.name,
                              decoration: const InputDecoration(
                                labelText: "First Name",
                                labelStyle: TextStyle(color: kPrimaryColor),
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
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: TextFormField(
                              controller: _lastName,
                              readOnly: loading,
                              obscureText: false,
                              validator: (String? value) =>
                              value!.isEmpty ? 'Last name is required' : null,
                              keyboardType: TextInputType.name,
                              decoration: const InputDecoration(
                                labelText: "Last Name",
                                labelStyle: TextStyle(color: kPrimaryColor),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: TextFormField(
                            controller: _dob,
                            validator: (String? value) =>
                            value!.isEmpty ? 'Date of Birth is required' : null,
                            onTap: (){
                              _selectDate(context);
                            },
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: "Date of Birth",
                              labelStyle: TextStyle(color: kPrimaryColor),
                              focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: kPrimaryColor),
                                  borderRadius: BorderRadius.all(Radius.circular(10))
                              ),
                              border: OutlineInputBorder(
                                  borderSide: BorderSide(color: kPrimaryColor),
                                  borderRadius: BorderRadius.all(Radius.circular(10))
                              ),
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey, width: 1),
                              borderRadius: BorderRadius.all(Radius.circular(10))
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0, right: 8),
                            child: DropdownButton(
                              value: _gender,
                              style: TextStyle(color: kPrimaryColor, fontSize: 18, fontWeight: FontWeight.w300),
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down),
                              items: items.map((String items) {
                                return DropdownMenuItem(
                                  value: items,
                                  child: Text(items),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _gender = newValue!;
                                });
                              },
                            ),
                          ),
                        ),
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: TextFormField(
                              controller: _phone,
                              readOnly: loading,
                              obscureText: false,
                              validator: (String? value) =>
                              value!.isEmpty ? 'Phone is required' : null,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: "Phone",
                                labelStyle: TextStyle(color: kPrimaryColor),
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
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: TextFormField(
                              controller: _address,
                              readOnly: loading,
                              obscureText: false,
                              validator: (String? value) =>
                              value!.isEmpty ? 'Address is required' : null,
                              keyboardType: TextInputType.streetAddress,
                              decoration: const InputDecoration(
                                labelText: "Address",
                                labelStyle: TextStyle(color: kPrimaryColor),
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
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: TextFormField(
                              controller: _city,
                              readOnly: loading,
                              obscureText: false,
                              validator: (String? value) =>
                              value!.isEmpty ? 'City is required' : null,
                              keyboardType: TextInputType.text,
                              decoration: const InputDecoration(
                                labelText: "City",
                                labelStyle: TextStyle(color: kPrimaryColor),
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
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: TextFormField(
                              controller: _state,
                              readOnly: loading,
                              obscureText: false,
                              validator: (String? value) =>
                              value!.isEmpty ? 'State is required' : null,
                              keyboardType: TextInputType.text,
                              decoration: const InputDecoration(
                                labelText: "State",
                                labelStyle: TextStyle(color: kPrimaryColor),
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
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: TextFormField(
                              controller: _country,
                              readOnly: loading,
                              obscureText: false,
                              validator: (String? value) =>
                              value!.isEmpty ? 'Country is required' : null,
                              keyboardType: TextInputType.text,
                              decoration: const InputDecoration(
                                labelText: "Country",
                                labelStyle: TextStyle(color: kPrimaryColor),
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
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: TextFormField(
                              controller: _zip,
                              readOnly: loading,
                              obscureText: false,
                              validator: (String? value) =>
                              value!.isEmpty ? 'Zip Code is required' : null,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Zip Code",
                                labelStyle: TextStyle(color: kPrimaryColor),
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
                      ],
                    ),
                  )
              )
            ],
          ),
        ),
      ),
    );
  }
}
