import 'package:flutter/material.dart';
import 'package:scrap_project/Dispatchpage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Payment extends StatefulWidget {
  final String Sales_id;
  const Payment({super.key, required this.Sales_id});

  @override
  State<Payment> createState() => PaymentState();
}

class PaymentState extends State<Payment> {
  bool showPayment = true;  // default = payment screen
  String user_id = '';
  String password = '';
  String uuid = '';
  Map<String, dynamic>? SaleDetails;
  Map<String, dynamic>? PaymentDetails;

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
          'sales_id': widget.Sales_id,
        },
      );

      print('Fetch Payment Data Response: ${response.body}');
      final data = jsonDecode(response.body);

      if (data['saleOrder_paymentList'] != null &&
          data['saleOrder_paymentList'].isNotEmpty) {
        final filtered = (data['saleOrder_paymentList'] as List).firstWhere(
              (item) => item['sale_order_id'].toString() == widget.Sales_id,
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
          'sale_order_id': widget.Sales_id,
          'bidder_id': ids['bidder_id'].toString(),
          'vendor_id': ids['vendor_id'].toString(),
          'branch_id': ids['branch_id'].toString(),
          'mat_id': ids['mat_id'].toString(),
        },
      );

      print('Payment Details Response: ${response.body}');
      final data = jsonDecode(response.body);

      if (data != null && data.isNotEmpty) {
        setState(() {
          PaymentDetails = data;
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

            SizedBox(height: 10,),
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
                                            border: Border(bottom: BorderSide(color: Colors.black12,width: 2),),
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
                    SizedBox(height: 20),
                    Container(
                    child: Column(
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
                        child:Padding(
                          padding: const EdgeInsets.only(top: 22,bottom: 25,right: 24,left: 15),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Icon(Icons.verified,color: Colors.deepPurple,size: 25,),
                                      SizedBox(
                                        width: 7,
                                      ),
                                      Text('EMD Details',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Colors.deepPurple),)
                                    ],
                                  ),
                                  IconButton(onPressed: (){}, icon:Icon(Icons.arrow_forward_ios_rounded,color: Colors.deepPurple,))
                                ],
                              ),
                              SizedBox(height: 20,),
                              PaymentDetails!['emd_status'] != null &&
                                  (PaymentDetails!['emd_status'] is Map<String, dynamic> ||
                                      (PaymentDetails!['emd_status'] is String &&
                                          PaymentDetails!['emd_status'] != "[]" &&
                                          PaymentDetails!['emd_status'].toString().isNotEmpty))
                                  ? (() {
                                final emdStatusRaw = PaymentDetails!['emd_status'];

                                // If it's a Map, use it directly
                                final emdStatus = emdStatusRaw is Map<String, dynamic>
                                    ? emdStatusRaw
                                    : null;

                                if (emdStatus == null) {
                                  return const Text('No data available',style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),);
                                }

                                return Table(
                                  columnWidths: const {
                                    0: IntrinsicColumnWidth(),
                                    1: FlexColumnWidth(),
                                  },
                                  children: [
                                    TableRow(children: [
                                      cell(title: 'Amount:'),
                                      _ValueCell(value: '${emdStatus['amt'] ?? '-'}'),
                                    ]),
                                    TableRow(children: [
                                      cell(title: 'Payment ID:'),
                                      _ValueCell(value: '${emdStatus['payment_id'] ?? '-'}'),
                                    ]),
                                    TableRow(children: [
                                      cell(title: 'Payment Type:'),
                                      _ValueCell(value: '${emdStatus['payment_type'] ?? '-'}'),
                                    ]),
                                    TableRow(children: [
                                      cell(title: 'Pay Ref No:'),
                                      _ValueCell(value: '${emdStatus['pay_ref_no'] ?? '-'}'),
                                    ]),
                                    TableRow(children: [
                                      cell(title: 'Date:'),
                                      _ValueCell(value: '${emdStatus['date'] ?? '-'}'),
                                    ]),
                                    TableRow(children: [
                                      cell(title: 'Type of Transfer:'),
                                      _ValueCell(value: '${emdStatus['typeoftransfer'] ?? '-'}'),
                                    ]),
                                  ],
                                );
                              })()
                                  : Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      const Text('No data available',style: TextStyle(fontSize:15,fontWeight: FontWeight.bold),),
                                    ],
                                  ),
                            ],
                          ),
                        )
                    )
                    ]
                    )
                    ),


                    //CMD DETAils
                    Container(
                        child: Column(
                            children: [
                              Container(
                                  margin: EdgeInsets.only(top: 15,bottom: 25,right: 15,left: 15),
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
                                    padding: const EdgeInsets.only(top: 22,bottom: 25,right: 24,left: 15),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              children: [
                                                Icon(Icons.account_balance,color: Colors.deepPurple,size: 25,),
                                                SizedBox(
                                                  width: 7,
                                                ),
                                                Text('CMD Details',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Colors.deepPurple),)
                                              ],
                                            ),
                                            IconButton(onPressed: (){}, icon:Icon(Icons.arrow_forward_ios_rounded,color: Colors.deepPurple,))
                                          ],
                                        ),
                                        SizedBox(height: 20,),
                                        PaymentDetails!['cmd_status'] != null &&
                                            (PaymentDetails!['cmd_status'] is Map<String, dynamic> ||
                                                (PaymentDetails!['emd_status'] is String &&
                                                    PaymentDetails!['cmd_status'] != "[]" &&
                                                    PaymentDetails!['cmd_status'].toString().isNotEmpty))
                                            ? (() {
                                          final cmdStatusRaw = PaymentDetails!['cmd_status'];

                                          // If it's a Map, use it directly
                                          final cmdStatus = cmdStatusRaw is Map<String, dynamic>
                                              ? cmdStatusRaw
                                              : null;

                                          if (cmdStatus == null) {
                                            return const Text('No data available',style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),);
                                          }

                                          return Table(
                                            columnWidths: const {
                                              0: IntrinsicColumnWidth(),
                                              1: FlexColumnWidth(),
                                            },
                                            children: [
                                              TableRow(children: [
                                                cell(title: 'Amount:'),
                                                _ValueCell(value: '${cmdStatus['amt'] ?? '-'}'),
                                              ]),
                                              TableRow(children: [
                                                cell(title: 'Payment ID:'),
                                                _ValueCell(value: '${cmdStatus['payment_id'] ?? '-'}'),
                                              ]),
                                              TableRow(children: [
                                                cell(title: 'Payment Type:'),
                                                _ValueCell(value: '${cmdStatus['payment_type'] ?? '-'}'),
                                              ]),
                                              TableRow(children: [
                                                cell(title: 'Pay Ref No:'),
                                                _ValueCell(value: '${cmdStatus['pay_ref_no'] ?? '-'}'),
                                              ]),
                                              TableRow(children: [
                                                cell(title: 'Date:'),
                                                _ValueCell(value: '${cmdStatus['date'] ?? '-'}'),
                                              ]),
                                              TableRow(children: [
                                                cell(title: 'Type of Transfer:'),
                                                _ValueCell(value: '${cmdStatus['typeoftransfer'] ?? '-'}'),
                                              ]),
                                            ],
                                          );
                                        })()
                                            : Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            const Text('No data available',style: TextStyle(fontSize:15,fontWeight: FontWeight.bold),),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                              )
                            ]
                        )
                    ),

                    //Payment DETAILS
                    Container(
                        child: Column(
                            children: [
                              Container(
                                  margin: EdgeInsets.only(top: 15,bottom: 25,right: 15,left: 15),
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
                                    padding: const EdgeInsets.only(top: 22,bottom: 25,right: 24,left: 15),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              children: [
                                                Icon(Icons.wallet,color: Colors.deepPurple,size: 25,),
                                                SizedBox(
                                                  width: 7,
                                                ),
                                                Text('Payment Details',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Colors.deepPurple),)
                                              ],
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 20,),
                                        PaymentDetails!['recieved_payment'] != null &&
                                            (PaymentDetails!['recieved_payment'] is List &&
                                                PaymentDetails!['recieved_payment'].isNotEmpty)
                                            ?  ListView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: PaymentDetails!['recieved_payment'].length,
                                            itemBuilder: (context, index) {
                                              final payment = PaymentDetails!['recieved_payment'][index];

                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 10),
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[50],
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: Colors.grey.shade300),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    _buildRow('Amount:', payment['amt']),
                                                    _buildRow('Pay Ref No:', payment['pay_ref_no']),
                                                    _buildRow('Date:', payment['date']),
                                                  ],
                                                ),
                                              );
                                            },
                                          ) : Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              const Text(
                                              'No data available',
                                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
                                            ],
                                          ),







                                      ],
                                    ),
                                  )
                              )
                            ]
                        )
                    ),




          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ToggleButtons(
              isSelected: [true, false], // Payment page selected
              borderRadius: BorderRadius.circular(10),
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
                  children: [
                    Icon(Icons.local_shipping),
                    Text("Dispatch Details"),
                  ],
                ),
              ],
              onPressed: (index) {
                if (index == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DispatchPage(salesId: widget.Sales_id),
                    ),
                  );
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

//build_row
Widget _buildRow(String title, String? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value ?? '-',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    ),
  );
}




