import 'package:flutter/material.dart';
import 'package:scrap_project/login.dart';
import 'package:scrap_project/payment.dart';
import 'package:scrap_project/profile_page.dart';
import 'package:scrap_project/seal/sealDetail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  String user_id = '';
  String password = '';
  String uuid = '';
  List<dynamic> Sales_data = [];
  bool isLoading = false;
  String errorMessage = '';
  String userName = '';
  String userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadCredentialsAndFetchData();
  }

  Future<void> _loadCredentialsAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      user_id = prefs.getString('user_id') ?? '';
      password = prefs.getString('user_pass') ?? '';
      uuid = prefs.getString('uuid') ?? '';
      userName = prefs.getString('user_name') ?? 'User';
      userEmail = prefs.getString('user_email') ?? 'N/A';
    });

    if (user_id.isNotEmpty && password.isNotEmpty && uuid.isNotEmpty) {
      _fetchActiveSales();
    } else {
      setState(() {
        errorMessage = 'Missing credentials in SharedPreferences.';
      });
    }
  }

  Future<void> _fetchActiveSales() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final url = Uri.parse(
          'https://scrap.systementerprises.in/api/Comp_login/sale_order_list');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'user_id': user_id,
          'user_pass': password,
          'uuid': uuid,
        },
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['aaData'] != null && data['aaData'].isNotEmpty) {
          setState(() {
            Sales_data = data['aaData'];
          });
        } else {
          setState(() {
            errorMessage = 'No data found.';
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,  // 👈 change drawer icon color
        ),
        title: const Text(
          'Scrap Management',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurpleAccent,
      ),
      drawer: Drawer(
        width: 300,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName:  Text(userName),
              accountEmail: Text(userEmail),
              currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 35,
                  child: Icon(
                    Icons.account_circle,
                    size: 70,
                    color: Colors.grey,
                  )
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade900, Colors.purple.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            TextButton(
                onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder:(context)=>ProfilePage()),
                  );
                }, child:Row(
              children: [Icon(Icons.person_outline,color: Colors.deepPurple,size: 30,),
                SizedBox(width: 15 ,),
                Text('Profile',style: TextStyle(color: Colors.deepPurple,fontSize: 20,fontWeight: FontWeight.bold),),],
            )
            ),
            TextButton(
                onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder:(context)=>WelcomePage()),
                  );
                }, child:Row(
              children: [Icon(Icons.share,color: Colors.deepPurple,size: 30,),
                SizedBox(width: 15 ,),
                Text('Refered Sale Order',style: TextStyle(color: Colors.deepPurple,fontSize: 20,fontWeight: FontWeight.bold),),],
            )
            ),
            TextButton(
                onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder:(context)=>sealdetailPage()),
                  );
                }, child:Row(
              children: [Icon(Icons.verified,color: Color(0xFF3949Ab),size: 30,),
                SizedBox(width: 15 ,),
                Text('Seal Data',style: TextStyle(color: Color(0xFF3949Ab),fontSize: 20,fontWeight: FontWeight.bold),),],
            )
            ),
            TextButton(
                onPressed: (){
                }, child:Row(
              children: [Icon(Icons.lock_reset,color: Colors.deepPurple,size: 30,),
                SizedBox(width: 15 ,),
                Text('Change Password',style: TextStyle(color: Colors.deepPurple,fontSize: 20,fontWeight: FontWeight.bold)),],
            )
            ),
            TextButton(
                onPressed: (){
                }, child:Row(
              children: [Icon(Icons.exit_to_app,color: Colors.deepPurple,size: 30,),
                SizedBox(width: 15 ,),
                Text('Leave Application',style: TextStyle(color: Colors.deepPurple,fontSize: 20,fontWeight: FontWeight.bold)),],
            )
            ),
            TextButton(
                onPressed: () {
                  Navigator.pop(context, MaterialPageRoute(builder:(context)=>Input()),
                  );
                }, child:Row(
              children: [Icon(Icons.logout,color: Colors.red,size: 30,),
                SizedBox(width: 15 ,),
                Text('Logout',style: TextStyle(color: Colors.deepPurple,fontSize: 20,fontWeight: FontWeight.bold)),],
            )
            ),

          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(
        child: Text(
          errorMessage,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      )
          : Sales_data.isEmpty
          ? const Center(child: Text("No data found"))
          : Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            const Text(
              'Active Sale Order',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: Sales_data.length,
                itemBuilder: (context, index) {
                  final item = Sales_data[index];
                  return Container(
                    margin:
                    const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black54),
                      color: Colors.white,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            borderRadius:
                            BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            crossAxisAlignment:
                            CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.warehouse,
                                  color: Colors.white, size: 23),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  '${item['description'] ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow:
                                  TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.business,color: Colors.teal,size: 25,),
                            SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                  'Vendor: ${item['vendor_name'] ?? 'N/A'}',),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 3,
                        ),
                        Row(
                          children: [
                            Icon(Icons.location_on,color: Colors.teal,size: 20,),
                            Center(child: SizedBox(width: 5)),
                            Text(
                                'Branch: ${item['branch_name'] ?? 'N/A'}'),
                          ],
                        ),
                        SizedBox(
                          height: 3,
                        ),

                        Row(
                          children: [
                            Icon(Icons.badge,color: Colors.teal,size: 20,),
                            Center(child: SizedBox(width: 5)),
                            Expanded(
                              child: Text(
                                  'Bidder: ${item['bidder_name'] ?? 'N/A'}',
                                overflow: TextOverflow.ellipsis,),
                            ),
                          ],
                        ),
                        SizedBox(
                          height:5 ,
                        ),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Center(
                              child: Container(
                                width: 170,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Color(0xFF3949Ab),
                                  borderRadius:
                                  BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.calendar_month,color: Colors.white,size: 20,),
                                    Center(child: SizedBox(width: 2)),
                                    Text(
                                        'Validity: ${item['valid_upto'] ?? 'N/A'}',style: TextStyle(color: Colors.white),),

                                  ],
                                ),
                              ),
                            ),
                            Container(
                                width: 135,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius:
                                  BorderRadius.circular(10),
                                ),
                                child: TextButton(onPressed: (){
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          Payment(Sales_id: '${item['sale_order_id'] ?? ''}' ),
                                    ),
                                  );
                                }, child:Text('View Details',style: TextStyle(fontSize: 16,color: Colors.white),)))
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
