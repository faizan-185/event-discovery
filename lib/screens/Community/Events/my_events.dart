import 'package:event_discovery/models/user.dart';
import 'package:flutter/material.dart';
import 'package:event_discovery/utils/theme.dart';
import 'package:event_discovery/widgets/my_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_discovery/widgets/primary_button.dart';
import 'package:url_launcher/url_launcher.dart';


class MyEvents extends StatefulWidget {
  const MyEvents({Key? key}) : super(key: key);

  @override
  State<MyEvents> createState() => _MyEventsState();
}

class _MyEventsState extends State<MyEvents> {
  bool loading = false;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  var events = [];

  @override
  void initState() {
    super.initState();
    getCommunity().then((value) {
      print(value);
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
        title: Text("My Events", style: title1Text,),
      ),
      drawer: MyDrawer(),
      body: loading ? Center(child: CircularProgressIndicator(),) : ListView(
        shrinkWrap: true,
        padding: EdgeInsets.all(20),
        children: [
          Text("My All Events", style: textStylePrimary12,),
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
                        SizedBox(height: 10,)
                      ],
                    )
                  ],
                ),
              );
            },
          ),
        ],
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

  Future<List> getCommunity() async {
    setState(() {
      loading = true;
    });

    QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
        .collection('communities')
        .get();

    for (var element in snapshot.docs) {
      CollectionReference eventsCollection = FirebaseFirestore.instance
          .collection('communities')
          .doc(element.id)
          .collection('events');
      QuerySnapshot eventsQuerySnapshot =
      await eventsCollection.where(FieldPath.documentId, whereIn: MyUser.events).get();
      for (var eventDoc in eventsQuerySnapshot.docs) {
        events.add(eventDoc);
      }
    }

    setState(() {
      loading = false;
    });

    return events;
  }

}
