import 'package:flutter/material.dart';

// Define a custom typography
final TextTheme customTypography = TextTheme(
  bodyLarge: TextStyle(
    fontFamily: 'Default', // You can specify a custom font family here
    fontWeight: FontWeight.normal,
    fontSize: 16.0,
    height: 24.0 / 16.0, // Line height is calculated as lineHeight / fontSize
    letterSpacing: 0.5,
  ),
  /* Other default text styles to override
  headline1: TextStyle(
    fontFamily: 'Default',
    fontWeight: FontWeight.normal,
    fontSize: 22.0,
    height: 28.0 / 22.0,
    letterSpacing: 0.0,
  ),
  caption: TextStyle(
    fontFamily: 'Default',
    fontWeight: FontWeight.w500,
    fontSize: 11.0,
    height: 16.0 / 11.0,
    letterSpacing: 0.5,
  ),
  */
);

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(
        textTheme: customTypography,
      ),
      home: MyHomePage(),
    ),
  );
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Custom Typography Example'),
      ),
      body: Center(
        child: Text(
          'Hello, Llama!',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
