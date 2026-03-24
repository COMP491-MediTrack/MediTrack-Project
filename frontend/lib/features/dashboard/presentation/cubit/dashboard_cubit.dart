import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:meditrack/core/constants/app_constants.dart';
import 'package:meditrack/features/auth/data/models/user_model.dart';
import 'package:meditrack/features/dashboard/presentation/cubit/dashboard_state.dart';

@injectable
class DashboardCubit extends Cubit<DashboardState> {
  final FirebaseFirestore _firestore;

  DashboardCubit(this._firestore) : super(DashboardInitial());

  Future<void> loadPatients(String doctorId) async {
    emit(DashboardLoading());
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: AppConstants.rolePatient)
          .where('doctorId', isEqualTo: doctorId)
          .get();
      final patients = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
          .toList();
      emit(DashboardPatientsLoaded(patients));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> loadDoctor(String doctorId) async {
    emit(DashboardLoading());
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(doctorId)
          .get();
      if (!doc.exists) {
        emit(const DashboardError('Doktor bulunamadı'));
        return;
      }
      final doctor = UserModel.fromFirestore(doc.data()!, doc.id);
      emit(DashboardDoctorLoaded(doctor));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
