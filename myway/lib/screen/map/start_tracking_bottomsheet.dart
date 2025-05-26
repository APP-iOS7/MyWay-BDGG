import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myway/provider/step_provider.dart';
import 'package:myway/screen/result/course_name_screen.dart';
import 'package:provider/provider.dart';

import '../../const/colors.dart';

class StartTrackingBottomsheet extends StatefulWidget {
  const StartTrackingBottomsheet({super.key});

  @override
  State<StartTrackingBottomsheet> createState() =>
      _StartTrackingBottomsheetState();
}

class _StartTrackingBottomsheetState extends State<StartTrackingBottomsheet> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final stepProvider = Provider.of<StepProvider>(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      snapSizes: [0.3, 0.7],
      snap: false,
      builder: (BuildContext context, scrollSheetController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0),
            child: Column(
              children: [
                SizedBox(height: 2),
                Container(
                  width: 80,
                  height: 4,
                  decoration: BoxDecoration(
                    color: GRAYSCALE_LABEL_300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                ),
                Container(
                  padding: EdgeInsets.all(18),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: YELLOW_INFO_BASE_30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${stepProvider.steps}',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '걸음',
                            style: TextStyle(
                              color: GRAYSCALE_LABEL_600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            stepProvider.formattedElapsed,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '시간',
                            style: TextStyle(
                              color: GRAYSCALE_LABEL_600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            stepProvider.distanceKm,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '거리 Km',
                            style: TextStyle(
                              color: GRAYSCALE_LABEL_600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/walking_background_2.png',
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        bottom: -15,
                        child: Image.asset(
                          'assets/images/walking_turtle.gif',
                          height: 90,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          stepProvider.toggle();
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding: EdgeInsets.all(16),

                          decoration: BoxDecoration(
                            color: YELLOW_INFO_BASE_30,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            stepProvider.status == TrackingStatus.running
                                ? '일시정지'
                                : '재시작',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return CupertinoAlertDialog(
                                content: Text(
                                  '산책을 종료 하시겠습니까?',
                                  style: TextStyle(
                                    color: BLUE_SECONDARY_800,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                actions: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                          '취소',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      CourseNameScreen(),
                                            ),
                                          ).then((_) {
                                            // 화면 이동 후 상태 초기화
                                            stepProvider.resetTracking();
                                          });
                                        },
                                        child: Text(
                                          '종료',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: YELLOW_INFO_BASE_30,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '산책 종료',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
