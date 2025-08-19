import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/core/theme/colors.dart';
import 'package:reentry/ui/components/app_bar.dart';
import 'package:reentry/ui/components/buttons/primary_button.dart';
import 'package:reentry/ui/components/input/input_field.dart';
import 'package:reentry/ui/components/scaffold/base_scaffold.dart';
import 'package:reentry/ui/modules/authentication/bloc/account_cubit.dart';
import 'package:reentry/ui/modules/profile/bloc/profile_cubit.dart';
import 'package:reentry/ui/modules/profile/bloc/profile_state.dart';

import '../../../data/model/user_dto.dart';

class ProfileScreen extends HookWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedImage = useState<Uint8List?>(null);
    final key = GlobalKey<FormState>();
    
    Future<XFile?> pickFile() async {
      try {
        final ImagePicker picker = ImagePicker();
        final pickResult = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );
        
        if (pickResult != null) {
          // Validate file size (max 20MB)
          // Use platform-safe check: on web, XFile.length() works without dart:io
          final fileSize = await pickResult.length();
          if (fileSize != null && fileSize > 20 * 1024 * 1024) {
            throw Exception('Image file is too large. Please select an image smaller than 20MB.');
          }
          
          // Validate file extension
          final extension = pickResult.path.split('.').last.toLowerCase();
          if (!['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
            throw Exception('Please select a valid image file (JPG, PNG, or GIF).');
          }
          
          // Read the image bytes and set the selectedImage state
          final bytes = await pickResult.readAsBytes();
          selectedImage.value = bytes;
        }
        
        return pickResult;
      } catch (e) {
        print('Error picking file: $e');
        rethrow;
      }
    }
    
    return BlocConsumer<ProfileCubit, ProfileState>(listener: (_, current) {
      if (current is ProfileSuccess) {
        context.read<AccountCubit>().readFromLocalStorage();
        context.showSnackbarSuccess("Profile updated successfully");
      }
      if (current is ProfileError) {
        context.showSnackbarError(current.message);
      }
    }, builder: (context, state) {
      return BaseScaffold(
          isLoading: state is ProfileLoading,
          appBar: const CustomAppbar(
            title: "Sainte",
          ),
          child: BlocBuilder<AccountCubit, UserDto?>(builder: (context, state) {
            if (state == null) {
              return const Center(
                child: Text("No user found. Please log in again."),
              );
            }
            final user = state;
            return HookBuilder(builder: (context) {
              final supervisorNameController =
                  useTextEditingController(text: user.supervisorsName);
              final supervisorEmailController =
                  useTextEditingController(text: user.supervisorsEmail);
              final organizationNameController =
                  useTextEditingController(text: user.organization);
              final organizationAddressController =
                  useTextEditingController(text: user.organizationAddress);
              final phoneNumberController =
                  useTextEditingController(text: user.phoneNumber);
              final address = useTextEditingController(text: user.address);
              return Form(
                  key: key,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 60,
                              width: 60,
                              child: Stack(
                                children: [
                                                                     SizedBox(
                                     height: 60,
                                     width: 60,
                                     child: Stack(
                                       children: [
                                         CircleAvatar(
                                           backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
                                               ? NetworkImage(user.avatar!)
                                               : null,
                                           child: user.avatar == null || user.avatar!.isEmpty
                                               ? Text(
                                                   user.name?.substring(0, 1).toUpperCase() ?? 'U',
                                                   style: const TextStyle(
                                                     color: AppColors.white,
                                                     fontSize: 24,
                                                     fontWeight: FontWeight.bold,
                                                   ),
                                                 )
                                               : null,
                                         ),
                                         // Show loading indicator when uploading
                                         if (state is ProfileLoading)
                                           Positioned.fill(
                                             child: Container(
                                               decoration: BoxDecoration(
                                                 color: Colors.black.withOpacity(0.5),
                                                 shape: BoxShape.circle,
                                               ),
                                               child: const Center(
                                                 child: CircularProgressIndicator(
                                                   color: AppColors.white,
                                                   strokeWidth: 2,
                                                 ),
                                               ),
                                             ),
                                           ),
                                       ],
                                     ),
                                   ),
                                  Positioned(
                                      right: -1,
                                      bottom: 0,
                                      child: GestureDetector(
                                        onTap: () async {
                                          try {
                                            // Check if profile picture functionality is set up
                                            final isSetup = await context.read<ProfileCubit>().checkProfilePictureSetup();
                                            if (!isSetup) {
                                              // Show dialog with options to set up storage
                                              final shouldSetup = await showDialog<bool>(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return AlertDialog(
                                                    backgroundColor: AppColors.greyDark,
                                                    title: const Text(
                                                      'Profile Picture Setup Required',
                                                      style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
                                                    ),
                                                    content: const Text(
                                                      'Profile picture functionality is not properly configured. Would you like to attempt to fix it automatically?',
                                                      style: TextStyle(color: AppColors.white, fontSize: 14),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.of(context).pop(false),
                                                        child: const Text(
                                                          'Cancel',
                                                          style: TextStyle(color: AppColors.gray2),
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () => Navigator.of(context).pop(true),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: AppColors.primary,
                                                          foregroundColor: AppColors.white,
                                                        ),
                                                        child: const Text('Auto-Fix'),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                              
                                              if (shouldSetup == true) {
                                                // Attempt to fix storage automatically
                                                final setupSuccess = await context.read<ProfileCubit>().autoFixStorageIssues();
                                                if (setupSuccess) {
                                                  context.showSnackbarSuccess("Storage fixed automatically! You can now upload images.");
                                                  // Continue with upload
                                                } else {
                                                  context.showSnackbarError("Automatic fix failed. Please try manual setup.");
                                                  return;
                                                }
                                              } else {
                                              return;
                                              }
                                            }
                                            
                                            final result = await pickFile();
                                            if (result == null) {
                                              return;
                                            }
                                            // Show loading indicator
                                            context.showSnackbarInfo("Uploading profile picture...");
                                            
                                            // Upload the profile photo using the new simplified method
                                            final success = await context
                                                .read<ProfileCubit>()
                                                .uploadProfilePictureSimple(result);
                                            
                                            if (success) {
                                              context.showSnackbarSuccess("Profile picture uploaded successfully!");
                                              // Refresh the user data
                                              context.read<AccountCubit>().readFromLocalStorage();
                                            } else {
                                              context.showSnackbarError("Failed to upload profile picture. Please try again.");
                                            }
                                            
                                            // Success message will be shown by the listener
                                          } catch (e) {
                                            print('Profile picture upload error: $e');
                                            if (e.toString().contains('_Namespace')) {
                                              context.showSnackbarError("Storage issue detected. Click 'Auto-Fix Storage Issues' to resolve permanently.");
                                            } else {
                                            context.showSnackbarError("Failed to upload profile picture: ${e.toString()}");
                                            }
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: const ShapeDecoration(
                                            shape: CircleBorder(
                                                side: BorderSide(
                                                    color: AppColors.gray1)),
                                            color: AppColors.white,
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            size: 10,
                                            color: AppColors.black,
                                          ),
                                        ),
                                      ))
                                ],
                              ),
                            ),
                            10.width,
                            Text(
                              user.name ?? '',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 18,
                              ),
                            )
                          ],
                        ),
                        5.height,
                        // Show both User ID and Profile ID
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User ID: ${user.userId ?? 'N/A'}',
                              style: TextStyle(fontSize: 14, color: Colors.white70),
                            ),
                            5.height,
                            Text(
                              'Profile ID: ${user.personId ?? 'N/A'}',
                              style: TextStyle(fontSize: 14, color: Colors.white70),
                            ),
                            10.height,
                            // Profile picture upload section
                            if (selectedImage.value != null) ...[
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.grey1, width: 2),
                                ),
                                child: ClipOval(
                                  child: Image.memory(
                                    selectedImage.value!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: AppColors.grey1,
                                        child: Icon(
                                          Icons.person,
                                          size: 50,
                                          color: AppColors.white,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              10.height,
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final result = await pickFile();
                                      if (result != null) {
                                        // selectedImage is already set in pickFile()
                                      }
                                    },
                                    icon: Icon(Icons.photo_camera, color: AppColors.white),
                                    label: Text('Change Photo', style: TextStyle(color: AppColors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      if (selectedImage.value != null) {
                                        final success = await context.read<ProfileCubit>().uploadProfilePictureSimple(
                                          XFile.fromData(
                                            selectedImage.value!,
                                            name: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
                                            mimeType: 'image/jpeg',
                                          ),
                                        );
                                        if (success) {
                                          context.showSnackbarSuccess("Profile picture updated successfully!");
                                          selectedImage.value = null;
                                        } else {
                                          context.showSnackbarError("Failed to update profile picture");
                                        }
                                      }
                                    },
                                    icon: Icon(Icons.save, color: AppColors.white),
                                    label: Text('Save Photo', style: TextStyle(color: AppColors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.green,
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              // Show current profile picture or placeholder
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.grey1, width: 2),
                                ),
                                child: ClipOval(
                                  child: user.avatar != null && user.avatar!.isNotEmpty
                                      ? Image.network(
                                          user.avatar!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: AppColors.grey1,
                                              child: Icon(
                                                Icons.person,
                                                size: 50,
                                                color: AppColors.white,
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          color: AppColors.grey1,
                                          child: Icon(
                                            Icons.person,
                                            size: 50,
                                            color: AppColors.white,
                                          ),
                                        ),
                                ),
                              ),
                              10.height,
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await pickFile();
                                  if (result != null) {
                                    // selectedImage is already set in pickFile()
                                  }
                                },
                                icon: Icon(Icons.photo_camera, color: AppColors.white),
                                label: Text('Change Photo', style: TextStyle(color: AppColors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                              ),
                            ],
                          ],
                        ),
                        20.height,
                        InputField(
                          hint: '(000) 000-0000',
                          controller: phoneNumberController,
                          enable: true,
                          phone: true,
                          label: "Phone number",
                        ),
                        20.height,
                        InputField(
                          hint: 'Enter your address',
                          controller: address,
                          enable: true,
                          label: "Address",
                        ),
                        if (user.supervisorsName?.isNotEmpty ?? false) ...[
                          20.height,
                          InputField(
                            hint: 'Supervisors Name',
                            controller: supervisorNameController,
                            label: 'Supervisors Name',
                            enable: true,
                          ),
                        ],
                        if (user.supervisorsEmail?.isNotEmpty ?? false) ...[
                          15.height,
                          InputField(
                            hint: 'Supervisors Email',
                            label: 'Supervisors Email',
                            controller: supervisorEmailController,
                            enable: true,
                          ),
                        ],
                        if (user.organization?.isNotEmpty ?? false) ...[
                          15.height,
                          InputField(
                            hint: 'Organization name',
                            label: 'Organization name',
                            controller: organizationNameController,
                            enable: true,
                          ),
                        ],
                        if (user.organizationAddress?.isNotEmpty ?? false) ...[
                          15.height,
                          InputField(
                            hint: 'Organization address',
                            label: 'Organization address',
                            controller: organizationAddressController,
                            enable: false,
                          ),
                        ],
                        20.height,
                        PrimaryButton(
                          text: 'Update',
                          onPress: () {
                            if (key.currentState!.validate()) {
                              context.read<ProfileCubit>().updateProfile(
                                  user.copyWith(
                                      supervisorsEmail:
                                          supervisorEmailController.text,
                                      phoneNumber: phoneNumberController.text,
                                      organization:
                                          organizationNameController.text,
                                      organizationAddress:
                                          organizationAddressController.text,
                                      supervisorsName:
                                          supervisorNameController.text,
                                      address: address.text));
                            }
                          },
                        )
                      ],
                    ),
                  ));
            });
          }));
    });
  }

}
