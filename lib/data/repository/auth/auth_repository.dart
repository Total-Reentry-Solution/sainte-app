import 'package:reentry/da      final currentUser = SupabaseConfig.client.auth.currentUser;
      if (currentUser == null) {
        throw BaseExceptions('Current user not found');
      }

      // Fetch user data from Supabase user_profiles table
      final user = await findUserById(currentUser.id);
      if (user == null) {
        // Try to create missing user profile
        print('User profile not found, attempting to create one...');
        try {
          await _createMissingUserProfile(currentUser);
          // Try to fetch again after creating profile
          final newUser = await findUserById(currentUser.id);
          if (newUser != null) {
            return newUser;
          }
        } catch (e) {
          print('Failed to create missing user profile: $e');
        }
        throw BaseExceptions('User profile not found');
      }

      return user;r_dto.dart';
import 'package:reentry/data/repository/auth/auth_repository_interface.dart';
import 'package:reentry/exception/app_exceptions.dart';
import '../../../domain/usecases/auth/login_usecase.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../core/config/supabase_config.dart';
import 'package:flutter/foundation.dart';

class AuthRepository extends AuthRepositoryInterface {

  @override
  Future<UserDto> appleSignIn() async {
    try {
      await SupabaseConfig.client.auth.signInWithOAuth(
        supabase.OAuthProvider.apple,
        redirectTo: kIsWeb
            ? Uri.base.toString()
            : 'ybpohdpizkbysfrvygxx://login-callback',
      );

      // Wait for auth state change and get current session
          final session = SupabaseConfig.client.auth.currentSession;
      if (session == null) {
        throw Exception('Authentication failed - no session created');
      }

      final currentUser = session.user;
      if (currentUser == null) {
        throw BaseExceptions('Apple sign in failed');
      }

      // Fetch user data from Supabase user_profiles table
      final user = await findUserById(currentUser.id);
      if (user == null) {
        throw BaseExceptions('User profile not found');
      }

      return user;
    } on supabase.AuthException catch (e) {
      throw BaseExceptions(e.message);
    } catch (e) {
      throw BaseExceptions(e.toString());
    }
  }

  /// Safe helper to get first name from full name string
  String? _getFirstName(String? fullName) {
    if (fullName == null || fullName.isEmpty) return null;
    final parts = fullName.split(' ');
    return parts.isNotEmpty ? parts.first : null;
  }
  
  /// Safe helper to get last name from full name string
  String? _getLastName(String? fullName) {
    if (fullName == null || fullName.isEmpty) return null;
    final parts = fullName.split(' ');
    return parts.length > 1 ? parts.skip(1).join(' ') : null;
  }
  
  /// Safe helper to get username from email
  String _getEmailUsername(String email) {
    if (email.isEmpty) return 'User';
    final parts = email.split('@');
    return parts.isNotEmpty ? parts.first : 'User';
  }

  /// Creates a basic user profile for users who have auth but no profile record
  Future<void> _createMissingUserProfile(supabase.User user) async {
    try {
      final email = user.email ?? '';
      final userMetadata = user.userMetadata ?? {};
      
      final firstName = userMetadata['first_name']?.toString() ?? 
                       _getFirstName(userMetadata['name']?.toString()) ?? 
                       _getEmailUsername(email);
      final lastName = userMetadata['last_name']?.toString() ?? 
                      _getLastName(userMetadata['name']?.toString()) ?? 
                      '';
      
      // Create a person record first
      final personResponse = await SupabaseConfig.client
          .from('persons')
          .insert({
            'email': email,
            'first_name': firstName,
            'last_name': lastName,
            'phone_number': userMetadata['phone']?.toString(),
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('person_id')
          .single();

      final personId = personResponse['person_id'];
      
      // Create user profile
      await SupabaseConfig.client
          .from('user_profiles')
          .insert({
            'id': user.id,
            'email': email,
            'first_name': firstName,
            'last_name': lastName,
            'phone': userMetadata['phone']?.toString(),
            'person_id': personId,
            'account_type': 'citizen', // Default account type
            'organizations': <String>[],
            'services': <String>[],
            'deleted': false,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
      
      print('Successfully created missing user profile for ${user.id}');
    } catch (e) {
      print('Error creating missing user profile: $e');
      rethrow;
    }
  }

  @override
  Future<UserDto> createAccount(UserDto createAccount) async {
    if (createAccount.userId == null) {
      throw BaseExceptions('Unable to create account');
    }
    
    try {
      // Check if user profile already exists
      final existingUser = await findUserById(createAccount.userId!);
      
      if (existingUser != null) {
        // User already exists, update the profile
        await updateUser(createAccount);
        return createAccount.copyWith(
          userId: createAccount.userId,
          createdAt: existingUser.createdAt,
          userCode: existingUser.userCode,
          updatedAt: DateTime.now(),
        );
      }
      
      // Handle organization validation for case managers
      List<String> organizations = createAccount.organizations;
      if (createAccount.accountType.name == 'case_manager' && createAccount.organization != null && createAccount.organization!.isNotEmpty) {
        try {
          print('Checking if organization exists: ${createAccount.organization}');
          
          // Check if organization already exists
          final existingOrg = await SupabaseConfig.client
              .from('organizations')
              .select()
              .eq('name', createAccount.organization!)
              .maybeSingle();
          
          if (existingOrg != null) {
            print('Organization exists: ${existingOrg['id']}');
            // Organization exists, add its ID to user's organizations
            organizations = [...organizations, existingOrg['id'].toString()];
          } else {
            // Organization doesn't exist - throw error
            throw BaseExceptions('Organization "${createAccount.organization}" does not exist. Please enter a valid organization name or contact an administrator to create the organization.');
          }
        } catch (e) {
          if (e is BaseExceptions) {
            // Re-throw the specific error about organization not existing
            rethrow;
          }
          print('Error handling organization lookup: $e');
          throw BaseExceptions('Error checking organization. Please try again.');
        }
      }
      
      // Create new user profile
      // First, create a person record
      final personResponse = await SupabaseConfig.client
          .from('persons')
          .insert({
            'email': createAccount.email,
            'first_name': _getFirstName(createAccount.name),
            'last_name': _getLastName(createAccount.name),
            'phone_number': createAccount.phoneNumber,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('person_id')
          .single();

      final personId = personResponse['person_id'];
      
      // Then create user profile with the person_id
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.userProfilesTable)
          .insert({
            'id': createAccount.userId,
            'email': createAccount.email,
            'first_name': _getFirstName(createAccount.name),
            'last_name': _getLastName(createAccount.name),
            'phone': createAccount.phoneNumber,
            'address': createAccount.address,
            'person_id': personId,
            'account_type': createAccount.accountType.name,
            'organizations': organizations,
            'organization': createAccount.organization,
            'organization_address': createAccount.organizationAddress,
            'job_title': createAccount.jobTitle,
            'supervisors_name': createAccount.supervisorsName,
            'supervisors_email': createAccount.supervisorsEmail,
            'services': createAccount.services,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      
      return createAccount.copyWith(
        userId: response['id'],
        createdAt: DateTime.now(),
        userCode: DateTime.now().millisecondsSinceEpoch.toString(),
        updatedAt: DateTime.now(),
        organizations: organizations,
        personId: personId,
      );
    } catch (e) {
      throw BaseExceptions('Failed to create account in Supabase: ${e.toString()}');
    }
  }

  Future<UserDto?> findUserById(String id) async {
    try {
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.userProfilesTable)
          .select()
          .eq('id', id)
          .eq('deleted', false)
          .single();
      
      if (response != null) {
        return UserDto.fromJson({
          'id': response['id'],
          'email': response['email'],
          'name': '${response['first_name'] ?? ''} ${response['last_name'] ?? ''}'.trim(),
          'phoneNumber': response['phone'],
          'avatar': response['avatar_url'],
          'address': response['address'],
          'created_at': response['created_at'],
          'updated_at': response['updated_at'],
          'account_type': response['account_type'],
          'organizations': response['organizations'],
          'person_id': response['person_id'],
          'deleted': response['deleted'],
          'reason_for_account_deletion':
              response['reason_for_account_deletion'],
        });
      }
      return null;
    } catch (e) {
      print('Error finding user in Supabase: $e');
      return null;
    }
  }

  Future<UserDto?> findUserByPersonId(String personId) async {
    try {
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.userProfilesTable)
          .select()
          .eq('person_id', personId)
          .eq('deleted', false)
          .single();
      
      if (response != null) {
        return UserDto.fromJson({
          'id': response['id'],
          'email': response['email'],
          'name': '${response['first_name'] ?? ''} ${response['last_name'] ?? ''}'.trim(),
          'phoneNumber': response['phone'],
          'avatar': response['avatar_url'],
          'address': response['address'],
          'created_at': response['created_at'],
          'updated_at': response['updated_at'],
          'account_type': response['account_type'],
          'organizations': response['organizations'],
          'person_id': response['person_id'],
          'deleted': response['deleted'],
          'reason_for_account_deletion':
              response['reason_for_account_deletion'],
        });
      }
      return null;
    } catch (e) {
      print('Error finding user by personId in Supabase: $e');
      return null;
    }
  }

  @override
  Future<UserDto> googleSignIn() async {
    try {
      await SupabaseConfig.client.auth.signInWithOAuth(
        supabase.OAuthProvider.google,
        redirectTo: kIsWeb
            ? Uri.base.toString()
            : 'ybpohdpizkbysfrvygxx://login-callback',
      );

      // Wait for auth state change and get current session
          final session = SupabaseConfig.client.auth.currentSession;
      if (session == null) {
        throw Exception('Authentication failed - no session created');
      }

      final currentUser = session.user;
      if (currentUser == null) {
        throw BaseExceptions('Google sign in failed');
      }

      // Fetch user data from Supabase user_profiles table
      final user = await findUserById(currentUser.id);
      if (user == null) {
        throw BaseExceptions('User profile not found');
      }

      return user;
    } on supabase.AuthException catch (e) {
      throw BaseExceptions(e.message);
    } catch (e) {
      throw BaseExceptions(e.toString());
    }
  }

  @override
  Future<LoginResponse?> login(
      {required String email, required String password}) async {
    try {
      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw BaseExceptions('Account not found');
      }
      final userId = response.user!.id;
      
      // Fetch user data from Supabase user_profiles table
      final user = await findUserById(userId);
      if (user == null) {
        throw BaseExceptions('User profile not found');
      }

      return LoginResponse(userId, user);
    } on supabase.AuthException catch (e) {
      throw BaseExceptions(e.message);
    } catch (e) {
      throw BaseExceptions(e.toString());
    }
  }

  @override
  Future<void> updateUser(UserDto payload) async {
    try {
      if (payload.userId == null) {
        throw BaseExceptions('User ID is required for update');
      }
      final firstName = _getFirstName(payload.name) ?? '';
      final lastName = _getLastName(payload.name) ?? '';
      
      await SupabaseConfig.client
          .from(SupabaseConfig.userProfilesTable)
          .update({
            'first_name': firstName,
            'last_name': lastName,
            'phone': payload.phoneNumber,
            'avatar_url': payload.avatar,
            'address': payload.address,
            'account_type': payload.accountType.name,
            'organizations': payload.organizations,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', payload.userId!);
      
             // Also update the person record with additional case manager info
       if (payload.organization != null || payload.jobTitle != null || 
           payload.supervisorsName != null || payload.supervisorsEmail != null) {
         final email = payload.email;
         if (email != null) {
           await SupabaseConfig.client
               .from('persons')
               .update({
                 'email': email,
                 'first_name': firstName,
                 'last_name': lastName,
                 'phone_number': payload.phoneNumber,
                 'updated_at': DateTime.now().toIso8601String(),
               })
               .eq('email', email);
         }
       }
      return;
    } catch (e) {
      throw BaseExceptions('Failed to update user: ${e.toString()}');
    }
  }

  @override
  Future<void> resetPassword({required String email}) async {
    try {
      await SupabaseConfig.client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw BaseExceptions(e.toString());
    }
  }

  @override
  Future<supabase.User?> createAccountWithEmailAndPassword(
      {required String email, required String password}) async {
    try {
      final response = await SupabaseConfig.client.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw BaseExceptions('Account not created');
      }
      
      // User profile will be created automatically by the trigger
      // But we can add additional data if needed
      await SupabaseConfig.client
          .from(SupabaseConfig.userProfilesTable)
          .update({
            'email': email,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', response.user!.id);
      
      return response.user;
    } on supabase.AuthException catch (e) {
      throw BaseExceptions(e.message);
    } catch (e) {
      throw BaseExceptions(e.toString());
    }
  }
}
