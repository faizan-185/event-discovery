import 'package:event_discovery/screens/Community/Events/create_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../utils/theme.dart';

class LocationPicker extends StatefulWidget {
  final communityUid;
  const LocationPicker({Key? key, required this.communityUid}) : super(key: key);

  @override
  _LocationPickerState createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  LatLng selectedLocation = LatLng(0, 0);
  bool loading = false;

  void setLocation() async {
    setState(() {
      loading = true;
    });
    final position = await Geolocator.getCurrentPosition();
    setState(() {
     selectedLocation = LatLng(position.latitude, position.longitude);
     loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    setLocation();
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
        title: Text("Pick Location", style: title1Text,),
      ),
      body: loading ? Center(child: CircularProgressIndicator()) : FlutterMap(
        options: MapOptions(
          center: selectedLocation, // Initial center of the map
          zoom: 13.0, // Initial zoom level of the map
          onTap: (LatLng point) {
            setState(() {
              selectedLocation = point;

            });
          },
        ),
        layers: [
          TileLayerOptions(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayerOptions(
            markers: [
              if (selectedLocation != null)
                Marker(
                  width: 80.0,
                  height: 80.0,
                  point: selectedLocation,
                  builder: (ctx) => Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40.0,
                  ),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryColor,
        onPressed: () {
          if (selectedLocation != null) {
            // Use the selectedLocation as needed (e.g., save to a database)
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text('Selected Location'),
                  content: Text(
                    'Latitude: ${selectedLocation.latitude}\n'
                        'Longitude: ${selectedLocation.longitude}',
                  ),
                  actions: [
                    TextButton(
                      onPressed: (){
                        Navigator.pop(context);
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateEvent(communityUid: widget.communityUid, latlng: selectedLocation),
                          ),
                        );
                      },
                      child: Text('Close'),
                    ),
                  ],
                );
              },
            );
          } else {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text('No Location Selected'),
                  content: Text('Please tap on the map to select a location.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);

                } ,
                      child: Text('OK'),
                    ),
                  ],
                );
              },
            );
          }
        },
        child: Icon(Icons.check),
      ),
    );
  }
}
