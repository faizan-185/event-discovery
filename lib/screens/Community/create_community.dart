import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_discovery/models/user.dart';
import 'package:event_discovery/screens/Community/invite_people.dart';
import 'package:event_discovery/widgets/custom_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:event_discovery/utils/theme.dart';
import 'package:event_discovery/widgets/my_drawer.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:event_discovery/widgets/primary_button.dart';


class CommunityCreate extends StatefulWidget {
  const CommunityCreate({Key? key}) : super(key: key);

  @override
  State<CommunityCreate> createState() => _CommunityCreateState();
}

class _CommunityCreateState extends State<CommunityCreate> {
  final ImagePicker picker = ImagePicker();
  late String _logo;
  CroppedFile? _croppedLogo;
  TextEditingController name = TextEditingController();
  TextEditingController description = TextEditingController();
  TextEditingController city = TextEditingController();
  TextEditingController state = TextEditingController();
  TextEditingController country = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseStorage storage = FirebaseStorage.instance;
  User? updateUser = FirebaseAuth.instance.currentUser;
  bool loading = false;
  String communityUid = "";
  bool isPrivate = false;

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
          setState(() {
            _croppedLogo = croppedFile;
          });
        }
      }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 1,
        iconTheme: const IconThemeData(
            color: kPrimaryColor,
            size: 30
        ),
        title: Text("Create Community", style: title1Text,),
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          GestureDetector(
            onTap: (){
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
                            _cropImage(profile, 'cover');
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
                            _cropImage(profile, 'cover');
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: Stack(
              children: [
                Container(
                  height: 200,
                  width: MediaQuery.of(context).size.width * 1,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1),
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: _croppedLogo == null ? const AssetImage("images/dummy_cover.jpeg") as ImageProvider :  FileImage(File(_croppedLogo!.path)),
                      )
                  ),
                ),
                Positioned(
                  bottom: 0.0,
                  right: 0.0,
                  child: Container(
                    height: 40,
                    width: 40,
                    padding: EdgeInsets.only(bottom: 30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kPrimaryColor
                    ),
                    child: IconButton(
                      icon: Icon(Icons.edit, color: kWhiteColor,),
                      onPressed: () {

                      },
                    ),
                  )
                ),
              ]
            ),
          ),
          SizedBox(height: 20,),
          Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: TextFormField(
                      controller: name,
                      readOnly: loading,
                      obscureText: false,
                      validator: (String? value) =>
                      value!.isEmpty ? 'Name is required' : null,
                      keyboardType: TextInputType.name,
                      decoration: const InputDecoration(
                        labelText: "Name",
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
                      controller: description,
                      readOnly: loading,
                      maxLines: 3,
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
                      controller: city,
                      readOnly: loading,
                      obscureText: false,
                      validator: (String? value) =>
                      value!.isEmpty ? 'City is required' : null,
                      keyboardType: TextInputType.name,
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
                      controller: state,
                      readOnly: loading,
                      obscureText: false,
                      validator: (String? value) =>
                      value!.isEmpty ? 'State is required' : null,
                      keyboardType: TextInputType.name,
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
                      controller: country,
                      readOnly: loading,
                      obscureText: false,
                      validator: (String? value) =>
                      value!.isEmpty ? 'Country is required' : null,
                      keyboardType: TextInputType.name,
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
                SizedBox(height: 5,),
                CheckboxListTile(
                  activeColor: kPrimaryColor,
                  title: const Text("Is Private ?"),
                    value: isPrivate, onChanged: (value){
                  setState(() {
                    isPrivate = value!;
                  });
                })
              ],
            ),
          ),
          const SizedBox(height: 20,),
          PrimaryButton(
            buttonText: loading ? const Center(child: CircularProgressIndicator(color: kWhiteColor,),) : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Community',
                  style: textButton.copyWith(color: kWhiteColor),
                ),
                SizedBox(width: 20,),
                Icon(Icons.arrow_right_alt_rounded, color: kWhiteColor,)
              ],
            ),
            onClick: ()async{
              if(!_formKey.currentState!.validate() || _croppedLogo == null){
                if(_croppedLogo == null) {
                  ScaffoldMessenger.of(context).showSnackBar(errorSnackBar("Community Logo is required!"));
                }
              }
              else{
                setState(() {
                  loading = true;
                });
                Reference storageReference = storage.ref().child('community_logo/${DateTime.now().millisecondsSinceEpoch}.png');
                UploadTask uploadTask = storageReference.putFile(File(_croppedLogo!.path));
                await uploadTask.then((TaskSnapshot taskSnapshot) async {
                  String downloadUrl = await storageReference.getDownloadURL();
                  setState(() {
                    _logo = downloadUrl;
                  });
                }).catchError((error) {

                });
                CollectionReference communitiesRef = firestore.collection('communities');
                DocumentReference newCommunityRef = communitiesRef.doc();
                await newCommunityRef.set({
                  'name': name.text,
                  'description': description.text,
                  'logo_url': _logo,
                  'city': city.text,
                  'state': state.text,
                  'country': country.text,
                  'creator': MyUser.uid,
                  'created_at': FieldValue.serverTimestamp(),
                  'members': [MyUser.uid],
                  'is_private': isPrivate
                });
                ScaffoldMessenger.of(context).showSnackBar(successSnackBar("Community Joined, See All new events in this community."));
                setState(() {
                  communityUid = newCommunityRef.id;
                  loading = false;
                });
                // Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InvitePeople(communityUid: communityUid),
                  ),
                );
              }
            },
          )
        ],
      )
    );
  }
}
