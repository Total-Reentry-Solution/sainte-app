import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reentry/data/model/user_dto.dart';
import 'package:reentry/data/repository/auth/auth_repository_interface.dart';
import 'package:reentry/exception/app_exceptions.dart';
import '../../../domain/usecases/auth/login_usecase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthRepository extends AuthRepositoryInterface {
  final collection = FirebaseFirestore.instance.collection('user');

  @override
  Future<UserDto> appleSignIn() {
    throw UnimplementedError();
  }

  @override
  Future<UserDto> createAccount(UserDto createAccount) async {
    if (createAccount.userId == null) {
      throw BaseExceptions('Unable to create account');
    }
    final doc = collection.doc(createAccount.userId!);
    final data = createAccount
        .copyWith(
        userId: doc.id,
        createdAt: DateTime.now(),
        userCode: DateTime.now().millisecondsSinceEpoch.toString(),
        updatedAt: DateTime.now());

    print('create account -> ${data.userCode} -> ${data.toJson()}');
    await doc.set(data.toJson());


    return createAccount;
  }

  Future<UserDto?> findUserById(String id) async {
    final doc = collection.doc(id);
    await doc.delete();
    await FirebaseFirestore.instance.collection('clients').doc(id).delete();
    await FirebaseAuth.instance.currentUser?.delete();
    return null;
    final result = await doc.get();

    if (result.exists) {

      final data =  UserDto.fromJson(result.data() ?? {});
      print('usercode -> ${data.userCode}');
      return data;
    }
    return null;
  }

  @override
  Future<UserDto> googleSignIn() async {
    // TODO: implement googleSignIn
    throw UnimplementedError();
  }

  @override
  Future<LoginResponse?> login(
      {required String email, required String password}) async {
    try {
      if (kIsWeb) {
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (response.user == null) {
          throw BaseExceptions('Account not found');
        }
        final userId = response.user!.id;
        // Optionally fetch user from your users table
        return LoginResponse(userId, null); // Replace null with your user object if needed
      } else {
        final loginResponse = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        final authUser = loginResponse.user;
        if (authUser == null) {
          throw BaseExceptions('Account not found');
        }
        final userId = authUser.uid;
        final user = await findUserById(userId);

        print('kebilate login -> ${user?.toJson()}');
        if (user?.deleted ?? false) {
          throw BaseExceptions('Your account have been deleted');
        }
        return LoginResponse(authUser.uid, user);
      }
    } on AuthException catch (e) {
      throw BaseExceptions(e.message);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw BaseExceptions('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        throw BaseExceptions('Wrong password provided for that user.');
      } else if (e.code == 'invalid-credential') {
        throw BaseExceptions("Invalid credential");
      }
      throw BaseExceptions('Something went wrong');
    } catch (e) {
      throw BaseExceptions(e.toString());
    }
  }

  @override
  Future<void> updateUser(UserDto payload) async {
    try {
      final doc = collection.doc(payload.userId!);
      await doc.set(payload.toJson());
      return;
    } catch (e) {
      return;
    }
  }

  @override
  Future<void> resetPassword({required String email}) async {
    try {
      if (kIsWeb) {
        await Supabase.instance.client.auth.resetPasswordForEmail(email);
      } else {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      }
    } catch (e) {
      throw BaseExceptions(e.toString());
    }
  }

  @override
  Future<User?> createAccountWithEmailAndPassword(
      {required String email, required String password}) async {
    try {
      if (kIsWeb) {
        final response = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );
        if (response.user == null) {
          throw BaseExceptions('Account not created');
        }
        // Optionally create user in your users table
        return null; // Or return a custom user object if needed
      } else {
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        //create db account
        return credential.user;
      }
    } on AuthException catch (e) {
      throw BaseExceptions(e.message);
    } on FirebaseAuthException catch (e) {
      String error = 'Something went wrong';
      if (e.code == 'weak-password') {
        error = ('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        error = ('The account already exists for that email.');
      }
      throw BaseExceptions(error);
    } catch (e) {
      throw BaseExceptions(e.toString());
    }
  }
}
