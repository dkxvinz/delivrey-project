import 'dart:developer';
import 'dart:io';
import 'package:blink_delivery_project/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  String role = "user"; // ค่าเริ่มต้น: user
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // controller สำหรับ textfield
  final emailCtl = TextEditingController();
  final passwordCtl = TextEditingController();
  final phoneCtl = TextEditingController();
  final fullnameCtl = TextEditingController();
  final vehicleNumberCtl = TextEditingController();
  final vehiclePhotoCtl = TextEditingController();
  final latitude = TextEditingController();
  final longitude = TextEditingController();
  final adddress = TextEditingController();
  // Firestore
  var db = FirebaseFirestore.instance;

  // Map
  final mapController = MapController();
  LatLng? selectedLocation;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF3B30),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Title
            const Text(
              "สมัครสมาชิก",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            // Toggle User / Rider
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRoleButton("ผู้ใช้ระบบ", "user"),
                const SizedBox(width: 10),
                _buildRoleButton("ไรเดอร์", "rider"),
              ],
            ),

            const SizedBox(height: 20),

            // ฟอร์ม
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Upload Profile Image
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[300],
                            border: Border.all(color: Colors.red, width: 2),
                            image: _imageFile != null
                                ? DecorationImage(
                                    image: FileImage(_imageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _imageFile == null
                              ? const Center(
                                  child: Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ฟอร์มที่เหมือนกัน
                  _buildTextField(
                    "ชื่อ-นามสกุล",
                    "กรุณากรอกชื่อ-นามสกุล",
                    controller: fullnameCtl,
                  ),
                  _buildTextField(
                    "อีเมล",
                    "กรุณากรอกอีเมล",
                    controller: emailCtl,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    "รหัสผ่าน",
                    "กรุณากรอกรหัสผ่าน",
                    obscure: true,
                    controller: passwordCtl,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    "หมายเลขโทรศัพท์",
                    "กรุณากรอกหมายเลขโทรศัพท์",
                    controller: phoneCtl,
                  ),
                  const SizedBox(height: 15),

                  const SizedBox(height: 15),

                  // เฉพาะ role = user → มีแผนที่
                  if (role == "user") ...[
                    _buildTextField("ที่อยู่", "ที่อยู่", controller: adddress),
                    // const Text(
                    //   "เลือกที่อยู่บนแผนที่",
                    //   style: TextStyle(
                    //     fontSize: 14,
                    //     fontWeight: FontWeight.bold,
                    //     color: Color(0xFFFF3B30),
                    //   ),
                    // ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 300,
                      child: FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                          initialCenter: LatLng(15.8700317, 100.99254),
                          initialZoom: 15.0,
                          onTap: (tapPosition, point) async {
                            setState(() {
                              selectedLocation = point;
                              latitude.text = point.latitude.toString();
                              longitude.text = point.longitude.toString();
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
                                adddress.text =
                                    address; // แสดงใน TextField ชื่อที่อยู่
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
                            maxNativeZoom: 19,
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
                                    size: 40,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    // ฟิลด์โชว์ lat/lng
                    _buildTextField(
                      "ละติจูด",
                      "Latitude",
                      controller: latitude,
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      "ลองจิจูด",
                      "Longitude",
                      controller: longitude,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // เฉพาะ role = rider → ฟิลด์เพิ่ม
                  if (role == "rider") ...[
                    _buildTextField(
                      "รูปถ่ายพาหนะ",
                      "กรุณาอัปโหลดรูปถ่ายพาหนะ",
                      controller: vehiclePhotoCtl,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      "ทะเบียนรถ",
                      "กรุณากรอกทะเบียนรถ",
                      controller: vehicleNumberCtl,
                    ),
                    const SizedBox(height: 15),
                  ],

                  const SizedBox(height: 25),

                  // Register button
                  SizedBox(
                    width: 200,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: adddata,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "สมัครสมาชิก",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("หากเป็นสมาชิกแล้ว?"),
                      InkWell(
                        onTap: () {
                          Navigator.pop(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        },
                        child: const Text(
                          ' เข้าสู่ระบบ',
                          style: TextStyle(
                            color: Color(0xFFFF3B30),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ปุ่มเลือก role
  Widget _buildRoleButton(String text, String value) {
    bool isSelected = role == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => role = value),
        child: Container(
          height: 45,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.red,
            border: Border.all(color: Colors.white),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.red : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // custom textfield
  Widget _buildTextField(
    String label,
    String hint, {
    bool obscure = false,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF3B30),
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  // เพิ่มข้อมูลเข้า Firestore
  void adddata() async {
    try {
      String collectionName = role == "rider" ? "riders" : "users";

      // ข้อมูลผู้ใช้พื้นฐาน
      var userData = {
        'role': role,
        'email': emailCtl.text.trim(),
        'password': passwordCtl.text.trim(),
        'phone': phoneCtl.text.trim(),
        'fullname': fullnameCtl.text.trim(),
        'created_at': FieldValue.serverTimestamp(),
      };

      // เพิ่มฟิลด์สำหรับ rider
      if (role == "rider") {
        userData.addAll({
          'vehicle_number': vehicleNumberCtl.text.trim(),
          'vehicle_photo': vehiclePhotoCtl.text.trim(),
        });
      }

      // สร้างผู้ใช้
      DocumentReference userDocRef = await db
          .collection(collectionName)
          .add(userData);
      log("สมัครสมาชิกสำเร็จ: ${userDocRef.id}");

      // ถ้าเป็น user เพิ่ม address
      if (role == "user" && selectedLocation != null) {
        var addressData = {
          'userId': userDocRef.id,
          'address': adddress.text.trim(),
          'latitude': latitude.text.trim(),
          'longitude': longitude.text.trim(),
          'created_at': FieldValue.serverTimestamp(),
        };

        await db.collection("addresses").add(addressData);
        log("เพิ่ม address สำเร็จสำหรับ user: ${userDocRef.id}");
      }

      Get.snackbar('สำเร็จ', 'สมัครสมาชิกเรียบร้อย');
      Navigator.pop(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      log("เกิดข้อผิดพลาด: $e");
      Get.snackbar('ผิดพลาด', e.toString());
    }
  }
}
