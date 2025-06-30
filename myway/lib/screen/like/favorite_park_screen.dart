import 'package:flutter/material.dart';
import 'package:myway/const/colors.dart';
import 'package:myway/provider/park_data_provider.dart';
import 'package:myway/screen/home/park_detail.dart';
import 'package:provider/provider.dart';

class FavoriteParkScreen extends StatefulWidget {
  const FavoriteParkScreen({super.key});

  @override
  State<FavoriteParkScreen> createState() => _FavoriteParkScreenState();
}

class _FavoriteParkScreenState extends State<FavoriteParkScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final provider = Provider.of<ParkDataProvider>(context, listen: false);
      if (provider.allParks.isEmpty) {
        provider.loadParksFromCsv();
      }
      if (provider.favoriteParkIds.isEmpty) {
        provider.loadFavoritesFromFirestore();
      }
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final parkDataProvider = context.watch<ParkDataProvider>();
    final isLoading = parkDataProvider.isLoading;
    final error = parkDataProvider.error;
    final allParks = parkDataProvider.allParks;
    final favoriteParkIds = parkDataProvider.favoriteParkIds;
    final likedParks =
        allParks.where((park) => favoriteParkIds.contains(park.id)).toList();

    print('allParks: \\${allParks.map((e) => e.id).toList()}');
    print('favoriteParkIds: \\${favoriteParkIds}');
    print('likedParks: \\${likedParks.map((e) => e.id).toList()}');

    return Scaffold(
      backgroundColor: GRAYSCALE_LABEL_50,
      body: Builder(
        builder: (context) {
          if (isLoading || allParks.isEmpty || favoriteParkIds.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (error.isNotEmpty && allParks.isEmpty) {
            return Center(child: Text('오류: $error'));
          }
          if (likedParks.isEmpty) {
            return const Center(child: Text('찜한 공원이 없습니다.'));
          }

          return ListView.builder(
            itemCount: likedParks.length,
            itemBuilder: (context, index) {
              final park = likedParks[index];
              return ListTile(
                title: Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  decoration: BoxDecoration(
                    color: GRAYSCALE_LABEL_50,
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(32, 32, 32, 0.05),
                        spreadRadius: 0.5,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ParkDetailScreen(park: park),
                          ),
                        ),
                    borderRadius: BorderRadius.circular(10.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 22,
                            color: ORANGE_PRIMARY_500,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        park.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: GRAYSCALE_LABEL_950,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${park.distanceKm.toStringAsFixed(1)} km',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: BLUE_SECONDARY_500,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  park.address.isNotEmpty
                                      ? park.address
                                      : '주소 정보 없음',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: GRAYSCALE_LABEL_700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: GRAYSCALE_LABEL_400,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
