import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../const/colors.dart';
import '../../model/step_model.dart';
import '../../provider/park_data_provider.dart';
import '../screen/home/course_detail_screen.dart';

class ParkRecommendScreen extends StatefulWidget {
  const ParkRecommendScreen({super.key});

  @override
  State<ParkRecommendScreen> createState() => _ParkRecommendScreenState();
}

class _ParkRecommendScreenState extends State<ParkRecommendScreen> {
  final ScrollController _scrollController = ScrollController();
  final int _perPage = 20;
  int _currentPage = 1;
  bool _isLoadingMore = false;
  List<StepModel> _records = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ParkDataProvider>(context, listen: false);
      _loadInitialRecords(provider);
    });
    _scrollController.addListener(_onScroll);
  }

  void _loadInitialRecords(ParkDataProvider provider) {
    setState(() {
      _records = provider.allUserCourseRecords.take(_perPage).toList();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoadingMore) {
      final provider = Provider.of<ParkDataProvider>(context, listen: false);
      if (_records.length < provider.allUserCourseRecords.length) {
        _loadMoreRecords(provider);
      }
    }
  }

  void _loadMoreRecords(ParkDataProvider provider) {
    setState(() => _isLoadingMore = true);
    _currentPage++;
    Future.delayed(const Duration(milliseconds: 300), () {
      final newRecords =
          provider.allUserCourseRecords.take(_perPage * _currentPage).toList();
      setState(() {
        _records = newRecords;
        _isLoadingMore = false;
      });
    });
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
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourseDetailScreen(data: record.toJson()),
            ),
          ),
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
                        )
                        : Image.asset(
                          'assets/images/default_course_image.png',
                          fit: BoxFit.cover,
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
  Widget build(BuildContext context) {
    return Consumer<ParkDataProvider>(
      builder: (context, provider, child) {
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
          body:
              provider.isLoadingUserRecords
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      color: Colors.white,
                      child: GridView.builder(
                        controller: _scrollController,
                        itemCount: _records.length + (_isLoadingMore ? 1 : 0),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.68,
                            ),
                        itemBuilder: (_, index) {
                          if (index == _records.length) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return _buildRecordCard(_records[index]);
                        },
                      ),
                    ),
                  ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
