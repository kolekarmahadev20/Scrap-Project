import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:scrap_project/Sales_order.dart';
import 'package:scrap_project/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scrap_project/profile_page.dart';
import 'package:scrap_project/seal/sealDetail.dart';
import 'package:image_picker/image_picker.dart';

class addsealdetailPage extends StatefulWidget {

  @override
  State<addsealdetailPage> createState() => addsealdetailPageState();
}

class addsealdetailPageState extends State<addsealdetailPage> {
  String userId = '';
  String userPass = '';
  String uuid = '';
  String userName = '';
  String userEmail = '';
  DropdownItem ? selectedLocationPort;
  DropdownItem ? selectedPlant;
  String? selectedPlantId;
  String? selectedVesselId;
  String? selectedMaterialId;
  DropdownItem ? selectedMaterial;
  DropdownItem ? selectedVessel;
  String? selectedLocationPortId;
  String? selectedReceiver;
  String? selectedRemarks;
  String? selectedColor;
  final TextEditingController locationPort = TextEditingController();
  final TextEditingController plant = TextEditingController();
  final TextEditingController material = TextEditingController();
  final TextEditingController vessel = TextEditingController();
  final TextEditingController allowslipNo = TextEditingController();
  final TextEditingController vehicleNo = TextEditingController();
  final TextEditingController sealDate = TextEditingController();
  final TextEditingController sealTime = TextEditingController();
  final TextEditingController firstWeight = TextEditingController();
  final TextEditingController secondWeight = TextEditingController();
  final TextEditingController netWeight = TextEditingController();
  final TextEditingController noofSeals = TextEditingController();
  final TextEditingController startsealNO = TextEditingController();
  final TextEditingController endsealNO = TextEditingController();
  final TextEditingController selectColor = TextEditingController();
  final TextEditingController extrastartSealno = TextEditingController();
  final TextEditingController extraendSealno = TextEditingController();
  final TextEditingController extraSeal = TextEditingController();
  final TextEditingController otherextrasealNO = TextEditingController();
  final TextEditingController GPSsealNO = TextEditingController();
  final TextEditingController senderRemarks = TextEditingController();
  final TextEditingController TarpaulinCondition = TextEditingController();
  final TextEditingController receivedBy = TextEditingController();
  final TextEditingController vehicleReached = TextEditingController();
  final TextEditingController vehicleReachedDate = TextEditingController();
  final TextEditingController recieverRemarks = TextEditingController();
  final TextEditingController enterrejectedSeal = TextEditingController();
  final TextEditingController enternewSeal = TextEditingController();
  List<DropdownItem> locationPorts = [];
  List<DropdownItem> plants = [];
  List<DropdownItem> materials = [];
  List<DropdownItem> vessels = [];
  Map<String, dynamic> fullVesselData = {};

  List<String> colorList = [];
  List<String> receiverList = [];
  List<String> remarksList = [];
  bool isLoading = true;
  final ImagePicker _picker = ImagePicker();
  File? _cameraImage;
  File? _galleryImage;
  String sealError = "";     // To show error message
  bool showSealError = false;
  bool isSubmitting = false;


  @override
  void initState() {
    super.initState();
    fetchDropdowns();
    fetchData();
    TarpaulinCondition.text = "Intact";
    startsealNO.addListener(_calculateSeals);
    endsealNO.addListener(_calculateSeals);

    DateTime now = DateTime.now();

    // Format Date: DD-MM-YYYY
    sealDate.text = "${now.day}-${now.month}-${now.year}";

    // Format Time: HH:MM
    sealTime.text = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  void _calculateSeals() {
    final start = startsealNO.text.trim();
    final end = endsealNO.text.trim();

    showSealError = false;
    sealError = "";
    noofSeals.text = "";

    if (start.isEmpty) {
      setState(() {});
      return;
    }

    // Extract START prefix & number
    final startPrefix = start.replaceAll(RegExp(r'[0-9]'), '');
    final startNumStr = start.replaceAll(RegExp(r'[^0-9]'), '');
    final startNum = int.tryParse(startNumStr);

    if (startNum == null) {
      showSealError = true;
      sealError = "Invalid Start Seal format.";
      setState(() {});
      return;
    }

    // Auto-fill END prefix if empty
    if (end.isEmpty) {
      endsealNO.text = startPrefix;
      endsealNO.selection = TextSelection.fromPosition(
        TextPosition(offset: endsealNO.text.length),
      );
    }

    final updatedEnd = endsealNO.text.trim();

    // Extract END prefix & number
    final endPrefix = updatedEnd.replaceAll(RegExp(r'[0-9]'), '');
    final endNumStr = updatedEnd.replaceAll(RegExp(r'[^0-9]'), '');
    final endNum = int.tryParse(endNumStr);

    // Prefix mismatch
    if (startPrefix != endPrefix) {
      showSealError = true;
      sealError = "Start and End seal letters must be same.";
      setState(() {});
      return;
    }

    if (endNum == null) {
      showSealError = true;
      sealError = "Invalid End Seal format.";
      setState(() {});
      return;
    }

    // START must be GREATER than END
    if (startNum < endNum) {
      showSealError = true;
      sealError = "Start Seal must be greater than End Seal.";
      setState(() {});
      return;
    }

    // FINAL CALCULATION (Start > End)
    final count = (startNum - endNum) + 1;
    noofSeals.text = count.toString();


    setState(() {});
  }

  Future<void> submitSealData() async {
    setState(() {
      isSubmitting = true;
    });
    // ✅ Manual validation for required fields
    if (selectedMaterialId == null || selectedMaterialId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Please select a material")),
      );
      return;
    }

    if (selectedLocationPortId == null || selectedLocationPortId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Please select a location")),
      );
      return;
    }

    if (selectedPlantId == null || selectedPlantId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Please select a plant")),
      );
      return;
    }

    if (startsealNO.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Start Seal No cannot be empty")),
      );
      return;
    }

    if (endsealNO.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ End Seal No cannot be empty")),
      );
      return;
    }

    if (noofSeals.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ No of Seals cannot be empty")),
      );
      return;
    }

    // 🔹 If all required fields are filled, continue submission
    try {
      final prefs = await SharedPreferences.getInstance();
       uuid = prefs.getString("uuid") ?? "";
       userId = prefs.getString("user_id") ?? "";
       userPass = prefs.getString("user_pass") ?? "";
      final userType = prefs.getString("userType") ?? "";


      print("UUID = $uuid");
      print("User ID = $userId");
      print("User Pass = $userPass");

      var url = Uri.parse("https://scrap.systementerprises.in/api/Comp_login/add_edit_seal_data_test");
      var request = http.MultipartRequest("POST", url);

      // 🔹 Add all fields (same as previous refactored version)
      request.fields.addAll({
        'uuid': uuid,
        'user_id': userId,
        'user_pass': userPass,
        'from_location': selectedLocationPortId ?? "",
        'to_location': selectedPlantId ?? "",
        'material_id': selectedMaterialId ?? "",
        'seal_date': sealDate.text,
        'start_time': sealTime.text,
        'allow_slip_no': allowslipNo.text,
        'vehicle_no': vehicleNo.text,
        'first_weight': firstWeight.text,
        'second_weight': secondWeight.text,
        'net_weight': netWeight.text,
        'tarpaulin_condition': TarpaulinCondition.text,
        'seal_remarks': senderRemarks.text ,
        'start_seal_no': startsealNO.text,
        'end_seal_no': endsealNO.text,
        'no_of_seal': noofSeals.text,
        'gps_seal_no': GPSsealNO.text,
        'extra_start_seal_no': extrastartSealno.text,
        'extra_end_seal_no': extraendSealno.text,
        'extra_no_of_seal': extraSeal.text,
        'other_extra_seal': otherextrasealNO.text,
        'seal_color': selectedColor ?? "",
        'vessel_id': selectedVesselId ?? "",
        'rejected[rejected_seal_no]': enterrejectedSeal.text,
        'rejected[new_seal_no]': enternewSeal.text,

      });



      // 🔹 Vehicle unloading info
      if ((userType == 'S' || userType == 'A')) {
        if (vehicleReachedDate.text.isNotEmpty) {
          request.fields['seal_unloading_date'] = vehicleReachedDate.text;
        }
        if (vehicleReached.text.isNotEmpty) {
          request.fields['seal_unloading_time'] = vehicleReached.text;
        }
        if (recieverRemarks.text.isNotEmpty) {
          request.fields['receiver_remarks'] = recieverRemarks.text;
        }
      }

      // 🔹 Attach images
      if (_cameraImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('pics[]', _cameraImage!.path),
        );
      }

      if (_galleryImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('pics[]', _galleryImage!.path),
        );
      }

      // 🔹 Send request and handle response (same as before)
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      Map<String, dynamic> jsonData = {};
      try {
        int jsonStart = responseBody.indexOf("{");
        if (jsonStart != -1) {
          String cleanJson = responseBody.substring(jsonStart).trim();
          jsonData = json.decode(cleanJson);
        } else {
          throw const FormatException("No JSON found in response");
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Invalid response from server")),
        );
        return;
      }
      try {
        // your validation + API code (unchanged)

        if (response.statusCode == 200 && jsonData["status"] == "success") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Seal added successfully"),
              backgroundColor: Colors.green,
            ),

          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("❌ ${jsonData["msg"] ?? "Failed to add seal"}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            isSubmitting = false;
          });
        }
      }

      if (response.statusCode == 200 && jsonData["status"] == "success") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ ${jsonData["msg"]}")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed: ${jsonData["msg"] ?? "Unknown error"}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }


  }

  Future<void> openCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _cameraImage = File(photo.path); // save in camera-specific variable
      });
    }
  }

  // Open Gallery
  Future<void> openGallery() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
    if (photo != null) {
      setState(() {
        _galleryImage = File(photo.path); // save in gallery-specific variable
      });
    }
  }

  // Remove Camera Image
  void removeCameraImage() {
    setState(() {
      _cameraImage = null;
    });
  }

  // Remove Gallery Image
  void removeGalleryImage() {
    setState(() {
      _galleryImage = null;
    });
  }

  void fetchData() async {
    // your API call or loading logic
    await Future.delayed(Duration(seconds: 2)); // simulate API
    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchDropdowns() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
     uuid = prefs.getString("uuid") ?? "";
     userId = prefs.getString("user_id") ?? "";
     userPass = prefs.getString("user_pass") ?? "";
    userName = prefs.getString('user_name') ?? 'User';
    userEmail = prefs.getString('user_email') ?? 'N/A';

    print("UUID = $uuid");
    print("User ID = $userId");
    print("User Pass = $userPass");

    final url = Uri.parse(
        'https://scrap.systementerprises.in/api/Comp_login/get_dropdown');

    final body = {
      "uuid": uuid,
      "user_id": userId,
      "user_pass": userPass,
    };

    print("📌 Request Body = $body");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      print("📥 API Response: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResp = jsonDecode(response.body);

        if (jsonResp["status"].toString() == "1") {
          setState(() {
            // 🔹 DropdownItem lists
            if (jsonResp.containsKey('location_port') && jsonResp['location_port'] is List) {
              locationPorts = (jsonResp['location_port'] as List)
                  .map((e) => DropdownItem.fromJson(e as Map<String, dynamic>, 'location_port'))
                  .toList();
            }

// Plants
            if (jsonResp.containsKey('plant') && jsonResp['plant'] is List) {
              plants = (jsonResp['plant'] as List)
                  .map((e) => DropdownItem.fromJson(e as Map<String, dynamic>, 'plant'))
                  .toList();
            }

// Materials
            if (jsonResp.containsKey('material') && jsonResp['material'] is List) {
              materials = (jsonResp['material'] as List)
                  .map((e) => DropdownItem.fromJson(e as Map<String, dynamic>, 'material'))
                  .toList();
            }

// Vessels
            if (jsonResp.containsKey('vessel') && jsonResp['vessel'] is Map) {
              fullVesselData = Map<String, dynamic>.from(jsonResp['vessel']);
              print(jsonResp["vessel"]);
              print(jsonResp["vessel"].runtimeType);
            }

            if (jsonResp.containsKey("color") && jsonResp["color"] is List) {
              colorList = (jsonResp["color"] as List)
                  .map((e) => e["color_name"].toString())
                  .toList();

              print("Fetched Colors: $colorList");   // For debug
            }

            if (jsonResp.containsKey("users") && jsonResp["users"] is List) {
              receiverList = (jsonResp["users"] as List)
                  .map((e) => e["person_name"].toString())
                  .toList();

              print("Fetched Receivers → $receiverList");
            }

            if (jsonResp.containsKey("reason") && jsonResp["reason"] is List) {
              remarksList = (jsonResp["reason"] as List)
                  .map((e) => e["reason"].toString())
                  .toList();

              print("Fetched Remarks → $remarksList");
            }
          });

          print("✅ Dropdown data fetched successfully");
        } else {
          print("❌ API Failed: ${jsonResp['msg'] ?? jsonResp['message']}");
        }
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      print("🔴 Exception Error: $e");
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
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text("Loading Seals Data...",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      )
          :SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 15, right: 10, left: 10, bottom: 20),
              child: Row(
                children: [
                  Icon(Icons.verified ,color: Color(0xFF3949Ab),),
                  SizedBox(width: 5,),
                  Text("Add Seals",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,decoration: TextDecoration.underline,)),
                ],
              ),
            ),
            Container(
              child: Column(
                children: [
              Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Location Port:',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 10),
                  IntrinsicWidth(
                    child: IntrinsicHeight(
                      child: SizedBox(
                        width: 230,
                        height: 50,
                        child: DropdownButtonFormField<DropdownItem>(
                          decoration: InputDecoration(
                            hintText: 'Select Location Port',
                            filled: true,
                            fillColor: Colors.grey[200],
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: BorderSide(color: Colors.black, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: BorderSide(color: Color(0xFF3949AB), width: 1),
                            ),
                          ),
                          value: selectedLocationPort,
                          items: locationPorts.map((item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(item.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedLocationPort = value;
                              locationPort.text = value!.name;
                              selectedLocationPortId = value.id; // store ID

                              // Populate vessels based on selected location
                              final key = selectedLocationPortId?.trim() ?? "";
                              final vesselList = fullVesselData[key] ?? [];

                              vessels = vesselList
                                  .map<DropdownItem>((v) => DropdownItem(
                                id: v["vessel_id"].toString(),
                                name: v["vessel_name"].toString(),
                              ))
                                  .toList();

                              selectedVessel = null;
                              vessel.text = "";
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a location port';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Plant:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 10),
              IntrinsicWidth(
                child: IntrinsicHeight(
                  child: SizedBox(
                    width: 230,
                    height: 50,
                    child: DropdownButtonFormField<DropdownItem>(
                      decoration: InputDecoration(
                        hintText: 'Select Plant',
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide(color: Colors.black, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide(color: Color(0xFF3949AB), width: 1),
                        ),
                      ),
                      value: selectedPlant,
                      items: plants.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(item.name),
                        );
                      }).toList(),
                      onChanged: (DropdownItem? value) {
                        setState(() {
                          selectedPlant = value; // store the whole object
                          plant.text = value?.name ?? ''; // for the controller if needed
                          selectedPlantId = value?.id;   // <-- store the ID separately
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a plant';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

       // add this at the top of your State class

// inside your DropdownButtonFormField<DropdownItem> for Material
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Material:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 10),
              IntrinsicWidth(
                child: IntrinsicHeight(
                  child: SizedBox(
                    width: 230,
                    height: 50,
                    child: DropdownButtonFormField<DropdownItem>(
                      isExpanded: true, // keeps dropdown full width inside SizedBox
                      decoration: InputDecoration(
                        hintText: 'Select Material',
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide(color: Colors.black, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide(color: Color(0xFF3949AB), width: 1),
                        ),
                      ),
                      value: selectedMaterial,
                      items: materials.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Tooltip(
                            message: item.name,
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedMaterial = value;          // store full object
                          material.text = value!.name;       // store name for controller
                          selectedMaterialId = value.id;     // ✅ store the ID separately
                        });
                      },
                      validator: (value) {
                        if (value == null) return 'Please select a material';
                        return null;
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vessel:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 10),
              IntrinsicWidth(
                child: IntrinsicHeight(
                  child: SizedBox(
                    width: 230,
                    height: 50,
                    child: DropdownButtonFormField<DropdownItem>(
                      value: selectedVessel,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: 'Select Vessel',
                        hintStyle: TextStyle(color: Colors.grey[700]),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
                      ),
                      icon: Icon(Icons.arrow_drop_down, size: 26, color: Colors.grey[700]),
                      selectedItemBuilder: (BuildContext context) {
                        return vessels.map<Widget>((DropdownItem item) {
                          return Center(
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          );
                        }).toList();
                      },
                      items: vessels.map((item) {
                        return DropdownMenuItem<DropdownItem>(
                          value: item,
                          child: Tooltip(
                            message: item.name,
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (DropdownItem? value) {
                        setState(() {
                          selectedVessel = value;                 // store the full object
                          vessel.text = value?.name ?? '';        // store the name
                          selectedVesselId = value?.id;           // ✅ store the ID separately
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a vessel';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Allow Slip No:',style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                        SizedBox(width: 10),  // optional spacing
                        IntrinsicWidth(
                          child: IntrinsicHeight(
                              child: SizedBox(
                                width: 230,
                                height: 50,
                                child: TextField(
                                  controller:allowslipNo ,
                                  decoration: InputDecoration(
                                    hintText: 'Enter Allow Slip No',
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(13),
                                      borderSide: BorderSide(color: Colors.black, width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(13),
                                      borderSide: BorderSide(color: Color(0xFF3949AB), width: 1),
                                    ),
                                  ),
                                )

                              )

                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Vehicle No:',style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                        SizedBox(width: 10),  // optional spacing
                        IntrinsicWidth(
                          child: IntrinsicHeight(
                              child: SizedBox(
                                  width: 230,
                                  height: 50,
                                  child: TextField(
                                    controller: vehicleNo,
                                    decoration: InputDecoration(
                                      hintText: 'Enter Vehicle Number',
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(13),
                                        borderSide: BorderSide(color: Colors.black, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(13),
                                        borderSide: BorderSide(color: Color(0xFF3949AB), width: 1),
                                      ),
                                    ),
                                  )

                              )

                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Seal Date:',style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                        SizedBox(width: 10),  // optional spacing
                        IntrinsicWidth(
                          child: IntrinsicHeight(
                              child: SizedBox(
                                  width: 230,
                                  height: 50,
                                  child: TextField(
                                    controller: sealDate,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(13),
                                        borderSide: BorderSide(color: Colors.black, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(13),
                                        borderSide: BorderSide(color: Color(0xFF3949AB), width: 1),
                                      ),
                                    ),
                                  )

                              )

                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Seal Time:',style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                        SizedBox(width: 10),  // optional spacing
                        IntrinsicWidth(
                          child: IntrinsicHeight(
                              child: SizedBox(
                                  width: 230,
                                  height: 50,
                                  child: TextField(
                                    controller: sealTime,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(13),
                                        borderSide: BorderSide(color: Colors.black, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(13),
                                        borderSide: BorderSide(color: Color(0xFF3949AB), width: 1),
                                      ),
                                    ),
                                  )

                              )

                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('First Weight:',style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                        SizedBox(width: 10),  // optional spacing
                        IntrinsicWidth(
                          child: IntrinsicHeight(
                              child: SizedBox(
                                  width: 230,
                                  height: 50,
                                  child: TextField(
                                    controller: firstWeight,
                                    decoration: InputDecoration(
                                      hintText: 'Enter First Weight',
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(13),
                                        borderSide: BorderSide(color: Colors.black, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(13),
                                        borderSide: BorderSide(color: Color(0xFF3949AB), width: 1),
                                      ),
                                    ),
                                  )

                              )

                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                            width:80,
                            child: Text('Second Weight:',style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),)),
                        SizedBox(width: 10),  // optional spacing
                        IntrinsicWidth(
                          child: IntrinsicHeight(
                              child: SizedBox(
                                  width: 230,
                                  height: 50,
                                  child: TextField(
                                    controller: secondWeight,
                                    decoration: InputDecoration(
                                      hintText: 'Enter Second Weight',
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(13),
                                        borderSide: BorderSide(color: Colors.black, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(13),
                                        borderSide: BorderSide(color: Color(0xFF3949AB), width: 1),
                                      ),
                                    ),
                                  )

                              )

                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Net Weight:',style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                        SizedBox(width: 10),  // optional spacing
                        IntrinsicWidth(
                          child: IntrinsicHeight(
                              child: SizedBox(
                                  width: 230,
                                  height: 50,
                                  child: TextField(
                                    controller: netWeight,
                                    decoration: InputDecoration(
                                      hintText: '0.0',
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(13),
                                        borderSide: BorderSide(color: Colors.black, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(13),
                                        borderSide: BorderSide(color: Color(0xFF3949AB), width: 1),
                                      ),
                                    ),
                                  )

                              )

                          ),
                        ),
                      ],
                    ),
                  ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Start Seal No:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 10),
              IntrinsicWidth(
                child: IntrinsicHeight(
                  child: SizedBox(
                    width: 230,
                    height: 50,
                    child: TextFormField(
                      controller: startsealNO,
                      keyboardType: TextInputType.text, // if numeric only
                      onChanged: (value) {
                        _calculateSeals();
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter Start Seal No',
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide(color: Colors.black, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide(color: Color(0xFF3949AB), width: 1),
                        ),
                      ),

                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter Start Seal No';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'End Seal No:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 10),
              IntrinsicWidth(
                child: IntrinsicHeight(
                  child: SizedBox(
                    width: 230,
                    height: 50,
                    child: TextFormField(
                      controller: endsealNO,
                      keyboardType: TextInputType.text, // numeric input
                      onChanged: (value) {
                        _calculateSeals();
                      },

                      decoration: InputDecoration(
                        hintText: 'Enter End Seal No',
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide(color: Colors.black, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide(color: Color(0xFF3949AB), width: 1),
                        ),
                      ),

                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter End Seal No';
                        }
                        return null;
                      },

                    ),

                  ),
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'No of Seals:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 10),
              IntrinsicWidth(
                child: IntrinsicHeight(
                  child: SizedBox(
                    width: 230,
                    height: 50,
                    child: TextFormField(
                      controller: noofSeals,
                      readOnly: true,
                      keyboardType: TextInputType.number, // numeric input
                      decoration: InputDecoration(
                        hintText: 'Enter Number of Seals',
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide(color: Colors.black, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide(color: Color(0xFF3949AB), width: 1),
                        ),
                      ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Seal count not calculated';
                          }
                          return null;
                        }
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Color:',style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                        SizedBox(width: 10),  // optional spacing
                        IntrinsicWidth(
                          child: IntrinsicHeight(
                              child: SizedBox(
                                width: 230,
                                height: 50,
                                child: DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    hintText: 'Select Color',
                                    hintStyle: TextStyle(fontSize: 15),   // Center will still work
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(13),
                                      borderSide: BorderSide(color: Colors.black, width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(13),
                                      borderSide: BorderSide(color: Color(0xFF3949AB), width: 1),
                                    ),
                                  ),

                                  value: selectedColor,
                                  isExpanded: true,   // dropdown icon visible and hint centered
                                  icon: Icon(Icons.arrow_drop_down, size: 30), // dropdown symbol
                                  items: colorList.map((item) {
                                    return DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    );
                                  }).toList(),

                                  onChanged: (value) {
                                    setState(() {
                                      selectedColor = value!;
                                      selectColor.text = value;  // update controller
                                    });
                                  },
                                ),
                              )

                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Extra Start Seal No:',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            softWrap: true,
                          ),
                        ),
                        SizedBox(width: 10),  // optional spacing
                        IntrinsicWidth(
                          child: IntrinsicHeight(
                              child: SizedBox(
                                  width: 230,
                                  height: 50,
                                  child: TextField(
                                    controller: extrastartSealno,
                                    decoration: InputDecoration(
                                      hintText: ' Enter Extra Start Seal No',
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(13),
                                        borderSide: BorderSide(color: Colors.black, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(13),
                                        borderSide: BorderSide(color: Color(0xFF3949AB), width: 1),
                                      ),
                                    ),
                                  )

                              )

                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Extra End Seal No:',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            softWrap: true,
                          ),
                        ),
                        SizedBox(width: 10),  // optional spacing
                        IntrinsicWidth(
                          child: IntrinsicHeight(
                              child: SizedBox(
                                  width: 230,
                                  height: 50,
                                  child: TextField(
                                    controller: extraendSealno,
                                    decoration: InputDecoration(
                                      hintText: ' Enter Extra End Seal No',
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(13),
                                        borderSide: BorderSide(color: Colors.black, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(13),
                                        borderSide: BorderSide(color: Color(0xFF3949AB), width: 1),
                                      ),
                                    ),
                                  )

                              )

                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Other Extra Seal No:',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            softWrap: true,
                          ),
                        ),
                        SizedBox(width: 10),  // optional spacing
                        IntrinsicWidth(
                          child: IntrinsicHeight(
                              child: SizedBox(
                                  width: 230,
                                  height: 50,
                                  child: TextField(
                                    controller: otherextrasealNO,
                                    decoration: InputDecoration(
                                      hintText: 'Add other extra seal by',
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(13),
                                        borderSide: BorderSide(color: Colors.black, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(13),
                                        borderSide: BorderSide(color: Color(0xFF3949AB), width: 1),
                                      ),
                                    ),
                                  )

                              )

                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('GPS Seal No:',style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                        SizedBox(width: 10),  // optional spacing
                        IntrinsicWidth(
                          child: IntrinsicHeight(
                              child: SizedBox(
                                  width: 230,
                                  height: 50,
                                  child: TextField(
                                    controller: GPSsealNO,
                                    decoration: InputDecoration(
                                      hintText: ' Enter GPS Seal No',
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(13),
                                        borderSide: BorderSide(color: Colors.black, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(13),
                                        borderSide: BorderSide(color: Color(0xFF3949AB), width: 1),
                                      ),
                                    ),
                                  )

                              )

                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Tarpaulin Condition:',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            softWrap: true,
                          ),
                        ),
                        SizedBox(width: 10),  // optional spacing
                        IntrinsicWidth(
                          child: IntrinsicHeight(
                              child: SizedBox(
                                  width: 230,
                                  height: 50,
                                  child: TextField(
                                    controller: TarpaulinCondition,
                                    decoration: InputDecoration(
                                      hintText: 'Intact',
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(13),
                                        borderSide: BorderSide(color: Colors.black, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(13),
                                        borderSide: BorderSide(color: Color(0xFF3949AB), width: 1),
                                      ),
                                    ),
                                  )

                              )

                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                            width:80,
                            child: Text('Sender Remarks:',style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),)),
                        SizedBox(width: 10),  // optional spacing
                        IntrinsicWidth(
                          child: IntrinsicHeight(
                              child: SizedBox(
                                  width: 230,
                                  height: 50,
                                  child: TextField(
                                    controller: senderRemarks,
                                    decoration: InputDecoration(
                                      hintText: 'Enter Sender Remarks',
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(13),
                                        borderSide: BorderSide(color: Colors.black, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(13),
                                        borderSide: BorderSide(color: Color(0xFF3949AB), width: 1),
                                      ),
                                    ),
                                  )

                              )

                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Received by:',style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                        SizedBox(width: 10),  // optional spacing
                        IntrinsicWidth(
                          child: IntrinsicHeight(
                              child: SizedBox(
                                width: 230,
                                height: 50,
                                child: DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    hintText: 'Select Receiver',
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(13),
                                      borderSide: BorderSide(color: Colors.black, width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(13),
                                      borderSide: BorderSide(color: Color(0xFF3949AB), width: 1),
                                    ),
                                  ),

                                  value: selectedReceiver,
                                  isExpanded: true,
                                  icon: Icon(Icons.arrow_drop_down, size: 30),

                                  items: receiverList.map((item) {
                                    return DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    );
                                  }).toList(),

                                  onChanged: (value) {
                                    setState(() {
                                      selectedReceiver = value!;
                                      receivedBy.text = value;   // update TextField if needed
                                    });
                                  },
                                ),
                              )

                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Vehicle Reached Date:',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            softWrap: true,
                          ),
                        ),
                        SizedBox(width: 10),  // optional spacing
                        IntrinsicWidth(
                          child: IntrinsicHeight(
                              child: SizedBox(
                                  width: 230,
                                  height: 50,
                                  child: TextField(
                                controller: vehicleReachedDate,
                                readOnly: true, // prevent typing, open calendar instead
                                decoration: InputDecoration(
                                  hintText: 'Select Date',
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(13),
                                    borderSide: BorderSide(color: Colors.black, width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(13),
                                    borderSide: BorderSide(color: Color(0xFF3949AB), width: 1),
                                  ),
                                ),
                                onTap: () async {
                                  DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),                // default today
                                    firstDate: DateTime(2000),                  // minimum date
                                    lastDate: DateTime(2100),                   // maximum date
                                  );

                                  if (pickedDate != null) {
                                    String formattedDate = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                                    setState(() {
                                      vehicleReachedDate.text = formattedDate;            // assign selected date
                                    });
                                  }
                                },
                              ),


                          )

                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Vehicle Reached Time:',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            softWrap: true,
                          ),
                        ),
                        SizedBox(width: 10),  // optional spacing
                        IntrinsicWidth(
                          child: IntrinsicHeight(
                              child: SizedBox(
                                  width: 230,
                                  height: 50,
                                  child: TextField(
                                controller: vehicleReached,
                                readOnly: true, // prevent typing & open clock instead
                                decoration: InputDecoration(
                                  hintText: 'Select Time',
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(13),
                                    borderSide: BorderSide(color: Colors.black, width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(13),
                                    borderSide: BorderSide(color: Color(0xFF3949AB), width: 1),
                                  ),
                                ),
                                onTap: () async {
                                  TimeOfDay? pickedTime = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );

                                  if (pickedTime != null) {
                                    setState(() {
                                      vehicleReached.text = pickedTime.format(context); // show selected time in controller
                                    });
                                  }
                                },
                              ),


                          )

                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Receiver Remarks:',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            softWrap: true,
                          ),
                        ),
                        SizedBox(width: 10),  // optional spacing
                        IntrinsicWidth(
                          child: IntrinsicHeight(
                              child: SizedBox(
                                width: 230,
                                height: 50,
                                child: DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    hintText: 'Select Remarks',
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(13),
                                      borderSide: BorderSide(color: Colors.black, width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(13),
                                      borderSide: BorderSide(color: Color(0xFF3949AB), width: 1),
                                    ),
                                  ),

                                  value: selectedRemarks,
                                  isExpanded: true,
                                  icon: Icon(Icons.arrow_drop_down, size: 30),

                                  items: remarksList.map((item) {
                                    return DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    );
                                  }).toList(),

                                  onChanged: (value) {
                                    setState(() {
                                      selectedRemarks = value!;
                                      recieverRemarks.text = value;  // update TextField if required
                                    });
                                  },
                                ),
                              )

                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height:8,
                  ),

                  Container(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child:Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: enterrejectedSeal,
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
                                hintText: 'Enter rejected Seal',
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(13),
                                    topRight: Radius.circular(0),
                                    bottomLeft: Radius.circular(13),
                                    bottomRight: Radius.circular(0),
                                  ),
                                  borderSide: BorderSide(color: Colors.black, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  //borderRadius: BorderRadius.circular(13),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(13),
                                    topRight: Radius.circular(0),
                                    bottomLeft: Radius.circular(13),
                                    bottomRight: Radius.circular(0),
                                  ),
                                  borderSide: BorderSide(color: Colors.blueAccent, width: 1),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: enternewSeal,
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
                                hintText: 'Enter New Seal',
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(0),
                                    topRight: Radius.circular(13),
                                    bottomLeft: Radius.circular(0),
                                    bottomRight: Radius.circular(13),
                                  ),
                                  borderSide: BorderSide(color: Colors.black, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                               //   borderRadius: BorderRadius.circular(13),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(0),
                                    topRight: Radius.circular(13),
                                    bottomLeft: Radius.circular(0),
                                    bottomRight: Radius.circular(13),
                                  ),
                                  borderSide: BorderSide(color: Colors.blueAccent, width: 1),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )

                    ),
                  ),

                  Container(
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: openCamera,
                          icon: Icon(Icons.camera_alt),
                          label: Text("Take Photo with Camera"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF3949Ab),      // Button background color
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8), // <-- Border radius here
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Display the camera image
                        if (_cameraImage != null)
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Image.file(
                                _cameraImage!,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                right: 5,
                                top: 5,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _cameraImage = null;
                                    });
                                  },
                                  child: CircleAvatar(
                                    radius: 15,
                                    backgroundColor: Colors.black.withOpacity(0.7),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // 👈 shows nothing if _image is null

                ],
              ),
            ),


// Display Gallery button + image
            Container(
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: openGallery,
                    icon: Icon(Icons.photo_library),
                    label: Text("Add Photo from Gallery"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3949Ab),      // Button background color
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // <-- Border radius here
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Display the gallery image
                  if (_galleryImage != null)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Image.file(
                          _galleryImage!,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          right: 5,
                          top: 5,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _galleryImage = null;
                              });
                            },
                            child: CircleAvatar(
                              radius: 15,
                              backgroundColor: Colors.black.withOpacity(0.7),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            SizedBox(
              height:15,
            ),

            Padding(
              padding: const EdgeInsets.only(bottom:10),
              child: Container(
                height: 45,
                width: 180,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black26,      // Button background color
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // <-- Border radius here
                      ),
                    ),
                    onPressed:(){
                      submitSealData();
                      Navigator.push(context, MaterialPageRoute(builder:(context)=>sealdetailPage()),
                      );

                    },
                    child:Text('Submit',style: TextStyle(fontSize: 18),)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class DropdownItem {
  final String id;
  final String name;

  DropdownItem({required this.id, required this.name});

  factory DropdownItem.fromJson(Map<String, dynamic> json, String type) {
    switch (type) {
      case 'location_port':
        return DropdownItem(
          id: json['location_id'].toString(),
          name: json['location_name'].toString(),
        );
      case 'plant':
        return DropdownItem(
          id: json['plant_id'].toString(),
          name: json['plant_name'].toString(),
        );
      case 'material':
        return DropdownItem(
          id: json['material_id'].toString(),
          name: json['material_name'].toString(),
        );
      case 'vessel':
        return DropdownItem(
          id: json['vessel_id'].toString(),
          name: json['vessel_name'].toString(),
        );
      default:
        return DropdownItem(id: '', name: '');
    }
  }
}

