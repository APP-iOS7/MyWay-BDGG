import 'package:flutter/material.dart';
import 'package:myway/screen/alert/dialog.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../../const/colors.dart';
import '../../provider/user_provider.dart';

class CustomerCenterScreen extends StatelessWidget {
  const CustomerCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: WHITE,
      appBar: AppBar(
        backgroundColor: WHITE,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          '고객센터',
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
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: GRAYSCALE_LABEL_50,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSettingItem(
                text: '1:1 문의하기',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return ConfirmationDialog(
                        title: '1:1 문의하기',
                        content: '이메일로 전송됩니다.\n문의 내용을 작성해주세요.',
                        confirmText: '메일 작성',
                        cancelText: '취소',
                        onConfirm: () {
                          sendInquiryEmail(
                            'MyWay 1:1 문의',
                            '안녕하세요, MyWay입니다.\n\n문의 내용을 작성해주세요 :)',
                          );
                        },
                      );
                    },
                  );
                },
              ),
              _buildSettingItem(
                text: '회원탈퇴',
                onTap: () async {
                  final password = await _showPasswordDialog(context);
                  if (password == null || password.isEmpty) return;

                  try {
                    await userProvider.deleteAccount(password);

                    toastification.show(
                      context: context,
                      type: ToastificationType.success,
                      alignment: Alignment.bottomCenter,
                      autoCloseDuration: Duration(seconds: 2),
                      title: Text('회원 탈퇴 완료'),
                    );

                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('signIn', (route) => false);
                  } catch (e) {
                    toastification.show(
                      context: context,
                      type: ToastificationType.error,
                      alignment: Alignment.bottomCenter,
                      autoCloseDuration: Duration(seconds: 2),
                      title: Text('회원 탈퇴 실패: ${e.toString()}'),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showPasswordDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: WHITE,
            title: Text('비밀번호 확인', style: TextStyle(fontSize: 15)),
            content: TextField(
              autofocus: true,
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                labelText: '비밀번호를 입력하세요',
                labelStyle: TextStyle(color: ORANGE_PRIMARY_500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ORANGE_PRIMARY_500, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ORANGE_PRIMARY_500, width: 1.5),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('취소', style: TextStyle(color: Colors.black)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ORANGE_PRIMARY_500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                    () => Navigator.of(context).pop(controller.text.trim()),
                child: Text('확인', style: TextStyle(color: WHITE)),
              ),
            ],
          ),
    );
  }

  Widget _buildSettingItem({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        padding: const EdgeInsets.only(left: 20, right: 20),
        decoration: BoxDecoration(
          color: GRAYSCALE_LABEL_50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color:
                    text == '회원탈퇴' ? RED_DANGER_TEXT_50 : GRAYSCALE_LABEL_900,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  void sendInquiryEmail(String title, String body) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'khjs7878@naver.com',
      query: Uri.encodeFull('subject=$title&body=$body'),
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw '메일 앱을 열 수 없습니다.';
    }
  }
}
