import 'package:flutter/material.dart';
import 'package:myway/temp/park_data_provider_test.dart';
import 'package:provider/provider.dart';
import 'package:myway/model/park_info.dart';

import '../const/colors.dart';
import '../model/step_model.dart';

enum ParkFilterType { all, nearby, favorites }

class ParkListScreenTest extends StatefulWidget {
  final int initialTabIndex;

  const ParkListScreenTest({super.key, this.initialTabIndex = 0});

  @override
  State<ParkListScreenTest> createState() => _ParkListScreenTestState();
}

class _ParkListScreenTestState extends State<ParkListScreenTest>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _parkListScrollController = ScrollController();
  final ScrollController _userRecordsScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  ParkFilterType _currentParkFilter = ParkFilterType.all;
  String _searchTerm = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );

    // 초기 전체 페이지 로딩
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ParkDataProviderTest>();
      await provider.loadInitialParkPage();
      await provider.fetchUserCourseRecordsInternal();
    });

    // 스크롤 시 다음 페이지 로딩 (탭 0만)
    _parkListScrollController.addListener(() {
      final provider = context.read<ParkDataProviderTest>();
      if (_tabController.index == 0 &&
          _parkListScrollController.position.pixels >=
              _parkListScrollController.position.maxScrollExtent - 100 &&
          !provider.isPaginatedLoading &&
          provider.hasMoreParks) {
        provider.loadNextParkPage();
      }
    });
  }

  @override
  void dispose() {
    _parkListScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ParkDataProviderTest>();

    final allParks = provider.paginatedParks;
    final hasMoreAll = provider.hasMoreParks;
    final nearbyParks = provider.nearbyParks;
    final isLoadingNearby = provider.isLoadingNearbyParks;
    final errorNearby = provider.apiError;

    return Consumer<ParkDataProviderTest>(
      builder: (context, parkDataProvider, child) {
        return Scaffold(
          backgroundColor: BACKGROUND_COLOR,
          appBar: AppBar(
            backgroundColor: BACKGROUND_COLOR,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: GRAYSCALE_LABEL_950,
                size: 20,
              ),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
            title: const Text(
              "공원 및 코스 추천",
              style: TextStyle(
                color: GRAYSCALE_LABEL_950,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            bottom: TabBar(
              controller: _tabController,
              labelColor: BLUE_SECONDARY_700,
              unselectedLabelColor: GRAYSCALE_LABEL_500,
              indicatorColor: BLUE_SECONDARY_700,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [Tab(text: "추천 코스"), Tab(text: "공원")],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              buildUserRecordsTabContent(provider),
              // _buildParkListView(parks: allParks, showLoading: hasMoreAll),
              _buildParkTabContent(provider),
              // _buildParkListView(parks: nearbyParks, showLoading: false),
            ],
          ),
        );
      },
    );
  }

  Widget _buildParkTabContent(ParkDataProviderTest provider) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          _buildParkSearchBarAndFilters(provider),
          // 공원 목록
          Expanded(
            child: _buildParkListView(
              parks: provider.paginatedParks,
              showLoading:
                  provider.hasMoreParks && !provider.isPaginatedLoading,
            ),
          ),
          // 로딩 중일 때
          if (provider.isPaginatedLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          // 오류 메시지
          if (provider.apiError.isNotEmpty)
            Center(child: Text('오류 발생: ${provider.apiError}')),
        ],
      ),
    );
  }

  Widget _buildParkSearchBarAndFilters(ParkDataProviderTest provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: TextField(
              controller: _searchController,
              // onChanged: (value) => _onParkSearchChanged(),
              cursorColor: ORANGE_PRIMARY_500,
              decoration: InputDecoration(
                hintText: "공원 이름 또는 주소 검색",
                hintStyle: const TextStyle(
                  color: GRAYSCALE_LABEL_400,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: GRAYSCALE_LABEL_500,
                  size: 20,
                ),
                filled: true,
                fillColor: GRAYSCALE_LABEL_100,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: const BorderSide(
                    color: GRAYSCALE_LABEL_300,
                    width: 1.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: const BorderSide(
                    color: GRAYSCALE_LABEL_300,
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: const BorderSide(
                    color: BLUE_SECONDARY_500,
                    width: 1.5,
                  ),
                ),
                suffixIcon:
                    _searchTerm.isNotEmpty
                        ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: GRAYSCALE_LABEL_500,
                            size: 20,
                          ),
                          onPressed: () => _searchController.clear(),
                        )
                        : null,
              ),
              style: const TextStyle(fontSize: 14, color: GRAYSCALE_LABEL_950),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildFilterChip(ParkFilterType.all, "전체", true, provider),
              const SizedBox(width: 8),
              _buildFilterChip(
                ParkFilterType.nearby,
                "내 주변 2km",
                true,
                provider,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                ParkFilterType.favorites,
                "찜 목록",
                true,
                provider,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    ParkFilterType type,
    String label,
    bool isSelected,
    ParkDataProviderTest provider,
  ) {
    return FilterChip(
      label: Text(label),
      selected: _currentParkFilter == type,
      onSelected: (selected) {
        setState(() {
          _currentParkFilter = type;
          _searchTerm = "";
          _searchController.clear();
        });
        // provider.updateParkFilter(type);
      },
      selectedColor: BLUE_SECONDARY_200,
      backgroundColor: GRAYSCALE_LABEL_200,
      labelStyle: TextStyle(
        color: isSelected ? BLUE_SECONDARY_700 : GRAYSCALE_LABEL_600,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: BorderSide(
          color: isSelected ? BLUE_SECONDARY_500 : GRAYSCALE_LABEL_300,
          width: 1.0,
        ),
      ),
    );
  }

  Widget _buildParkListView({
    required List<ParkInfo> parks,
    required bool showLoading,
  }) {
    return ListView.builder(
      controller: _parkListScrollController,
      itemCount: parks.length + (showLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == parks.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final park = parks[index];
        return ListTile(
          title: Text(park.name),
          subtitle: Text(
            '${park.address}\n거리: ${park.distanceKm.toStringAsFixed(2)} km',
          ),
        );
      },
    );
  }

  Widget buildUserRecordsTabContent(ParkDataProviderTest provider) {
    final userRecords = provider.allUserCourseRecords;
    final isLoading = provider.isLoadingUserRecords;
    final error = provider.userRecordsError;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error.isNotEmpty) {
      return Center(child: Text('오류 발생: $error'));
    }

    if (userRecords.isEmpty) {
      return const Center(child: Text('사용자 기록이 없습니다.'));
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: GridView.builder(
        controller: _userRecordsScrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          childAspectRatio: 0.68,
        ),
        itemCount: userRecords.length,
        itemBuilder: (context, index) {
          final record = userRecords[index];
          return _buildUserRecordCardItem(record);
        },
      ),
    );
  }

  String formatDuration(String durationStr) {
    final parts = durationStr.split(':');
    if (parts.length == 3) {
      int hours = int.tryParse(parts[0]) ?? 0;
      int minutes = int.tryParse(parts[1]) ?? 0;
      int seconds = int.tryParse(parts[2]) ?? 0;
      String result = "";
      if (hours > 0) result += "$hours시간 ";
      if (minutes > 0 || hours > 0) result += "$minutes분 ";
      result += "$seconds초";
      return result.trim().isEmpty ? "0초" : result.trim();
    }
    return durationStr;
  }

  String formatStopTime(String stopTimeStr) {
    try {
      DateTime dt = DateTime.parse(stopTimeStr);
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return stopTimeStr;
    }
  }

  Widget _buildUserRecordCardItem(StepModel record) {
    return Container(
      key: ValueKey('user_record_item_${record.id}'),
      decoration: BoxDecoration(
        color: BACKGROUND_COLOR,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(32, 32, 32, 0.08),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12.0),
              ),
              child:
                  record.imageUrl.isNotEmpty
                      ? Image.network(
                        record.imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                              color: BLUE_SECONDARY_500,
                            ),
                          );
                        },
                        errorBuilder:
                            (context, error, stackTrace) => const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: GRAYSCALE_LABEL_400,
                                size: 40,
                              ),
                            ),
                      )
                      : Image.asset(
                        'assets/images/default_course_image.png',
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: GRAYSCALE_LABEL_400,
                                size: 40,
                              ),
                            ),
                      ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  record.courseName.isNotEmpty ? record.courseName : "코스 이름 없음",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: GRAYSCALE_LABEL_950,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (record.parkName != null && record.parkName!.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    record.parkName!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: GRAYSCALE_LABEL_800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 3),

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
    );
  }
}

// void main() {
//   runApp(
//     ChangeNotifierProvider(
//       create: (context) => ParkDataProviderTest(),
//       child: MaterialApp(
//         debugShowCheckedModeBanner: false,
//         home: const ParkListScreen(),
//       ),
//     ),
//   );
// }
