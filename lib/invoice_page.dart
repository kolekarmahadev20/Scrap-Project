import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class InvoicePage extends StatefulWidget {
  final String salesId;

  const InvoicePage({super.key, required this.salesId});

  @override
  State<InvoicePage> createState() => InvoicePageState();
}
class InvoicePageState extends State<InvoicePage> {
  bool showPayment = true; // default = payment screen
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
            : SingleChildScrollView(
          child: Column(
            children: [
              Container(
                child: Column(
                  children: [
                    Container(
                      child:Column(
                        children: [
                          ...displayLifting.map((item) {
                            double qty = double.tryParse(item['qty'].toString()) ?? 0;
                            double rate = double.tryParse(item['rate'].toString()) ?? 0;

                            double total = qty * rate;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                    margin: EdgeInsets.only(top:15,bottom:23,right: 18,left: 18),
                                    decoration: BoxDecoration(
                                      border: Border(bottom: BorderSide(color: Colors.black12,width: 2),),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Invoice No: ${item['invoice_no'] ?? ''}",style: TextStyle(fontWeight: FontWeight.bold,color: Colors.deepPurple,fontSize: 20),),
                                        Icon(Icons.image,color: Colors.deepPurple,)
                                      ],
                                    )),
                                SizedBox(
                                  height: 10,
                                ),
                                Container(
                                    margin: EdgeInsets.only(top: 10,bottom: 10,right: 18,left: 18),
                                    width: 400,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(25),
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

                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(25),
                                      child: Padding(padding: const EdgeInsets.only(top: 13,bottom: 13,right: 13,left: 13),
                                        child: Table(
                                          columnWidths: const {
                                            0: IntrinsicColumnWidth(),
                                            1: FlexColumnWidth(),
                                          },
                                          children: [
                                            TableRow(children: [
                                              cell(title: 'Vendor Name:'),
                                              _ValueCell(
                                                  value: ' ${SaleDetails!['vendor_name'] ?? ''}')
                                            ]),
                                            TableRow(children: [
                                              cell(title: 'Buyer Name:'),
                                              _ValueCell(
                                                  value: '${SaleDetails!['bidder_name'] ?? ''}')
                                            ]),

                                            TableRow(children: [
                                              cell(title: 'Branch:'),
                                              _ValueCell(
                                                  value:
                                                  '${SaleDetails!['branch_name'] ?? ''}')
                                            ]),
                                          ],
                                        ),
                                      ),
                                    )
                                ),
                                Container(
                                color: Colors.white,
                            margin: EdgeInsets.only(top: 20, bottom: 20, right: 10, left: 10),
                            child: Table(
                              border: TableBorder.all(
                            color: Colors.black,
                            width: 1,
                            ),
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
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 22),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                children: const [
                                                Icon(Icons.receipt_long, color: Colors.deepPurple),
                                                SizedBox(width: 6),
                                                Text(
                                                'INVOICE NO',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                          ),
                                      ),
                                    ),
                                    TableCell(
                                    verticalAlignment: TableCellVerticalAlignment.middle,
                                    child:  Container(
                                      width:double.infinity,
                                      height: 42,
                                      color:Colors.black12,
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 7,top: 10),
                                        child: Text('${item['invoice_no'] ?? 'N/A'}', style: const TextStyle(fontSize: 14,fontWeight: FontWeight.bold,)
                                        ),
                                      ),
                                    ),
                                    ),
                                  ],
                                  ),

                            TableRow(
                            children: [
                              Container(
                                color:Colors.black12,
                                child: TableCell(
                                  verticalAlignment: TableCellVerticalAlignment.middle,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 22),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: const [
                                        Icon(Icons.event_available, color: Colors.deepPurple),
                                        SizedBox(width: 6),
                                        Text(
                                        'DATE',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ),
                              ),
                              TableCell(
                              verticalAlignment: TableCellVerticalAlignment.middle,
                              child: _ValueCell(
                              value: '${item['date_time'] ?? ''}',
                              ),
                              ),
                            ],
                            ),

                            TableRow(
                            children: [
                              TableCell(
                                verticalAlignment: TableCellVerticalAlignment.middle,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 22),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: const [
                                      Icon(Icons.warehouse, color: Colors.deepPurple),
                                      SizedBox(width: 6),
                                      Text(
                                      'MATERIAL NAME',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      ],
                                    ),
                                  ),
                              ),
                              TableCell(
                              verticalAlignment: TableCellVerticalAlignment.middle,
                              child: Container(
                                width:double.infinity,
                                height: 58,
                                color:Colors.black12,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 7,top:10),
                                  child: Text('${item['material_name'] ?? 'N/A'}', style: const TextStyle(fontSize: 14,fontWeight: FontWeight.bold,)
                                  ),
                                ),
                              ),
                              ),
                            ],
                            ),

                            TableRow(
                            children: [
                              Container(
                                color:Colors.black12,
                                child: TableCell(
                                  verticalAlignment: TableCellVerticalAlignment.middle,
                                  child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 22),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: const [
                                      Icon(Icons.local_shipping, color: Colors.deepPurple),
                                      SizedBox(width: 6),
                                      Text(
                                      'TRUCK NO',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                verticalAlignment: TableCellVerticalAlignment.middle,
                                child: Container(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 7),
                                    child: Text('${item['truck_no'] ?? ''}', style: const TextStyle(fontSize: 14,fontWeight: FontWeight.bold,)
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            ),

                            TableRow(
                            children: [
                              TableCell(
                                verticalAlignment: TableCellVerticalAlignment.middle,
                                child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 22),
                                  child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: const [
                                  Icon(Icons.all_inbox_rounded, color: Colors.deepPurple),
                                  SizedBox(width: 6),
                                  Text(
                                  'QTY',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  ],
                                  ),
                                ),
                              ),
                              TableCell(
                                verticalAlignment: TableCellVerticalAlignment.middle,
                                child: Container(
                                  width:double.infinity,
                                  height: 42,
                                  color:Colors.black12,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 7,top:10),
                                    child: Text('${item['qty'] ?? 'N/A'}', style: const TextStyle(fontSize: 14,fontWeight: FontWeight.bold,)
                                    ),
                                  ),
                                ),
                                ),
                            ],
                            ),

                            TableRow(
                            children: [
                              Container(
                                color:Colors.black12,
                                child: TableCell(
                                  verticalAlignment: TableCellVerticalAlignment.middle,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 22),
                                        child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: const [
                                        Icon(Icons.currency_rupee, color: Colors.deepPurple),
                                        SizedBox(width: 6),
                                        Text(
                                        'BASIC AMOUNT',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        ],
                                        ),
                                    ),
                                ),
                              ),
                              TableCell(
                              verticalAlignment: TableCellVerticalAlignment.middle,
                              child: _ValueCell(
                              value: '$total',
                              ),
                              ),
                            ],
                            ),
                            ],
                            ),
                            ),
                                SizedBox(
                                  height: 10,
                                ),
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
                                          child:Padding(
                                            padding: const EdgeInsets.only(top: 13,bottom: 20,right: 25,left: 25),
                                            child: Column(
                                              children: [
                                                if (item['tax_details'].isNotEmpty)
                                                  Column(
                                                    children: [
                                                      ...(item['tax_details']).map((tax){
                                                        return Container(
                                            child: Column(
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    border: Border(bottom: BorderSide(color: Colors.black12,width: 2),),
                                                  ),
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(bottom: 6,top: 6),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text("${tax['tax_name']}@${tax['tax_rate']}% ",
                                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                        Text('₹${tax['tax_value']}',style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))

                                                      ],
                                                    ),
                                                  ),
                                                )
                                              ],
                                            )
                                                        );
                                                        },
                                                      ),],
                                                  ),
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 6),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text("FINAL AMOUNT",
                                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.deepPurple)),
                                                      Text('₹${item['total_amt']}',style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.deepPurple))
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                          )
                                          ),
                                    ],
                                  ),
                                )

                              ],
                            );
                          }).toList(),
                        ],
                      ) ,
                    ),

                  ],
                ),
              )
            ],
          )

        )
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
        style: const TextStyle( fontSize: 15,fontWeight:FontWeight.bold),
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