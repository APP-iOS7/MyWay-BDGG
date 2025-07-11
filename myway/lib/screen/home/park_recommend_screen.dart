import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../const/colors.dart';
import '../../../model/step_model.dart';
import '../../../provider/park_data_provider.dart';
import 'course_detail_screen.dart';

class ParkRecommendScreen extends StatefulWidget {
  const ParkRecommendScreen({super.key});

  @override
  State<ParkRecommendScreen> createState() => _ParkRecommendScreenState();
}

class _ParkRecommendScreenState extends State<ParkRecommendScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final int _perPage = 20;
  bool _isLoadingMore = false;
  Future<void>? _initializationFuture;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // FutureBuilder에서 사용할 Future 생성
    _initializationFuture = _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final provider = Provider.of<ParkDataProvider>(context, listen: false);
      if (provider.allUserCourseRecords.isEmpty &&
          !provider.isLoadingUserRecords) {
        await provider.initialize();
      }
    } catch (e) {
      debugPrint('Provider error: $e');
    }
  }

  void _onScroll() {
    // iOS에서 더 부드러운 스크롤을 위해 임계값 조정
    final threshold =
        Theme.of(context).platform == TargetPlatform.iOS ? 150 : 100;
    if (!_isLoadingMore &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - threshold) {
      try {
        final provider = Provider.of<ParkDataProvider>(context, listen: false);
        final currentDisplayCount = _perPage;
        if (currentDisplayCount < provider.allUserCourseRecords.length) {
          _loadMoreRecords();
        }
      } catch (e) {
        debugPrint('Error in scroll: $e');
      }
    }
  }

  void _loadMoreRecords() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final parkDataProvider = Provider.of<ParkDataProvider>(
        context,
        listen: false,
      );
      await parkDataProvider.loadMoreUserCourseRecords();
    } catch (e) {
      debugPrint('Failed to load more: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  String formatStopTime(String stopTimeStr) {
    try {
      DateTime dt = DateTime.parse(stopTimeStr);
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return stopTimeStr;
    }
  }

  Widget _buildRecordCard(StepModel record) {
    return GestureDetector(
      onTap: () {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourseDetailScreen(data: record.toJson()),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: BACKGROUND_COLOR,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child:
                    record.imageUrl.isNotEmpty
                        ? Image.network(
                          record.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: GRAYSCALE_LABEL_100,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                  strokeWidth: 2,
                                  color: ORANGE_PRIMARY_500,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: GRAYSCALE_LABEL_200,
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: GRAYSCALE_LABEL_600,
                              ),
                            );
                          },
                        )
                        : Container(
                          color: GRAYSCALE_LABEL_200,
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: GRAYSCALE_LABEL_600,
                          ),
                        ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.courseName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: GRAYSCALE_LABEL_950,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),

                  Text(
                    record.parkName != null
                        ? record.parkName!.isEmpty
                            ? '선택 안함'
                            : record.parkName!
                        : '공원 미지정',
                    style: const TextStyle(
                      fontSize: 12,
                      color: GRAYSCALE_LABEL_800,
                    ),
                  ),

                  Text(
                    formatStopTime(record.stopTime),
                    style: const TextStyle(
                      fontSize: 12,
                      color: GRAYSCALE_LABEL_800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin을 위해 필요

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '추천 코스',
          style: TextStyle(
            color: GRAYSCALE_LABEL_950,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: FutureBuilder<void>(
        future:
            _initializationFuture ?? _initializeData(), // Future가 없으면 초기화 수행
        builder: (context, snapshot) {
          // 연결 상태 파악 및 초기 데이터 로딩 확인
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: ORANGE_PRIMARY_500),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    '데이터 로딩 중 오류가 발생했습니다.',
                    style: TextStyle(fontSize: 16, color: GRAYSCALE_LABEL_600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _initializationFuture = _initializeData();
                      });
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          return Consumer<ParkDataProvider>(
            builder: (context, parkDataProvider, child) {
              final displayRecords = parkDataProvider.allUserCourseRecords;

              if (displayRecords.isEmpty) {
                return const Center(
                  child: Text(
                    '추천 코스가 없습니다.',
                    style: TextStyle(fontSize: 16, color: GRAYSCALE_LABEL_600),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  controller: _scrollController,
                  itemCount: displayRecords.length + (_isLoadingMore ? 1 : 0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 600 ? 3 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                  itemBuilder: (_, index) {
                    if (index >= displayRecords.length) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: ORANGE_PRIMARY_500,
                        ),
                      );
                    }
                    return _buildRecordCard(displayRecords[index]);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
}
