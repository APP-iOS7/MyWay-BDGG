import 'package:flutter/material.dart';

class FindpasswordScreen extends StatefulWidget {
  const FindpasswordScreen({super.key});

  @override
  State<FindpasswordScreen> createState() => _FindpasswordScreenState();
}

class _FindpasswordScreenState extends State<FindpasswordScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '비밀번호 찾기',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('이메일 입력', style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                labelText: '비밀번호를 변경 할 메일을 받을 이메일을 입력',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 80),
        child: GestureDetector(
          onTap: () {},
          child: Container(
            width: double.infinity,
            height: 55,
            decoration: BoxDecoration(
              color: Color(0xFFFFB03A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '이메일 전송',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
