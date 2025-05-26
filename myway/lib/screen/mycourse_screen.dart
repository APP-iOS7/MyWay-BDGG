import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myway/const/colors.dart';

class MycourseScreen extends StatefulWidget {
  const MycourseScreen({super.key});

  @override
  State<MycourseScreen> createState() => _MycourseScreenState();
}

class _MycourseScreenState extends State<MycourseScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isEditing = false;
  List<bool> _selected = [];

  void toggleEditing(int count) {
    setState(() {
      isEditing = !isEditing;
      _selected = List<bool>.filled(count, false);
    });
  }

  Future<void> deleteSelected(List<dynamic> trackingResult) async {
    final docRef = _firestore
        .collection('trackingResult')
        .doc(_auth.currentUser?.uid);
    final newList = <dynamic>[];

    for (int i = 0; i < trackingResult.length; i++) {
      if (!_selected[i]) newList.add(trackingResult[i]);
    }

    await docRef.update({'TrackingResult': newList});
    setState(() {
      isEditing = false;
    });
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
        Widget content; // body에 들어갈 위젯

        if (snapshot.connectionState == ConnectionState.waiting) {
          content = const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          content = const Center(
            child: Text('에러가 발생했습니다.', style: TextStyle(color: Colors.black)),
          );
        } else if (!snapshot.hasData || !snapshot.data!.exists) {
          content = const Center(
            child: Text('저장된 기록이 없습니다.', style: TextStyle(color: Colors.black)),
          );
        } else {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final trackingResult = List<Map<String, dynamic>>.from(
            data['TrackingResult'] ?? [],
          );

          trackingResult.sort(
            (a, b) =>
                DateTime.parse(b['종료시간']).compareTo(DateTime.parse(a['종료시간'])),
          );

          if (_selected.length != trackingResult.length) {
            _selected = List<bool>.filled(trackingResult.length, false);
          }

          if (trackingResult.isEmpty) {
            content = const Center(
              child: Text(
                '저장된 기록이 없습니다.',
                style: TextStyle(color: Colors.black),
              ),
            );
          } else {
            content = Padding(
              padding: const EdgeInsets.all(20),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                ),
                itemCount: trackingResult.length,
                itemBuilder: (context, index) {
                  final result = trackingResult[index];
                  final imageUrl = result['이미지 Url'] ?? '';

                  return Stack(
                    children: [
                      Card(
                        child: Column(
                          children: [
                            imageUrl.isNotEmpty
                                ? ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: Image.network(
                                    imageUrl,
                                    width: double.infinity,
                                    height: 98,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : const SizedBox(
                                  width: double.infinity,
                                  height: 98,
                                  child: Icon(Icons.image_not_supported),
                                ),
                            const SizedBox(height: 5),
                            Padding(
                              padding: const EdgeInsets.only(left: 10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${result['코스이름'] ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Text(
                                        '${result['거리']} km',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: GRAYSCALE_LABEL_500,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '${result['소요시간']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: GRAYSCALE_LABEL_500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isEditing)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Checkbox(
                            value: _selected[index],
                            onChanged: (val) {
                              setState(() {
                                _selected[index] = val!;
                              });
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            );
          }
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            scrolledUnderElevation: 0,
            centerTitle: true,
            title: const Text(
              '나의 코스',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions:
                snapshot.hasData &&
                        snapshot.data!.exists &&
                        (snapshot.data!.data() as Map<String, dynamic>)
                            .containsKey('TrackingResult') &&
                        (snapshot.data!.data()
                                as Map<String, dynamic>)['TrackingResult']
                            .isNotEmpty
                    ? (isEditing
                        ? [
                          TextButton(
                            onPressed:
                                () => deleteSelected(
                                  List<Map<String, dynamic>>.from(
                                    (snapshot.data!.data()
                                            as Map<
                                              String,
                                              dynamic
                                            >)['TrackingResult'] ??
                                        [],
                                  ),
                                ),
                            child: const Text(
                              '삭제',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() => isEditing = false);
                            },
                            child: const Text(
                              '취소',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ]
                        : [
                          TextButton(
                            onPressed:
                                () => toggleEditing(
                                  (snapshot.data!.data()
                                          as Map<
                                            String,
                                            dynamic
                                          >)['TrackingResult']
                                      .length,
                                ),
                            child: const Text(
                              '편집',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ])
                    : [],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1, color: Colors.grey[300]),
            ),
          ),
          body: content,
        );
      },
    );
  }
}
