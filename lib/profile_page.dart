import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:scrap_project/Sales_order.dart';
import 'package:scrap_project/login.dart';
import 'package:scrap_project/seal/sealDetail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  bool isPunchedIn = false;
  bool isPunchedOut = false;
  bool isPunchInDisabled = false;
  bool isPunchOutDisabled = false;
  bool showprofile_page = true;
  String userName = '';
  String userEmail = '';
  String userAdd = '';
  String userLocation='';
  String remainingDays = '';
  String loginUserId = '';
  String loginPassword = '';
  String loginUuid = '';
  String remainingDaysString = '';
  int presentCount = 0;
  int absentCount = 0;
  int late_login_count=0;
  bool showAttendanceHistory = false;
  List<dynamic> attendanceHistory = [];
  List<dynamic> LeaveHistory = [];
  bool showLeaveHistory = false;
  int leaveTaken = 0;
  int upcomingLeave = 0;



  @override
  void initState() {
    super.initState();
    showprofile_page = true;
    loadUserData();
    fetchEmployeeDetails();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      userName = prefs.getString('user_name') ?? 'User';
      userEmail = prefs.getString('user_email') ?? 'N/A';
      userAdd = prefs.getString('user_add') ?? 'N/A';

      remainingDays = prefs.getString('remaining_days') ?? 'N/A';
      DateTime today = DateTime.now();
      DateTime targetDate = DateTime.parse(remainingDays);

      Duration difference = targetDate.difference(today);
      remainingDaysString =
          difference.inDays.toString(); // Convert duration to string

      print("Remaining Days: $remainingDaysString");
    });
  }


  // ============================
  // CENTER MESSAGE POPUP (2 SEC)
  // ============================
  void showCenterMessage(String message) {
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              message,
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    Future.delayed(Duration(seconds: 2)).then((_) => overlayEntry.remove());
  }

  // ============================
  // PUNCH IN API
  // ============================
  Future<void> punchInApi() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      loginUserId = prefs.getString('user_id') ?? '';
      loginPassword = prefs.getString('user_pass') ?? '';
      loginUuid = prefs.getString('uuid') ?? '';
    });
    if (isPunchInDisabled) return;

    setState(() {
      isPunchInDisabled = true;
    });

    final url = Uri.parse(
        "https://scrap.systementerprises.in/api/Comp_login/set_user_attendance");

    final body = {
      "user_id":loginUserId ,
      "user_pass":loginPassword ,
      "uuid":loginUuid ,
      "status": "logged in"
    };

    try {
      final response = await http.post(url, body: body);
      final data = json.decode(response.body);

      if (data["status"] == "1") {
        setState(() {
          isPunchedIn = true;
        });

        showCenterMessage(data["msg"]);
      } else {
        showCenterMessage("Something went wrong");
        setState(() {
          isPunchInDisabled = false;
        });
      }
    } catch (e) {
      showCenterMessage("Error: $e");
      setState(() {
        isPunchInDisabled = false;
      });
    }
  }

  // ============================
  // PUNCH OUT API
  // ============================
  Future<void> punchOutApi() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      loginUserId = prefs.getString('user_id') ?? '';
      loginPassword = prefs.getString('user_pass') ?? '';
      loginUuid = prefs.getString('uuid') ?? '';
    });
    if (isPunchOutDisabled) return;

    setState(() {
      isPunchOutDisabled = true;
    });

    final url = Uri.parse(
        "https://scrap.systementerprises.in/api/Comp_login/set_user_attendance");

    final body = {
      "user_id": loginUserId,
      "user_pass": loginPassword,
      "uuid":loginUuid ,
      "status": "logged out"
    };

    try {
      final response = await http.post(url, body: body);
      final data = json.decode(response.body);

      if (data["status"] == "1") {
        setState(() {
          isPunchedOut = true;
        });

        showCenterMessage(data["msg"]);
      } else {
        showCenterMessage("Something went wrong");
        setState(() {
          isPunchOutDisabled = false;
        });
      }
    } catch (e) {
      showCenterMessage("Error: $e");
      setState(() {
        isPunchOutDisabled = false;
      });
    }
  }

  // ============================
  // Employee Details API
  // ============================
  Future<void> fetchEmployeeDetails() async {
    final prefs = await SharedPreferences.getInstance();

    String loginUserId = prefs.getString('user_id') ?? '';
    String loginPassword = prefs.getString('user_pass') ?? '';
    String loginUuid = prefs.getString('uuid') ?? '';

    final url = Uri.parse(
        "https://scrap.systementerprises.in/api/Comp_login/employee_details");

    final body = {
      "user_id": loginUserId,
      "user_pass": loginPassword,
      "uuid": loginUuid,
    };

    try {
      final response = await http.post(url, body: body);
      final data = json.decode(response.body);
      final summary = data['attendance_summary'] ?? {};
      attendanceHistory = data["attendance_data"] ?? [];
      LeaveHistory = data["leave_data"] ?? [];
      final Leavesummary = data['attendance_summary'] ?? {};



      print("Employee API Response: $data");

      setState(() {
        userName = data["name"] ?? userName;
        userLocation = data["location_data"]?["location"] ?? userAdd;
        presentCount = summary["present_count"] ?? 0;
        absentCount = summary["absent_count"] ?? 0;
        late_login_count=summary["late_login_count"] ?? 0;
        leaveTaken=Leavesummary["taken_leaves"] ?? 0;
        upcomingLeave=Leavesummary["upcoming_leaves"] ?? 0;
      });

    } catch (e) {
      showCenterMessage("Error: $e");
    }
  }


  // ============================
  // UI STARTS HERE
  // ============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,  // 👈 change drawer icon color
        ),
        title: Text(
          'Scrap Management',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      drawer: Drawer(
        width: 300,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text( userName),
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

      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.all(10),
              width: 400,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(21),
                color: Colors.white,
                border: Border.all(color: Color(0xFF3949AB)),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(21),
                    child: Image.asset(
                      'assets/images/themeimg1.jpeg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 250,
                      colorBlendMode: BlendMode.darken,
                    ),
                  ),
                  Center(
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: AssetImage('assets/images/hello.gif'),
                          backgroundColor: Colors.blueGrey.shade100,
                        ),
                        SizedBox(height: 10),
                        Text(
                          userName,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          userEmail,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        Text(
                          "Deactivates in $remainingDaysString days!",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            SizedBox(height: 20),

            // ============================
            // 🔘 PUNCH IN BUTTON
            // ============================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed:
                      isPunchInDisabled ? null : () => punchInApi(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        isPunchedIn ? Colors.grey : Colors.green,
                        padding:
                        EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.login, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            isPunchedIn ? "Punched In" : "Punch In",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed:
                      isPunchOutDisabled ? null : () => punchOutApi(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        isPunchedOut ? Colors.grey : Colors.red,
                        padding:
                        EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            isPunchedOut ? "Punched Out" : "Punch Out",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 20),

            // ============================
            // 🔘 PUNCH OUT BUTTON
            // ============================
            Container(
              margin: EdgeInsets.only(top: 10,bottom: 10,right: 15,left: 15),
              width: 400,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.4), // soft grey shadow
                    spreadRadius: 1, // small spread
                    blurRadius: 5, // softness of shadow
                    offset: const Offset(2, 4), // position of shadow (x, y)
                  ),
                ],

              ),
              child:Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          height:60,
                          width: 60,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.red,width: 2)
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundImage: AssetImage('assets/images/location.jpeg'),

                          ),
                        ),
                        SizedBox(width: 15,),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Address',style: TextStyle(fontSize: 15,color: Color(0xFF3949Ab),fontWeight: FontWeight.bold),),
                            Text(userAdd)
                          ],

                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.circle,color: Colors.greenAccent,size: 18,),
                      ],
                    )
                  ],
                )
              ) ,

            ),
            Container(
              margin: EdgeInsets.only(top: 10,bottom: 10,right: 15,left: 15),
              width: 400,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.4), // soft grey shadow
                    spreadRadius: 1, // small spread
                    blurRadius: 5, // softness of shadow
                    offset: const Offset(2, 4), // position of shadow (x, y)
                  ),
                ],

              ),
              child:Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          height:60,
                          width: 60,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.red,width: 2)
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundImage: AssetImage('assets/images/location.jpeg'),

                          ),
                        ),
                        SizedBox(width: 15,),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Location',style: TextStyle(fontSize: 15,color: Color(0xFF3949Ab),fontWeight: FontWeight.bold),),
                            Text(userLocation)
                          ],

                        ),

                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.circle,color: Colors.greenAccent,size: 18,),
                      ],
                    )
                  ],
                )
              ) ,

            ),

            //****************//
            //present and absent Container
            //****************//
        GestureDetector(
          onTap: () {
            setState(() {
              showAttendanceHistory = !showAttendanceHistory;
            });
          },
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 10, bottom: 10, right: 15, left: 15),
                width: 400,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.4),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(2, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(top: 15, bottom: 15, right: 5, left: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// HEADER
                      Padding(
                        padding: EdgeInsets.only(left: 10, bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Attendance',
                              style: TextStyle(
                                fontSize: 17,
                                color: Color(0xFF3949AB),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              showAttendanceHistory
                                  ? Icons.arrow_drop_up
                                  : Icons.arrow_drop_down,
                              size: 30,
                              color: Colors.deepPurple,
                            ),
                          ],
                        ),
                      ),

                      /// SUMMARY ROW
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // PRESENT
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(17),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.4),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: Offset(2, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 19),
                              child: Column(
                                children: [
                                  Icon(Icons.verified_user, color: Colors.green),
                                  Text('Present'),
                                  Text("$presentCount"),
                                ],
                              ),
                            ),
                          ),

                          // ABSENT
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(17),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.4),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: Offset(2, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 21),
                              child: Column(
                                children: [
                                  Icon(Icons.person_off, color: Colors.red),
                                  Text('Absent'),
                                  Text("$absentCount"),
                                ],
                              ),
                            ),
                          ),

                          // LATE LOGIN
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(17),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.4),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: Offset(2, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 11),
                              child: Column(
                                children: [
                                  Icon(Icons.access_alarms, color: Colors.orange),
                                  Text('Late Login'),
                                  Text("$late_login_count"),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      /// MOVE HISTORY INSIDE PARENT
                      if (showAttendanceHistory)
                        Container(
                          margin: EdgeInsets.only(top: 15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(17),
                            color: Colors.white,
                          ),
                          child:  attendanceHistory.isEmpty
                              ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: Text(
                                "No Leave Data Available",
                                style: TextStyle(
                                  color: Colors.black12,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                              :ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: attendanceHistory.length,
                            itemBuilder: (context, index) {
                              final item = attendanceHistory[index];
                              final status = item["status"];

                              Color statusColor = status == "Present"
                                  ? Colors.green
                                  : status == "Not Logged Out"
                                  ? Colors.orange
                                  : Colors.red;

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
                                    Text("Punch In: ${item["punchintime"]}"),
                                    Text("Punch Out: ${item["punchout"]}"),
                                    Row(
                                      children: [
                                        Icon(Icons.circle, size: 12, color: statusColor),
                                        SizedBox(width: 6),
                                        Text(
                                          status,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      GestureDetector(
        onTap: () {
          setState(() {
            showLeaveHistory = !showLeaveHistory;
          });
        },
        child:Column(
          children: [
            Container(
        margin: EdgeInsets.only(top: 10, bottom: 10, right: 15, left: 15),
        width: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.4),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(2, 4),
            ),
          ],
        ),
              child: Padding(
                padding: const EdgeInsets.only(top: 15, bottom: 15, right: 5, left: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 10, bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Leave',
                            style: TextStyle(
                              fontSize: 17,
                              color: Color(0xFF3949AB),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(
                            showLeaveHistory
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down,
                            size: 30,
                            color: Colors.deepPurple,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(17),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.4), // soft grey shadow
                                spreadRadius: 1, // small spread
                                blurRadius: 5, // softness of shadow
                                offset: const Offset(2, 4), // position of shadow (x, y)
                              ),
                            ],

                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 15,bottom: 15,right: 24,left: 24),
                            child: Column(
                              children: [
                                Icon(Icons.airline_seat_individual_suite,color: Colors.lightBlue,),
                                Text('Taken Leaves'),
                                Text("$leaveTaken")
                              ],
                            ),
                          ),
                        ),
                        Container(

                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(17),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.4), // soft grey shadow
                                spreadRadius: 1, // small spread
                                blurRadius: 5, // softness of shadow
                                offset: const Offset(2, 4), // position of shadow (x, y)
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 15,bottom: 15,right: 11,left: 11),
                            child: Column(
                              children: [
                                Icon(Icons.upcoming,color: Colors.red,),
                                Text('Upcoming Leaves'),
                                Text("$upcomingLeave")
                              ],
                            ),
                          ),
                        ),

                      ],
                    ),
                    if (showLeaveHistory)
                      Container(
                        margin: EdgeInsets.only(top: 15),
                        child: LeaveHistory.isEmpty
                            ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: Text(
                              "No Leave Data Available",
                              style: TextStyle(
                                color: Colors.black12,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                            : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: LeaveHistory.length,
                          itemBuilder: (context, index) {
                            final item = LeaveHistory[index];
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
                                  Text("Leave Date: ${item["date"] ?? "N/A"}"),
                                  Text("Reason: ${item["reason"] ?? "N/A"}"),
                                  Text("Status: ${item["status"] ?? "N/A"}"),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),

              ),


            )
          ],
        )
      ),
          ],
        ),
      ),


      //Bottom Navigation bar
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
                    Icon(Icons.person_outline),
                    Text("Profile"),
                  ],
                ),
                Column(
                  children: [
                    Icon(Icons.check_circle),
                    Text("Attendance"),
                  ],
                ),
              ],
              onPressed: (index) {
                if (index == 1) {

                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
