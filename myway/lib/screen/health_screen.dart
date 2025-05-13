import 'package:flutter/material.dart';
import 'package:myway/provider/step_provider.dart';
import 'package:provider/provider.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stepProvider = context.watch<StepProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('걸음걸음')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('걸음 수:${stepProvider.steps}', style: TextStyle(fontSize: 32)),
            SizedBox(height: 20),
            Text('상태: ${stepProvider.status}', style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}
