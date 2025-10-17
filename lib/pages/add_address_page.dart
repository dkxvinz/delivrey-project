import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

class AddAddressPage extends StatefulWidget {
  final String uid;
  const AddAddressPage({super.key, required this.uid});

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final addresses = TextEditingController();
  final latitude = TextEditingController();
  final longitude = TextEditingController();
  final mapController = MapController();
  LatLng? selectedLocation;

  Future<void> _saveAddress() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('addresses')
          .add({
        'address': addresses.text,
        'latitude': double.tryParse(latitude.text) ?? 0,
        'longitude': double.tryParse(longitude.text) ?? 0,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เพิ่มที่อยู่สำเร็จ!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("เพิ่มที่อยู่ใหม่",style: TextStyle(color: Color(0xffffffff)),),
        backgroundColor: const Color(0xffff3b30),
        iconTheme: IconThemeData(color: Color(0xffffffff)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 320, 10),
              child: Text("ที่อยู่",style: TextStyle(color: Color(0xffff3b30),fontWeight:FontWeight.bold,fontSize: 18),),
            ),

            TextFormField(
              controller: addresses,
              decoration: const InputDecoration(
                labelText: "ที่อยู่",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: LatLng(16.243998, 103.249047),
                  initialZoom: 15,
                  onTap: (tapPosition, point) async {
                    setState(() {
                      selectedLocation = point;
                      latitude.text = point.latitude.toString();
                      longitude.text = point.longitude.toString();
                    });
                    final placemarks =
                        await placemarkFromCoordinates(point.latitude, point.longitude);
                    if (placemarks.isNotEmpty) {
                      final place = placemarks.first;
                      final address =
                          "${place.street}, ${place.locality}, ${place.administrativeArea}";
                      setState(() {
                        addresses.text = address;
                      });
                    }
                    log("เลือกพิกัด: $point");
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.thunderforest.com/atlas/{z}/{x}/{y}.png?apikey=d7b6821f750e49e2864ef759ef2223ec',
                    userAgentPackageName: 'com.example.my_rider',
                  ),
                  if (selectedLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: selectedLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("บันทึก",style: TextStyle(color: Color(0xffffffff),fontWeight:FontWeight.bold,fontSize: 18),),
            ),
          ],
        ),
      ),
    );
  }
}
