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
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';

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
  @override
  void initState() {
    super.initState();
    _determinePosition(); // 🔹เรียกหาตำแหน่งปัจจุบันทันทีที่เปิดหน้า
  }

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

  File? _vehicleImageFile;

  Future<void> _pickVehicleImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery, // หรือ ImageSource.camera
    );
    if (pickedFile != null) {
      setState(() {
        _vehicleImageFile = File(pickedFile.path);
        vehiclePhotoCtl.text = pickedFile.path; // เก็บ path ไว้ใน controller
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
                          initialCenter:
                              selectedLocation ??
                              LatLng(
                                16.1831,
                                103.3020,
                              ), // 🔹 ถ้ามี location ใช้ของจริง
                          initialZoom: 15.2,
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
                            maxNativeZoom: 18,
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
                    // _buildTextField(
                    //   "ละติจูด",
                    //   "Latitude",
                    //   controller: latitude,
                    // ),
                    // const SizedBox(height: 10),
                    // _buildTextField(
                    //   "ลองจิจูด",
                    //   "Longitude",
                    //   controller: longitude,
                    // ),
                    const SizedBox(height: 20),
                  ],

                  // เฉพาะ role = rider → ฟิลด์เพิ่ม
                  if (role == "rider") ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "รูปถ่ายพาหนะ",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF3B30),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: _pickVehicleImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey[200],
                          image: _vehicleImageFile != null
                              ? DecorationImage(
                                  image: FileImage(_vehicleImageFile!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _vehicleImageFile == null
                            ? const Center(
                                child: Icon(
                                  Icons.add_a_photo,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              )
                            : null,
                      ),
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
                          // Navigator.pop(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => const LoginPage(),
                          //   ),
                          // );
                          Get.to(() => LoginPage());
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

  // ฟังก์ชันเข้ารหัสรหัสผ่านด้วย SHA256
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void adddata() async {
    try {
      String collectionName = role == "rider" ? "riders" : "users";

      String email = emailCtl.text.trim();
      String phone = phoneCtl.text.trim();

      // -----------------------------
      // ✅ ตรวจสอบ email/phone ซ้ำในทั้ง users และ riders
      // -----------------------------
      var emailInUsers = await db
          .collection("users")
          .where('email', isEqualTo: email)
          .get();

      var emailInRiders = await db
          .collection("riders")
          .where('email', isEqualTo: email)
          .get();

      if (emailInUsers.docs.isNotEmpty || emailInRiders.docs.isNotEmpty) {
        Get.snackbar('ผิดพลาด', 'อีเมลนี้ถูกใช้แล้ว');
        return;
      }

      var phoneInUsers = await db
          .collection("users")
          .where('phone', isEqualTo: phone)
          .get();

      var phoneInRiders = await db
          .collection("riders")
          .where('phone', isEqualTo: phone)
          .get();

      if (phoneInUsers.docs.isNotEmpty || phoneInRiders.docs.isNotEmpty) {
        Get.snackbar('ผิดพลาด', 'เบอร์โทรศัพท์นี้ถูกใช้แล้ว');
        return;
      }

      // -----------------------------
      // ✅ อัปโหลดรูปโปรไฟล์
      // -----------------------------
      String? profileUrl;
      if (_imageFile != null) {
        profileUrl = await uploadToCloudinary(_imageFile!);
        if (profileUrl == null) {
          Get.snackbar('ผิดพลาด', 'อัปโหลดรูปโปรไฟล์ไม่สำเร็จ');
          return;
        }
      }

      // -----------------------------
      // ✅ เตรียมข้อมูลพื้นฐาน (hash password ก่อนเก็บ)
      // -----------------------------
      var userData = {
        'role': role,
        'email': email,
        'password': hashPassword(passwordCtl.text.trim()), // เก็บแบบ hash
        'phone': phone,
        'fullname': fullnameCtl.text.trim(),
        'profile_photo': profileUrl,
        'created_at': FieldValue.serverTimestamp(),
      };

      // -----------------------------
      // ✅ กรณี rider → อัปโหลดรูปพาหนะ
      // -----------------------------
      if (role == "rider") {
        String? vehicleUrl;
        if (_vehicleImageFile != null) {
          vehicleUrl = await uploadToCloudinary(_vehicleImageFile!);
          if (vehicleUrl == null) {
            Get.snackbar('ผิดพลาด', 'อัปโหลดรูปรถไม่สำเร็จ');
            return;
          }
        }

        userData.addAll({
          'vehicle_number': vehicleNumberCtl.text.trim(),
          'vehicle_photo': vehicleUrl,
        });
      }

      // -----------------------------
      // ✅ บันทึก Firestore
      // -----------------------------
      DocumentReference userDocRef = await db
          .collection(collectionName)
          .add(userData);

      // -----------------------------
      // ✅ ถ้าเป็น user → บันทึกที่อยู่
      // -----------------------------
      if (role == "user" && selectedLocation != null) {
        var addressData = {
          'userId': userDocRef.id,
          'address': adddress.text.trim(),
          'latitude': latitude.text.trim(),
          'longitude': longitude.text.trim(),
          'created_at': FieldValue.serverTimestamp(),
        };
        await db.collection("addresses").add(addressData);
      }

      Get.snackbar('สำเร็จ', 'สมัครสมาชิกเรียบร้อย');
      Get.to(() => const LoginPage());
    } catch (e) {
      log("เกิดข้อผิดพลาด: $e");
      Get.snackbar('ผิดพลาด', e.toString());
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar("ผิดพลาด", "กรุณาเปิด GPS");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar("ผิดพลาด", "ไม่ได้รับสิทธิ์การเข้าถึงตำแหน่ง");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar("ผิดพลาด", "ไม่ได้รับสิทธิ์ถาวร");
      return;
    }

    // ดึงตำแหน่งปัจจุบัน
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      selectedLocation = LatLng(position.latitude, position.longitude);
      latitude.text = position.latitude.toString();
      longitude.text = position.longitude.toString();
    });

    // ย้ายกล้องไปตำแหน่งนั้น
  mapController.move(LatLng(position.latitude, position.longitude), 16);
  }

  Future<String?> uploadToCloudinary(File imageFile) async {
    try {
      const cloudName = "dywfdy174";
      const uploadPreset = "flutter_upload";

      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );

      var request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonData = jsonDecode(responseData);
        return jsonData['secure_url']; // ✅ ได้ URL กลับมา
      } else {
        return null;
      }
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }
}
