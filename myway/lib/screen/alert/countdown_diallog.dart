import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myway/const/colors.dart';

class CountdownDialog {
  static void show(
    BuildContext context, {
    int start = 3,
    required VoidCallback onComplete,
  }) {
    int count = start;
    late void Function(void Function()) setDialogState;
    bool isDialogVisible = true;
    BuildContext? dialogContextRef;
    Timer? countdownTimer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        dialogContextRef = dialogContext;

        return StatefulBuilder(
          builder: (context, setState) {
            setDialogState = setState;

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                height: 220,
                width: 200,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder:
                      (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                  child: _buildCountdownContent(count, key: ValueKey(count)),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      isDialogVisible = false;
      dialogContextRef = null;
      countdownTimer?.cancel();
    });

    countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      count--;
      if (count < 0) {
        timer.cancel();
        onComplete();

        if (isDialogVisible && dialogContextRef != null) {
          try {
            if (Navigator.canPop(dialogContextRef!)) {
              Navigator.pop(dialogContextRef!);
            }
          } catch (e) {
            print('다이얼로그 닫기 오류: \$e');
          }
        }
      } else if (isDialogVisible) {
        try {
          setDialogState(() {});
        } catch (e) {
          print('상태 업데이트 오류: \$e');
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  static Widget _buildCountdownContent(int count, {Key? key}) {
    String numberText = '';
    String subtitle = '';
    String imagePath = '';

    switch (count) {
      case 3:
        numberText = '3';
        subtitle = '마음은 가볍게';
        imagePath = 'assets/images/test_turtle_3.png';
        break;
      case 2:
        numberText = '2';
        subtitle = '스텝은 신나게';
        imagePath = 'assets/images/test_turtle_2.png';
        break;
      case 1:
        numberText = '1';
        subtitle = '산책은 즐겁게';
        imagePath = 'assets/images/test_turtle_1.png';
        break;
      default:
        return Center(
          key: key,
          child: Text(
            '시작!',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: BLUE_SECONDARY_800,
            ),
          ),
        );
    }

    return Stack(
      key: key,
      children: [
        Positioned(
          top: 16,
          left: 20,
          child: Text(
            numberText,
            style: GoogleFonts.interTight(
              color: ORANGE_PRIMARY_500,
              fontSize: 80,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Center(child: Image.asset(imagePath, height: 80)),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              subtitle,
              style: TextStyle(
                color: BLUE_SECONDARY_800,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
