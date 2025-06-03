import 'package:flutter/material.dart';
import 'package:myway/provider/step_provider.dart';
import 'package:myway/screen/alert/dialog.dart';
import 'package:provider/provider.dart';

import '../../const/colors.dart';
import '../../provider/map_provider.dart';

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
    final mapProvider = Provider.of<MapProvider>(context);
    print('StartTrackingBottomsheet build called');
    print('stepProvider status: ${stepProvider.status}');
    print('route: ${stepProvider.route}');
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
                              color: GRAYSCALE_LABEL_950,
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
                              color: GRAYSCALE_LABEL_950,
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
                              color: GRAYSCALE_LABEL_950,
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
                          'assets/images/walking_background.png',
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
                              return ConfirmationDialog(
                                title: '산책 종료',
                                content:
                                    '산책을 종료합니다.\n산책코스가 모두 보이도록 지도를 축소해주세요.',
                                cancelText: '취소',
                                confirmText: '종료',
                                onConfirm: () {
                                  mapProvider.setTracking(false);
                                  stepProvider.stopTracking();
                                },
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
