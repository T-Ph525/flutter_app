import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Define color schemes
final ThemeData darkTheme = ThemeData.dark().copyWith(
  colorScheme: ColorScheme.dark(
    primary: Color(0xFFD0BCFF), // Purple80
    secondary: Color(0xFFCCC2DC), // PurpleGrey80
    tertiary: Color(0xFFEFB8C8), // Pink80
  ),
);

final ThemeData lightTheme = ThemeData.light().copyWith(
  colorScheme: ColorScheme.light(
    primary: Color(0xFF6650a4), // Purple40
    secondary: Color(0xFF625b71), // PurpleGrey40
    tertiary: Color(0xFF7D5260), // Pink40
  ),
);

class LlamaApp extends StatelessWidget {
  final bool darkTheme;
  final bool dynamicColor;
  final Widget content;

  LlamaApp({
    required this.darkTheme,
    required this.dynamicColor,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData theme;

    if (dynamicColor && Theme.of(context).platform == TargetPlatform.android) {
      // Dynamic color is available on Android 12+
      theme = darkTheme ? darkTheme : lightTheme;
    } else {
      theme = darkTheme ? darkTheme : lightTheme;
    }

    return MaterialApp(
      theme: theme,
      darkTheme: darkTheme ? darkTheme : lightTheme,
      themeMode: darkTheme ? ThemeMode.dark : ThemeMode.light,
      home: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: theme.colorScheme.primary,
          statusBarIconBrightness: darkTheme ? Brightness.light : Brightness.dark,
        ),
        child: content,
      ),
    );
  }
}

void main() {
  runApp(
    LlamaApp(
      darkTheme: WidgetsBinding.instance.window.platformBrightness == Brightness.dark,
      dynamicColor: true,
      content: MyHomePage(),
    ),
  );
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Llama App'),
      ),
      body: Center(
        child: Text('Hello, Llama!'),
      ),
    );
  }
}
