import 'dart:convert';

import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:laira/utils/constant.dart';
import 'package:laira/utils/uses-api.dart';

final storage = new FlutterSecureStorage();

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> with UsesApi {
  String email = "";
  String password = "";
  String error = "";

  void _setError(String error) {
    setState(() {
      this.error = error;
    });
  }

  Future<http.Response> login() {
    return http.post(
      Uri.http(dotenv.env['API_HOST_IP']!, '/api/user/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
          <String, String>{'email': this.email, 'password': this.password}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        backgroundColor: Theme.of(context).backgroundColor,
        body: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(children: <Widget>[
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Laira",
                      style: TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor)),
                  Text("Twoja podróż zaczyna się tutaj!",
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w200,
                          color: Theme.of(context).accentColor)),
                ],
              ),
            ),
            SizedBox(
              height: 50,
            ),
            TextField(
              onChanged: (email) => this.email = email,
              decoration: InputDecoration(
                hintText: "Adres email",
                prefixIcon:
                    Icon(Icons.mail, color: Theme.of(context).primaryColor),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              onChanged: (password) => this.password = password,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Hasło",
                prefixIcon:
                    Icon(Icons.lock, color: Theme.of(context).primaryColor),
              ),
            ),
            SizedBox(height: 5),
            SizedBox(height: 20),
            SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Text(this.error, style: TextStyle(color: Colors.red))),
            SizedBox(height: 20),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 50,
              child: TextButton(
                onPressed: () async {
                  try {
                    CoolAlert.show(
                      context: context,
                      backgroundColor: Theme.of(context).backgroundColor,
                      type: CoolAlertType.loading,
                    );
                    http.Response response = await this.login();
                    Map<String, dynamic> map = jsonDecode(response.body);
                    if (response.statusCode != 200) {
                      this._setError(map['error']);
                    } else {
                      await storage.write(key: 'jwtLaira', value: map['jwt']);
                      Position position = await GeolocatorPlatform.instance
                          .getCurrentPosition();
                      await UsesApi.post("/api/user/location", body: {
                        "lat": position.latitude,
                        "lon": position.longitude
                      });
                      await Navigator.pushReplacementNamed(context, "/home");
                    }
                  } catch (e) {
                    this._setError("Error occures " + e.toString());
                  } finally {
                    Navigator.of(context, rootNavigator: true).pop();
                  }
                },
                child: Text("Zaloguj się",
                    style: TextStyle(
                        color: Theme.of(context).accentColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w300)),
                style: TextButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ),
            SizedBox(height: 5),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 50,
              child: TextButton(
                onPressed: () async {
                  try {
                    await Navigator.pushReplacementNamed(context, "/register");
                  } catch (e) {} finally {}
                },
                child: Text("Utwórz konto",
                    style: TextStyle(
                        color: Theme.of(context).accentColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w300)),
                style: TextButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ),
            )
          ]),
        ));
  }
}
