import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../cubit/pharmacy_cubit.dart';
import '../../domain/entities/pharmacy.dart';
import 'package:url_launcher/url_launcher.dart';
class PharmacyMapPage extends StatefulWidget {
  const PharmacyMapPage({Key? key}) : super(key: key);

  @override
  State<PharmacyMapPage> createState() => _PharmacyMapPageState();
}

class _PharmacyMapPageState extends State<PharmacyMapPage> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<PharmacyCubit>()..fetchNearbyPharmacies(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Yakın Nöbetçi Eczaneler'),
        ),
        body: BlocBuilder<PharmacyCubit, PharmacyState>(
          builder: (context, state) {
            if (state is PharmacyLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is PharmacyError) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48.r, color: Colors.red),
                      SizedBox(height: 16.h),
                      Text(state.message, textAlign: TextAlign.center),
                      SizedBox(height: 24.h),
                      ElevatedButton(
                        onPressed: () => context.read<PharmacyCubit>().fetchNearbyPharmacies(),
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                ),
              );
            } else if (state is PharmacyLoaded) {
              return _buildMapWithList(context, state.pharmacies, state.currentPosition);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _showPharmacyDetails(BuildContext context, Pharmacy p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h).copyWith(
            bottom: MediaQuery.of(context).viewInsets.bottom + 30.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24.r,
                    backgroundColor: Colors.red[50],
                    child: Icon(Icons.local_pharmacy, color: Colors.red, size: 28.r),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      p.name,
                      style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Text(
                'Adres',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600], fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4.h),
              Text(p.address, style: TextStyle(fontSize: 16.sp, height: 1.4)),
              SizedBox(height: 16.h),
              
              if (p.phone.isNotEmpty) ...[
                Text(
                  'Telefon',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600], fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4.h),
                Text('📞 ${p.phone}', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
                SizedBox(height: 24.h),
              ],
              
              Row(
                children: [
                  if (p.phone.isNotEmpty) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final parsedPhone = p.phone.replaceAll(RegExp(r'[^\d+]'), '');
                          final uri = Uri.parse('tel:$parsedPhone');
                          try {
                            await launchUrl(uri);
                          } catch (_) {}
                        },
                        icon: const Icon(Icons.call, color: Colors.white),
                        label: const Text('Ara', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${p.latitude},${p.longitude}');
                        try {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (_) {}
                      },
                      icon: const Icon(Icons.directions, color: Colors.white),
                      label: const Text('Yol Tarifi', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapWithList(BuildContext context, List<Pharmacy> pharmacies, Position? userPosition) {
    final userLatLng = userPosition != null 
        ? LatLng(userPosition.latitude, userPosition.longitude) 
        : const LatLng(41.0082, 28.9784); // Default to Istanbul

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: userLatLng,
            initialZoom: 13.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.meditrack.app',
            ),
            MarkerLayer(
              markers: [
                // User Marker
                 Marker(
                  point: userLatLng,
                  width: 40.r,
                  height: 40.r,
                  child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                ),
                // Pharmacy Markers
                ...pharmacies.where((p) => p.latitude != 0.0 && p.longitude != 0.0).map(
                  (p) => Marker(
                    point: LatLng(p.latitude, p.longitude),
                    width: 40.r,
                    height: 40.r,
                    child: GestureDetector(
                      onTap: () {
                         // Focus map on this marker
                         _mapController.move(LatLng(p.latitude, p.longitude), 15.0);
                         _showPharmacyDetails(context, p);
                      },
                      child: Icon(Icons.location_on, color: Colors.red, size: 40.r),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        
        // Draggable Sheet for List
        DraggableScrollableSheet(
          initialChildSize: 0.3,
          minChildSize: 0.1,
          maxChildSize: 0.8,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10.r, spreadRadius: 5.r)
                ],
              ),
              child: Stack(
                children: [
                  // Scrollable List
                  ListView.separated(
                    controller: scrollController,
                    padding: EdgeInsets.only(top: 35.h, left: 16.w, right: 16.w, bottom: 20.h),
                    itemCount: pharmacies.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final p = pharmacies[index];
                      return ListTile(
                        onTap: () {
                          if (p.latitude != 0.0 && p.longitude != 0.0) {
                            _mapController.move(LatLng(p.latitude, p.longitude), 15.0);
                          }
                          _showPharmacyDetails(context, p);
                        },
                        leading: CircleAvatar(
                          backgroundColor: Colors.red[50],
                          child: const Icon(Icons.local_pharmacy, color: Colors.red),
                        ),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4.h),
                            Text(p.address),
                            SizedBox(height: 4.h),
                            if (p.phone.isNotEmpty) Text('📞 ${p.phone}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        trailing: p.distance != null 
                            ? Text('${(p.distance! / 1000).toStringAsFixed(1)} km', 
                                style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold))
                            : const SizedBox.shrink(),
                      );
                    },
                  ),
                  
                  // Sticky Handle
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 30.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                      ),
                      child: Center(
                        child: Container(
                          width: 40.w,
                          height: 5.h,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
