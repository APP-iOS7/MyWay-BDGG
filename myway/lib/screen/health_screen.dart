import 'package:flutter/material.dart';
import 'package:myway/provider/step_provider.dart';
import 'package:provider/provider.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stepProvider = context.watch<StepProvider>().steps;

    return Scaffold(
      appBar: AppBar(title: Text('걸음걸음')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '걸음수:',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            Text('$stepProvider 걸음', style: TextStyle(fontSize: 60)),
          ],
        ),
      ),
    );
  }
}
