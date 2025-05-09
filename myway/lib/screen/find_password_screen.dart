import 'package:flutter/material.dart';
import 'package:myway/const/colors.dart'; // colors.dart 파일 import

class FindPasswordScreen extends StatefulWidget {
  const FindPasswordScreen({super.key});

  @override
  State<FindPasswordScreen> createState() => _FindPasswordScreenState();
}

class _FindPasswordScreenState extends State<FindPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double horizontalPageMargin = 20.0;
    const double fieldHeight = 52.0;
    const double borderRadiusValue = 8.0;

    return Scaffold(
      backgroundColor: BACKGROUND_COLOR,
      appBar: AppBar(
        backgroundColor: BACKGROUND_COLOR,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: GRAYSCALE_LABEL_950),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          "비밀번호 찾기",
          style: TextStyle(
            color: GRAYSCALE_LABEL_950,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPageMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 30),
              Text(
                "이메일 입력",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: GRAYSCALE_LABEL_900,
                ),
              ),
              SizedBox(height: 5),
              SizedBox(
                height: fieldHeight,
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "비밀번호를 변경 할 메일을 받을 이메일을 입력",
                    hintStyle: TextStyle(
                      color: GRAYSCALE_LABEL_500,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: GRAYSCALE_LABEL_100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadiusValue),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadiusValue),
                      borderSide: BorderSide(
                        color: GRAYSCALE_LABEL_300,
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadiusValue),
                      borderSide: BorderSide(
                        color: BLUE_SECONDARY_500,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                  style: TextStyle(fontSize: 14, color: GRAYSCALE_LABEL_950),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: fieldHeight,
                child: ElevatedButton(
                  onPressed: () {
                    print("입력된 이메일: ${_emailController.text}");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ORANGE_PRIMARY_400,
                    foregroundColor: GRAYSCALE_LABEL_950,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(borderRadiusValue),
                    ),
                    elevation: 0,
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Text("이메일 전송"),
                ),
              ),
              SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
