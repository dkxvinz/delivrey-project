import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;


class Ridertopage extends StatefulWidget {
  final String uid;
  const Ridertopage({super.key, required this.uid});

  @override
  State<Ridertopage> createState() => _RidertopageState();
}

class _RidertopageState extends State<Ridertopage> {
  File? pickupImage;
  File? deliveredImage;
  double? distanceToPickup;
  double? distanceToReceiver;
  Timer? _timer;
  LatLng? riderPos;
  LatLng? pickupPos;
  LatLng? receiverPos;
  Map<String, dynamic>? currentOrder;
  bool _isFinished = false;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 🔹 เริ่มติดตามตำแหน่งไรเดอร์
  void _startLocationTracking() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!_isFinished &&
          currentOrder != null &&
          currentOrder!['status'] != 'ไรเดอร์นำส่งสินค้าแล้ว') {
        await _updateRiderLocation();
      }
    });
  }

  /// 🔹 อัปเดตตำแหน่งไรเดอร์ใน Firestore
  Future<void> _updateRiderLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        riderPos = LatLng(pos.latitude, pos.longitude);
      });

      if (pickupPos != null) {
        distanceToPickup = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          pickupPos!.latitude,
          pickupPos!.longitude,
        );
      }

      if (receiverPos != null) {
        distanceToReceiver = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          receiverPos!.latitude,
          receiverPos!.longitude,
        );
      }

      // ✅ update ตำแหน่งใน riders
      await FirebaseFirestore.instance
          .collection('riders')
          .doc(widget.uid)
          .update({
            'latitude': pos.latitude,
            'longitude': pos.longitude,
            'last_update': FieldValue.serverTimestamp(),
          });

      // ✅ update ตำแหน่งใน orders ถ้ามีงาน
      if (currentOrder != null && currentOrder!['order_id'] != null) {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(currentOrder!['order_id'])
            .update({
              'rider_latitude': pos.latitude,
              'rider_longitude': pos.longitude,
              'rider_last_update': FieldValue.serverTimestamp(),
            });
      }

      _mapController.move(LatLng(pos.latitude, pos.longitude), 16);
    } catch (e) {
      log('Error updating location: $e');
    }
  }

  /// ✅ อัปโหลดรูปไป Cloudinary
  Future<String?> _uploadToCloudinary(File image) async {
    try {
      const cloudName = "dywfdy174";
      const uploadPreset = "flutter_upload";
      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );

      var request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        var resData = jsonDecode(await response.stream.bytesToString());
        return resData['secure_url'];
      }
      return null;
    } catch (e) {
      log('❌ Upload Error: $e');
      return null;
    }
  }

  /// 🔹 ถ่ายรูปตอนรับ/ส่งสินค้า
  Future<void> _captureAndUploadImage(bool isPickup) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    final file = File(image.path);
    final url = await _uploadToCloudinary(file);

    if (url == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('❌ อัปโหลดรูปไม่สำเร็จ')));
      return;
    }

    if (isPickup) {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(currentOrder!['order_id'])
          .update({
            'image_pickup': url,
            'status': 'ไรเดอร์รับสินค้าแล้ว (กำลังเดินทางไปส่ง)',
          });

      setState(() {
        pickupImage = file;
        currentOrder?['status'] = 'ไรเดอร์รับสินค้าแล้ว (กำลังเดินทางไปส่ง)';
        currentOrder?['image_pickup'] = url;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ รับสินค้าเรียบร้อย กำลังเดินทางไปส่ง')),
      );
    } else {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(currentOrder!['order_id'])
          .update({
            'image_delivered': url,
            'status': 'ไรเดอร์นำส่งสินค้าแล้ว',
            'delivered_at': FieldValue.serverTimestamp(),
          });

      _isFinished = true;
      _timer?.cancel();

      await FirebaseFirestore.instance
          .collection('riders')
          .doc(widget.uid)
          .update({
            'latitude': '',
            'longitude': '',
            'last_update': FieldValue.serverTimestamp(),
          });

      setState(() {
        deliveredImage = file;
        currentOrder?['status'] = 'ไรเดอร์นำส่งสินค้าแล้ว';
        currentOrder?['image_delivered'] = url;
        riderPos = null;
        pickupPos = null;
        receiverPos = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ ส่งสินค้าเรียบร้อยแล้ว 🎉')),
      );
    }
  }

  /// 🔹 ดึงพิกัดจาก Firestore
  Future<void> _fetchAddresses(Map<String, dynamic> order) async {
    try {
      final senderSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(order['sender_id'])
          .collection('addresses')
          .limit(1)
          .get();

      if (senderSnapshot.docs.isNotEmpty) {
        final sender = senderSnapshot.docs.first.data();
        pickupPos = LatLng(
          double.tryParse(sender['latitude'].toString()) ?? 0,
          double.tryParse(sender['longitude'].toString()) ?? 0,
        );
      }

      final receiverSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(order['receiver_id'])
          .collection('addresses')
          .limit(1)
          .get();

      if (receiverSnapshot.docs.isNotEmpty) {
        final receiver = receiverSnapshot.docs.first.data();
        receiverPos = LatLng(
          double.tryParse(receiver['latitude'].toString()) ?? 0,
          double.tryParse(receiver['longitude'].toString()) ?? 0,
        );
      }

      log("📍 sender: $pickupPos | receiver: $receiverPos");
    } catch (e) {
      log('❌ Error fetching addresses: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("จัดการการส่งสินค้า"),
        backgroundColor: const Color(0xFFFF3B30),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('rider_id', isEqualTo: widget.uid)
            .where(
              'status',
              whereIn: [
                'ไรเดอร์รับงานแล้ว (กำลังเดินทางไปรับสินค้า)',
                'ไรเดอร์รับสินค้าแล้ว (กำลังเดินทางไปส่ง)',
              ],
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('ไม่มีงานที่ต้องจัดส่งในขณะนี้'));
          }

          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          currentOrder = data;
          _fetchAddresses(data);

          final status = data['status'] ?? '';
          final canPickup = (distanceToPickup ?? 9999) <= 20;
          final canDeliver = (distanceToReceiver ?? 9999) <= 20;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  /// 🗺️ แผนที่
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter:
                            pickupPos ?? const LatLng(15.870031, 100.992541),
                        initialZoom: 14,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.rider_app',
                        ),
                        MarkerLayer(
                          markers: [
                            if (pickupPos != null)
                              Marker(
                                point: pickupPos!,
                                width: 60,
                                height: 60,
                                child: const Icon(
                                  Icons.location_on_sharp,
                                  color: Colors.green,
                                  size: 40,
                                ),
                              ),
                            if (receiverPos != null)
                              Marker(
                                point: receiverPos!,
                                width: 60,
                                height: 60,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.blue,
                                  size: 40,
                                ),
                              ),
                            if (riderPos != null)
                              Marker(
                                point: riderPos!,
                                width: 60,
                                height: 60,
                                child: const Icon(
                                  Icons.pedal_bike,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// 📸 ถ่ายรูปตอนรับสินค้า
                  ElevatedButton.icon(
                    onPressed:
                        status.toString().contains('ไปรับสินค้า') && canPickup
                        ? () => _captureAndUploadImage(true)
                        : null,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("ถ่ายรูป รับสินค้า"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canPickup
                          ? const Color(0xFFFF3B30)
                          : Colors.grey,
                    ),
                  ),
                  if (pickupImage != null)
                    Image.file(pickupImage!, height: 200, fit: BoxFit.cover),

                  const SizedBox(height: 16),

                  /// 📦 ถ่ายรูปตอนส่งสินค้า
                  ElevatedButton.icon(
                    onPressed: status.toString().contains('ไปส่ง') && canDeliver
                        ? () => _captureAndUploadImage(false)
                        : null,
                    icon: const Icon(Icons.camera),
                    label: const Text("ถ่ายรูป ส่งสินค้า"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canDeliver ? Colors.green : Colors.grey,
                    ),
                  ),
                  if (deliveredImage != null)
                    Image.file(deliveredImage!, height: 200, fit: BoxFit.cover),

                  const SizedBox(height: 16),

            
                  ElevatedButton.icon(
                    onPressed: () async {
                      bool confirmCancel = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('ยืนยันการยกเลิกการส่ง'),
                          content: const Text(
                            'คุณต้องการยกเลิกการส่งสินค้านี้ใช่หรือไม่?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('ไม่'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('ใช่'),
                            ),
                          ],
                        ),
                      );

                      if (confirmCancel == true && currentOrder != null) {
                        try {
                          final orderId = currentOrder!['order_id'];

                          await FirebaseFirestore.instance
                              .collection('orders')
                              .doc(orderId)
                              .update({
                                'status': 'รอไรเดอร์รับสินค้า',
                                'rider_id': '',
                                'rider_latitude': '',
                                'rider_longitude': '',
                                'rider_last_update':
                                    FieldValue.serverTimestamp(),
                                'canceled_at': FieldValue.serverTimestamp(),
                              });

                          await FirebaseFirestore.instance
                              .collection('riders')
                              .doc(widget.uid)
                              .update({
                                'latitude': '',
                                'longitude': '',
                                'last_update': FieldValue.serverTimestamp(),
                              });

                          _timer?.cancel();

                          setState(() {
                            _isFinished = true;
                            currentOrder = null;
                            riderPos = null;
                            pickupPos = null;
                            receiverPos = null;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '🚫 ยกเลิกการส่งสำเร็จ — งานกลับไปรอรับใหม่',
                              ),
                            ),
                          );
                        } catch (e) {
                          log('❌ Error cancel delivery: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('เกิดข้อผิดพลาดในการยกเลิก'),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text("ยกเลิกการส่งสินค้า"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 255, 0, 0),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// 📄 สถานะและข้อมูลระยะทาง
                  Text(
                    "สถานะ: $status",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (distanceToPickup != null)
                    Text(
                      "ระยะจากจุดรับสินค้า: ${distanceToPickup!.toStringAsFixed(1)} ม.",
                      style: TextStyle(
                        color: (distanceToPickup ?? 999) <= 20
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  if (distanceToReceiver != null)
                    Text(
                      "ระยะจากจุดส่งสินค้า: ${distanceToReceiver!.toStringAsFixed(1)} ม.",
                      style: TextStyle(
                        color: (distanceToReceiver ?? 999) <= 20
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}