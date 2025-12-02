import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:scrap_project/Sales_order.dart';
import 'package:scrap_project/login.dart';
import 'package:scrap_project/seal/addSealPage.dart';
import 'package:scrap_project/seal/FullImageView.dart';
import 'package:scrap_project/seal/edit_seal_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scrap_project/profile_page.dart';

class sealdetailPage extends StatefulWidget {

  @override
  State<sealdetailPage> createState() => sealdetailPageState();
}

class sealdetailPageState extends State<sealdetailPage> {
  String user_id = '';
  String password = '';
  String uuid = '';
  String userType='';
  List sealList = [];   // ⬅ stores API response list
  bool isLoading = true; // ⬅ shows loading indicator while fetching data
  int rowCount = 1;
  String userName = '';
  String userEmail = '';



  @override
  void initState() {
    super.initState();
    fetchSealData();
  }


  Future<void> fetchSealData() async {
    setState(() => isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String uuid = prefs.getString("uuid") ?? "";
    String userId = prefs.getString("user_id") ?? "";
    String userPass = prefs.getString("user_pass") ?? "";
    userName = prefs.getString('user_name') ?? 'User';
    userEmail = prefs.getString('user_email') ?? 'N/A';


    final url = Uri.parse(
        "https://scrap.systementerprises.in/api/Comp_login/get_seal_data");

    try {
      final response = await http.post(url, body: {
        "uuid": uuid,
        "user_id": userId,
        "user_pass": userPass,
        "userType": "S",
      });
      print("📥 Response Status: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print("📌 seal_data count: ${jsonResponse["seal_data"].length}");


        setState(() {
          sealList = jsonResponse["seal_data"] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        print("API failed: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Error: $e");
    }
  }

  Future<void> deleteSealRecord(String sealTransactionId, int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String uuid = prefs.getString("uuid") ?? "";
    String userId = prefs.getString("user_id") ?? "";
    String userPass = prefs.getString("user_pass") ?? "";

    final url = Uri.parse(
        "https://scrap.systementerprises.in/api/Comp_login/delete_seal_record");

    try {
      final response = await http.post(url, body: {
        "uuid": uuid,
        "user_id": userId,
        "user_pass": userPass,
        "userType": "S",
        "seal_transaction_id": sealTransactionId,   // 🔥 the required ID
      });

      print("DELETE Status: ${response.statusCode}");
      print("DELETE Response: ${response.body}");

      if (response.statusCode == 200) {
        final body = json.decode(response.body);

        if (body["status"] == "success") {
          setState(() {
            sealList.removeAt(index);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Seal deleted successfully")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(body["message"] ?? "Failed to delete")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,  // 👈 change drawer icon color
        ),
        title: Text(
          'Seal Management',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF3949Ab),
      ),
      drawer: Drawer(
        width: 300,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(userName),
              accountEmail:Text(userEmail),
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
              children: [Icon(Icons.check_circle_outline,color: Color(0xFF3949Ab),size: 30,),
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
      body:  Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 15, right: 10, left: 10, bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("View Seals",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF3949Ab),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Icon(Icons.filter_alt, color: Colors.white),
                        SizedBox(width: 5),
                        Text("Filter", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// Expanded must be here (only once)
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : sealList.isEmpty
                ? Center(
              child: Text(
                "No seal data found",
                style: TextStyle(fontSize: 16, color: Color(0xFF3949Ab)),
              ),
            )
                : ListView.builder(
              itemCount: sealList.length,
              itemBuilder: (context, index) {
                final seal = sealList[index];
                final List pics = seal['pics'] ?? [];
                //int currentIndex = index+1; // copy the counter
                return Container(
                  child: Column(
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: 8.0,left: 8.0,top: 8.0,bottom: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Color(0xFF3949Ab),

                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 5,left: 15,top: 5,bottom:5),
                          child: Row(
                            mainAxisAlignment:MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text('${seal['sr_no'].replaceAll("=>", "").trim()}',style:TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 15),overflow:
                              TextOverflow.ellipsis,
                                maxLines: 1,)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  // ========== IMAGE / HIDE-IMAGE ICON ==========
                                  IconButton(
                                    onPressed: pics.isNotEmpty
                                        ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ImagePreviewScreen(images: pics),
                                        ),
                                      );
                                    }
                                        : null, // ❌ Disable when empty
                                    icon: Icon(
                                      pics.isNotEmpty ? Icons.image : Icons.hide_image,
                                      color: Colors.white,
                                    ),
                                  ),

                                  IconButton(onPressed: (){
                                    Navigator.push(context, MaterialPageRoute(builder:(context)=>editsealPage(sealTransactionId: sealList[index]["seal_transaction_id"].toString())),
                                    );

                                  }, icon:Icon(Icons.edit,color: Colors.white,)),
                                  IconButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: Text("Delete Seal Record"),
                                          content: Text("Are you sure you want to delete this record?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(ctx).pop(),
                                              child: Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(ctx).pop();

                                                // 🔥 Read ID from sealList
                                                String sealTransactionId =
                                                sealList[index]["seal_transaction_id"].toString();

                                                deleteSealRecord(sealTransactionId, index);
                                              },
                                              child: Text("Delete", style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: Icon(Icons.delete, color: Colors.white),
                                  )


                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                      Container(
                      margin: EdgeInsets.only(right: 14,left: 14,top: 4,bottom: 15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child:Column(
                          children: [
                            buildRow(rowCount++, [
                              buildField("Location", seal["location_name"]?.toString()),
                              buildField("Plant", seal["plant_name"]?.toString()),
                            ]),
                            buildRow(rowCount++ , [
                              buildField("Material", seal["material_name"]?.toString()),
                              buildField("Vessel", seal["vessel_name"]?.toString()),
                            ]),
                            buildRow(rowCount++ , [
                              buildField("Start Seal No", seal["start_seal_no"]?.toString()),
                              buildField("End Seal No", seal["end_seal_no"]?.toString()),
                            ]),
                            buildRow(rowCount++ , [
                              buildField("Extra Start Seal No", seal["extra_start_seal_no"]?.toString()),
                              buildField("Extra End Seal No", seal["extra_end_seal_no"]?.toString()),
                            ]),
                            buildRow(rowCount++ , [
                              buildField("No of seals", seal["no_of_seal"]?.toString()),
                              buildField("Extra No of Seals", seal["extra_no_of_seal"]?.toString()),
                            ]),
                            buildRow(rowCount++ , [
                              buildField("Rejected Seal", seal["rejected_seal_no"]?.toString()),
                              buildField("New Seal", seal["new_seal_no"]?.toString()),
                            ]),
                            buildRow(rowCount++ , [
                              buildField("Net Weight", seal["net_weight"]?.toString()),
                              buildField("Seal Color", seal["seal_color"]?.toString()),
                            ]),
                            buildRow(rowCount++ , [
                              buildField("Vehicle No", seal["vehicle_no"]?.toString()),
                              buildField("Allow Slip No", seal["allow_slip_no"]?.toString()),
                            ]),
                            buildRow(rowCount++ , [
                              buildField("Seal Date", seal["seal_date"]?.toString()),
                            ]),
                            buildRow(rowCount++ , [
                              buildField("Vehicle Reached Date", seal["seal_unloading_date"]?.toString()),
                            ]),
                            buildRow(rowCount++ , [
                              buildField("GPS Seal No", seal["gps_seal_no"]?.toString()),
                            ]),
                            buildRow(rowCount++ , [
                              buildField("Sender Remarks", seal["remarks"]?.toString()),
                            ]),
                            buildRow(rowCount++ , [
                              buildField("Receiver Remarks", seal["rev_remarks"]?.toString()),
                            ]),

                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder:(context)=>addsealdetailPage()));

          // your action here
        },
        backgroundColor: Color(0xFF3949Ab),
        child: Icon(Icons.add, color: Colors.white),
      ),

    );
  }
}


Widget buildRow(int index, List<Widget> children) {
  return Container(
  color: index.isEven ? Colors.white : Colors.grey[200],
    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    child: Row(children: children),
  );
}

Widget buildField(String label, String? value) {
  return Expanded(
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 2),
          Text(
            value ?? "-",
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    ),
  );
}

class ImagePreviewScreen extends StatelessWidget {
  final List images;

  ImagePreviewScreen({required this.images});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Images"),
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullImageView(url: images[index]),
                ),
              );
            },
            child: Hero(
              tag: images[index],
              child: Image.network(
                images[index],
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}
