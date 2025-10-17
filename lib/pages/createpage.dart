import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:blink_delivery_project/pages/detailOrder.dart';
import 'package:blink_delivery_project/pages/homepage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_notifier.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class Createpage extends StatefulWidget {
  final String uid;
  const Createpage({super.key,required this.uid});

  @override
  State<Createpage> createState() => _CreatepageState();
}

class _CreatepageState extends State<Createpage> {

  final TextEditingController _searchController =
      TextEditingController(); //for search

  final TextEditingController detailCtl = TextEditingController();
  File? pickedFile;

  final ImagePicker _picker = ImagePicker();

  XFile? image; //บันทึกรูปลง firebase
  String? _imageUrl; //ดึงรูปจาก firebase มาแสดง
  bool _isUploading = false;

  bool isCreate = false; //check create button

  int _currentIndex = 0; //rout page of menu bar

  void dispose() {
    detailCtl.dispose();
  }

  Future<void> pickFromGallery(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      log("Picked from gallery: ${image.path}");
      setState(() {
        pickedFile = File(image.path);
      });
    } else {
      log("No Image selected from gallery");
    }
  }

  Future<void> pickFromCamera(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      log("Picked from camera: ${image.path}");
      setState(() {
        pickedFile = File(image.path);
      });
    } else {
      log("No Image captured from camera");
    }
  }

  Future<String?> uploadImage(File imageFile) async {
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
        return jsonData['secure_url']; // ได้ URL กลับมา
      } else {
        print("Upload failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print('Upload Error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Color(0xffff3b30),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20.0),
        actions: [
          GestureDetector(
            onTap: () {
              print("โปรไฟล์ผู้ใช้!");
            },
            child: CircleAvatar(
              backgroundImage: AssetImage("assets/avatar.png"),
              // เหลือปรับแต่งกรอบ
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(color: const Color(0xFFFF3B30)),
          Positioned(
            top: 120,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsetsGeometry.only(top: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isCreate) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 30.0,
                                top: 20,
                              ),
                              child: Text(
                                'ผู้ส่งสินค้า',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.only(
                                left: 50.0,
                                bottom: 30.0,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    height: 150,
                                    width: 300,
                                    padding: EdgeInsets.all(
                                      15,
                                    ), // เผื่อระยะห่างด้านใน
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
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [
                                        // 🔹 วงกลมโปรไฟล์
                                        CircleAvatar(
                                          radius: 25,
                                          backgroundImage: AssetImage(""),
                                        ),
                                        SizedBox(width: 15),

                                        // 🔹 ชื่อ และที่อยู่
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Text(
                                              "ขจรศักดิ์ มานะ",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "123/45 ถ.สุขสบาย",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
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

                            //สินค้า
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 30.0,
                                // top: 20,
                              ),
                              child: Text(
                                'รายการสินค้า',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                              child: Container(
                                width: 500,
                                height: 300,

                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 50),
                                      child: Container(
                                        width: 300,
                                        height: 200,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            width: 3,
                                            color: Colors.grey,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color.fromARGB(
                                                255,
                                                110,
                                                107,
                                                107,
                                              ),
                                            ),
                                          ],
                                        ),

                                        child: pickedFile == null
                                            ? Icon(
                                                Icons.image,
                                                size: 50,
                                                color: Color(0xFF121212),
                                              )
                                            : Image.file(
                                                pickedFile!,
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          80,
                                          0,
                                          1,
                                          40,
                                        ),
                                        child: Row(
                                          children: [
                                            FilledButton(
                                              onPressed: () async {
                                                await pickFromCamera(
                                                  ImageSource.camera,
                                                );
                                                if (pickedFile != null) {
                                                  String? url =
                                                      await uploadImage(
                                                        pickedFile!,
                                                      );
                                                  setState(() {
                                                    _imageUrl = url;
                                                  });
                                                }
                                              },
                                              style: FilledButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor: Colors.black87,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                elevation: 2,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 12,
                                                    ),
                                              ),
                                              child: const Row(
                                                children: [
                                                  Icon(
                                                    Icons.camera_alt,
                                                    size: 20,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'ถ่ายรูป',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            const SizedBox(width: 30),

                                            FilledButton(
                                              onPressed: () async {
                                                await pickFromGallery(
                                                  ImageSource.gallery,
                                                );
                                                if (pickedFile != null) {
                                                  String? url =
                                                      await uploadImage(
                                                        pickedFile!,
                                                      );
                                                  setState(() {
                                                    _imageUrl = url;
                                                  });
                                                }
                                              },
                                              style: FilledButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor: Colors.black87,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                elevation: 2,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 12,
                                                    ),
                                              ),
                                              child: const Row(
                                                children: [
                                                  Icon(
                                                    Icons.folder_open,
                                                    size: 20,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'อัพโหลด',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(20, 10, 20, 50),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "รายละเอียดสินค้า:",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextField(
                                    controller: detailCtl,
                                    maxLines: 5,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      hintText: "",
                                      fillColor: Colors.grey[200],
                                      filled: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 30.0,
                                top: 20,
                              ),
                              child: Text(
                                'รายการสินค้าที่สร้างแล้ว',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.only(
                                left: 20.0,
                                bottom: 30.0,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    height: 120,
                                    width: 350,
                                    padding: EdgeInsets.all(
                                      15,
                                    ), // เผื่อระยะห่างด้านใน
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
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [
                                        //ภาพสินค้ารายการที่สร้างแล้ว
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),

                                          child: pickedFile == null
                                              ? Icon(
                                                  Icons.image,
                                                  size: 50,
                                                  color: Color(0xFF121212),
                                                )
                                              : Image.file(
                                                  pickedFile!,
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                        SizedBox(width: 15),

                                        // รายละเอียด
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Text(
                                              "รายละเอียดบลาๆ",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // 🔹 Label ด้านซ้าย
                                                const Text(
                                                  "ผู้รับ:",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w900,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),

                                                // 🔹 ข้อมูลผู้รับ (ชื่อ + ที่อยู่)
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "อารี ดำรง",
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.grey[800],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Container(
                                                      width:200, 
                                                      height: 40,
                                                      child: SingleChildScrollView(
                                                        scrollDirection: Axis.vertical,
                                                         child: Text(
                                                        "112/211 ถ.สุขสบาย แขวงบางรัก เขตบางรัก กรุงเทพฯ",
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color:
                                                              Colors.grey[700],
                                                        ),
                                                        // softWrap: true,
                                                      ),
                                                      )
                                                      
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Padding(
                              padding: EdgeInsetsGeometry.fromLTRB(
                                10,
                                10,
                                10,
                                50,
                              ),

                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Homepage(uid:widget.uid, aid: '',),
                                        ),
                                      );
                                    },
                                    style: ButtonStyle(
                                      foregroundColor:
                                          MaterialStateProperty.resolveWith<
                                            Color
                                          >(
                                            (states) =>
                                                states.contains(
                                                  MaterialState.pressed,
                                                )
                                                ? Colors.white
                                                : const Color(0xffff3b30),
                                          ),
                                      backgroundColor:
                                          MaterialStateProperty.resolveWith<
                                            Color
                                          >(
                                            (states) =>
                                                states.contains(
                                                  MaterialState.pressed,
                                                )
                                                ? const Color(0xffff3b30)
                                                : Colors.transparent,
                                          ),
                                      side: MaterialStateProperty.all(
                                        const BorderSide(
                                          color: Color(0xffff3b30),
                                          width: 1.5,
                                        ),
                                      ),
                                      shape: MaterialStateProperty.all(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                      minimumSize: MaterialStateProperty.all(
                                        const Size(110, 40),
                                      ),
                                    ),

                                    child: const Text("ยกเลิก"),
                                  ),

                                  FilledButton(
                                    onPressed: () async {
                                      var db = FirebaseFirestore.instance;

                                      var ordersData = {
                                        'detail': detailCtl.text,
                                        'imageUrl': _imageUrl ?? '',
                                        'createAt': DateTime.now(),
                                      };

                                      await db
                                          .collection('orders')
                                          .add(ordersData);

                                      // Navigator.push(
                                      //   context,
                                      //   MaterialPageRoute(
                                      //     builder: (context) => Detailorder(),
                                      //   ),
                                      // );
                                    },
                                    style: ButtonStyle(
                                      foregroundColor:
                                          MaterialStateProperty.resolveWith<
                                            Color
                                          >((states) => Colors.white),
                                      backgroundColor:
                                          MaterialStateProperty.resolveWith<
                                            Color
                                          >(
                                            (states) =>
                                                states.contains(
                                                  MaterialState.pressed,
                                                )
                                                ? Colors.white
                                                : const Color(0xffff3b30),
                                          ),
                                      side: MaterialStateProperty.all(
                                        const BorderSide(
                                          color: Color(0xffff3b30),
                                          width: 1.5,
                                        ),
                                      ),
                                      shape: MaterialStateProperty.all(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                    ),
                                    child: const Text("สร้างรายการ"),
                                  ),
                                ],
                              ),
                              
                            ),
                          ] else ...[
                            //ปุ่มสร้างรายการ(เริ่มต้น)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                              child: GestureDetector(
                                child: TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      isCreate = true;
                                    });
                                  },
                                  icon: const Icon(Icons.add_box),
                                  label: const Text(
                                    'สร้างรายการ',
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
                          ], //else ไม่ได้สร้าง
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // แถบแดงด้านบน
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 0, 0),
                  child: Text(
                    "สร้างรายการส่งสินค้า",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ค้นหาผู้รับ',

                      prefixIcon: IconButton(
                        icon: Icon(Icons.search, color: Color(0xffff3b30)),
                        onPressed: () {
                          // ใส่ logic ค้นหา
                        },
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 5.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // bottomNavigationBar: BottomNavigationBar(
      //   type: BottomNavigationBarType.fixed,
      //   backgroundColor: Colors.white,
      //   selectedItemColor: const Color(0xffff3b30),
      //   unselectedItemColor: Colors.grey,
      //   currentIndex: _currentIndex,
      //   onTap: (index) {
      //     setState(() {
      //       _currentIndex = index;
      //     });
      //   },
      //   items: const [
      //     BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าแรก'),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.history),
      //       label: 'ประวัติการสั่ง',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.list_alt),
      //       label: 'รายการสินค้า',
      //     ),
      //     BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'ตั้งค่า'),
      //   ],
      // ),
    );
  }
}
