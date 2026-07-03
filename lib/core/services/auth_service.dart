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
  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._userDataService);

  final UserDataService _userDataService;
  firebase_auth.FirebaseAuth get _auth => firebase_auth.FirebaseAuth.instance;

  @override
  Stream<AuthUser?> authStateChanges() {
    if (!FirebaseBootstrap.initialized) {
      return DevAuthService.instance.authStateChanges();
    }
    return _auth.authStateChanges().map(_mapUser);
  }

  @override
  AuthUser? get currentUser {
    if (!FirebaseBootstrap.initialized) {
      return DevAuthService.instance.currentUser;
    }
    return _mapUser(_auth.currentUser);
  }

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (!FirebaseBootstrap.initialized) {
      return DevAuthService.instance.register(
        name: name,
        email: email,
        password: password,
      );
    }
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(name);
    final user = _mapUser(credential.user)!;
    await _userDataService.ensureUserProfile(user);
    return user;
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    if (!FirebaseBootstrap.initialized) {
      return DevAuthService.instance.signIn(email: email, password: password);
    }
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
    if (!FirebaseBootstrap.initialized) return;
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() async {
    if (!FirebaseBootstrap.initialized) {
      return DevAuthService.instance.signOut();
    }
    await _auth.signOut();
  }

  AuthUser? _mapUser(firebase_auth.User? user) {
    if (user == null) return null;
    return AuthUser(
      id: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? user.email?.split('@').first ?? 'Piloto',
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
    _user = AuthUser(id: 'dev-user', email: email, name: name);
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
    );
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }
}
