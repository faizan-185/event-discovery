import 'package:event_discovery/screens/User/profile_edit.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_discovery/models/user.dart';
import 'package:event_discovery/utils/theme.dart';
import 'package:event_discovery/widgets/my_drawer.dart';


class ViewProfile extends StatefulWidget {
  final String uid;
  const ViewProfile({Key? key, required this.uid}) : super(key: key);

  @override
  State<ViewProfile> createState() => _ViewProfileState();
}

class _ViewProfileState extends State<ViewProfile> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  late Map<String, dynamic> user;
  bool loading = false;

  Future<void> fetchUser(uid) async {
    setState(() {
      loading = true;
    });
    DocumentReference documentReference = firestore.collection('users').doc(uid);
    DocumentSnapshot documentSnapshot = await documentReference.get();
    if (documentSnapshot.exists) {
      user = documentSnapshot.data() as Map<String, dynamic>;
      setState(() {
        user = user;
        loading = false;
      });
    }

    setState(() {
      loading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      drawer: MyDrawer(),
      appBar: AppBar(
        title: Text("Profile", style: title1Text,),
        backgroundColor: kBackgroundColor,
        elevation: 1,
        iconTheme: const IconThemeData(
            color: kPrimaryColor,
            size: 30
        ),
        actions: [
          MyUser.uid == widget.uid ? TextButton(
            onPressed: (){
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfile(uid: widget.uid, user: user),
                ),
              );
            },
            child: Text("Edit", style: textButton,),
          ) : Text("")
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
                    foregroundImage: user['profile_url']!= "" ? NetworkImage(user['profile_url']) : const AssetImage("images/dummy_user.png") as ImageProvider,
                  ),
                ),
              ),
              SizedBox(height: 30,),
              Text("${user["first_name"]} ${user["last_name"]}", style: titleTextBlack,),
              const SizedBox(height: 20),
              user['bio'] == "" ?
              Center(child: Text("No Description", style: textStylePrimary12,)) :
              Center(child: Text(user['bio'], style: textStylePrimary12,)),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  SizedBox(width: 100, child: Icon(Icons.email_outlined, color: kPrimaryColor,)),
                  Flexible(child: Text(user['email'], style: textStylePrimary15Light)),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(width: 100, child: Icon(Icons.phone_enabled_outlined, color: kPrimaryColor,)),
                  Flexible(child: Text(user['phone'], style: textStylePrimary15Light)),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(width: 100, child: Icon(Icons.account_circle_outlined, color: kPrimaryColor,)),
                  Flexible(child: Text("${DateTime.now().difference(DateTime.parse(user['dob'])).inDays ~/ 365} Years Old", style: textStylePrimary15Light)),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  const SizedBox(width: 100, child: Icon(Icons.pin_drop_outlined, color: kPrimaryColor,)),
                  Flexible(child: Text(user['city'] + ", " + user['country'], style: textStylePrimary15Light)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchUser(widget.uid);
  }
}
