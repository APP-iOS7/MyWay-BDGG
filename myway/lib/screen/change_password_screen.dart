import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/const/colors.dart';

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

  bool _isCurrentPasswordObscured = true;
  bool _isNewPasswordObscured = true;
  bool _isConfirmNewPasswordObscured = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
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
      fillColor: GRAYSCALE_LABEL_100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: GRAYSCALE_LABEL_700, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Color(0xFF3B64BD), width: 1.0),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
      suffixIcon:
          onToggleObscure != null && isObscured != null
              ? IconButton(
                icon: Icon(
                  isObscured ? Icons.visibility_off : Icons.visibility,
                  color: GRAYSCALE_LABEL_600,
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
          height: 52.0,
          child: TextField(
            controller: controller,
            obscureText: isObscured,
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

    if (currentPassword.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("현재 비밀번호를 입력해주세요.")));
      return;
    }

    if (newPassword.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("새 비밀번호를 입력해주세요.")));
      return;
    }

    if (newPassword.length < 8) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("비밀번호는 8자 이상이어야 합니다.")));
      return;
    }

    if (newPassword != confirmNewPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("비밀번호가 일치하지 않습니다.")));
      return;
    }

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("비밀번호가 변경되었습니다.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("비밀번호 변경 실패: ${e.toString()}")));
    }
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
          "비밀번호 변경",
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
              _buildPasswordTextField(
                controller: _currentPasswordController,
                labelText: "현재 비밀번호",
                hintText: "현재 비밀번호 입력",
                isObscured: _isCurrentPasswordObscured,
                onToggleObscure: () {
                  setState(() {
                    _isCurrentPasswordObscured = !_isCurrentPasswordObscured;
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
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: fieldHeight,
                child: ElevatedButton(
                  onPressed: () {
                    _onPasswordChanged();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFC654), // 버튼 배경색
                    foregroundColor: GRAYSCALE_LABEL_950, // 버튼 텍스트 색상 (가독성 고려)
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
              SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
