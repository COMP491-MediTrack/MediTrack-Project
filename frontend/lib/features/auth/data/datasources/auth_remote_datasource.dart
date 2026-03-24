import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:meditrack/core/constants/app_constants.dart';
import 'package:meditrack/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    required String role,
  });
  Future<UserModel?> getCurrentUser();
  Future<void> logout();
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl(this._firebaseAuth, this._firestore);

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    return UserModel.fromFirestore(doc.data()!, uid);
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    final userModel = UserModel(
      uid: uid,
      email: email,
      name: name,
      role: role,
    );
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set(userModel.toFirestore());
    return userModel;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc.data()!, user.uid);
  }

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }
}
