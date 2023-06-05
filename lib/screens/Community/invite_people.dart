import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_discovery/models/user.dart';
import 'package:event_discovery/screens/Community/view_community.dart';
import 'package:flutter/material.dart';
import 'package:event_discovery/utils/theme.dart';
import 'package:event_discovery/widgets/custom_snackbar.dart';
import 'package:event_discovery/widgets/primary_button.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';


class InvitePeople extends StatefulWidget {
  final String communityUid;
  const InvitePeople({Key? key, required this.communityUid}) : super(key: key);

  @override
  State<InvitePeople> createState() => _InvitePeopleState();
}

class _InvitePeopleState extends State<InvitePeople> {
  final TextEditingController _emailController = TextEditingController();
  Stream<QuerySnapshot<Map<String, dynamic>>> _userStream = Stream.empty();
  var membersInvited = [];
  bool loading = false;
  bool loading1 = false;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  var communityMembers = [];
  String community = "";


  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }


  @override
  void initState() {
    super.initState();
    getMembers().then((value) {
      // print(communityMembers);
    });
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
        title: Text("Invite People", style: title1Text,),
        actions: [
          TextButton(
            onPressed: (){
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewCommunity(communityUid: widget.communityUid),
                ),
              );
            },
            child: Text("Skip", style: textButton),
          )
        ],
      ),
      body: loading1 ? const Center(child: CircularProgressIndicator(color: kPrimaryColor,)) : ListView(
        padding: const EdgeInsets.all(20),
        children: [
        Wrap(
          children: membersInvited.map((userDoc) {
            return Chip(
              label: Text(userDoc['email']),
              onDeleted: () {
                setState(() {
                  membersInvited.remove(userDoc);
                  communityMembers.remove(userDoc['uid']);
                });
              },
            );
          }).toList(),
        ),
          SizedBox(height: 20,),
          TextField(
            controller: _emailController,
            onChanged: (value) {
              setState(() {
                _userStream = _searchUsers(value);
              });
            },
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.search_outlined, color: kPrimaryColor,),
              labelText: "Enter Email",
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
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _userStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final users = snapshot.data!.docs;
                return ListView(
                  padding: EdgeInsets.only(top: 10),
                  shrinkWrap: true,
                  children: users.map((userDoc) {
                    final userData = userDoc.data();
                    final userId = userDoc.id;
                    return Card(
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(userData['profile_url']),
                        ),
                        title: Text(userData['first_name'] + " " + userData['last_name']),
                        subtitle: Text(userData['email']),
                        trailing: Text(communityMembers.any((obj) => obj == userId) ? "Joined" : "Add"),
                        onTap: (){
                          if(!membersInvited.any((obj) => obj['email'] == userData['email'] && obj['uid'] == userId))
                            {
                              if(!communityMembers.any((obj) => obj == userId))
                                {
                                  setState(() {
                                    membersInvited.add({'email': userData['email'], 'uid': userId});
                                    communityMembers.add(userId);
                                  });
                                }
                                else{
                                  ScaffoldMessenger.of(context).showSnackBar(errorSnackBar("Already a member!"));
                                }
                            }
                          else{
                            ScaffoldMessenger.of(context).showSnackBar(errorSnackBar("Already invited!"));
                          }
                        },
                      ),
                    );
                  }).toList(),
                );
              } else {
                return Container(); // Placeholder for no search results
              }
            },
          ),
          SizedBox(height: 20,),
          PrimaryButton(
            buttonText: loading ? const Center(child: CircularProgressIndicator(color: kWhiteColor,),) : Text(
              'Send Invites',
              style: textButton.copyWith(color: kWhiteColor),
            ),
            onClick: () async {
              setState(() {
                loading = true;
              });
              DocumentReference documentReference = firestore.collection('communities').doc(widget.communityUid);
              await documentReference.update({
                "members": communityMembers
              });
              await sendInvites().then((value) => {});
              setState(() {
                loading = false;
              });
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewCommunity(communityUid: widget.communityUid),
                ),
              );
            }
          )
        ],
      ),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _searchUsers(String email) {
    final CollectionReference usersRef = FirebaseFirestore.instance.collection('users');
    if (email == ""){
      email = "-00";
    }
    Stream<QuerySnapshot<Map<String, dynamic>>> user =  usersRef
        .where('email', isGreaterThanOrEqualTo: email)
        .where('email', isLessThan: '${email}z')
        .snapshots() as Stream<QuerySnapshot<Map<String, dynamic>>>;
    return user;
  }

  Future<void> getMembers() async {
    setState(() {
      loading1 = true;
    });

    DocumentReference documentReference = firestore.collection('communities').doc(widget.communityUid);
    DocumentSnapshot documentSnapshot = await documentReference.get();
    if(documentSnapshot.exists){
      setState(() {
        community = documentSnapshot.get('name');
        communityMembers = documentSnapshot.get('members');
      });
    }

    setState(() {
      loading1 = false;
    });
  }


  Future<void> sendInvites() async {
    String name = '${MyUser.firstName} ${MyUser.lastName}';
    final Email email = Email(
      body: "$name invited you to $community community.",
      subject: "Invitation to $community",
      recipients: membersInvited.map((e) => e['email'].toString()).toList(),
      attachmentPaths: [],
      isHTML: false,
    );

    String platformResponse;

    try {
      await FlutterEmailSender.send(email);
      platformResponse = 'email invites sent!';
    } catch (error) {
      platformResponse = error.toString();
    }

    ScaffoldMessenger.of(context).showSnackBar(errorSnackBar(platformResponse));

    if (!mounted) return;
  }
}
