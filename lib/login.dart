import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:scrap_project/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


class Input extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => Input_State();
}

class Input_State extends State<Input> {
  final TextEditingController user_id = TextEditingController();
  final TextEditingController user_pass = TextEditingController();




  bool isLoading = false;
  String errorMessage = '';

  Future<void> login() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final url = Uri.parse('https://scrap.systementerprises.in/api/Comp_login/login');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'user_id': user_id.text.trim(),
          'user_pass': user_pass.text.trim(),
          'uuid': 'PPR1.180610.011',
        },
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['session_data'] != null) {
          final session = data['session_data'];
          final userName = session['user_name'] ?? 'User';
          final remaining_days = session['remaining_days'] ?? 'N/A';
          final user_email = session['user_email'] ?? 'N/A';
          final user_add = session['user_add'] ?? 'N/A';

          // ✅ Save data locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('user_id', user_id.text.trim());
          await prefs.setString('user_pass', user_pass.text.trim());
          await prefs.setString('uuid','PPR1.180610.011');
          await prefs.setString('user_name', userName);
          await prefs.setString('remaining_days', remaining_days);
          await prefs.setString('user_email',user_email );
          await prefs.setString('user_add',user_add );


          // ✅ Go to welcome page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ProfilePage()),
          );
        } else {
          setState(() {
            errorMessage = 'Invalid login credentials';
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
        title: const Text('LOGIN FORM'),
        backgroundColor: Colors.lightBlue,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextField(
                  controller: user_id,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: 'ENTER USER ID',
                    prefixIcon: const Icon(Icons.person, color: Colors.lightBlue),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: const BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: user_pass,
                  obscureText: true,
                  obscuringCharacter: '*',
                  decoration: InputDecoration(
                    hintText: 'ENTER PASSWORD',
                    prefixIcon: const Icon(Icons.lock, color: Colors.lightBlue),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: const BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const SizedBox(height: 15),

                if (errorMessage.isNotEmpty)
                  Text(errorMessage, style: const TextStyle(color: Colors.red)),

                const SizedBox(height: 10),
                Container(
                  width: 300,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Login',style: TextStyle(fontSize: 15),),
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Register'),
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  width: 135,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Go Back'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
