import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myway/screen/login/signIn_screen.dart';
import 'package:toastification/toastification.dart';

import '../../const/colors.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();

  String validationLabelString = '';

  bool _isCurrentPasswordObscured = true;
  bool _isNewPasswordObscured = true;
  bool _isConfirmNewPasswordObscured = true;
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _currentPasswordController.addListener(_checkFields);
    _newPasswordController.addListener(_checkFields);
    _confirmNewPasswordController.addListener(_checkFields);
  }

  @override
  void dispose() {
    _currentPasswordController.removeListener(_checkFields);
    _newPasswordController.removeListener(_checkFields);
    _confirmNewPasswordController.removeListener(_checkFields);
    super.dispose();
  }

  void _checkFields() {
    setState(() {
      _isButtonEnabled =
          _currentPasswordController.text.isNotEmpty &&
          _newPasswordController.text.isNotEmpty &&
          _confirmNewPasswordController.text.isNotEmpty;
    });
  }

  InputDecoration _passwordInputDecoration(
    String hintText, {
    VoidCallback? onToggleObscure,
    bool? isObscured,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: GRAYSCALE_LABEL_500, fontSize: 14),
      filled: true,
      fillColor: WHITE,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: GRAYSCALE_LABEL_400, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: ORANGE_PRIMARY_500, width: 1.0),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
      suffixIcon:
          onToggleObscure != null && isObscured != null
              ? IconButton(
                icon: Icon(
                  isObscured ? Icons.visibility_off : Icons.visibility,
                  color: GRAYSCALE_LABEL_500,
                ),
                onPressed: onToggleObscure,
              )
              : null,
    );
  }

  Widget _buildPasswordTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required bool isObscured,
    required VoidCallback onToggleObscure,
    double topMarginLabel = 20.0,
    double bottomMarginLabelToField = 10.0,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: topMarginLabel),
        Text(
          labelText,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: GRAYSCALE_LABEL_900,
          ),
        ),
        SizedBox(height: bottomMarginLabelToField),
        SizedBox(
          height: 48.0,
          child: TextField(
            controller: controller,
            obscureText: isObscured,
            cursorColor: ORANGE_PRIMARY_500,
            decoration: _passwordInputDecoration(
              hintText,
              onToggleObscure: onToggleObscure,
              isObscured: isObscured,
            ),
            style: TextStyle(fontSize: 14, color: GRAYSCALE_LABEL_950),
          ),
        ),
      ],
    );
  }

  Future<void> _onPasswordChanged() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmNewPassword = _confirmNewPasswordController.text.trim();

    if (newPassword.length < 8) {
      setState(() {
        validationLabelString = "비밀번호는 8자 이상이어야 합니다.";
      });
    } else if (newPassword != confirmNewPassword) {
      setState(() {
        validationLabelString = "비밀번호가 일치하지 않습니다.";
      });
    }
    // 특수문자 미포함일시
    else if (!newPassword.contains(
      RegExp(r'^(?=.*[a-zA-Z])(?=.*[0-9])(?=.*[!@#$%^&*(),.?":{}|<>]).{8,}$'),
    )) {
      setState(() {
        validationLabelString = "비밀번호는 영문, 숫자, 특수문자를 포함해야 합니다.";
      });
    } else {
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // 현재 비밀번호로 재인증
          AuthCredential credential = EmailAuthProvider.credential(
            email: user.email!,
            password: currentPassword,
          );

          await user.reauthenticateWithCredential(credential);

          // 비밀번호 변경
          await user.updatePassword(newPassword);
          // 로그아웃
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SigninScreen()),
          );
          toastification.show(
            context: context,
            type: ToastificationType.info,
            style: ToastificationStyle.flat,
            alignment: Alignment.bottomCenter,
            autoCloseDuration: Duration(seconds: 2),
            title: Text('비밀번호가 변경되었습니다. 다시 로그인해주세요.'),
          );
        }
      } catch (e) {
        if (e is FirebaseAuthException) {
          if (e.code == 'wrong-password') {
            setState(() {
              validationLabelString = "현재 비밀번호가 일치하지 않습니다.";
            });
          } else if (e.code == 'weak-password') {
            setState(() {
              validationLabelString = "비밀번호가 너무 약합니다.";
            });
          } else {
            setState(() {
              validationLabelString = "비밀번호 변경 실패: ${e.message}";
            });
          }
        } else {
          setState(() {
            validationLabelString = "비밀번호 변경 실패: ${e.toString()}";
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double fieldHeight = 52.0;
    const double borderRadiusValue = 8.0;

    return Scaffold(
      backgroundColor: WHITE,
      appBar: AppBar(
        backgroundColor: WHITE,
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
          "비밀번호 변경",
          style: TextStyle(
            color: GRAYSCALE_LABEL_950,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildPasswordTextField(
                      controller: _currentPasswordController,
                      labelText: "현재 비밀번호",
                      hintText: "현재 비밀번호 입력",
                      isObscured: _isCurrentPasswordObscured,
                      onToggleObscure: () {
                        setState(() {
                          _isCurrentPasswordObscured =
                              !_isCurrentPasswordObscured;
                        });
                      },
                      topMarginLabel: 40.0,
                      bottomMarginLabelToField: 5.0,
                    ),
                    _buildPasswordTextField(
                      controller: _newPasswordController,
                      labelText: "새 비밀번호",
                      hintText: "영문, 숫자, 특수문자 포함 8자 이상",
                      isObscured: _isNewPasswordObscured,
                      onToggleObscure: () {
                        setState(() {
                          _isNewPasswordObscured = !_isNewPasswordObscured;
                        });
                      },
                      topMarginLabel: 20.0,
                      bottomMarginLabelToField: 5.0,
                    ),
                    _buildPasswordTextField(
                      controller: _confirmNewPasswordController,
                      labelText: "새 비밀번호 확인",
                      hintText: "영문, 숫자, 특수문자 포함 8자 이상",
                      isObscured: _isConfirmNewPasswordObscured,
                      onToggleObscure: () {
                        setState(() {
                          _isConfirmNewPasswordObscured =
                              !_isConfirmNewPasswordObscured;
                        });
                      },
                      topMarginLabel: 20.0,
                      bottomMarginLabelToField: 5.0,
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        validationLabelString,
                        style: TextStyle(
                          fontSize: 15,
                          color: RED_DANGER_TEXT_50,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: fieldHeight,
              child: ElevatedButton(
                onPressed: () {
                  if (_isButtonEnabled) {
                    print('enable');
                    _onPasswordChanged();
                  } else {
                    print('no');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isButtonEnabled
                          ? ORANGE_PRIMARY_500
                          : GRAYSCALE_LABEL_300,
                  foregroundColor: WHITE,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(borderRadiusValue),
                  ),
                  elevation: 0,
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text("변경하기"),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
