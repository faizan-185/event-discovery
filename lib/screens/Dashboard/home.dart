import 'package:event_discovery/screens/Community/create_community.dart';
import 'package:event_discovery/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:event_discovery/widgets/my_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user.dart';
import '../Community/view_community.dart';


class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late List<DocumentSnapshot<Map<String, dynamic>>> communities;
  bool loading = false;
  List<String> list = <String>['My State', 'My City', 'My Country'];
  String filter = "My Country";

  @override
  void initState() {
    super.initState();
    myCommunities().then((value) {
      setState(() {
        communities = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 1,
        iconTheme: const IconThemeData(
            color: kPrimaryColor,
            size: 30
        ),
        title: Text("Local Savvy", style: title1Text,),
      ),
      drawer: const MyDrawer(),
      body: loading ? const Center(child: CircularProgressIndicator(color: kPrimaryColor,)) : ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(20),
        children: [
          Text("Explore some public Communities",style: textStylePrimary12,),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Filter Communities By:"),
              SizedBox(width: 20,),
              DropdownButton<String>(
                value: filter,
                icon: const Icon(Icons.arrow_downward, color: kPrimaryColor),
                elevation: 16,
                style: const TextStyle(color: kPrimaryColor),
                underline: Container(
                  height: 2,
                  color: kPrimaryColor,
                ),
                onChanged: (String? value) async {
                  setState(() {
                    filter = value!;
                    loading = true;
                  });
                  await myCommunities().then((value) {
                    setState(() {
                      communities = value;
                    });
                  });
                  late List<DocumentSnapshot<Map<String, dynamic>>> newCommunities = [];

                    if (filter == 'My Country'){
                      communities.forEach((element) {
                        if(element.data()!['country'].toLowerCase() == MyUser.country.toLowerCase()){
                          newCommunities.add(element);
                        }
                      });
                    }
                  else if (filter == 'My State'){
                    communities.forEach((element) {
                      if(element.data()!['state'].toLowerCase() == MyUser.state.toLowerCase()){
                        newCommunities.add(element);
                      }
                    });
                  }
                  else if (filter == 'My City'){
                    communities.forEach((element) {
                      if(element.data()!['city'].toLowerCase() == MyUser.city.toLowerCase()){
                        newCommunities.add(element);
                      }
                    });
                  }

                  setState(() {
                    loading = false;
                    print(newCommunities);
                    communities = newCommunities;
                  });
                },
                items: list.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
          SizedBox(height: 20,),
          communities.length == 0 ? Center(child: Text("No Communities To Show")) :
          ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: communities.length,
            itemBuilder: (BuildContext context, int index){
              String communityUid = communities[index].id;
              Map<String, dynamic> community = communities[index].data() as Map<String, dynamic>;
              return !community['members'].contains(MyUser.uid) ? GestureDetector(
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
              ) : SizedBox();
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryColor,
        elevation: 5,
        tooltip: "Create Community",
        child: const Icon(Icons.add, color: kWhiteColor,),
        onPressed: (){
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CommunityCreate(),
            ),
          );
        },
      ),
    );
  }
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> myCommunities() async {
    setState(() {
      loading = true;
    });
    final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
        .collection('communities')
        .where('is_private', isEqualTo: false)
        .get();
    setState(() {
      loading = false;
    });
    return snapshot.docs;
  }
}
