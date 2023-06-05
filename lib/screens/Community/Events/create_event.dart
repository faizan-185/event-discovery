import 'package:event_discovery/screens/Community/Events/location_pick.dart';
import 'package:event_discovery/screens/Community/view_community.dart';
import 'package:event_discovery/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:event_discovery/utils/theme.dart';
import 'package:event_discovery/widgets/my_drawer.dart';
import 'package:event_discovery/widgets/primary_button.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_discovery/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';



class CreateEvent extends StatefulWidget {
  final LatLng latlng;
  final communityUid;
  const CreateEvent({Key? key, required this.communityUid, required this.latlng}) : super(key: key);

  @override
  State<CreateEvent> createState() => _CreateEventState();
}

class _CreateEventState extends State<CreateEvent> {
  bool loading = false;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  var community;
  final ImagePicker picker = ImagePicker();
  late String _logo;
  CroppedFile? _croppedLogo;
  TextEditingController title = TextEditingController();
  TextEditingController description = TextEditingController();
  TextEditingController location = TextEditingController();
  TextEditingController start_date_time = TextEditingController();
  TextEditingController end_date_time = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  FirebaseStorage storage = FirebaseStorage.instance;
  User? updateUser = FirebaseAuth.instance.currentUser;
  int currentIndex = 0;
  ScrollController _scroll = ScrollController();
  DateTime? selectedDateTime;
  DateTime? selectedDateTime1;
  String pickedLocation = '';


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


  void _selectDateTime(val) {
    DatePicker.showDateTimePicker(
      context,
      showTitleActions: true,
      onChanged: (dateTime) {
        print('Selected DateTime: $dateTime');
      },
      onConfirm: (dateTime) {
        setState(() {
          if(val == "start"){
            selectedDateTime = dateTime;
            start_date_time.text = dateTime.toString();
          }else{
            selectedDateTime1 = dateTime;
            end_date_time.text = dateTime.toString();
          }
        });
      },
    );
  }

  void changeIndex(index) {
    setState(() {
      _scroll.animateTo(
        0,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    String loc = "Latitude: ${widget.latlng.latitude}, Longitude: ${widget.latlng.longitude}";
    location.text = loc;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 1,
        iconTheme: const IconThemeData(
            color: kPrimaryColor,
            size: 30
        ),
        title: Text("Create Event", style: title1Text,),
      ),
      drawer: MyDrawer(),
      body: loading ? const Center(child: CircularProgressIndicator(color: kPrimaryColor,)) : ListView(
        padding: EdgeInsets.all(20),
        shrinkWrap: true,
        children: [
          Text("Please Enter Following Details"),
          SizedBox(height: 20),
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
          SizedBox(height: 20,),
          Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: TextFormField(
                      controller: title,
                      readOnly: loading,
                      obscureText: false,
                      validator: (String? value) =>
                      value!.isEmpty ? 'Title is required' : null,
                      keyboardType: TextInputType.name,
                      decoration: const InputDecoration(
                        labelText: "Title",
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
                      onTap: (){
                        _selectDateTime("start");
                      },
                      controller: start_date_time,
                      readOnly: true,
                      obscureText: false,
                      validator: (String? value) =>
                      value!.isEmpty ? 'Start Date Time is required' : null,
                      keyboardType: TextInputType.name,
                      decoration: const InputDecoration(
                        labelText: "Start Date Time",
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
                      controller: end_date_time,
                      readOnly: true,
                      onTap: (){
                        _selectDateTime("end");
                      },
                      obscureText: false,
                      validator: (String? value) =>
                      value!.isEmpty ? 'End Date Time is required' : null,
                      keyboardType: TextInputType.name,
                      decoration: const InputDecoration(
                        labelText: "End Date Time",
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
                      controller: location,
                      readOnly: true,
                      // onTap: (){
                      //   Navigator.push(
                      //     context,
                      //     MaterialPageRoute(
                      //       builder: (context) => LocationPicker(communityUid: widget.communityUid,),
                      //     ),
                      //   );
                      // },
                      obscureText: false,
                      validator: (String? value) =>
                      value!.isEmpty ? 'Location is required' : null,
                      keyboardType: TextInputType.name,
                      decoration: const InputDecoration(
                        labelText: "Location",
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
                SizedBox(height: 20,),
                PrimaryButton(buttonText: Text("Create Event", style: textButton.copyWith(color: kWhiteColor),), onClick: ()async{
                  if(!_formKey.currentState!.validate() || _croppedLogo == null)
                    {
                      ScaffoldMessenger.of(context).showSnackBar(errorSnackBar("All fields and image are necessary!"));
                    }
                  else{
                    setState(() {
                      loading = true;
                    });
                    Reference storageReference = storage.ref().child('events_logo/${DateTime.now().millisecondsSinceEpoch}.png');
                    UploadTask uploadTask = storageReference.putFile(File(_croppedLogo!.path));
                    await uploadTask.then((TaskSnapshot taskSnapshot) async {
                      String downloadUrl = await storageReference.getDownloadURL();
                      setState(() {
                        _logo = downloadUrl;
                      });
                    }).catchError((error) {
                      // Handle errors when uploading the profile photo
                    });
                    CollectionReference eventsCollection = FirebaseFirestore.instance
                        .collection('communities')
                        .doc(widget.communityUid)
                        .collection('events');
                    GeoPoint geoPoint = GeoPoint(widget.latlng.latitude, widget.latlng.longitude);
                    Map<String, dynamic> eventData = {
                      'title': title.text,
                      'description': description.text,
                      'start_date_time': selectedDateTime,
                      'end_date_time': selectedDateTime1,
                      'location': geoPoint,
                      'logo': _logo,
                      'created_at': FieldValue.serverTimestamp(),
                      // Add more fields as needed
                    };
                    DocumentReference eventDocRef = await eventsCollection.add(eventData);
                    setState(() {
                      loading = false;
                    });
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewCommunity(communityUid: widget.communityUid),
                      ),
                    );
                  }
                })
              ],
            ),
          ),
        ],
      ),
    );
  }
}
