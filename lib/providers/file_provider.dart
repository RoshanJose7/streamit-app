import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:uuid/uuid.dart';

import '../models/file_transfer.dart';

class FileProvider extends ChangeNotifier {
  int chunkSize = 1000000;
  int _currentPosition = 0;
  int _currentChunkCount = 0;
  int progressPercentage = 0;

  String? notification;

  late Socket socket;
  final uuid = const Uuid();

  String? _name;
  String? _room;

  File? _currentFileToBeSent;
  File? _currentReceivingFile;

  final List _messages = [];

  List get messages => _messages;

  String? get name => _name;
  String? get room => _room;

  FileProvider() {
    socket = io('https://d55b-49-206-133-199.ngrok-free.app', <String, dynamic>{
      'upgrade': false,
      'transports': ["websocket"],
      'maxHttpBufferSize': chunkSize,
    });

    socket.connect();
    socket.on('connect', (_) => debugPrint('Connected: ${socket.id}'));
    socket.on('disconnect', (_) => debugPrint('Disconnected: ${socket.id}'));
    socket.on("error", (err) => debugPrint(err));

    // Custom Events
    socket.on("ack_file_create", ackFileCreate);
    socket.on("file_part_recv", filePartReceive);
    socket.on("notification", displayNotification);
    socket.on("ack_file_part", ackFilePart);
  }

  set setName(String kName) {
    _name = kName;
    notifyListeners();
  }

  void joinRoom(String roomid) {
    _room = roomid;
    socket.emit("join_room", {"name": _name, "room": roomid});

    notifyListeners();
  }

  void leaveRoom(String roomid) {
    _room = null;
    socket.emit("leave_room", {"name": _name, "room": roomid});

    notifyListeners();
  }

  // Custom Event Handlers
  void displayNotification(dynamic data) async {
    debugPrint("notification: ${data["type"]}");
    String type = data["type"];

    if (type == "log") {
      _messages.add(data["notification"]);
    } else if (type == "new_file") {
      Directory? externalDirectory = await getExternalStorageDirectory();

      _currentReceivingFile =
          File('${externalDirectory!.path}/${data["data"]["name"]}');
      bool outFileExists = await _currentReceivingFile!.exists();

      if (!outFileExists) await _currentReceivingFile!.create();
    } else if (type == "percentage_update") {
      progressPercentage = data["data"]["percentage"];
    } else if (type == "new_file_received") {
      final fileData = data["data"];

      FileTransfer newFile = FileTransfer(
        file: _currentReceivingFile!,
        fileName: fileData["name"],
        type: fileData["type"],
        sender: fileData["sender"],
        isLeft: true,
        timestamp: DateTime.now().toUtc(),
      );

      _messages.add(newFile);
    }

    notifyListeners();
  }

  void filePartReceive(dynamic data) async {
    if (_currentReceivingFile != null) {
      Uint8List chunkData = data["chunk"];

      await _currentReceivingFile!.writeAsBytes(
        chunkData,
        mode: FileMode.append,
      );
    }
  }

  Future<void> ackFileCreate(dynamic data) async {
    final length = _currentFileToBeSent!.lengthSync();
    final raFile = _currentFileToBeSent!.openSync();

    final percentage = (100 / _currentChunkCount) * 1;

    int start = _currentPosition;
    int end = (_currentPosition + chunkSize).clamp(0, length);

    List<int> bytes = Uint8List(end);
    List<int> chunkBytes = Uint8List(end - start);

    raFile.readIntoSync(bytes, start, end);

    List.copyRange(chunkBytes, 0, bytes, start, end);

    uploadChunk(chunkBytes, data["transferid"], _currentPosition);

    raFile.closeSync();
  }

  Future<void> ackFilePart(dynamic data) async {
    final raFile = await _currentFileToBeSent!.open();
    final length = await _currentFileToBeSent!.length();

    if ((_currentPosition + chunkSize) >= length) {
      socket.emit("file_complete", {
        "counter": _currentPosition,
        "transferid": data["transferid"],
      });

      _currentPosition = 0;
      _currentFileToBeSent = null;

      debugPrint("File Sent!");
    } else {
      if (!data["chunkReceived"]) {
        // Send same chunk
        print("Chunk failed at ${data["counter"]}");
      } else {
        // Next Chunk
        _currentPosition += chunkSize;
      }

      int start = _currentPosition;
      int end = (_currentPosition + chunkSize).clamp(0, length);

      List<int> bytes = Uint8List(end);
      List<int> chunkBytes = Uint8List(end - start);

      raFile.readIntoSync(bytes, start, end);

      List.copyRange(chunkBytes, 0, bytes, start, end);

      uploadChunk(chunkBytes, data["transferid"], _currentPosition);

      await raFile.close();
    }
  }

  void createFile(File file, String fileid) async {
    _currentFileToBeSent = file;

    final transferid = uuid.v4();
    FileStat fileStat = await file.stat();

    _currentChunkCount = (fileStat.size % chunkSize == 0
            ? fileStat.size / chunkSize
            : (fileStat.size / chunkSize).floor() + 1)
        .toInt();

    final data = {
      "room": _room,
      "sender": _name,
      "fileid": fileid,
      "size": fileStat.size,
      "transferid": transferid,
      "type": lookupMimeType(file.path),
      "name": file.path.split("/").last,
    };

    FileTransfer newFile = FileTransfer(
      file: file,
      isLeft: false,
      sender: _name!,
      type: lookupMimeType(file.path)!,
      fileName: file.path.split("/").last,
      timestamp: DateTime.now().toUtc(),
    );

    _messages.add(newFile);

    socket.emit("file_create", data);
    notifyListeners();
  }

  Future uploadChunk(dynamic chunk, String transferid, int i) async {
    socket.emit("file_part", {
      "transferid": transferid,
      "chunk": chunk,
      "checksum": "1",
      "counter": i,
      "percentage": 0,
    });
  }
}
