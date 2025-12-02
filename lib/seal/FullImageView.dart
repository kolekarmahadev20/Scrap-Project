import 'package:flutter/material.dart';

class FullImageView extends StatelessWidget {
  final String url;

  FullImageView({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: Center(
        child: Hero(
          tag: url,
          child: Image.network(url),
        ),
      ),
    );
  }
}
