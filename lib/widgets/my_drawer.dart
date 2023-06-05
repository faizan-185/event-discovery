import 'package:event_discovery/screens/Community/Events/my_events.dart';
import 'package:event_discovery/screens/Community/my_communities.dart';
import 'package:flutter/material.dart';
import 'package:event_discovery/models/user.dart';
import 'package:event_discovery/screens/Auth/login.dart';
import 'package:event_discovery/screens/Dashboard/home.dart';
// import 'package:event_discovery/screens/User/profile_view.dart';
// import 'package:event_discovery/screens/chat/inbox.dart';
import 'package:event_discovery/utils/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:event_discovery/screens/User/profile_view.dart';

// import '../screens/chat/discussion.dart';


class MyDrawer extends StatefulWidget {
  const MyDrawer({Key? key}) : super(key: key);

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    setState(() {
      cover = MyUser.coverUrl;
      profile = MyUser.profileUrl;
    });
  }

  late String cover, profile;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
              child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${MyUser.firstName} ${MyUser.lastName}", style: title1Text,),
                      SizedBox(height: 10,),
                      Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: kPrimaryColor, width: 3),
                            shape: BoxShape.circle
                        ),
                        child: GestureDetector(
                          onTap: (){
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewProfile(uid: MyUser.uid,),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            backgroundImage: profile == '' ? AssetImage('images/dummy_user.png') : NetworkImage(profile) as ImageProvider,
                            radius: 43,
                          ),
                        ),
                      ),
                    ],
                  )
              )
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined, color: kPrimaryColor,),
            title: Text("Home", style: textButton,),
            onTap: (){
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Home(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.groups_outlined, color: kPrimaryColor,),
            title: Text("My Communities", style: textButton,),
            onTap: (){
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyCommunities(),
                ),
              );
            },
          ),
          // ListTile(
          //   leading: const Icon(Icons.star_outline, color: kPrimaryColor,),
          //   title: Text("Favorites", style: textButton,),
          //   onTap: (){
          //     Navigator.pop(context);
          //     // Navigator.push(
          //     //   context,
          //     //   MaterialPageRoute(
          //     //     builder: (context) => const Discussion(),
          //     //   ),
          //     // );
          //   },
          // ),
          ListTile(
            leading: const Icon(Icons.event_available_outlined, color: kPrimaryColor,),
            title: Text("My Events", style: textButton,),
            onTap: (){
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyEvents(),
                ),
              );
            },
          ),
          const Divider(
            thickness: 1,
            color: kPrimaryColor,
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: kPrimaryColor,),
            title: Text("Sign Out", style: textButton,),
            onTap: () async {
              await _auth.signOut().then((value) {
                Navigator.popUntil(context, (route) => route.isFirst);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LogInScreen()));
              });
            },
          ),

        ],
      ),
    );
  }
}
