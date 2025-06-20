import 'package:flutter/material.dart';
import 'package:myway/const/colors.dart';
import 'package:myway/temp/park_data_provider_test.dart';
import 'package:provider/provider.dart';
import 'package:myway/model/park_info.dart';

enum ParkFilterType { all, nearby2km, bookmarked }

class ParkListScreenTest extends StatefulWidget {
  final initialTabIndex;
  const ParkListScreenTest({super.key, this.initialTabIndex = 0});

  @override
  State<ParkListScreenTest> createState() => _ParkListScreenTestState();
}

class _ParkListScreenTestState extends State<ParkListScreenTest>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 초기 전체 페이지 로딩
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ParkDataProviderTest>();
      await provider.loadInitialParkPage();
    });

    // 스크롤 시 다음 페이지 로딩 (탭 0만)
    _scrollController.addListener(() {
      final provider = context.read<ParkDataProviderTest>();
      if (_tabController.index == 0 &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !provider.isPaginatedLoading &&
          provider.hasMoreParks) {
        provider.loadNextParkPage();
      }
    });
    // 탭 변경 리스너 추가
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        // 탭 1(2km 이내)로 변경될 때 근처 공원 로딩
        final provider = context.read<ParkDataProviderTest>();
        if (provider.nearbyParks.isEmpty && !provider.isLoadingNearbyParks) {
          provider.fetchNearbyParks2km();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('공원 목록'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '2km 이내'), Tab(text: '전체')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 🟦 Tab 0: 전체 공원 목록 (pagination)
          _buildParkListTab(provider),

          // _buildNearbyParks2km(provider),
          _buildNearbyParksTab(provider),
        ],
      ),
    );
  }

  Widget _buildNearbyParksTab(ParkDataProviderTest provider) {
    final nearbyParks = provider.nearbyParks;
    final isLoadingNearby = provider.isLoadingNearbyParks;
    final error = provider.apiError;

    return Column(
      children: [
        // 수동 새로고침 버튼
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed:
                isLoadingNearby
                    ? null
                    : () {
                      provider.fetchNearbyParks2km();
                    },
            icon: const Icon(Icons.refresh),
            label: const Text('2km 이내 공원 찾기'),
          ),
        ),

        // 에러 표시
        if (error.isNotEmpty && !isLoadingNearby)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              error,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),

        // 로딩 또는 리스트 표시
        Expanded(
          child:
              isLoadingNearby
                  ? const Center(
                    child: CircularProgressIndicator(color: ORANGE_PRIMARY_500),
                  )
                  : nearbyParks.isEmpty
                  ? const Center(
                    child: Text(
                      '2km 이내에 공원이 없거나\n위치 권한을 확인 해주세요.',
                      textAlign: TextAlign.center,
                    ),
                  )
                  : _buildParkListView(parks: nearbyParks, showLoading: false),
        ),
      ],
    );
  }

  Widget _buildParkListTab(ParkDataProviderTest provider) {
    final allParks = provider.paginatedParks;
    final hasMoreAll = provider.hasMoreParks;
    return Column(
      children: [
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 20),
        //   child: _buildParkSearchBarAndFilters(provider),
        // ),
        Expanded(
          child: _buildParkListView(parks: allParks, showLoading: hasMoreAll),
        ),
      ],
    );
  }

  Widget _buildParkListView({
    required List<ParkInfo> parks,
    required bool showLoading,
  }) {
    return ListView.builder(
      controller: _scrollController,
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
