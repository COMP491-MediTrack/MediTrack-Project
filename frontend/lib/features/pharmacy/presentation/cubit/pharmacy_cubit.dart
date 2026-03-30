import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/pharmacy.dart';
import '../../domain/usecases/get_nearby_pharmacies.dart';
import 'package:geolocator/geolocator.dart';

abstract class PharmacyState extends Equatable {
  const PharmacyState();

  @override
  List<Object?> get props => [];
}

class PharmacyInitial extends PharmacyState {}

class PharmacyLoading extends PharmacyState {}

class PharmacyLoaded extends PharmacyState {
  final List<Pharmacy> pharmacies;
  final Position? currentPosition;

  const PharmacyLoaded(this.pharmacies, this.currentPosition);

  @override
  List<Object?> get props => [pharmacies, currentPosition];
}

class PharmacyError extends PharmacyState {
  final String message;

  const PharmacyError(this.message);

  @override
  List<Object?> get props => [message];
}

@injectable
class PharmacyCubit extends Cubit<PharmacyState> {
  final GetNearbyPharmacies getNearbyPharmacies;

  PharmacyCubit({required this.getNearbyPharmacies}) : super(PharmacyInitial());

  Future<void> fetchNearbyPharmacies() async {
    emit(PharmacyLoading());
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        emit(const PharmacyError('Konum izni olmadan yakındaki eczaneleri göremeyiz. Lütfen ayarlardan konum izni verin.'));
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      
      final result = await getNearbyPharmacies.call();
      
      result.fold(
        (failure) => emit(PharmacyError(failure.message)),
        (pharmacies) => emit(PharmacyLoaded(pharmacies, position)),
      );
    } catch (e) {
      emit(PharmacyError('Failed to fetch location: $e'));
    }
  }
}
