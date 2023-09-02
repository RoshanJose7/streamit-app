import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../providers/file_provider.dart';
import '../utils/colours.dart';

class RoomPage extends StatefulWidget {
  final String roomName;
  final String userName;

  const RoomPage({
    Key? key,
    required this.roomName,
    required this.userName,
  }) : super(key: key);

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  Uuid uuid = const Uuid();

  File? _selectedFile;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final fileProvider = context.watch<FileProvider>();

    return Scaffold(
      backgroundColor: kWhite,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 10,
                  bottom: 10,
                ),
                decoration: const BoxDecoration(
                  color: kBlue,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.roomName,
                        style: textTheme.titleLarge,
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.exit_to_app_rounded,
                          color: kWhite,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: 20,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      kBlue,
                      kWhite,
                    ],
                  ),
                ),
              ),
            ],
          ),
          fileProvider.messages.isEmpty
              ? const Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 50),
                      child: Center(
                        child: Text("No Files Yet!"),
                      ),
                    ),
                  ],
                )
              : Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ListView.separated(
                      itemCount: fileProvider.messages.length,
                      separatorBuilder: (ctx, idx) =>
                          const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final fileData = fileProvider.messages[idx];

                        if (fileData.runtimeType == String) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Center(
                              child: Text(fileData),
                            ),
                          );
                        } else {
                          return InkWell(
                            onTap: () {
                              Directory generalDownloadDir =
                                  Directory('/storage/emulated/0/Download');
                              fileProvider.messages[idx].file.copySync(
                                  "${generalDownloadDir.path}/${fileProvider.messages[idx].fileName}");

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "${fileProvider.messages[idx].fileName} saved to ${generalDownloadDir.path}",
                                  ),
                                ),
                              );
                            },
                            child: Align(
                              alignment: fileData.isLeft
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                  horizontal: 10,
                                ),
                                constraints: const BoxConstraints(
                                  maxWidth: 200,
                                  minWidth: 100,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: kLightGray,
                                    width: 2,
                                  ),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.file_present),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fileData.sender,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            fileData.fileName,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: Text(
                                              DateFormat.ms().format(
                                                fileData.timestamp.toUtc(),
                                              ),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
          Column(
            children: [
              Container(
                height: 20,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      kBlue,
                      kWhite,
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 25,
                ),
                decoration: const BoxDecoration(
                  color: kBlue,
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedFile != null
                              ? _selectedFile!.path.split("/").last
                              : "No File Selected!",
                          style: textTheme.headlineSmall!.copyWith(
                            color: kWhite,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _pickFile,
                            icon: const Icon(
                              Icons.attach_file_rounded,
                              color: kWhite,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            onPressed: () {
                              if (_selectedFile != null) {
                                String fileid = uuid.v4();

                                fileProvider.createFile(
                                  _selectedFile!,
                                  fileid,
                                );

                                setState(() => _selectedFile = null);
                              }
                            },
                            icon: const Icon(
                              Icons.send_rounded,
                              color: kWhite,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);

      setState(() {
        _selectedFile = file;
      });
    } else {
      setState(() {
        _selectedFile = null;
      });
    }
  }
}
