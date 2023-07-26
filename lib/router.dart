import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './pages/join_room_page.dart';
import './providers/file_provider.dart';
import './utils/themes.dart';

class StreamItRouter extends StatelessWidget {
  const StreamItRouter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FileProvider>(
          create: (_) => FileProvider(),
        ),
      ],
      child: MaterialApp(
        theme: lightTheme,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        home: const JoinRoomPage(),
      ),
    );
  }
}
