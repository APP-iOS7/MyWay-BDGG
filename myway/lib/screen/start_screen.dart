import 'package:flutter/material.dart';
import 'package:myway/provider/step_provider.dart';
import 'package:myway/screen/health_screen.dart';
import 'package:provider/provider.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stepProvider = context.read<StepProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('start')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            stepProvider.startTracking();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HealthScreen()),
            );
          },
          child: Text('시작하기'),
        ),
      ),
    );
  }
}
