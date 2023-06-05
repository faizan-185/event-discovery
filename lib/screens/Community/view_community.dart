import 'package:event_discovery/screens/Community/edit_community.dart';
import 'package:event_discovery/screens/User/profile_view.dart';
import 'package:event_discovery/widgets/custom_snackbar.dart';
import 'package:event_discovery/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:event_discovery/widgets/my_drawer.dart';
import 'package:event_discovery/utils/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart';
import 'package:url_launcher/url_launcher.dart';


class ViewCommunity extends StatefulWidget {
  final String communityUid;
  const ViewCommunity({Key? key, required this.communityUid}) : super(key: key);

  @override
  State<ViewCommunity> createState() => _ViewCommunityState();
}

class _ViewCommunityState extends State<ViewCommunity> {
  bool loading = false;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  var community;
  var members;
  var events;
  int currentIndex = 0;
  ScrollController _scroll = ScrollController();


  @override
  void initState() {
    super.initState();
    getCommunity();
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
    return Scaffold(
      appBar: loading ? AppBar(backgroundColor: kBackgroundColor,) :AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 1,
        iconTheme: const IconThemeData(
            color: kPrimaryColor,
            size: 30
        ),
        title: Text("Community", style: title1Text,),
        actions: [
          community['creator'] == MyUser.uid ? IconButton(onPressed: (){
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditCommunity(communityUid: widget.communityUid),
              ),
            );
          }, icon: Icon(Icons.settings_outlined, color: kPrimaryColor,)) : SizedBox(),

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
                    Text(community["name"], style: titleText,),
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          image: DecorationImage(
                              image: NetworkImage(community['logo_url']),
                              fit: BoxFit.cover
                          )
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(child: Text(community['is_private'] ? "Private Community": "Public Community", style: textStylePrimary12,)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        SizedBox(width: 100, child: Text("Description", style: textStylePrimary12)),
                        Flexible(child: Text(community['description'], style: textStylePrimary15Light)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        SizedBox(width: 100, child: Text("Area", style: textStylePrimary12)),
                        Flexible(child: Text(community['city'] + ", " + community['country'], style: textStylePrimary15Light)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        SizedBox(width: 100, child: Text("Members", style: textStylePrimary12)),
                        Flexible(child: Text(community['members'].length.toString() + ' +' , style: textStylePrimary15Light)),
                      ],
                    ),
                    SizedBox(height: 20),
                    !community['members'].contains(MyUser.uid) ?
                        PrimaryButton(buttonText: Text("join Community", style: textButton.copyWith(color: kWhiteColor),), onClick: ()async{
                          setState(() {
                            loading = true;
                          });
                          DocumentReference documentReference = firestore.collection('communities').doc(widget.communityUid);
                          setState(() {
                            community['members'].add(MyUser.uid);
                          });
                          await documentReference.update({
                            "members": community['members'],
                          });
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
                        }) : SizedBox()
                  ],
                ),
                !community['members'].contains(MyUser.uid) ?
                Center(
                  child: Text("Join Community to see details", style: textStylePrimary12,),
                ) : ListView(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  children: [
                    Text("Members", style: titleText,),
                    const SizedBox(
                      height: 20,
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: members.length,
                      itemBuilder: (BuildContext context, int index){
                        var user = members[index];
                        String userUid = members[index].id;
                        return Card(
                          elevation: 3,
                          child: ListTile(
                            onTap: (){
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ViewProfile(uid: userUid),
                                ),
                              );
                            },
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(user['profile_url']),
                            ),
                            title: Text("${user['first_name']} ${user['last_name']}", style: textStylePrimary15,),
                            subtitle: Text(user['email'], style: textStylePrimary12,),
                            trailing: Text((community['creator'] == userUid) ? "Admin" : ""),
                          )
                        );
                      },
                    )
                  ],
                ),
                !community['members'].contains(MyUser.uid) ?
                Center(
                  child: Text("Join Community to see details", style: textStylePrimary12,),
                ) : ListView(
                  physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                  children: [
                    Text("New Events for this community", style: textStylePrimary12,),
                    SizedBox(height: 20,),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: events.length,
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
                                      buttonText: Text("Join", style: textButton.copyWith(color: kWhiteColor),),
                                      onClick: () async {
                                        setState(() {
                                          loading = true;
                                        });
                                        MyUser.events.add(eventUid);
                                        DocumentReference communitiesRef = firestore.collection('users').doc(MyUser.uid);
                                        await communitiesRef.update({
                                          'events': MyUser.events,
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(successSnackBar("Event joined!"));
                                        setState(() {
                                          loading = false;
                                        });
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
