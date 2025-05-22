import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapInputScreen extends StatefulWidget {
  const MapInputScreen({super.key});

  @override
  State<MapInputScreen> createState() => _MapInputScreenState();
}

class _MapInputScreenState extends State<MapInputScreen> {
  GoogleMapController? _controller;
  final Location _location = Location();
  LatLng _currentPosition = const LatLng(37.5665, 126.9780); // 초기 위치 (서울시청)

  final List<LatLng> _route = []; // 경로 저장 리스트
  Set<Polyline> _polylines = {}; // 지도에 표시할 Polyline
  bool _tracking = false;
  StreamSubscription<LocationData>? _locationSub;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      final serviceRequested = await _location.requestService();
      if (!serviceRequested) return;
    }

    final permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      final permissionRequested = await _location.requestPermission();
      if (permissionRequested != PermissionStatus.granted) return;
    }

    final current = await _location.getLocation();
    if (mounted) {
      setState(() {
        _currentPosition = LatLng(current.latitude!, current.longitude!);
        _controller?.animateCamera(CameraUpdate.newLatLng(_currentPosition));
      });
    }
  }

  void _startTracking() {
    _route.clear();
    _polylines.clear();
    setState(() => _tracking = true);

    _locationSub = _location.onLocationChanged.listen((loc) {
      if (!_tracking ||
          !mounted ||
          loc.latitude == null ||
          loc.longitude == null)
        return;

      final newPos = LatLng(loc.latitude!, loc.longitude!);
      setState(() {
        _currentPosition = newPos;
        _route.add(newPos);
        _polylines = {
          Polyline(
            polylineId: const PolylineId("route"),
            points: List<LatLng>.from(_route),
            color: Colors.blue,
            width: 5,
          ),
        };
      });
      _controller?.animateCamera(CameraUpdate.newLatLng(newPos));
    });
  }

  void _stopTracking() {
    _locationSub?.cancel();
    setState(() => _tracking = false);
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("실시간 경로 추적 지도")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 16,
            ),
            onMapCreated: (controller) => _controller = controller,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _tracking ? _stopTracking : _startTracking,
              child: Text(_tracking ? '중지' : '시작'),
            ),
          ),
        ],
      ),
    );
  }
}
