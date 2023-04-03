import 'dart:isolate';

import 'package:flutter/foundation.dart';

class FlutterIsolate {
  FlutterIsolate._internal();
  static final FlutterIsolate _flutterIsolate = FlutterIsolate._internal();

  factory FlutterIsolate() {
    return _flutterIsolate;
  }
  
  ///Receiver port on main isolate
  final receivePort = ReceivePort();
  SendPort? sendPort;

  createIsolate() async { 
    
    ///sending sendPort to new isolate to send messages back
    var sendData = <String, dynamic>{
      'send_port': receivePort.sendPort,
    };
    
    ///creating isolate 
    await Isolate.spawn<Map<String, dynamic>>(expensiveTask, sendData);
    
    ///listening to messages from new isolate
    receivePort.listen((message) {
      ///checking if the message is sendPort data
      if (message['is_port_data'] as bool) {
        sendPort = message['send_port'] as SendPort;
      } else {
        var taskName = message['task_name'];
        debugPrint('$taskName completed');
      }
    });
  }
  
  /// function that will send message to new isolate and do our task(printing the task name in our case)
  doExpensiveTask(String taskName) {
    if (sendPort != null) {
      var sendData = {'task_name': taskName};
      sendPort!.send(sendData);
    }
  }
}

///isolate entry point
expensiveTask(Map<String, dynamic> data) {
  ///Receiver port of new isolate
  final receivePort = ReceivePort();

  var sendProt = data['send_port'] as SendPort;
  var sendData = {'send_port': receivePort.sendPort, 'is_port_data': true};

  ///sending sendPort to main isolate to send messages back
  sendProt.send(sendData);

  ///Listening to messages from main isolate
  receivePort.listen((message) {
    var taskName = message['task_name'];

    ///prints the task name
    debugPrint('$taskName printing in new isolate');
    var sendData = {'is_port_data': false, 'task_name': taskName};
    sendProt.send(sendData);
  });
}