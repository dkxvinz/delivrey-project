import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_address_page.dart';

class AddressesListPage extends StatefulWidget {
  final String uid;
  const AddressesListPage({super.key, required this.uid});

  @override
  State<AddressesListPage> createState() => _AddressesListPageState();
}

class _AddressesListPageState extends State<AddressesListPage> {
  List<Map<String, dynamic>> addressesList = [];
  bool _isLoading = true;

  Future<void> _fetchAddresses() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('addresses')
        .get();

    setState(() {
      addressesList = snapshot.docs
          .map((doc) => {'aid': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ที่อยู่ของฉัน',style: TextStyle(color: Color(0xffffffff)),),
        backgroundColor: const Color(0xffff3b30),
        iconTheme: IconThemeData(color: Color(0xffffffff)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : addressesList.isEmpty
              ? const Center(child: Text('ยังไม่มีที่อยู่'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: addressesList.length,
                  itemBuilder: (context, index) {
                    final addr = addressesList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(addr['address'] ?? 'ไม่มีข้อมูล'),
                        subtitle: Text(
                            'Lat: ${addr['latitude']} | Lng: ${addr['longitude']}'),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xffff3b30),
        icon: const Icon(Icons.add_location_alt,color: Color(0xffffffff),),
        label: const Text('เพิ่มที่อยู่',style: TextStyle(color: Color(0xffffffff),fontWeight: FontWeight.bold,fontSize: 15),),
        onPressed: () async {
          // ไปหน้าฟอร์มเพิ่ม
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddAddressPage(uid: widget.uid),
            ),
          );
          // โหลดใหม่เมื่อกลับมา
          _fetchAddresses();
        },
      ),
    );
  }
}
