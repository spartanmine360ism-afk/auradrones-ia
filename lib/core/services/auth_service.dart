import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../models/auth_user.dart';
import 'firebase_bootstrap.dart';
import 'user_data_service.dart';

abstract class AuthService {
  Stream<AuthUser?> authStateChanges();
  AuthUser? get currentUser;
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  });
  Future<AuthUser> signIn({required String email, required String password});
  Future<void> sendPasswordReset(String email);
  Future<void> sendEmailVerification();
  Future<AuthUser?> reloadCurrentUser();
  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._userDataService);

  final UserDataService _userDataService;
  firebase_auth.FirebaseAuth get _auth => firebase_auth.FirebaseAuth.instance;

  StateError get _firebaseFailure => StateError(
    'Firebase esta configurado pero no pudo iniciar: ${FirebaseBootstrap.failureMessage}',
  );

  @override
  Stream<AuthUser?> authStateChanges() {
    if (FirebaseBootstrap.localMode) {
      return DevAuthService.instance.authStateChanges();
    }
    if (FirebaseBootstrap.failed) return Stream.error(_firebaseFailure);
    return _auth.authStateChanges().map(_mapUser);
  }

  @override
  AuthUser? get currentUser {
    if (FirebaseBootstrap.localMode) {
      return DevAuthService.instance.currentUser;
    }
    if (FirebaseBootstrap.failed) return null;
    return _mapUser(_auth.currentUser);
  }

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (FirebaseBootstrap.localMode) {
      return DevAuthService.instance.register(
        name: name,
        email: email,
        password: password,
      );
    }
    if (FirebaseBootstrap.failed) throw _firebaseFailure;
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(name);
    await credential.user?.sendEmailVerification();
    final user = _mapUser(credential.user)!;
    await _userDataService.ensureUserProfile(user);
    return user;
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    if (FirebaseBootstrap.localMode) {
      return DevAuthService.instance.signIn(email: email, password: password);
    }
    if (FirebaseBootstrap.failed) throw _firebaseFailure;
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = _mapUser(credential.user)!;
    await _userDataService.ensureUserProfile(user);
    return user;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    if (FirebaseBootstrap.localMode) return;
    if (FirebaseBootstrap.failed) throw _firebaseFailure;
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> sendEmailVerification() async {
    if (FirebaseBootstrap.localMode) return;
    if (FirebaseBootstrap.failed) throw _firebaseFailure;
    await _auth.currentUser?.sendEmailVerification();
  }

  @override
  Future<AuthUser?> reloadCurrentUser() async {
    if (FirebaseBootstrap.localMode) {
      return DevAuthService.instance.reloadCurrentUser();
    }
    if (FirebaseBootstrap.failed) throw _firebaseFailure;
    await _auth.currentUser?.reload();
    return _mapUser(_auth.currentUser);
  }

  @override
  Future<void> signOut() async {
    if (FirebaseBootstrap.localMode) {
      return DevAuthService.instance.signOut();
    }
    if (FirebaseBootstrap.failed) throw _firebaseFailure;
    await _auth.signOut();
  }

  AuthUser? _mapUser(firebase_auth.User? user) {
    if (user == null) return null;
    return AuthUser(
      id: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? user.email?.split('@').first ?? 'Piloto',
      emailVerified: user.emailVerified,
    );
  }
}

class DevAuthService implements AuthService {
  DevAuthService._();

  static final instance = DevAuthService._();
  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _user = AuthUser(
      id: 'dev-user',
      email: email,
      name: name,
      emailVerified: true,
    );
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    _user = AuthUser(
      id: 'dev-user',
      email: email,
      name: email.split('@').first,
      emailVerified: true,
    );
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<AuthUser?> reloadCurrentUser() async => _user;

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }
}
