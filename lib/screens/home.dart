import 'package:flutter/material.dart';

import '../model/todo.dart';
import '../constants/colors.dart';
import '../widgets/todo_item.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tuple/tuple.dart';
import 'package:intl/intl.dart';
import 'package:flutter/animation.dart';

class Home extends StatefulWidget {
  Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home>{
  final todosList = ToDo.todoList();
  List<ToDo> _foundToDo = [];

  final _todoController = TextEditingController();
  final _searchController = TextEditingController();

  Timer?_timer;

  @override
  void initState() {_foundToDo = _sortToDoList(todosList);_timer = Timer.periodic(Duration(minutes: 1), (Timer t) {
    setState(() {});
  });
  super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime? _completionDate;
  TimeOfDay? _completionTime;

  //original sorting
  /*
  List<ToDo>_sortToDoList(List<ToDo> listToSort) {
    List<ToDo> sortedList = listToSort.toList(); // Create a copy of the list
    sortedList.sort((a, b) {
      if (a.isDone == b.isDone) {
        // Compare the createdTime properties, providing a default value of 'DateTime.fromMicrosecondsSinceEpoch(0)' in case it is null
        return (b.createdTime ?? DateTime.fromMicrosecondsSinceEpoch(0)).compareTo(a.createdTime ?? DateTime.fromMicrosecondsSinceEpoch(0));
      }
      return a.isDone ? 1 : -1;
    });
    return sortedList;
  }
  */

  //new sorting
  List<ToDo>_sortToDoList(List<ToDo> listToSort) {
    List<ToDo> sortedList = listToSort.toList(); // Create a copy of the list

    Comparator<ToDo> todoComparator = (a, b) {
      // Sort by isDone
      if (a.isDone != b.isDone) {
        return a.isDone ? 1 : -1;
      }

      // Sort by completionDate
      if (a.completionDate != b.completionDate) {
        if (a.completionDate == null) return 1;
        if (b.completionDate == null) return -1;
        return a.completionDate!.compareTo(b.completionDate!);
      }

      // Sort by completionTime
      if (a.completionTime != b.completionTime) {
        if (a.completionTime == null) return 1;
        if (b.completionTime == null) return -1;
        int aMinutes = a.completionTime!.hour *60 + a.completionTime!.minute;
        int bMinutes = b.completionTime!.hour* 60 + b.completionTime!.minute;
        return aMinutes.compareTo(bMinutes);
      }

      // Sort by createdTime as a final tiebreaker
      DateTime aCreatedTime = a.createdTime ?? DateTime.fromMicrosecondsSinceEpoch(0);
      DateTime bCreatedTime = b.createdTime ?? DateTime.fromMicrosecondsSinceEpoch(0);
      return bCreatedTime.compareTo(aCreatedTime);
    };

    sortedList.sort(todoComparator);
    return sortedList;
  }

  List<Tuple3<String?, DateTime?, TimeOfDay?>> parseAssistantResponse(String response) {
    List<Tuple3<String?, DateTime?, TimeOfDay?>> parsedList = [];
    List<String> taskEntries = response.split('---');
    for (String entry in taskEntries) {
      String? extractedText;
      DateTime? extractedDate;
      TimeOfDay? extractedTime;
      RegExp taskPattern = RegExp(r'\(Task\)([^()]+)');
      RegExp datePattern = RegExp(r'\(Date\)([^()]+)');
      RegExp timePattern = RegExp(r'\(Time\)([^()\n]+)');
      final taskMatch = taskPattern.firstMatch(entry);
      final dateMatch = datePattern.firstMatch(entry);
      final timeMatch = timePattern.firstMatch(entry);
      if (taskMatch != null) {
        extractedText = taskMatch.group(1)?.trim();
      }
      if (dateMatch != null) {
        String? dateString = dateMatch.group(1)?.trim();
        if (dateString != null && dateString.isNotEmpty) {
          List<String> formats = [
            "dd/MM/yyyy",
            "MM-dd-yyyy",
            "yyyy/MM/dd",
            "yyyy-MM-dd",
            "dd-MM-yyyy",
          ];

          for (String format in formats) {
            try {
              DateFormat dateFormat = DateFormat(format);
              extractedDate = dateFormat.parseStrict(dateString);
              if (extractedDate != null) {
                print("Extracted Date: $extractedDate");
                break;
              }
            } catch (e) {}
          }
        }
      }

      if (timeMatch != null) {
        String? timeString = timeMatch.group(1)?.trim();
        if (timeString != null && timeString.isNotEmpty) {
          try {
            DateTime parsedDateTime = DateTime.parse(
                '1970-01-01 $timeString');
            TimeOfDay parsedTime = TimeOfDay.fromDateTime(parsedDateTime);
            extractedTime = parsedTime;
            if (extractedTime != null) {
              print("Extracted Time: $extractedTime");
            }
          } catch (e) {
            print("Error parsing time: $e");
          }
        }
      }
      parsedList.add(Tuple3<String?, DateTime?, TimeOfDay?>(extractedText, extractedDate, extractedTime));
    }
    return parsedList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tdBGColor,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Column(
                children: [
                searchBox(),
            Expanded(
              child: SingleChildScrollView(
                child:Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 50, bottom: 20),
                      child: Text('AI Assistant To-Do List',
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500)),
                    ),
                    for (ToDo todoo in _sortToDoList(_foundToDo))
                      ToDoItem(
                          key: Key(todoo.id!),
                          todo: todoo,
                          onToDoChanged: _handleToDoChange,
                          onDeleteItem:_deleteToDoItem,
                        ),
                    SizedBox(height: 70),
                  ],
                ),
              ),
            ),
            ],),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Row(children: [
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(bottom: 20, right: 20, left: 20),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(
                      color: Colors.grey, offset: Offset(0.0, 0.0),
                      blurRadius: 10.0, spreadRadius: 0.0,)
                    ],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller:_todoController,
                    decoration: InputDecoration(
                        hintText: 'Add a new todo item',
                        border: InputBorder.none),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(bottom: 20, right: 10),
                child:buildButtonWithText('+'),
              ),
              Container(
                margin: EdgeInsets.only(bottom: 20, right: 20),
                child:buildButtonWithText('AI'),
              ),
            ]),
          ),
        ],
      ),
    );
  }

// Added a new function to create button with given text
  Widget buildButtonWithText(String buttonText) {
    return ElevatedButton(
      child: Text(
        buttonText,
        style: TextStyle(fontSize: buttonText == '+' ? 40 : 20),
      ),
      onPressed: () async {
        if (buttonText == 'AI') {
          try {
            final generatedText = await _sendToAnthropicApi(_todoController.text);
            List<Tuple3<String?, DateTime?, TimeOfDay?>> parsedResponses = parseAssistantResponse(generatedText);
            for (var parsedResponse in parsedResponses) {
              String? textToUse = parsedResponse.item1;
              // Check if Claude's response is in the expected format
              if (textToUse != null && textToUse.isNotEmpty) {
                setState(() {_completionDate = parsedResponse.item2;_completionTime = parsedResponse.item3;
                if (_completionDate == null ||_completionTime == null) {
                  TextEditingController dateController = TextEditingController();
                  TextEditingController timeController = TextEditingController();_showDateTimeDialog(context, dateController, timeController).then((_) {
                    setState(() {
                      _addToDoItem(textToUse,_completionDate,_completionTime, delayMilliseconds: 50);_todoController.clear();_completionDate = null;_completionTime = null;
                    });
                  });
                } else {
                  _addToDoItem(textToUse,_completionDate,_completionTime, delayMilliseconds: 50);_todoController.clear();_completionDate = null;_completionTime = null;
                }
                });
              } else {_showResponsePopup(context, generatedText);
              }
            }

          } catch (e) {
            print('Error: $e');
          }
        } else {
          TextEditingController dateController = TextEditingController();
          TextEditingController timeController = TextEditingController();
          await _showDateTimeDialog(context, dateController, timeController);

          setState(() {_addToDoItem(
              _todoController.text,_completionDate, _completionTime);_todoController.clear();
          _completionDate = null;_completionTime = null;
          });
        }
      },
      style: ElevatedButton.styleFrom(
          primary: tdBlue, minimumSize: Size(60, 60), elevation: 10),
    );
  }

// Moved the showDialog logic to a separate function
  Future<void>_showDateTimeDialog(
      BuildContext context,
      TextEditingController dateController,
      TextEditingController timeController) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter completion date/time'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                readOnly: true,
                controller: dateController,
                decoration: InputDecoration(
                  labelText: 'Date',
                  hintText: 'Select date',
                ),
                onTap: () async {
                  DateTime? date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100));
                  if (date != null) {
                    setState(() {_completionDate = date;
                    dateController.text =
                    date.toString().split(' ')[0];
                    });
                  }
                },
              ),
              TextField(
                readOnly: true,
                controller: timeController,
                decoration: InputDecoration(
                  labelText: 'Time',
                  hintText: 'Select time',
                ),
                onTap: () async {
                  TimeOfDay? time = await showTimePicker(
                      context: context, initialTime: TimeOfDay.now());
                  if (time != null) {
                    setState(() {_completionTime = time;
                    timeController.text =
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Submit'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _handleToDoChange(ToDo todo) {
    setState(() {
      todo.isDone = !todo.isDone;
    });
  }

  void _deleteToDoItem(String? todoId) {
    setState(() {
      todosList.removeWhere((todo) => todo.id == todoId);
      _runFilter(_searchController.text); // Use_runFilter to refresh the list
    });
  }

  void _addToDoItem(String toDo, DateTime? completionDate, TimeOfDay? completionTime, {int? delayMilliseconds}) async {
    if (delayMilliseconds != null) {
      await Future.delayed(Duration(milliseconds: delayMilliseconds));
    }

    setState(() {
      todosList.add(ToDo(
        id: UniqueKey().toString(),
        todoText: toDo,
        completionDate: completionDate,
        completionTime: completionTime,
        createdTime: DateTime.now(),
      ));_foundToDo = _sortToDoList(todosList);
    });
  }

  void _runFilter(String enteredKeyword) {
    List<ToDo> results = [];
    if (enteredKeyword.isEmpty) {
      results = todosList;
    } else {
      results = todosList.where((item) =>
          item.todoText!.toLowerCase().contains(enteredKeyword.toLowerCase())
      ).toList();
    }
    setState(() {
      _foundToDo =_sortToDoList(results);
    });
  }

  void _showResponsePopup(BuildContext context, String response) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Claude's Response"),
          content: SingleChildScrollView(
            child: Text(response),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  //Claude Implementation
  Future<String>_sendToAnthropicApi(String prompt) async {
    const apiKey = 'YOURAPIKEYHERE'; // Replace this with your actual API key
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('MMM d, y').format(now);
    String formattedTime = DateFormat('HH:mm').format(now);
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/complete'),
      headers: {
        'x-api-key': apiKey,
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'prompt': 'Today is $formattedDate and the current time is $formattedTime. Break down the following task(s) into: simplified tasks, a date in the format DD/MM/YYYY, and a time in 24-hour format, all formatted as thus: (Task) <task_text> (Date) <date_text> (Time) <time_text>. It is very important to separate EACH individual tasks with "---" when you are asked for several tasks. Example: \n(Task) Task 1 (Date) 01/01/2022 (Time) 14:00 --- (Task) Task 2 (Date) 02/01/2022 (Time) 16:00 --- (Task) Task 3 (Date) 03/01/2022 (Time) 18:00\nStrictly follow this formatting and use the "---" separator between tasks. Do not set the date and time to be in the past, unless explicitly told. Do not output anything else, unless you are unable to complete the task or need clarification.\n\nHuman: $prompt\n\nAssistant: ',
        'model': 'claude-v1',
        'max_tokens_to_sample': 8192,
        'stop_sequences': ['\n\nHuman:'],
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('Anthropic API response: $responseData'); //print in terminal
      // Check if responseData contains 'completion' key instead of 'choices'
      if (responseData != null && responseData.containsKey('completion')) {
        final generatedText = responseData['completion'].toString(); // Get the generated text from 'completion'
        return generatedText;
      } else {
        throw Exception('Failed to get response from Anthropic API: Invalid data received');
      }
    } else {
      throw Exception('Failed to get response from Anthropic API. Status Code: ${response.statusCode}');
    }
  }

  Widget searchBox() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => _runFilter(value),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.all(0),
          prefixIcon: Icon(Icons.search, color: tdBlack, size: 20),
          prefixIconConstraints: BoxConstraints(maxHeight: 20, minWidth: 25),
          border: InputBorder.none,
          hintText: 'Search',
          hintStyle: TextStyle(color: tdGrey),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: tdBGColor,
      elevation: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            Icons.menu,
            color: tdBlack,
            size: 30,
          ),
          Container(
            height: 40,
            width: 40,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset('assets/images/avatar.jpeg'),
            ),
          ),
        ],
      ),
    );
  }
}
