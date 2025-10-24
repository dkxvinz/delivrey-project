import 'dart:developer';
import 'dart:io';

import 'package:blink_delivery_project/pages/createpage.dart';
import 'package:blink_delivery_project/pages/historypage.dart';
import 'package:blink_delivery_project/pages/orderlist.dart';
import 'package:blink_delivery_project/pages/receiving_status.dart';
import 'package:blink_delivery_project/pages/sending_status.dart';
import 'package:blink_delivery_project/pages/setting.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Homepage extends StatefulWidget {
  final String uid, aid,rid,oid;

  const Homepage({super.key, required this.uid, required this.aid, required this.rid, required this.oid});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      HomeContent(uid: widget.uid),
      Historypage(uid: widget.uid),
      OrderlistPage(uid: widget.uid,rid: widget.rid, oid: widget.oid,),
      SettingPage(uid: widget.uid, aid: widget.aid),
    ];
    // print('home page');
    // log('uid:${widget.uid}');
    //   log('aid:${widget.aid}');
    //   log('rid:${widget.rid}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(child: _pages[_currentIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5), // สีเงา
              spreadRadius: 3,
              blurRadius: 8, // ความฟุ้งของเงา
              offset: Offset(0, -2), // y เป็น -3 จะทำให้เงาอยู่ด้านบน
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white, // ต้องเหมือน Container
          selectedItemColor: const Color(0xffff3b30),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าแรก'),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'ประวัติการสั่ง',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'รายการสินค้า',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'ตั้งค่า',
            ),
          ],
          currentIndex: _currentIndex,
          onTap: (int index) {
            setState(() {
              _currentIndex = index;
              log(_currentIndex.toString());
        
            });
          },
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  final String uid;
  const HomeContent({super.key, required this.uid});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String role = "user"; // ค่าเริ่มต้น: user
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  // Firestore
  var db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: const Color(0xFFFF3B30)),
          Positioned(
            top: 150,
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
                      padding: const EdgeInsets.only(top: 10),
                      child: TextButton(
                        onPressed: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Createpage(uid: widget.uid),
                            ),
                          );
                        },
                        child: Text(
                          "ส่งสินค้า",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          fixedSize: Size(300, 50),
                          backgroundColor: Color(0xffff3b30),
                        ),
                      ),
                    ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceAround,
                    //   children: [
                    //      Padding(
                    //   padding: const EdgeInsets.only(top: 10),
                    //   child: TextButton(
                    //     onPressed: () async {
                    //       Navigator.push(context, MaterialPageRoute(builder: (context) => const SendingStatus()),);
                    //     },
                    //     child: Text(
                    //       "สินค้ากำลังจัดส่ง",
                    //       style: TextStyle(color: Colors.white, fontSize: 24,fontWeight: FontWeight.bold),
                    //     ),
                    //     style: TextButton.styleFrom(
                    //       fixedSize: Size(170, 50),
                    //       backgroundColor: Color(0xffff3b30),
                    //     ),
                    //   ),
                    // ),
                    //   // const SizedBox(width: 10,),
                    //  Padding(
                    //   padding: const EdgeInsets.only(top: 10),
                    //   child: TextButton(
                    //     onPressed: () async {
                    //       Navigator.push(context, MaterialPageRoute(builder: (context) => const ReceivingStatus()),);
                    //     },
                    //     child: Text(
                    //       "สินค้าที่รอรับ",
                    //       style: TextStyle(color: Colors.white, fontSize: 24,fontWeight: FontWeight.bold),
                    //     ),
                    //     style: TextButton.styleFrom(
                    //       fixedSize: Size(170, 50),
                    //       backgroundColor: Color(0xffff3b30),
                    //     ),
                    //   ),
                    // ),
                    //   ],
                    // )
                  ],
                ),
              ),
            ),
          ),

          // ข้อความสีแดงด้านบน
          SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 70),
                  child: Text(
                    "สวัสดี คุณ",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(left: 60),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[300],
                      border: Border.all(color: Colors.white, width: 3),
                      image: _imageFile != null
                          ? DecorationImage(
                              image: FileImage(_imageFile!),
                              fit: BoxFit.cover,
                            )
                          : null,
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
}
