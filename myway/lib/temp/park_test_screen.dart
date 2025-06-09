import 'package:flutter/material.dart';
import 'package:myway/temp/park_api_service_test.dart';
import 'package:myway/temp/park_data_provider_test.dart';
import 'package:provider/provider.dart';
import 'package:myway/model/park_info.dart';

class ParkListScreen extends StatefulWidget {
  const ParkListScreen({super.key});

  @override
  State<ParkListScreen> createState() => _ParkListScreenState();
}

class _ParkListScreenState extends State<ParkListScreen>
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
      _tabController.addListener(() {
        if (_tabController.index == 1) {
          context.read<ParkDataProviderTest>().fetchNearbyParks2km();
        }
      });
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '전체'), Tab(text: '2km 이내')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 🟦 Tab 0: 전체 공원 목록 (pagination)
          _buildParkListView(parks: allParks, showLoading: hasMoreAll),

          _buildParkListView(parks: nearbyParks, showLoading: false),
        ],
      ),
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

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ParkDataProviderTest(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const ParkListScreen(),
      ),
    ),
  );
}
