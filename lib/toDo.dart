import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_slidable/flutter_slidable.dart';

import 'main.dart';

class ToDo extends StatefulWidget {
  String token;
  List<dynamic> tasks;
  ToDo(this.token, this.tasks);

  @override
  _ToDoState createState() => new _ToDoState(token, tasks);
}

class _ToDoState extends State<ToDo> {
  String token;
  List<dynamic> tasks;
  bool debugger = false;

  _ToDoState(this.token, this.tasks);

  TextEditingController taskCtrl = TextEditingController();
  void debug() {
    print("Currently in tasks");
    if (tasks != null) {
      for (int i = 0; i < tasks.length; ++i) {
        print('${tasks[i]["id"]} ${tasks[i]["text"]} ${tasks[i]["completed"]}');
      }
    }
  }

  Future<bool> start() async {
    tasks = await GetTask.getTasks(token);

    if (tasks.isNotEmpty) {
      buildTasks();
      if (debugger == true) {
        debug();
      }
      return true;
    }
    return false;
  }

// Create new task
  Future<String> addTask(String token, String newTask) async {
    // To add a new task
    var response = await http.post(
        'https://blooming-lake-91015.herokuapp.com/todo_items?text=$newTask',
        headers: {HttpHeaders.authorizationHeader: "bearer " + token});

    //if successful, that is, status is 201
    if (response.statusCode == 201) {
      if (debugger == true) {
        print("ITEM HAS BEEN CREATED");
      }
      return "Created";
    } else {
      if (debugger == true) {
        print("ERROR: FAILED TO CREATE ITEM");
      }
      return null;
    }
  }

  // Get all the tasks
  Future<bool> deleteTask(String token, String n) async {
    //try to delete task
    var response = await http.delete(
        'https://blooming-lake-91015.herokuapp.com/todo_items/$n',
        headers: {HttpHeaders.authorizationHeader: "bearer " + token});

    // if successful, that is, status is 200 - then the item has been deleted
    if (response.statusCode == 200) {
      if (debugger == true) {
        print("ITEM HAS BEEN DELETED");
      }

      return true;
    } else {
      if (debugger == true) {
        print("ERROR: FAILED TO DELETE ITEM");
      }
      return false;
    }
  }

  Future<bool> updateTask(
      String token, String n, String text, String check) async {
    // Check if task exist - update it
    var response = await http.patch(
        'https://blooming-lake-91015.herokuapp.com/todo_items/$n?text=$text&completed=$check',
        headers: {HttpHeaders.authorizationHeader: "bearer " + token});

    // if 200 then task was updated
    if (response.statusCode == 200) {
      tasks = await GetTask.getTasks(token);
      buildTasks();

      if (debugger == true) {
        print('TASK WAS UPDATED');
        debug();
      }
      return true;
    }
    // error
    else {
      if (debugger == true) {
        print('ERROR: FAILED TO UPDATE TASK');
      }
      return false;
    }
  }

  void _showDialog(int id, String taskName, bool completed, int n) {
    taskCtrl = new TextEditingController();
    taskCtrl.text = taskName;
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("Edit Task"),
            content: new TextField(
              controller: taskCtrl,
            ),
            actions: <Widget>[
              new FlatButton(
                child: new Text("Save"),
                onPressed: () async {
                  bool added = await updateTask(token, id.toString(),
                      taskCtrl.text, completed.toString());
                  if (added != null) {
                    tasks = await GetTask.getTasks(token);
                    Navigator.of(context).pop();
                  }
                },
              )
            ],
          );
        });
  }

  Widget buildTasks() {
    return new ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, n) {
        bool complete = false;

        if (tasks[n]["completed"] == 'true') {
          complete = true;
        }
        if (tasks[n]["text"] == null) {
          return _buildRow(tasks[n]["id"], "", complete, n);
        } else {
          return _buildRow(tasks[n]["id"], tasks[n]["text"], complete, n);
        }
      },
    );
  }

  Widget _buildRow(int id, String taskName, bool completed, int n) {
    return new Slidable(
      delegate: new SlidableDrawerDelegate(),
      actionExtentRatio: 0.25,
      child: new Container(
        color: Colors.white,
        child: new CheckboxListTile(
          value: tasks[n]['completed'],
          onChanged: (bool newValue) {
            setState(() {
              tasks[n]['completed'] = newValue;
              completed = newValue;
              updateTask(token, id.toString(), taskName, completed.toString());
            });
          },
          title: new Text(taskName),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ),
      secondaryActions: <Widget>[
        new IconSlideAction(
            caption: 'Edit',
            color: Colors.blue,
            icon: Icons.edit,
            onTap: () async {
              _showDialog(id, taskName, tasks[n][2], n);
              tasks = await GetTask.getTasks(token);
            }),
        new IconSlideAction(
            caption: 'Delete',
            color: Colors.red,
            icon: Icons.delete,
            onTap: () async {
              bool delete = await deleteTask(token, id.toString());
              tasks = await GetTask.getTasks(token);
              if (delete != null) {
                setState(() {
                  buildTasks();
                });
              }
            }), 
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    start();
    return Scaffold(
      appBar: AppBar(
        title: Text("To Do"),
        leading: new IconButton(
          icon: new Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),),
        ),
      ),
      body: buildTasks(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          taskCtrl = new TextEditingController();
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: new Text("Add Task"),
                  content: new TextField(
                    controller: taskCtrl,),
                  actions: <Widget>[
                    new FlatButton(
                      child: new Text("Save"),
                      onPressed: () async {
                        String added = await addTask(token, taskCtrl.text);
                        tasks = await GetTask.getTasks(token);
                        if (added != null) {
                          Navigator.of(context).pop();}},
                    )
                  ],
                );
              });
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
