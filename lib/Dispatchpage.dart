import 'package:flutter/material.dart';
import 'package:scrap_project/invoice_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class DispatchPage extends StatefulWidget {
  final String salesId;

  const DispatchPage({super.key, required this.salesId});

  @override
  State<DispatchPage> createState() => DispatchPageState();
}
class DispatchPageState extends State<DispatchPage> {
  bool showPayment = true;  // default = payment screen
  String user_id = '';
  String password = '';
  String uuid = '';
  Map<String, dynamic>? SaleDetails;
  Map<String, dynamic>? PaymentDetails;
  List<Map<String, dynamic>> liftingList = [];






  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    showPayment = true;
    _loadCredentialsAndFetch();

  }

  Future<void> _loadCredentialsAndFetch() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      user_id = prefs.getString('user_id') ?? '';
      password = prefs.getString('user_pass') ?? '';
      uuid = prefs.getString('uuid') ?? '';
    });

    if (user_id.isNotEmpty && password.isNotEmpty && uuid.isNotEmpty) {
      await _fetchPaymentData();

    } else {
      setState(() => errorMessage = 'Missing credentials.');
    }
  }

  // Step 1: Fetch sale order data
  Future<void> _fetchPaymentData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      SaleDetails = null;
      PaymentDetails = null;
    });

    try {
      final url = Uri.parse(
          'https://scrap.systementerprises.in/api/Comp_login/fetch_payment_data');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'user_id': user_id,
          'user_pass': password,
          'uuid': uuid,
          'sales_id': widget.salesId,
        },
      );

      print('Fetch Payment Data Response: ${response.body}');
      final data = jsonDecode(response.body);
      if (data != null && data.isNotEmpty) {
        // convert map to list before setState
        // --- FIX for handling both Map and List ---




        setState(() {
          PaymentDetails = data;



      });

      }



      if (data['saleOrder_paymentList'] != null &&
          data['saleOrder_paymentList'].isNotEmpty) {
        final filtered = (data['saleOrder_paymentList'] as List).firstWhere(
              (item) => item['sale_order_id'].toString() == widget.salesId,
          orElse: () => {},

        );

        if (filtered.isNotEmpty) {
          setState(() {
            SaleDetails = filtered;

          });
          // Step 2: Use extracted IDs to fetch payment details
          await _fetchPaymentDetails(filtered);
        } else {
          setState(() => errorMessage = 'No data found for this Sale ID.');
        }
      } else {
        setState(() => errorMessage = 'No data found in response.');
      }
    } catch (e) {
      setState(() => errorMessage = 'Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Step 2: Fetch payment_details using IDs from SaleDetails['Ids']
  Future<void> _fetchPaymentDetails(Map<String, dynamic> saleData) async {
    try {
      final ids = saleData['Ids'];
      if (ids == null) {
        setState(() => errorMessage = 'Missing ID details in response.');
        return;
      }

      final url = Uri.parse(
          'https://scrap.systementerprises.in/api/Comp_login/payment_details');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'user_id': user_id,
          'user_pass': password,
          'uuid': uuid,
          'sale_order_id': widget.salesId,
          'bidder_id': ids['bidder_id'].toString(),
          'vendor_id': ids['vendor_id'].toString(),
          'branch_id': ids['branch_id'].toString(),
          'mat_id': ids['mat_id'].toString(),
        },
      );

      print('Payment Details Response: ${response.body}');
      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        setState(() => errorMessage = "Invalid response format.");
        return;
      }
      if (data.isNotEmpty) {
        final rawLifting = data["material_lifting_details"];

        List<Map<String, dynamic>> safeList = [];

        if (rawLifting is Map) {
          print("✔ Lifting is MAP");
          print("RAW LIFTING DETAILS >>> $rawLifting");

          safeList = rawLifting.values
              .map((e) => e as Map<String, dynamic>)
              .toList();
        } else if (rawLifting is List) {
          print("✔ Lifting is LIST");
          print("RAW LIFTING DETAILS >>> $rawLifting");

          safeList = rawLifting
              .map((e) => e as Map<String, dynamic>)
              .toList();
        } else {
          print("❌ LIFTING UNKNOWN TYPE");
        }
        print("RAW LIFTING DETAILS >>> ${data['material_lifting_details']}");


        setState(() {
          PaymentDetails = data;
          liftingList = safeList;

        });
      } else {
        setState(() => errorMessage = 'No payment details found.');
      }
    } catch (e) {
      setState(() => errorMessage = 'Error fetching payment details: $e');
    }

  }


  @override
  Widget build(BuildContext context) {
    final displayLifting = liftingList;
    final bool noLifting = liftingList.isEmpty;
    return Scaffold(
      appBar:
      AppBar(
        title: const Text(
          'Sale Order',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurpleAccent,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(
          child: Text(errorMessage,
              style: const TextStyle(color: Colors.red)))
          : SaleDetails == null
          ? const Center(child: Text('No payment data found'))
          :SingleChildScrollView(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        margin: EdgeInsets.only(top: 20,bottom: 20,right: 15,left: 15),
        width: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade100.withOpacity(0.4), // soft grey shadow
              spreadRadius: 2, // small spread
              blurRadius: 10, // softness of shadow
              offset: const Offset(2, 7), // position of shadow (x, y)
            ),
          ],


        ),
        child: Column(
          children: [
            SizedBox(height: 22,),
            Container(
              width: 300,
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.black12,width: 2),
                  bottom: BorderSide(color: Colors.black12,width: 2),),

              ),
              child: Center(child: Text('${SaleDetails!['description'] ?? ''}',style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),)),
            ),
            Container(
              margin: EdgeInsets.only(top: 15,bottom: 15,right: 20,left: 20),
              child: Table(
                  columnWidths: const {
                    0: IntrinsicColumnWidth(),
                    1: FlexColumnWidth(),
                  },
                  children: [
                    TableRow(children: [
                      cell(title: 'Material Name:'),
                      _ValueCell(
                          value: '${SaleDetails!['description'] ?? ''}')
                    ]),
                    TableRow(children: [
                      cell(title: 'Vendor Name:'),
                      _ValueCell(
                          value: ' ${SaleDetails!['vendor_name'] ?? ''}')
                    ]),
                    TableRow(children: [
                      cell(title: 'Branch:'),
                      _ValueCell(
                          value:
                          '${SaleDetails!['branch_name'] ?? ''}')
                    ]),
                    TableRow(children: [
                      cell(title: 'Buyer Name:'),
                      _ValueCell(
                          value:
                          '${SaleDetails!['bidder_name'] ?? ''}')
                    ]),
                  ]
              ),
            ),

          ],
        ),
      ),
      ...PaymentDetails!['sale_order_details'].map<Widget>((detail) {
        return Container(
          color: Colors.white,
          margin: EdgeInsets.only(top: 20, bottom: 20, right: 10, left: 10),
          child: Table(
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth(),
            },
            children: [
              TableRow(
                children: [
                  TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                          Icon(Icons.warehouse, color: Colors.deepPurple),
                          SizedBox(width: 6),
                          Text(
                            'Material Name:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: _ValueCell(
                      value: '${detail['material_name'] ?? ''}',
                    ),
                  ),
                ],
              ),

              TableRow(
                children: [
                  TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                          Icon(Icons.all_inbox, color: Colors.deepPurple),
                          SizedBox(width: 6),
                          Text(
                            'Total Qty:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: _ValueCell(
                      value: '${detail['totalqty'] ?? ''}',
                    ),
                  ),
                ],
              ),

              TableRow(
                children: [
                  TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                          Icon(Icons.local_shipping, color: Colors.deepPurple),
                          SizedBox(width: 6),
                          Text(
                            'Lifted Qty:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: _ValueCell(
                      value: '${detail['lifted_qty'] ?? '0.000'}',
                    ),
                  ),
                ],
              ),

              TableRow(
                children: [
                  TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                          Icon(Icons.currency_rupee, color: Colors.deepPurple),
                          SizedBox(width: 6),
                          Text(
                            'Rate:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: _ValueCell(
                      value: '${detail['rate'] ?? ''}',
                    ),
                  ),
                ],
              ),

              TableRow(
                children: [
                  TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                          Icon(Icons.event, color: Colors.deepPurple),
                          SizedBox(width: 6),
                          Text(
                            'SO Date:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: _ValueCell(
                      value: '${detail['sod'] ?? ''}',
                    ),
                  ),
                ],
              ),

              TableRow(
                children: [
                  TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                          Icon(Icons.hourglass_bottom, color: Colors.deepPurple),
                          SizedBox(width: 6),
                          Text(
                            'SO Validity:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: _ValueCell(
                      value: '${detail['sovu'] ?? ''}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
      Container(
        margin: const EdgeInsets.only(top: 20, bottom: 20, right: 15, left: 15),
        width: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade100.withOpacity(0.4),
              spreadRadius: 2,
              blurRadius: 10,
              offset: Offset(2, 7),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 20,bottom: 20,right: 20,left: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lifted Quantity: '
                    '${(PaymentDetails!['lifted_quantity'] is List && PaymentDetails!['lifted_quantity'].isNotEmpty)
                    ? PaymentDetails!["lifted_quantity"][0]["quantity"]
                    : "0"} MT  '
                    '${PaymentDetails!['total_material_lifted_amount'] ?? "0"}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10,),

              Text(
                'SO Balance Qty: '
                    '${PaymentDetails!['balance_qty'] ?? "0"} MT '
                    '${PaymentDetails!['total_balance'] ?? "0"}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      SizedBox(height: 25,),
      if (PaymentDetails != null && PaymentDetails!['tax_and_rate'] != null)
        Container(
          child: Column(
            children: [
              Center(child: Text('Tax Invoice',style: TextStyle(color: Colors.deepPurple,fontSize: 20,fontWeight: FontWeight.bold),)),
              Container(
                  margin: EdgeInsets.only(top: 10,bottom: 10,right: 15,left: 15),
                  width: 400,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.shade100.withOpacity(0.4), // soft grey shadow
                        spreadRadius: 2, // small spread
                        blurRadius: 10, // softness of shadow
                        offset: const Offset(2, 7), // position of shadow (x, y)
                      ),
                    ],
                  ),
                  child:Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 25,right: 25,left: 25),
                          child: Container(
                            height: 30,
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.black12,width:2),),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Basic Amount',style:TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                                Text('₹ ${PaymentDetails!['tax_and_rate']['basicTaxAmount']}',style:TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),


                              ],
                            ),
                          ),
                        ),
                      ),
                      if (PaymentDetails!['tax_and_rate']['taxes'] != null)
                        ...List.generate(
                            PaymentDetails!['tax_and_rate']['taxes'].length,
                                (index) {
                              final tax = PaymentDetails!['tax_and_rate']['taxes'][index];
                              return Container(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 25,left: 25),
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      border: Border(bottom: BorderSide(color: Colors.black12,width: 2),),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text('${tax['tax_name']}',style:TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                                        Text('₹ ${tax['tax_amount']}',style:TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),


                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                        ),
                      Container(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 5,bottom:13,right: 25,left: 25),
                          child: Container(
                            height: 30,

                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Final Amount',style:TextStyle(fontSize: 15,fontWeight: FontWeight.bold,color: Colors.deepPurple),),
                                Text('₹ ${PaymentDetails!['tax_and_rate']['finalTaxAmount']}',style:TextStyle(fontSize: 15,fontWeight: FontWeight.bold,color: Colors.deepPurple),),


                              ],
                            ),
                          ),
                        ),
                      ),


                    ],
                  )

              ),
            ],
          ),
        ),
        Container(

          child:noLifting
        ? Container(
              margin: EdgeInsets.only(top: 18,bottom: 18,right: 10,left: 10),
              width: 400,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.shade100.withOpacity(0.4), // soft grey shadow
                    spreadRadius: 2, // small spread
                    blurRadius: 10, // softness of shadow
                    offset: const Offset(2, 7), // position of shadow (x, y)
    ),
              ],
              ),
          child: Padding(
            padding: const EdgeInsets.only(top:10,bottom: 10),
            child: Center(
              child: const Text(
              "No lifting details available",
                style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                ),
                ),
            ),
          ),
        )
        : TextButton(onPressed: (){
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  InvoicePage(salesId: widget.salesId ),
            ),
          );
        },
          child: Container(
          margin: EdgeInsets.only(top: 10,bottom: 10,right: 10,left: 10),
          width: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.red.shade100.withOpacity(0.4), // soft grey shadow
                spreadRadius: 2, // small spread
                blurRadius: 10, // softness of shadow
                offset: const Offset(2, 7), // position of shadow (x, y)
              ),
            ],
          ),
          child:Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 10,bottom: 10,right: 15,left: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.deepPurple,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7,bottom: 7,left: 10),
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long,
                            color: Colors.white,),
                          Text(" Invoice: ${(PaymentDetails?['material_lifting_details'] is Map &&
                              PaymentDetails!['material_lifting_details']['1'] is Map &&
                              PaymentDetails!['material_lifting_details']['1']['invoice_no'] != null)
                              ? PaymentDetails!['material_lifting_details']['1']['invoice_no']
                              : 'N/A'}",style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 5,),
              Container(
                margin: EdgeInsets.only(bottom: 10,right: 15,left: 15),
                child: Column(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...displayLifting.map((item) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.warehouse, color: Colors.deepPurple),
                                  SizedBox(width: 6),

                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        children: [
                                          const TextSpan(text: "Material: "),
                                          TextSpan(text: item['material_name'] ?? ''),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.currency_rupee_rounded,color: Colors.deepPurple),
                                  SizedBox(width: 6),
                                  Text("Lifted Rate: ₹${item['rate'] ?? ''}",
                                      style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [Icon(Icons.edit_calendar,color: Colors.deepPurple),
                                  SizedBox(width: 6),
                                  Text("Date: ${item['date_time'] ?? ''}",
                                      style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [ Icon(Icons.person,color: Colors.deepPurple),
                                  SizedBox(width: 6),
                                  Text("Dispatch By: ${item['person_name'] ?? ''}",
                                      style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
                                ],
                              ),
                              SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: (item['status'] ?? '').toString().toLowerCase() == 'c'
                                      ? Colors.green.shade300
                                      : Colors.red.shade400,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 10),
                                  child: Text(
                                      "User Dispatch: ${(item['user_status'] ?? '').toString().toLowerCase() == 'c'
                                          ? 'Dispatch Completed'
                                          : 'Pending'}",style: TextStyle(color: (item['user_status'] ?? '').toString().toLowerCase() == 'c'
                                      ? Colors.green.shade900
                                      : Colors.red.shade900,fontWeight: FontWeight.bold)),
                                ),
                              ),
                              SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: (item['status'] ?? '').toString().toLowerCase() == 'c'
                                      ? Colors.green.shade300
                                      : Colors.red.shade400,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 10),
                                  child: Text(
                                      "S/A Dispatch: ${(item['status'] ?? '').toString().toLowerCase() == 'c'
                                          ? 'Dispatch Completed'
                                          : 'Pending'}",style: TextStyle(color: (item['status'] ?? '').toString().toLowerCase() == 'c'
                                      ? Colors.green.shade900
                                      : Colors.red.shade900,fontWeight: FontWeight.bold)),
                                ),
                              ),

                              SizedBox(height: 10),
                            ],
                          );
                        }).toList(),
                      ],
                    )



                  ],
                ),
              )
            ],

          ),

        ),)



        )]
    )
      ),


      // 🔵 Bottom toggle — Dispatch selected
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ToggleButtons(
              isSelected: [false, true], // dispatch selected
              borderRadius: BorderRadius.circular(22),
              fillColor: Colors.deepPurpleAccent,
              selectedColor: Colors.white,
              color: Colors.black,
              constraints: const BoxConstraints(minHeight: 45, minWidth: 160),
              children: const [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payment_rounded),
                    Text("Payment Details"),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_shipping),
                    Text("Dispatch Details"),
                  ],
                ),
              ],
              onPressed: (index) {
                if (index == 0) {
                  Navigator.pop(context); // 👉 go back to payment page
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}


// 🔹 Title Cell Widget
class cell extends StatelessWidget {
  final String title;
  const cell({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Text(
        title,
        style: const TextStyle( fontSize: 15),
      ),
    );
  }
}

/// 🔹 Value Cell Widget
class _ValueCell extends StatelessWidget {
  final String value;
  const _ValueCell({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Text(
        value,
        style: const TextStyle(fontSize: 14,fontWeight: FontWeight.bold),
      ),
    );
  }
}




