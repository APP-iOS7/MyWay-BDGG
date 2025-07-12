import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../const/colors.dart';
import '../../../model/step_model.dart';
import '../../../provider/park_data_provider.dart';
import 'course_detail_screen.dart';

// 상수들을 클래스로 분리
class ParkRecommendConstants {
  static const int perPage = 20;
  static const int scrollThreshold = 150;
  static const double childAspectRatio = 0.68;
  static const double crossAxisSpacing = 12.0;
  static const double mainAxisSpacing = 12.0;
  static const int desktopBreakpoint = 600;
  static const int desktopCrossAxisCount = 3;
  static const int mobileCrossAxisCount = 2;
}

class ParkRecommendScreen extends StatefulWidget {
  const ParkRecommendScreen({super.key});

  @override
  State<ParkRecommendScreen> createState() => _ParkRecommendScreenState();
}

class _ParkRecommendScreenState extends State<ParkRecommendScreen>
    with AutomaticKeepAliveClientMixin {
  late final ScrollController _scrollController;
  bool _isLoadingMore = false;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (_isInitialized) return;

    try {
      final provider = Provider.of<ParkDataProvider>(context, listen: false);

      print('추천코스 화면 초기화 시작');
      print('현재 사용자 레코드 개수: ${provider.allUserCourseRecords.length}');
      print('CSV 로드 상태: ${provider.csvLoaded}');

      // 사용자 레코드가 비어있고 로딩 중이 아니면 독립적으로 초기화
      if (provider.allUserCourseRecords.isEmpty &&
          !provider.isLoadingUserRecords) {
        print('사용자 레코드가 없어서 독립적으로 초기화 시작');
        await provider.initializeUserRecords();
        print('사용자 레코드 초기화 완료: ${provider.allUserCourseRecords.length}개');
      } else {
        print('사용자 레코드가 이미 로드되어 있음: ${provider.allUserCourseRecords.length}개');
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '데이터 초기화 중 오류가 발생했습니다: $e';
        });
      }
      debugPrint('Provider 초기화 오류: $e');
    }
  }

  void _onScroll() {
    if (!mounted || _isLoadingMore) return;

    final position = _scrollController.position;
    final threshold = ParkRecommendConstants.scrollThreshold;

    if (position.pixels >= position.maxScrollExtent - threshold) {
      _loadMoreRecords();
    }
  }

  Future<void> _loadMoreRecords() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final parkDataProvider = Provider.of<ParkDataProvider>(
        context,
        listen: false,
      );

      if (parkDataProvider.hasMoreRecords) {
        await parkDataProvider.loadMoreUserCourseRecords();
      }
    } catch (e) {
      debugPrint('추가 데이터 로딩 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('추가 데이터를 불러오지 못했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    if (!_isInitialized) {
      return _buildLoadingWidget();
    }

    return Consumer<ParkDataProvider>(
      builder: (context, provider, child) {
        _handleProviderError(provider);

        final displayRecords = provider.allUserCourseRecords;

        if (displayRecords.isEmpty) {
          return _buildEmptyWidget();
        }

        return _buildGridView(displayRecords, provider);
      },
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: ORANGE_PRIMARY_500),
          SizedBox(height: 16),
          Text(
            '추천 코스를 불러오는 중...',
            style: TextStyle(fontSize: 16, color: GRAYSCALE_LABEL_600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? '알 수 없는 오류가 발생했습니다.',
            style: const TextStyle(fontSize: 16, color: GRAYSCALE_LABEL_600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _errorMessage = null;
                _isInitialized = false;
              });
              _initializeData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ORANGE_PRIMARY_500,
              foregroundColor: Colors.white,
            ),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.park_outlined, size: 64, color: GRAYSCALE_LABEL_400),
          const SizedBox(height: 16),
          const Text(
            '추천 코스가 없습니다.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: GRAYSCALE_LABEL_600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '산책 기록을 추가하면\n개인화된 추천 코스를 받을 수 있습니다.',
            style: TextStyle(fontSize: 14, color: GRAYSCALE_LABEL_500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(
    List<StepModel> displayRecords,
    ParkDataProvider provider,
  ) {
    final crossAxisCount =
        MediaQuery.of(context).size.width >
                ParkRecommendConstants.desktopBreakpoint
            ? ParkRecommendConstants.desktopCrossAxisCount
            : ParkRecommendConstants.mobileCrossAxisCount;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        controller: _scrollController,
        itemCount: displayRecords.length + (_isLoadingMore ? 1 : 0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: ParkRecommendConstants.crossAxisSpacing,
          mainAxisSpacing: ParkRecommendConstants.mainAxisSpacing,
          childAspectRatio: ParkRecommendConstants.childAspectRatio,
        ),
        itemBuilder: (_, index) {
          if (index >= displayRecords.length) {
            return _buildLoadingIndicator();
          }
          return _buildRecordCard(displayRecords[index]);
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(color: ORANGE_PRIMARY_500),
    );
  }

  Widget _buildRecordCard(StepModel record) {
    return GestureDetector(
      onTap: () => _navigateToCourseDetail(record),
      child: Container(
        decoration: BoxDecoration(
          color: BACKGROUND_COLOR,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: _buildImageWidget(record),
              ),
            ),
            _buildCardContent(record),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(StepModel record) {
    if (record.imageUrl.isEmpty) {
      return _buildPlaceholderImage();
    }

    return Image.network(
      record.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildImageLoadingWidget(loadingProgress);
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholderImage();
      },
    );
  }

  Widget _buildImageLoadingWidget(ImageChunkEvent loadingProgress) {
    return Container(
      color: GRAYSCALE_LABEL_100,
      child: Center(
        child: CircularProgressIndicator(
          value:
              loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
          strokeWidth: 2,
          color: ORANGE_PRIMARY_500,
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: GRAYSCALE_LABEL_200,
      child: const Icon(
        Icons.image_not_supported,
        size: 48,
        color: GRAYSCALE_LABEL_600,
      ),
    );
  }

  Widget _buildCardContent(StepModel record) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
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
            maxLines: 2,
          ),
          const SizedBox(height: 4),
          Text(
            _getParkName(record),
            style: const TextStyle(fontSize: 12, color: GRAYSCALE_LABEL_800),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            record.stopTime,
            style: const TextStyle(fontSize: 12, color: GRAYSCALE_LABEL_600),
          ),
        ],
      ),
    );
  }

  String _getParkName(StepModel record) {
    if (record.parkName == null) return '공원 미지정';
    if (record.parkName!.isEmpty) return '선택 안함';
    return record.parkName!;
  }

  void _navigateToCourseDetail(StepModel record) {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseDetailScreen(data: record.toJson()),
      ),
    );
  }

  void _handleProviderError(ParkDataProvider provider) {
    if (provider.initError.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.initError),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
}
