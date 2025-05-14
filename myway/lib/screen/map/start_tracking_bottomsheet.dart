import 'package:flutter/material.dart';
import 'package:myway/provider/step_provider.dart';
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '산책중',
                      style: TextStyle(
                        color: GRAYSCALE_LABEL_900,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.close_outlined),
                    ),
                  ],
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
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '걸음',
                            style: TextStyle(
                              color: GRAYSCALE_LABEL_600,
                              fontSize: 18,
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
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '시간',
                            style: TextStyle(
                              color: GRAYSCALE_LABEL_600,
                              fontSize: 18,
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
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '거리 Km',
                            style: TextStyle(
                              color: GRAYSCALE_LABEL_600,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Image.asset('assets/images/park.png'),
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
                          stepProvider.stopTracking();
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
