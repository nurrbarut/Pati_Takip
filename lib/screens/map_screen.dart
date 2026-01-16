import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'dart:async';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _selectedPlaceDetails;
  bool _isDetailLoading = false;
  String? _selectedPlaceId;
  List<dynamic> _placePredictions = [];
  Timer? _debounce;
  bool _isOpenNowOnly = false;
  bool _showSearchAreaButton = false;
  LatLng? _mapCenterPosition;

  final String _apiKey = "AIzaSyBhX5iX8MGIjA4Lb4-5nSbKwLuR_NPOx34";

  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  bool _isLoading = true;

  int _selectedFilterIndex = -1;

  final List<Map<String, dynamic>> _filters = [
    {
      "name": "Veteriner",
      "type": "veterinary_care",
      "icon": Icons.local_hospital,
      "image": "assets/icons/vet.png",
      "uiColor": const Color.fromARGB(255, 255, 0, 0),
    },
    {
      "name": "Pet Shop",
      "type": "pet_store",
      "icon": Icons.shopping_bag,
      "image": "assets/icons/petshop.png",
      "uiColor": Colors.orange,
    },
    {
      "name": "Pet Otel",
      "keyword": "pet boarding",
      "icon": Icons.hotel,
      "image": "assets/icons/pethotel.png",
      "uiColor": Colors.purple,
    },
    {
      "name": "Park",
      "type": "park",
      "icon": Icons.park,
      "image": "assets/icons/park.png",
      "uiColor": Colors.green,
    },
  ];
  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Servis Kontrolü
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return; // Sayfa kapalıysa dur
        _showError("Konum servisi kapalı. Harita için açmanız gerekiyor.");
        setState(() => _isLoading = false);
        return;
      }

      // İzin Kontrolü
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          _showError("Konum izni reddedildi.");
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        _showError("Konum izni kalıcı engelli. Ayarlardan açın.");
        setState(() => _isLoading = false);
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      if (!mounted) return;

      print("KONUM BULUNDU: ${position.latitude}, ${position.longitude}");

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      // Harita hazırsa uçur
      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 14),
      );
    } catch (e) {
      if (!mounted) return;
      print("Konum hatası: $e");

      if (e.toString().contains("TimeoutException")) {
        _showError("Konum bulunamadı (Zaman aşımı).");
      } else {
        _showError("Konum alınırken hata oluştu.");
      }

      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchCustomPlace(String query) async {
    if (_currentPosition == null || query.isEmpty) return;

    setState(() {
      _markers.clear();
      _selectedFilterIndex = -1;
    });

    final double lat = _currentPosition!.latitude;
    final double lng = _currentPosition!.longitude;

    final String url =
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=10000&keyword=$query&key=$_apiKey&language=tr";

    try {
      final response = await http.get(Uri.parse(url));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final List results = data['results'];
          Set<Marker> searchMarkers = {};

          for (var place in results) {
            searchMarkers.add(
              Marker(
                markerId: MarkerId(place['place_id']),
                position: LatLng(
                  place['geometry']['location']['lat'],
                  place['geometry']['location']['lng'],
                ),
                infoWindow: InfoWindow(
                  title: place['name'],
                  snippet: place['vicinity'],
                ),
                icon: BitmapDescriptor.defaultMarker,
              ),
            );
          }

          setState(() {
            _markers.addAll(searchMarkers);
          });
        } else {
          _showError("Sonuç bulunamadı.");
        }
      }
    } catch (e) {
      print("Arama hatası: $e");
    }
  }

  void _autoCompleteSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length < 3) {
        setState(() => _placePredictions = []);
        return;
      }

      final double lat = _currentPosition!.latitude;
      final double lng = _currentPosition!.longitude;
      final String url =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&location=$lat,$lng&radius=50000&language=tr&key=$_apiKey";

      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK') {
            setState(() {
              _placePredictions = data['predictions'];
            });
          }
        }
      } catch (e) {
        print("Autocomplete Hatası: $e");
      }
    });
  }

  Future<void> _goToPlace(String placeId) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _placePredictions = [];
      _searchController.clear();
    });

    final String url =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          final double lat = location['lat'];
          final double lng = location['lng'];
          final String name = data['result']['name'];

          mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16),
          );

          setState(() {
            _markers.add(
              Marker(
                markerId: MarkerId(placeId),
                position: LatLng(lat, lng),
                infoWindow: InfoWindow(title: name),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
                onTap: () {
                  _getPlaceDetails(placeId);
                },
              ),
            );
          });
        }
      }
    } catch (e) {
      print("Detay Hatası: $e");
    }
  }

  Future<void> _searchNearbyPlaces({LatLng? targetLocation}) async {
    if (targetLocation == null && _currentPosition == null) return;

    setState(() {
      _showSearchAreaButton = false;
      _markers.clear();
    });
    int targetIndex = _selectedFilterIndex == -1 ? 0 : _selectedFilterIndex;
    final filter = _filters[targetIndex];
    final double lat = targetLocation?.latitude ?? _currentPosition!.latitude;
    final double lng = targetLocation?.longitude ?? _currentPosition!.longitude;

    String url =
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=10000&type=${filter['type']}&keyword=${filter['keyword'] ?? ''}&language=tr&key=$_apiKey";

    if (_isOpenNowOnly) {
      url += "&opennow";
    } else {
      url =
          "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=5000&type=${filter['type']}&key=$_apiKey&language=tr";
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final List results = data['results'];
          _createMarkers(results, filter['image'], filter['uiColor']);
        } else {
          print("API Boş veya Hata: ${data['status']}");
          if (data['status'] == 'REQUEST_DENIED') {
            _showError("API Key Hatası: Yetki yok.");
          }
        }
      }
    } catch (e) {
      print("Hata: $e");
    }
  }

  Future<void> _getPlaceDetails(String placeId) async {
    setState(() {
      _isDetailLoading = true;
      _selectedPlaceDetails = null;
    });

    final String url =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=name,rating,formatted_phone_number,photos,reviews,formatted_address&language=tr&key=$_apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            _selectedPlaceDetails = data['result'];
            _isDetailLoading = false;
          });
        }
      }
    } catch (e) {
      print("Detay hatası: $e");
      setState(() => _isDetailLoading = false);
    }
  }

  String _getPhotoUrl(String photoReference) {
    return "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=$photoReference&key=$_apiKey";
  }

  Future<Uint8List> _createCustomMarkerBitmap(
    String path,
    Color color,
    int targetSize,
  ) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    final Paint borderPaint = Paint()..color = Colors.white;
    double size = targetSize.toDouble();
    double iconSize = size * 0.6;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.0, paint);

    canvas.drawCircle(
      Offset(size / 2, size / 2),
      (size / 2.0) - 2,
      borderPaint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: iconSize.toInt(),
    );
    ui.FrameInfo fi = await codec.getNextFrame();

    double xOffset = (size - iconSize) / 2;
    double yOffset = (size - iconSize) / 2;

    canvas.drawImage(fi.image, Offset(xOffset, yOffset), Paint());

    final ui.Image image = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  Future<void> _createMarkers(
    List places,
    String imagePath,
    Color color,
  ) async {
    Set<Marker> newMarkers = {};

    try {
      final Uint8List smallIconBytes = await _createCustomMarkerBitmap(
        imagePath,
        color.withOpacity(1),
        100,
      );
      final BitmapDescriptor smallIcon = BitmapDescriptor.fromBytes(
        smallIconBytes,
      );

      final Uint8List bigIconBytes = await _createCustomMarkerBitmap(
        imagePath,
        color,
        150,
      );
      final BitmapDescriptor bigIcon = BitmapDescriptor.fromBytes(bigIconBytes);

      for (var place in places) {
        final geometry = place['geometry']['location'];
        final double lat = geometry['lat'];
        final double lng = geometry['lng'];
        final String placeId = place['place_id'];
        bool isSelected =
            _selectedPlaceDetails != null &&
            _selectedPlaceDetails!['place_id'] == placeId;

        newMarkers.add(
          Marker(
            markerId: MarkerId(placeId),
            position: LatLng(lat, lng),
            zIndex: isSelected ? 10.0 : 1.0,
            icon: isSelected ? bigIcon : smallIcon,

            onTap: () {
              _getPlaceDetails(placeId);
              setState(() {});
              _createMarkers(places, imagePath, color);
            },
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        _markers = newMarkers;
      });
    } catch (e) {
      print("Marker hatası: $e");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (_currentPosition != null) {
      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 14),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  padding: EdgeInsets.only(
                    top: 380,
                    bottom: MediaQuery.of(context).padding.bottom + 90 + 20,
                  ),
                  onMapCreated: (controller) {
                    mapController = controller;
                    if (_currentPosition != null) {
                      mapController!.animateCamera(
                        CameraUpdate.newLatLngZoom(_currentPosition!, 14),
                      );
                    }
                  },
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition ?? const LatLng(39.9334, 32.8597),
                    zoom: 14.0,
                  ),
                  markers: _markers,
                  myLocationButtonEnabled: true,
                  myLocationEnabled: true,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onCameraMove: (CameraPosition position) {
                    _mapCenterPosition = position.target;
                    if (!_showSearchAreaButton) {
                      setState(() => _showSearchAreaButton = true);
                    }
                  },
                  onTap: (_) {
                    FocusScope.of(context).unfocus();
                    setState(() {
                      _placePredictions = [];
                      _selectedPlaceDetails = null;
                    });
                  },
                ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) => _autoCompleteSearch(value),
                            decoration: InputDecoration(
                              hintText: "Veteriner, klinik veya otel ara...",
                              border: InputBorder.none,
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.grey,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _placePredictions = []);
                                },
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 15,
                              ),
                            ),
                          ),
                        ),
                        if (_placePredictions.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: _placePredictions.length,
                              itemBuilder: (context, index) {
                                final place = _placePredictions[index];
                                return ListTile(
                                  leading: const Icon(
                                    Icons.location_on,
                                    color: Colors.redAccent,
                                  ),
                                  title: Text(
                                    place['structured_formatting']['main_text'] ??
                                        "",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    place['structured_formatting']['secondary_text'] ??
                                        "",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () => _goToPlace(place['place_id']),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  if (_placePredictions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: List.generate(_filters.length, (index) {
                            final filter = _filters[index];
                            final bool isSelected =
                                _selectedFilterIndex == index;
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedFilterIndex = index;
                                    _searchController.clear();
                                    _placePredictions = [];
                                    _selectedPlaceDetails = null;
                                  });
                                  _searchNearbyPlaces();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? filter['uiColor']
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: isSelected
                                          ? filter['uiColor']
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        filter['icon'],
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        filter['name'],
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  if (_placePredictions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10, right: 20),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isOpenNowOnly = !_isOpenNowOnly;
                              _searchNearbyPlaces();
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _isOpenNowOnly
                                  ? Colors.red.shade50
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isOpenNowOnly
                                    ? Colors.red
                                    : Colors.grey.shade300,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isOpenNowOnly
                                      ? Icons.access_time_filled
                                      : Icons.access_time,
                                  size: 18,
                                  color: _isOpenNowOnly
                                      ? Colors.red
                                      : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Sadece Açık",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _isOpenNowOnly
                                        ? Colors.red
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (_showSearchAreaButton)
            Positioned(
              top: 260,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_mapCenterPosition != null) {
                      _searchNearbyPlaces(targetLocation: _mapCenterPosition);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search, size: 16, color: Colors.blueAccent),
                        SizedBox(width: 8),
                        Text(
                          "Bu Alanı Ara",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_isDetailLoading || _selectedPlaceDetails != null)
            Positioned(
              bottom: 120,
              left: 20,
              right: 20,
              child: Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 350),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _isDetailLoading
                      ? const SizedBox(
                          height: 100,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 8,
                                top: 12,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedPlaceDetails!['name'] ??
                                          "Bilinmeyen Yer",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () => setState(
                                      () => _selectedPlaceDetails = null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, thickness: 0.5),
                            Flexible(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_selectedPlaceDetails!['photos'] !=
                                        null)
                                      Container(
                                        height: 150,
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          image: DecorationImage(
                                            image: NetworkImage(
                                              _getPhotoUrl(
                                                _selectedPlaceDetails!['photos'][0]['photo_reference'],
                                              ),
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (_selectedPlaceDetails!['rating'] !=
                                            null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.amber,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.star,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "${_selectedPlaceDetails!['rating']}",
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _selectedPlaceDetails!['formatted_address'] ??
                                                "",
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_selectedPlaceDetails!['reviews'] !=
                                            null &&
                                        (_selectedPlaceDetails!['reviews']
                                                as List)
                                            .isNotEmpty)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 8.0,
                                            ),
                                            child: Text(
                                              "Son Yorumlar:",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          ...(_selectedPlaceDetails!['reviews']
                                                  as List)
                                              .take(5)
                                              .map((review) {
                                                return Container(
                                                  width: double.infinity,
                                                  margin: const EdgeInsets.only(
                                                    bottom: 10,
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          Colors.grey.shade200,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            review['author_name'] ??
                                                                "Anonim",
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .black87,
                                                                ),
                                                          ),
                                                          if (review['rating'] !=
                                                              null)
                                                            Row(
                                                              children: [
                                                                Text(
                                                                  "${review['rating']}",
                                                                  style: const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: Colors
                                                                        .amber,
                                                                  ),
                                                                ),
                                                                const Icon(
                                                                  Icons.star,
                                                                  size: 12,
                                                                  color: Colors
                                                                      .amber,
                                                                ),
                                                              ],
                                                            ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        review['text'] ?? "",
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontStyle:
                                                              FontStyle.italic,
                                                          color: Colors.black54,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              })
                                              .toList(),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
