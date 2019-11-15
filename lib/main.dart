import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'toDo.dart';
import 'secretScreen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(),
    );
  }
}

class GetTask {
  static Future<List<dynamic>> getTasks(String token) async {
    // get tasks from api
    var response = await http.get(
        'https://blooming-lake-91015.herokuapp.com/todo_items',
        headers: {HttpHeaders.authorizationHeader: "bearer " + token});

    //if successful, that is, status is 200
    if (response.statusCode == 200) {
      List<dynamic> mess = json.decode(response.body);

      return mess;
    } else {
      return null;
    }
  }
}

class LoginScreen extends StatelessWidget {
  TextEditingController usernameCtrl = TextEditingController();
  TextEditingController passwordCtrl = TextEditingController();

  Future<String> login(String username, String password) async {
    //try to login to https://sleepy-hamlet-97922.herokuapp.com/api/login
    var response = await http.get(
        'https://blooming-lake-91015.herokuapp.com/api/login?username=$username&password=$password');

    //if successful, that is, status is 200
    if (response.statusCode == 200) {
      //parse the response
      Map<String, dynamic> parsedJson = json.decode(response.body);
      String token = parsedJson['token'];
      //return the token
      return token;
    }
    //if not successful return null
    else {
      return null;
    }
  }

  Future<String> register(String username, String password) async {
    //try to login to https://sleepy-hamlet-97922.herokuapp.com/api/login
    var response = await http.post(
        'https://blooming-lake-91015.herokuapp.com/api/register?username=$username&password=$password');

    //if successful, that is, status is 201
    if (response.statusCode == 201) {
      //parse the response
      Map<String, dynamic> parsedJson = json.decode(response.body);
      //return the token
      String message = parsedJson['message'];
      return message;
    }
    //if not successful return null
    else {
      return null;
    }
  }

  Future<String> getSecretMessage(String token) async {
    //try to retrieve secret
    //set HttpHeaders.authorizationHeader to Bearer token
    var response = await http.get(
        'https://blooming-lake-91015.herokuapp.com/secret',
        headers: {HttpHeaders.authorizationHeader: "bearer " + token});

    //if successful, that is, status is 200
    if (response.statusCode == 200) {
      //parse the response
      Map<String, dynamic> parsedJson = json.decode(response.body);
      String message = parsedJson['message'];
      //return the secret message
      return message;
    }
    //if not successful, return null
    else {
      return null;
    }
  }

  bool emailCheck(String username) {
    return RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(username);
  }

  void _showDialog(BuildContext context, String title, String body,
      String button, bool pressed, String token2, List<dynamic> tasks) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text('$title'),
            content: new Text('$body'),
            actions: <Widget>[
              new FlatButton(
                child: new Text('$button'),
                onPressed: () {
                  if (pressed == true) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ToDo(token2, tasks)),
                    );
                  }
                },
              )
            ],
          );
        });
  }

  void loginSubmit(BuildContext context) async {
    if (emailCheck(usernameCtrl.text) == true) {
      //Try to login and retrieve token
      //String token = await login('p@test.com', 'admin');
      String token = await login(usernameCtrl.text, passwordCtrl.text);
      List<dynamic> tasks;
      //if token is valid
      if (token != null) {
        //try to fetch the secret info
        String secret = await getSecretMessage(token);
        tasks = await GetTask.getTasks(token);

        //if successfully retrieved
        if (secret != null) {
          //navigate to MainScreen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ToDo(token, tasks)),
          );
        }
      } else {
        _showDialog(
            context,
            "Invalid",
            "The username and or password you entered did not match our records. Please double-check and try again.",
            "Close",
            true,
            null,
            null);
      }
    } else {
      _showDialog(
          context,
          "Invalid",
          "Not a valid email. Please double-check and try again.",
          "Close",
          true,
          null,
          null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TextField(
            //Placeholder Text for username
            decoration: new InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.go,
            controller: usernameCtrl,
            onSubmitted: (usernameCtrl) {
              loginSubmit(context);
            },
          ),
          TextField(
            //Placeholder Text for password
            decoration: new InputDecoration(
              hintText: "Password",
            ),
            textInputAction: TextInputAction.go,
            // Hide password
            obscureText: true,
            controller: passwordCtrl,
            onSubmitted: (usernameCtrl) {
              loginSubmit(context);
            },
          ),
          RaisedButton(
            child: Text("Login"),
            onPressed: () async {
              loginSubmit(context);
            },
          ),
          RaisedButton(
            child: Text("Register"),
            onPressed: () async {
              String reg;
              String token2;
              List<dynamic> tasks;

              if(usernameCtrl.text != "" && passwordCtrl.text != ""){
              reg = await register(usernameCtrl.text, passwordCtrl.text);
              token2 = await login(usernameCtrl.text, passwordCtrl.text);
              tasks = await GetTask.getTasks(token2);

              }
              //navigate to
              //MainScreen("Secret constructor message")

              if (reg != null) {
                _showDialog(
                    context,
                    "Congratulations!",
                    "Your account was successfully created.",
                    "Ok",
                    false,
                    token2,
                    tasks);
              } else {
                _showDialog(
                    context,
                    "Invalid Username",
                    "Someone already has that username. Please try again.",
                    "Close",
                    true,
                    null,
                    null);
              }
            },
          )
        ],
      ),
    );
  }
}


