import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myway/const/colors.dart';
import 'package:toastification/toastification.dart';

import '../../const/custome_button.dart';
import 'course_detail_screen.dart';

class MycourseScreen extends StatefulWidget {
  const MycourseScreen({super.key});

  @override
  State<MycourseScreen> createState() => _MycourseScreenState();
}

class _MycourseScreenState extends State<MycourseScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isEditing = false;
  final ValueNotifier<List<bool>> _selectedNotifier = ValueNotifier([]);

  void toggleEditing(int count) {
    setState(() {
      isEditing = !isEditing;
      _selectedNotifier.value = List<bool>.filled(count, false);
    });
  }

  Future<void> deleteSelected(List<dynamic> trackingResult) async {
    final docRef = _firestore
        .collection('trackingResult')
        .doc(_auth.currentUser?.uid);

    final current = _selectedNotifier.value;
    final newList = <dynamic>[];
    int deletedCount = 0;
    for (int i = 0; i < trackingResult.length; i++) {
      if (!current[i]) {
        newList.add(trackingResult[i]);
      } else {
        deletedCount++;
      }
    }

    await docRef.update({'TrackingResult': newList});
    setState(() {
      isEditing = false;
    });

    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      alignment: Alignment.bottomCenter,
      autoCloseDuration: Duration(seconds: 2),
      title: Text('$deletedCount개의 코스 삭제완료.'),
    );
  }

  @override
  void dispose() {
    _selectedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          _firestore
              .collection('trackingResult')
              .doc(_auth.currentUser?.uid)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildScaffoldWithBody(
            const Center(child: Text('에러가 발생했습니다.')),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildScaffoldWithBody(
            const Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final trackingResult = List<Map<String, dynamic>>.from(
          data['TrackingResult'] ?? [],
        );

        if (!snapshot.hasData ||
            !snapshot.data!.exists ||
            trackingResult.isEmpty) {
          return _buildScaffoldWithBody(
            Padding(
              padding: const EdgeInsets.only(top: 200.0),
              child: Column(
                children: [
                  const Icon(Icons.directions_walk),
                  const SizedBox(height: 10),
                  const SizedBox(
                    width: double.infinity,
                    child: Text(
                      '저장된 기록이 없습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: GRAYSCALE_LABEL_800,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const Text(
                    '산책을 시작해서 나만의 코스를 만들어보세요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: GRAYSCALE_LABEL_600,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (_selectedNotifier.value.length != trackingResult.length) {
          _selectedNotifier.value = List<bool>.filled(
            trackingResult.length,
            false,
          );
        }

        trackingResult.sort(
          (a, b) =>
              DateTime.parse(b['종료시간']).compareTo(DateTime.parse(a['종료시간'])),
        );

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            title: const Text(
              '나의 코스',
              style: TextStyle(
                color: GRAYSCALE_LABEL_950,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions:
                isEditing
                    ? [
                      ValueListenableBuilder<List<bool>>(
                        valueListenable: _selectedNotifier,
                        builder: (context, selected, _) {
                          final selectedCount =
                              selected.where((isSelected) => isSelected).length;
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 10.0,
                                  right: 10.0,
                                ),
                                child: Row(
                                  children: [
                                    TextButton(
                                      onPressed:
                                          () => deleteSelected(trackingResult),
                                      style: customTextButtonStyle(),
                                      child: const Text(
                                        '삭제',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () =>
                                              setState(() => isEditing = false),
                                      style: customTextButtonStyle(),
                                      child: const Text(
                                        '취소',
                                        style: TextStyle(
                                          color: GRAYSCALE_LABEL_900,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '$selectedCount개 선택',
                                      style: const TextStyle(
                                        color: GRAYSCALE_LABEL_900,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ]
                    : [
                      TextButton(
                        onPressed: () => toggleEditing(trackingResult.length),
                        style: customTextButtonStyle(),
                        child: const Text(
                          '편집',
                          style: TextStyle(
                            color: GRAYSCALE_LABEL_900,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                childAspectRatio: 0.9,
                crossAxisCount: 2,
                crossAxisSpacing: 5.0,
                mainAxisSpacing: 5,
              ),
              itemCount: trackingResult.length,
              itemBuilder: (context, index) {
                final result = trackingResult[index];
                final imageUrl = result['이미지 Url'] ?? '';

                return InkWell(
                  focusColor: WHITE,
                  hoverColor: WHITE,
                  highlightColor: WHITE,
                  onTap:
                      isEditing
                          ? null
                          : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        CourseDetailScreen(data: result),
                              ),
                            );
                          },
                  child: Stack(
                    children: [
                      Card(
                        color: WHITE,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            imageUrl.isNotEmpty
                                ? ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: Image.network(
                                    imageUrl,
                                    width: double.infinity,
                                    height: 130,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : const SizedBox(
                                  width: double.infinity,
                                  height: 150,
                                  child: Icon(Icons.image_not_supported),
                                ),
                            const SizedBox(height: 5),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    result['코스이름'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: BLUE_SECONDARY_700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        result['종료시간'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: GRAYSCALE_LABEL_800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isEditing)
                        Positioned(
                          top: 1,
                          right: 1,
                          child: ValueListenableBuilder<List<bool>>(
                            valueListenable: _selectedNotifier,
                            builder: (context, selected, _) {
                              return Checkbox(
                                activeColor: ORANGE_PRIMARY_500,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                checkColor: Colors.white,
                                overlayColor: WidgetStateProperty.all(
                                  Colors.transparent,
                                ),
                                value: selected[index],
                                onChanged: (val) {
                                  final copy = List<bool>.from(selected);
                                  copy[index] = val!;
                                  _selectedNotifier.value = copy;
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Scaffold _buildScaffoldWithBody(Widget bodyContent) {
    return Scaffold(
      backgroundColor: WHITE,
      appBar: AppBar(
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          '나의 코스',
          style: TextStyle(
            color: GRAYSCALE_LABEL_950,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: bodyContent,
    );
  }
}
