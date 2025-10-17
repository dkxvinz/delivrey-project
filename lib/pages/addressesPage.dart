import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

class Addressespage extends StatefulWidget {
  final String uid, aid;
  const Addressespage({super.key, required this.uid, required this.aid});

  @override
  State<Addressespage> createState() => _AddressesState();
}

class _AddressesState extends State<Addressespage> {
  bool isCreate = false; //check create button

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _addressController;
  late TextEditingController _nameController;

  //map
  final latitude = TextEditingController();
  final longitude = TextEditingController();
  final addresses = TextEditingController();

  final mapController = MapController();
  LatLng? selectedLocation;

  bool _isLoading = true;

  Map<String, dynamic>? userData, addrData;
  String? currentAid; //
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();

    _fetchAddressesData(); //
  }

  Future<void> _fetchAddressesData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();
      QuerySnapshot addressDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('addresses')
          .get();
      if (userDoc.exists) {
        userData = userDoc.data() as Map<String, dynamic>;
        _isLoading = false;

        if (!mounted) {
          return;
        }
        setState(() {
          _nameController.text = userData!['fullname'] ?? '';
          _addressController.text = userData!['address'] ?? '';

          if (addressDoc.docs.isNotEmpty) {
            addrData = addressDoc.docs.first.data() as Map<String, dynamic>;
            addresses.text = addrData!['address'] ?? '';
            latitude.text = (addrData!['latitude'].toString() ?? '');
            longitude.text = (addrData!['longitude'].toString() ?? '');
            currentAid = addressDoc.docs.first.id;
          }
        });
      } else {
        setState(() {
          userData == null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      print("Failed to fetch user data: $e");
    }
  }

  Future<void> _createAddres() async {
    if (_formKey.currentState!.validate()) {
      try {
        final addressRef = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .collection('addresses');

        if (currentAid != null) {
          await addressRef.doc(currentAid).update({
            'address': addresses.text,
            'latitude': double.tryParse(latitude.text) ?? 0,
            'longitude': double.tryParse(longitude.text) ?? 0,
          });
        } else {
          await addressRef.add({
            'address': addresses.text,
            'latitude': double.tryParse(latitude.text) ?? 0,
            'longitude': double.tryParse(longitude.text) ?? 0,
          });
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ!')));
         Get.to(() => DisplayAddress(
          uid: widget.uid,
          aid: widget.aid,
          addresses: addresses.text,
          latitude: latitude.text,
          longitude: longitude.text,
        ));
      } catch (e) { 
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xffff3b30),
        iconTheme: IconThemeData(color: Color(0xffffffff)),
      ),
      body: Stack(
        children: [
          Container(color: const Color(0xFFFF3B30)),
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            bottom: 0,

            // พืื้นหลังสีขาว
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                child: Container(
                  child: Column(
                    children: [
                      if(!_isLoading)...[
                          if (!isCreate) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                                child: GestureDetector(
                                  child: TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        
                                        isCreate = true;
                                      });
                                    },
                                    icon: const Icon(Icons.add_box),
                                    label: const Text(
                                      'เพิ่มที่อยู่',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Color(0xffff3b30),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  50,
                                  20,
                                  20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ที่อยู่',
                                      style: const TextStyle(
                                        color: Color(0xffff3b30),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: addresses,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10.0,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.black54,
                                            width: 2.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              //show map
                              SizedBox(height: 10),
                              Container(
                                child: Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: 370,
                                      height: 300,
                                      child: FlutterMap(
                                        mapController: mapController,
                                        options: MapOptions(
                                          initialCenter:
                                              selectedLocation ??
                                              LatLng(16.243998, 103.249047),
                                          initialZoom: 15.2,
                                          onTap: (tapPosition, point) async {
                                            setState(() {
                                              selectedLocation = point;
                                              latitude.text = point.latitude
                                                  .toString();
                                              longitude.text = point.longitude
                                                  .toString();
                                            });
                                            List<Placemark> placemarks =
                                                await placemarkFromCoordinates(
                                                  point.latitude,
                                                  point.longitude,
                                                );

                                            if (placemarks.isNotEmpty) {
                                              final place = placemarks.first;
                                              final address =
                                                  "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";

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
                                            userAgentPackageName:
                                                'com.example.my_rider',
                                            maxNativeZoom: 18,
                                          ),
                                          if (selectedLocation != null)
                                            MarkerLayer(
                                              markers: [
                                                Marker(
                                                  point:
                                                      selectedLocation ??
                                                      LatLng(0, 0),
                                                  width: 40,
                                                  height: 40,
                                                  child: const Icon(
                                                    Icons.location_on,
                                                    size: 40,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton(
                                      onPressed: _createAddres,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        minimumSize: const Size(
                                          double.infinity,
                                          50,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'บันทึก',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ], //else

                      ]
                      
                    ],
                  ),
                ),
              ),
            ), //
          ),


          //header
          SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: Text(
                    "เพิ่มที่อยู่",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} //end address class
//------------------------------------------------------------------------------------------------
class DisplayAddress extends  StatefulWidget{
  final String uid,aid;
  
  final dynamic addresses;
  final dynamic longitude;
  
  final dynamic latitude;
   const DisplayAddress({
    super.key,
    required this.uid,
    required this.aid,
    required this.addresses,
    required this.latitude,
    required this.longitude
  });
  @override
  State<DisplayAddress> createState() => _DisplayAddressState();
}

class _DisplayAddressState extends State<DisplayAddress> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: Padding(
          padding: const EdgeInsets.only(left: 20.0, bottom: 30.0),
          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                               Padding(
                          padding: const EdgeInsets.fromLTRB(30, 30, 30, 30),
                          child: Column(
                            children: [
                              Container(
                                height: 150,
                                width: 350,
                                padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                                 
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.grey,
                                    width: 1.0,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black,
                                      spreadRadius: 1,
                                      blurRadius: 1,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    SizedBox(width: 15),

                                    // รายละเอียด
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Container(
                                            constraints: BoxConstraints(
                                              maxWidth: MediaQuery.of(context).size.width*0.8, 
                                              maxHeight: 200, 
                                            ),
                                          padding: const EdgeInsets.all(5),
                                          child: Text(
                                            widget.addresses.text.isNotEmpty
                                                ? widget.addresses.text
                                                : 'ยังไม่มีที่อยู่',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                            
                          ],
                        ),
        ),
      
    );
  }
}