import 'package:firebase_auth/firebase_auth.dart';
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
                  await _handleAccountDeletion(context, userProvider);
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            title: Text('비밀번호 확인', style: TextStyle(fontSize: 15)),
            content: TextField(
              cursorColor: ORANGE_PRIMARY_500,
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
          borderRadius: BorderRadius.circular(12),
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
      query: Uri.encodeFull('subject=$title\u0026body=$body'),
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw '메일 앱을 열 수 없습니다.';
    }
  }

  // 회원탈퇴 처리 메서드
  Future<void> _handleAccountDeletion(
    BuildContext context,
    UserProvider userProvider,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorToast(context, '로그인이 필요합니다.');
        return;
      }

      // 로그인 방식 확인
      bool isGoogleProvider = user.providerData.any(
        (provider) => provider.providerId == 'google.com',
      );

      // 경고 메시지 표시
      bool? confirmed = await _showConfirmationDialog(
        context,
        isGoogleProvider,
      );
      if (confirmed != true) return;

      String? password;

      // 이메일 계정인 경우 비밀번호 확인
      if (!isGoogleProvider) {
        password = await _showPasswordDialog(context);
        if (password == null || password.isEmpty) return;
      }

      // 로딩 표시
      _showLoadingDialog(context);

      // 회원탈퇴 실행
      await userProvider.deleteAccount(password: password);

      // 로딩 다이얼로그 닫기
      Navigator.of(context).pop();

      _showSuccessToast(context, '회원탈퇴가 완료되었습니다.');

      // 로그인 화면으로 이동
      Navigator.of(context).pushNamedAndRemoveUntil('signIn', (route) => false);
    } catch (e) {
      // 로딩 다이얼로그가 열려 있다면 닫기
      Navigator.of(context, rootNavigator: true).pop();

      String errorMessage = '회원탈퇴에 실패했습니다.';

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'wrong-password':
            errorMessage = '비밀번호가 올바르지 않습니다.';
            break;
          case 'requires-recent-login':
            errorMessage = '최근 로그인이 필요합니다. 로그아웃 후 다시 로그인해주세요.';
            break;
          case 'google-signin-cancelled':
            errorMessage = '구글 로그인이 취소되었습니다.';
            break;
          case 'network-request-failed':
            errorMessage = '네트워크 오류가 발생했습니다.';
            break;
          default:
            errorMessage = e.message ?? '회원탈퇴에 실패했습니다.';
        }
      }

      _showErrorToast(context, errorMessage);
    }
  }

  // 확인 다이얼로그
  Future<bool?> _showConfirmationDialog(
    BuildContext context,
    bool isGoogleProvider,
  ) async {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: WHITE,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            title: Text(
              '회원탈퇴',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('정말로 회원탈퇴를 진행하시겠습니까?', style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: RED_DANGER_TEXT_50.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: RED_DANGER_TEXT_50.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ 주의사항',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: RED_DANGER_TEXT_50,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        '• 모든 개인 데이터가 영구적으로 삭제됩니다.',
                        style: TextStyle(fontSize: 13),
                      ),
                      Text(
                        '• 산책 기록 및 이미지가 모두 삭제됩니다.',
                        style: TextStyle(fontSize: 13),
                      ),
                      Text(
                        '• 이 작업은 취소할 수 없습니다.',
                        style: TextStyle(fontSize: 13),
                      ),
                      if (isGoogleProvider)
                        Text(
                          '• 구글 로그인 재인증이 필요합니다.',
                          style: TextStyle(fontSize: 13),
                        )
                      else
                        Text(
                          '• 비밀번호 확인이 필요합니다.',
                          style: TextStyle(fontSize: 13),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('취소', style: TextStyle(color: GRAYSCALE_LABEL_700)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: RED_DANGER_TEXT_50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('회원탈퇴', style: TextStyle(color: WHITE)),
              ),
            ],
          ),
    );
  }

  // 로딩 다이얼로그
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: WHITE,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: ORANGE_PRIMARY_500),
                SizedBox(height: 20),
                Text('회원탈퇴를 진행 중입니다...', style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                Text(
                  '잠시만 기다려주세요.',
                  style: TextStyle(fontSize: 14, color: GRAYSCALE_LABEL_600),
                ),
              ],
            ),
          ),
    );
  }

  // 성공 토스트
  void _showSuccessToast(BuildContext context, String message) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      alignment: Alignment.bottomCenter,
      autoCloseDuration: Duration(seconds: 3),
      title: Text(message),
    );
  }

  // 에러 토스트
  void _showErrorToast(BuildContext context, String message) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.flat,
      alignment: Alignment.bottomCenter,
      autoCloseDuration: Duration(seconds: 4),
      title: Text(message),
    );
  }
}
