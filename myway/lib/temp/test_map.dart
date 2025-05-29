import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TestMapScreen extends StatefulWidget {
  const TestMapScreen({super.key});

  @override
  State<TestMapScreen> createState() => _TestMapScreenState();
}

class _TestMapScreenState extends State<TestMapScreen> {
  GoogleMapController? _controller;
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  LatLng _currentPosition = const LatLng(35.178, 129.0874);
  final List<LatLng> _route = [];
  Set<Polyline> _polylines = {};

  void _updatePosition() {
    final double? lat = double.tryParse(_latController.text);
    final double? lng = double.tryParse(_lngController.text);

    if (lat != null && lng != null) {
      final newPosition = LatLng(lat, lng);
      setState(() {
        _currentPosition = newPosition;
        _route.add(newPosition);
        print('route : $_route');
        _polylines = {
          Polyline(
            polylineId: const PolylineId("route"),
            points: List<LatLng>.from(_route),
            color: Colors.blue,
            width: 5,
          ),
        };
      });

      _controller?.animateCamera(CameraUpdate.newLatLng(newPosition));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("올바른 좌표를 입력해주세요.")));
    }
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("좌표 입력으로 경로 그리기")),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: 17,
              ),
              onMapCreated: (controller) => _controller = controller,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _latController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '위도 (latitude)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _lngController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '경도 (longitude)',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _updatePosition,
                    child: const Text("이동 및 경로 추가"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
