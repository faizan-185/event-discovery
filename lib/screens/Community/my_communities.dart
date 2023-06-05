import 'package:event_discovery/models/user.dart';
import 'package:event_discovery/screens/Community/view_community.dart';
import 'package:flutter/material.dart';
import 'package:event_discovery/widgets/my_drawer.dart';
import 'package:event_discovery/utils/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class MyCommunities extends StatefulWidget {
  const MyCommunities({Key? key}) : super(key: key);

  @override
  State<MyCommunities> createState() => _MyCommunitiesState();
}

class _MyCommunitiesState extends State<MyCommunities> {
  late List<DocumentSnapshot<Map<String, dynamic>>> communities;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    myCommunities().then((value) {
      setState(() {
        communities = value;
        print(communities);
      });
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
        title: Text("My Communities", style: title1Text,),
      ),
      drawer: MyDrawer(),
      body: loading ? const Center(child: CircularProgressIndicator(color: kPrimaryColor,)) : ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(20),
        children: [
          communities.length == 0 ? Center(child: Text("No Communities To Show")) :
              ListView.builder(
                shrinkWrap: true,
                itemCount: communities.length,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (BuildContext context, int index){
                  String communityUid = communities[index].id;
                  Map<String, dynamic> community = communities[index].data() as Map<String, dynamic>;
                  return GestureDetector(
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewCommunity(communityUid: communityUid),
                        ),
                      );
                    },
                    child: Container(
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
                                image: NetworkImage(community['logo_url']),
                                fit: BoxFit.cover
                              )
                            ),
                          ),
                        ListTile(
                          tileColor: kWhiteColor,
                          title: Text(community['name'], style: textStylePrimary15),
                          subtitle: Text("${community['city']}, ${community['country']}", style: textStylePrimary12,),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text("${community['members'].length} +", style: textStylePrimary12,),
                              const Icon(Icons.person_2_outlined,)
                            ],
                          ),
                        )
                        ],
                      ),
                    ),
                  );
                },
              )
        ],
      ),
    );
  }
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> myCommunities() async {
    setState(() {
      loading = true;
    });
    final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
        .collection('communities')
        .where('members', arrayContains: MyUser.uid)
        .get();
    setState(() {
      loading = false;
    });
    return snapshot.docs;
  }
}

