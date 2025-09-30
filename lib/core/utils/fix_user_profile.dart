import 'package:reentry/core/config/supabase_config.dart';
import 'package:reentry/data/enum/account_type.dart';

class UserProfileFixer {
  /// Safe helper to get first name from full name string
  static String? _getFirstName(String? fullName) {
    if (fullName == null || fullName.isEmpty) return null;
    final parts = fullName.split(' ');
    return parts.isNotEmpty ? parts.first : null;
  }
  
  /// Safe helper to get last name from full name string
  static String? _getLastName(String? fullName) {
    if (fullName == null || fullName.isEmpty) return null;
    final parts = fullName.split(' ');
    return parts.length > 1 ? parts.skip(1).join(' ') : null;
  }
  
  /// Safe helper to get username from email
  static String _getEmailUsername(String email) {
    if (email.isEmpty) return 'User';
    final parts = email.split('@');
    return parts.isNotEmpty ? parts.first : 'User';
  }
  /// Creates a user profile for an existing auth user who doesn't have a profile record
  static Future<void> createMissingUserProfile({
    required String userId,
    required String email,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    AccountType accountType = AccountType.citizen,
  }) async {
    try {
      print('Creating missing user profile for user: $userId');
      
      // First check if user profile already exists
      final existingProfile = await SupabaseConfig.client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
          
      if (existingProfile != null) {
        print('User profile already exists');
        return;
      }
      
      // Create a person record first
      final personResponse = await SupabaseConfig.client
          .from('persons')
          .insert({
            'email': email,
            'first_name': firstName,
            'last_name': lastName,
            'phone_number': phoneNumber,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('person_id')
          .single();

      final personId = personResponse['person_id'];
      print('Created person record with ID: $personId');
      
      // Create user profile
      await SupabaseConfig.client
          .from('user_profiles')
          .insert({
            'id': userId,
            'email': email,
            'first_name': firstName,
            'last_name': lastName,
            'phone': phoneNumber,
            'person_id': personId,
            'account_type': accountType.name,
            'organizations': <String>[],
            'services': <String>[],
            'deleted': false,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
      
      print('Successfully created user profile for $userId');
      
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }
  
  /// Fixes user profile for the currently logged in user
  static Future<void> fixCurrentUserProfile() async {
    final currentUser = SupabaseConfig.currentUser;
    if (currentUser == null) {
      throw Exception('No user is currently logged in');
    }
    
    final email = currentUser.email;
    if (email == null) {
      throw Exception('User email not found');
    }
    
    // Get user metadata if available
    final userMetadata = currentUser.userMetadata;
    final firstName = userMetadata?['first_name'] ?? 
                     _getFirstName(userMetadata?['name']?.toString()) ?? 
                     _getEmailUsername(email);
    final lastName = userMetadata?['last_name'] ?? 
                    _getLastName(userMetadata?['name']?.toString()) ?? 
                    '';
    
    await createMissingUserProfile(
      userId: currentUser.id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: userMetadata?['phone'],
    );
  }
}