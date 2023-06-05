import 'package:event_discovery/screens/Community/Events/create_event.dart';
import 'package:event_discovery/screens/Community/Events/location_pick.dart';
import 'package:event_discovery/screens/Community/invite_people.dart';
import 'package:event_discovery/screens/Community/view_community.dart';
import 'package:event_discovery/screens/Dashboard/home.dart';
import 'package:flutter/material.dart';
import 'package:event_discovery/utils/theme.dart';
import 'package:event_discovery/widgets/my_drawer.dart';
import 'package:event_discovery/widgets/primary_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:latlong2/latlong.dart';
import '../../models/user.dart';
import 'package:url_launcher/url_launcher.dart';



class EditCommunity extends StatefulWidget {
  final communityUid;
  const EditCommunity({Key? key, required this.communityUid}) : super(key: key);

  @override
  State<EditCommunity> createState() => _EditCommunityState();
}

class _EditCommunityState extends State<EditCommunity> {
  bool loading = false;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  int currentIndex = 0;
  ScrollController _scroll = ScrollController();
  var community;
  var members;
  var events;
  final ImagePicker picker = ImagePicker();
  late String _logo;
  CroppedFile? _croppedLogo;
  TextEditingController name = TextEditingController();
  TextEditingController description = TextEditingController();
  TextEditingController city = TextEditingController();
  TextEditingController state = TextEditingController();
  TextEditingController country = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  FirebaseStorage storage = FirebaseStorage.instance;
  User? updateUser = FirebaseAuth.instance.currentUser;
  bool isPrivate = false;

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
  void initState() {
    super.initState();
    getCommunity();
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
        title: Text("Edit", style: title1Text,),
        actions: [
          TextButton(onPressed: () async {
            setState(() {
              loading = true;
            });
            if(_croppedLogo!=null) {
              Reference storageReference = storage.ref().child('community_logo/${DateTime.now().millisecondsSinceEpoch}.png');
              UploadTask uploadTask = storageReference.putFile(File(_croppedLogo!.path));
              await uploadTask.then((TaskSnapshot taskSnapshot) async {
                String downloadUrl = await storageReference.getDownloadURL();
                setState(() {
                  _logo = downloadUrl;
                });
              }).catchError((error) {
                // Handle errors when uploading the profile photo
              });
            }
            DocumentReference documentReference = firestore.collection('communities').doc(widget.communityUid);
            var new_members = members.map((member) => member.id).toList();
            await documentReference.update({
              'name': name.text,
              'description': description.text,
              'logo_url': _logo,
              'city': city.text,
              'state': state.text,
              'country': country.text,
              "members": new_members,
              'is_private': isPrivate,
              'updated_at': FieldValue.serverTimestamp(),
            });
            setState(() {
              loading = false;
            });
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewCommunity(communityUid: widget.communityUid),
              ),
            );
          }, child: Text("Save", style: textButton,))
        ],
      ),
      drawer: const MyDrawer(),
      body: loading ? const Center(child: CircularProgressIndicator(color: kPrimaryColor,)) : SingleChildScrollView(
        controller: _scroll,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: RepaintBoundary(
            child: IndexedStack(
                index: currentIndex,
                children: [
                  ListView(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
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
                                      image: _logo!= "" && _croppedLogo == null ? NetworkImage(_logo) : _croppedLogo!=null && _logo== "" ? FileImage(File(_croppedLogo!.path)) : _croppedLogo!=null && _logo!= "" ? FileImage(File(_croppedLogo!.path)) : const AssetImage("images/dummy_user.png") as ImageProvider,
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
                      const SizedBox(height: 30,),
                      PrimaryButton(
                        buttonText: Text("Delete Community", style: textButton.copyWith(color: kWhiteColor),),
                        onClick: () async {
                          setState(() {
                            loading = true;
                          });
                          DocumentReference eventRef = FirebaseFirestore.instance
                              .collection('communities')
                              .doc(widget.communityUid);

                          await eventRef.delete();

                          setState(() {
                            loading = false;
                          });
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Home(),
                            ),
                          );
                        },
                      )
                    ],
                  ),
                  ListView(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: [
                      Text("Members", style: titleText,),
                      const SizedBox(
                        height: 20,
                      ),
                      PrimaryButton(
                        buttonText: Text("Invite Members", style: textButton.copyWith(color: kWhiteColor),),
                        onClick: () async {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InvitePeople(communityUid: widget.communityUid),
                            ),
                          );
                        },
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: members.length,
                        itemBuilder: (BuildContext context, int index){
                          var user = members[index];
                          String userUid = members[index].id;
                          return userUid!=MyUser.uid ? Card(
                              elevation: 3,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(user['profile_url']),
                                ),
                                title: Text("${user['first_name']} ${user['last_name']}", style: textStylePrimary15,),
                                subtitle: Text(user['email'], style: textStylePrimary12,),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.red,),
                                  onPressed: (){
                                    setState(() {
                                      members.remove(user);
                                    });
                                  },
                                ),
                              )
                          ) : const SizedBox();
                        },
                      )
                    ],
                  ),
                  ListView(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: [
                      Text("New Events for this community", style: textStylePrimary12,),
                      SizedBox(height: 20,),
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: events.length,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (BuildContext context, int index){
                          String eventUid = events[index].id;
                          Map<String, dynamic> event = events[index].data() as Map<String, dynamic>;
                          DateTime now = DateTime.now();
                          DateTime dateTime = event['start_date_time'].toDate();
                          Duration difference = dateTime.difference(now);
                          int days = difference.inDays;
                          int hours = difference.inHours.remainder(24);
                          String formattedTimeLeft = '${days} days ${hours} hours to start';

                          DateTime dateTime1 = event['start_date_time'].toDate();
                          Duration difference1 = dateTime1.difference(now);
                          int days1 = difference1.inDays;
                          int hours1 = difference1.inHours.remainder(24);
                          String formattedTimeLeft1 = '${days1} days ${hours1} hours to end';
                          return Container(
                            margin: EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                              boxShadow: [
                                BoxShadow(
                                  color: kPrimaryColor.withOpacity(0.5),
                                  spreadRadius: 1,
                                  blurRadius: 0,
                                  offset: Offset(0, 0), // changes position of shadow
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 170,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                                      image: DecorationImage(
                                          image: NetworkImage(event['logo']),
                                          fit: BoxFit.cover
                                      )
                                  ),
                                ),
                                ExpansionTile(
                                  leading: IconButton(
                                    icon: Icon(Icons.location_on_outlined, color: kBlackColor,),
                                    onPressed: (){
                                      openGoogleMaps(event['location'].latitude, event['location'].longitude);
                                    },
                                  ),
                                  title: Text(event['title'], style: textStylePrimary15),
                                  subtitle: Text(formattedTimeLeft, style: textStylePrimary12,),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [
                                          SizedBox(width: 100, child: Text("Ends In", style: textStylePrimary12)),
                                          Flexible(child: Text(formattedTimeLeft1, style: textStylePrimary13,)),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [
                                          SizedBox(width: 100, child: Text("Description", style: textStylePrimary12)),
                                          Flexible(child: Text(event['description'], style: textStylePrimary13,)),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: 50,
                                      width: 100,
                                      child: PrimaryButton(
                                        buttonText: Text("Delete", style: textButton.copyWith(color: kWhiteColor),),
                                        onClick: () async {
                                          setState(() {
                                            loading = true;
                                          });
                                          DocumentReference eventRef = FirebaseFirestore.instance
                                              .collection('communities')
                                              .doc(widget.communityUid)
                                              .collection('events')
                                              .doc(eventUid);

                                          await eventRef.delete();

                                          setState(() {
                                            events.remove(event);
                                            loading = false;
                                          });
                                          Navigator.pop(context);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ViewCommunity(communityUid: widget.communityUid),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(height: 10,)
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      )
                    ],
                  ),
                ]
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryColor,
        child: Icon(Icons.add, color: kWhiteColor),
        onPressed: (){
          setState(() {
            currentIndex = 2;
          });
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LocationPicker(communityUid: widget.communityUid),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, color: kBlackColor,),
            label: "Community",
            activeIcon: Icon(Icons.home_outlined, color: kPrimaryColor,),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined, color: kBlackColor,),
            label: "Members",
            activeIcon: Icon(Icons.groups_outlined, color: kPrimaryColor,),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined, color: kBlackColor),
            label: "Events",
            activeIcon: Icon(Icons.calendar_month_outlined, color: kPrimaryColor,),
          ),
        ],
        currentIndex: currentIndex,
        selectedItemColor: kSelectedColor,
        onTap: changeIndex,
      ),
    );
  }

  void openGoogleMaps(double latitude, double longitude) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not open Google Maps';
    }
  }

  Future<void> getCommunity() async {
    setState(() {
      loading = true;
    });

    DocumentReference documentReference = firestore.collection('communities').doc(widget.communityUid);
    DocumentSnapshot documentSnapshot = await documentReference.get();
    if(documentSnapshot.exists){
      setState(() {
        community = documentSnapshot.data();
        name.text = community['name'];
        description.text = community['description'];
        city.text = community['city'];
        state.text = community['state'];
        country.text = community['country'];
        isPrivate = community['is_private'];
        _logo = community['logo_url'];
      });

      CollectionReference eventsRef = firestore.collection('communities').doc(widget.communityUid).collection('events');
      QuerySnapshot eventsQuerySnapshot = await eventsRef.get();
      setState(() {
        events = eventsQuerySnapshot.docs;
      });

      final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: community['members'].map((member) => member.toString()).toList())
          .get();
      setState(() {
        members = snapshot.docs;
      });
    }
    setState(() {
      loading = false;
    });
  }
}
