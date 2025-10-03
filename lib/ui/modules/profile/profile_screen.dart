import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'bloc/profile_cubit.dart';
import 'bloc/profile_state.dart';
import '../../../../data/model/user.dart';
import '../../../../data/repository/user/mock_user_repository.dart';
import '../../../../data/repository/auth/mock_auth_repository.dart';
import '../../components/input/input_field.dart';
import '../../components/buttons/primary_button.dart';

// Clean Profile Screen
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _organizationController = TextEditingController();
  final _aboutController = TextEditingController();
  
  bool _isEditing = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _jobTitleController.dispose();
    _organizationController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  void _loadProfileData(AppUser user) {
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _emailController.text = user.email;
    _phoneController.text = user.phoneNumber ?? '';
    _addressController.text = user.address ?? '';
    _jobTitleController.text = user.jobTitle ?? '';
    _organizationController.text = user.organization ?? '';
    _aboutController.text = user.about ?? '';
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final profileData = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'phoneNumber': _phoneController.text,
        'address': _addressController.text,
        'jobTitle': _jobTitleController.text,
        'organization': _organizationController.text,
        'about': _aboutController.text,
      };
      
      final currentState = context.read<ProfileCubit>().state;
      if (currentState is ProfileLoaded) {
        context.read<ProfileCubit>().updateProfile(currentState.user.id, profileData);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileCubit(
        userRepository: MockUserRepository(),
        authRepository: MockAuthRepository(),
      )..loadProfile('current-user-id'), // Mock user ID
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Profile',
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          actions: [
            BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, state) {
                if (state is ProfileLoaded) {
                  return IconButton(
                    onPressed: _toggleEdit,
                    icon: Icon(
                      _isEditing ? Icons.close : Icons.edit,
                      color: Colors.black,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocConsumer<ProfileCubit, ProfileState>(
          listener: (context, state) {
            if (state is ProfileUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile updated successfully!'),
                  backgroundColor: Color(0xFF3AE6BD),
                ),
              );
              setState(() {
                _isEditing = false;
              });
            } else if (state is ProfileError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is ProfileUpdateError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is ProfileLoading || state is ProfileUpdating) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3AE6BD)),
                ),
              );
            }
            
            if (state is ProfileError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<ProfileCubit>().loadProfile('current-user-id'),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            
            if (state is ProfileLoaded || state is ProfileUpdated) {
              final user = state is ProfileLoaded ? state.user : (state as ProfileUpdated).user;
              
              if (!_isEditing) {
                _loadProfileData(user);
              }
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header
                      Center(
                        child: Column(
                          children: [
                            // Avatar
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3AE6BD),
                                borderRadius: BorderRadius.circular(60),
                                border: Border.all(color: Colors.grey[300]!, width: 3),
                              ),
                              child: user.avatarUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(57),
                                      child: Image.network(
                                        user.avatarUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Colors.white,
                                          );
                                        },
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              user.fullName,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.accountType.name.toUpperCase(),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Profile Form
                      _buildFormSection('Personal Information', [
                        _buildInputField(
                          controller: _firstNameController,
                          label: 'First Name',
                          enabled: _isEditing,
                          validator: (value) => value?.isEmpty == true ? 'First name is required' : null,
                        ),
                        _buildInputField(
                          controller: _lastNameController,
                          label: 'Last Name',
                          enabled: _isEditing,
                          validator: (value) => value?.isEmpty == true ? 'Last name is required' : null,
                        ),
                        _buildInputField(
                          controller: _emailController,
                          label: 'Email',
                          enabled: false, // Email is not editable
                          keyboardType: TextInputType.emailAddress,
                        ),
                        _buildInputField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          enabled: _isEditing,
                          keyboardType: TextInputType.phone,
                        ),
                        _buildInputField(
                          controller: _addressController,
                          label: 'Address',
                          enabled: _isEditing,
                          maxLines: 2,
                        ),
                      ]),
                      
                      const SizedBox(height: 24),
                      
                      _buildFormSection('Professional Information', [
                        _buildInputField(
                          controller: _jobTitleController,
                          label: 'Job Title',
                          enabled: _isEditing,
                        ),
                        _buildInputField(
                          controller: _organizationController,
                          label: 'Organization',
                          enabled: _isEditing,
                        ),
                      ]),
                      
                      const SizedBox(height: 24),
                      
                      _buildFormSection('About', [
                        _buildInputField(
                          controller: _aboutController,
                          label: 'About Me',
                          enabled: _isEditing,
                          maxLines: 4,
                        ),
                      ]),
                      
                      const SizedBox(height: 32),
                      
                      // Save Button
                      if (_isEditing)
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            text: 'Save Changes',
                            onPress: _saveProfile,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }
            
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildFormSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required bool enabled,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InputField(
        controller: controller,
        label: label,
        hint: label,
        validator: validator,
      ),
    );
  }
}
