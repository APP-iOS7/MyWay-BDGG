import 'package:flutter/material.dart';

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
          child: Column(
            children: [
              SizedBox(height: 10),
              Column(
                children: [
                  SizedBox(height: 10),
                  Row(
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(children: [Text('테스트 트래킹'), Text('')]),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
