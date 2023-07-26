import 'dart:io';

class FileTransfer {
  File file;

  String fileName;
  String type;
  String sender;

  bool isLeft;
  DateTime timestamp;

  FileTransfer({
    required this.file,
    required this.fileName,
    required this.type,
    required this.sender,
    required this.isLeft,
    required this.timestamp,
  });
}
