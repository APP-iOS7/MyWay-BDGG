import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myway/const/colors.dart';

class CountdownDiallog {
  static void show(
    BuildContext context, {
    int start = 3,
    required VoidCallback onComplete,
  }) {
    int count = start;
    late void Function(void Function()) setDialogState;
    bool isDialogVisible = true;
    BuildContext? dialogContextRef; // diallogContext를 저장할 변수
    Timer? countdownTimer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        // diallogContext 저장
        dialogContextRef = dialogContext;

        return StatefulBuilder(
          builder: (context, setState) {
            setDialogState = setState;

            Widget content;
            switch (count) {
              case 3:
                content = Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 120,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '3',
                              style: TextStyle(
                                color: ORANGE_PRIMARY_500,
                                fontSize: 80,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              '마음은 가볍게',
                              style: TextStyle(
                                color: BLUE_SECONDARY_800,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Spacer(),
                    Image.asset(
                      'assets/images/alert_turtle_cut_3.png',
                      height: 100,
                    ),
                  ],
                );
                break;
              case 2:
                content = Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 120,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Row(
                          spacing: 10,
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '2',
                              style: GoogleFonts.instrumentSans(
                                color: ORANGE_PRIMARY_500,
                                fontSize: 80,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            Text(
                              '스텝은 신나게',
                              style: TextStyle(
                                color: BLUE_SECONDARY_800,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Spacer(),
                    Image.asset(
                      'assets/images/alert_turtle_2.png',
                      height: 120,
                    ),
                  ],
                );
                break;
              case 1:
                content = Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 120,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Row(
                          spacing: 10,
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '1',
                              style: GoogleFonts.interTight(
                                color: ORANGE_PRIMARY_500,
                                fontSize: 80,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '산책은 즐겁게',
                              style: TextStyle(
                                color: BLUE_SECONDARY_800,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Spacer(),
                    Image.asset(
                      'assets/images/alert_turtle_4.png',
                      height: 120,
                    ),
                  ],
                );
                break;
              default:
                content = Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '시작!',
                      style: TextStyle(
                        fontSize: 120,
                        fontWeight: FontWeight.bold,
                        color: BLUE_SECONDARY_800,
                      ),
                    ),
                  ],
                );
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              content: SizedBox(height: 250, width: 200, child: content),
            );
          },
        );
      },
    ).then((_) {
      // 다이얼 로그가 닫힐 때 플래그 업데이트 및 타이머 취소
      isDialogVisible = false;
      dialogContextRef = null;
      countdownTimer?.cancel();
    });

    countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      count--;
      if (count < 0) {
        timer.cancel();

        // 먼저 콜백 실행
        onComplete();

        // 다이얼로그가 아직 표시되어 있는지 확인 후 닫기
        if (isDialogVisible && dialogContextRef != null) {
          try {
            // 저장된 diallogContext를 다이얼로그 닫기
            if (Navigator.canPop(dialogContextRef!)) {
              Navigator.pop(dialogContextRef!);
            }
          } catch (e) {
            print('다이얼로그 닫기 오류: $e');
          }
        }
      } else if (isDialogVisible) {
        // 다이얼로그가 표시되어 있을 때만 상태 업데이트
        try {
          setDialogState(() {});
        } catch (e) {
          print('상태 업데이트 오류: $e');
          timer.cancel(); // 오류 발생 시 타이머 중지
        }
      } else {
        // 다이얼로그가 이미 닫혔으면 타이머도 중지
        timer.cancel();
      }
    });
  }
}
