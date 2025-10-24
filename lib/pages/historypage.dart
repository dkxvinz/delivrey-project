import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Historypage extends StatefulWidget {
  final String uid;
  const Historypage({super.key, required this.uid});

  @override
  State<Historypage> createState() => _HistorypageState();
}

class _HistorypageState extends State<Historypage> {

  @override
  void initState() {
    super.initState();
    _fetchOrders(); 
  }

  List<Map<String, dynamic>> ordersList = [];
  bool _isLoading = true;


  
  Future<void> _fetchOrders() async {
    try {
      final orderSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('sender_id',isEqualTo:widget.uid)
          .where('status',isEqualTo: 'ไรเดอร์นำส่งสินค้าแล้ว').get();
     
        
   

      List<Map<String,dynamic>> tempOrder = [];

      for (var itemOne in orderSnapshot.docs){
          final orderData = itemOne.data();
             if(orderData['sender_id'] == widget.uid || orderData['receiver_id'] == widget.uid){


        final senderDoc = await  FirebaseFirestore.instance.collection('users').doc(orderData['sender_id']).get();
          final receiverDoc = await  FirebaseFirestore.instance.collection('users').doc(orderData['receiver_id']).get();


        tempOrder.add({
              'order_id': itemOne.id,
              'item': orderData['items'] ?? [],
              'sender_name': senderDoc.exists ? senderDoc['fullname'] : null,
              'sender_phone': senderDoc.exists ? senderDoc['phone'] : null,
              'sender_address': orderData['sender_address']??'',
              'receiver_name': receiverDoc.exists ? receiverDoc['fullname'] : null,
              'receiver_phone': receiverDoc.exists ? receiverDoc['phone'] : null,
               'receiver_address': orderData['receiver_address']?? '',
              'status': orderData['status']??'',


        });
          
        print('All orders: $tempOrder');

        }
        
       
    
        setState(() {
          ordersList = tempOrder;
          _isLoading = false;
        });
      }
      
    } catch (e) {
      print('Error fetching orders: $e');
      
      setState(() => _isLoading = false);
    }
  
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffff3b30),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(150.0),
        child: AppBar(
          backgroundColor: const Color(0xffff3b30),
          automaticallyImplyLeading: false,
          flexibleSpace: Padding(
            padding: const EdgeInsets.only(top: 120.0,),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Text(
                        'ประวัติรายการส่งสินค้า',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      
                    ),

                    // CircleAvatar(
                    //   radius: 20,
                    //   backgroundImage: NetworkImage(),
                    // ),
                  ],
                ),
                const SizedBox(height: 10),
                
              ],
            ),
          ),
         
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            height: MediaQuery.of(context).size.height*0.6811,
            width: double.infinity,
            decoration: BoxDecoration(color: Color(0XFFFFFFFF),
            borderRadius: BorderRadius.only(topRight: Radius.circular(20),topLeft: Radius.circular(20)) ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ordersList.isEmpty
                    ? const Center (child: Text('ไม่มีประวัติการส่งของคุณ'))
                    : ListView.builder(
                        itemCount: ordersList.length,
                        itemBuilder: (context, index) {
                          var order = ordersList[index];
                          final items = order['item'] as List<dynamic>; // list ของ item

                          return Column(
                            children:  items.map((item){
                              return Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: _buildHistoryItem(
                                  imageUrl: item['imageUrl'] ?? '',
                                  itemDetail: item['detail'] ?? 'ไม่ระบุรายละเอียดสินค้า',
                                  senderName: order['sender_name']?? 'ไม่ระบุชื่อผู้ส่ง',
                                  senderAddress:
                                      order['sender_address'] ?? 'ไม่ระบุที่อยู่ผู้ส่ง',
                                  senderPhone: order['sender_phone'] ?? '-',
                                  receiverName:
                                      order['receiver_name'] ?? 'ไม่ระบุชื่อผู้รับ',
                                    receiverAddress:
                                      order['receiver_address'] ?? 'ไม่ระบุที่อยู่ผู้รับ',
                                    receiverPhone: order['receiver_phone'] ?? '-', 
                                    status: order['status'] ?? 'ไม่มีสเตตัส',
                                    
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem({
    required String imageUrl,
    required String itemDetail,
    required String senderName,
    required String senderAddress,
    required String senderPhone,
    required String receiverName,
    required String receiverAddress,
    required String receiverPhone,
    required String status,
    
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.grey,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.network(
                        imageUrl.isNotEmpty
                            ? imageUrl :imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                    size: 40,
                  ),
                );
                          },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemDetail,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          
                        ),
                      
                      ],
                    ),
                    
                  ],
                ),
                SizedBox(height: 10,),
                 Row(
                      children: [
                        Text('สถานะ:'),
                        // SizedBox(width:5,),
                        Text(status, style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,fontWeight: FontWeight.bold,
                          ),),
                      ],
                    )
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 0.0),
              child: Divider(),
            ),
            _buildAddressInfo(
              title: 'ผู้ส่ง:',
              name: senderName,
              address: senderAddress,
              phone: senderPhone,
            ),
             const Padding(
              padding: EdgeInsets.symmetric(vertical:0.0),
              child: Divider(),
            ),
            
            const SizedBox(height: 5),
            _buildAddressInfo(
              title: 'ผู้รับ:',
              name: receiverName,
              address: receiverAddress,
              phone: receiverPhone,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildAddressInfo({
    required String title,
    required String name,
    required String address,
    required String phone,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),overflow: TextOverflow.ellipsis,maxLines: 3,
              ),
              Text(
                address,
                style: TextStyle(fontSize: 14, color: Colors.grey[800]),overflow: TextOverflow.ellipsis,maxLines: 3,
              ),
              Text(
                'เบอร์โทร: $phone',
                style: TextStyle(fontSize: 14, color: Colors.grey[800]),overflow: TextOverflow.ellipsis,maxLines: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }
  



}
