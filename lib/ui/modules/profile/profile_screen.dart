import 'dart:io';
import 'dart:convert';

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
    final selectedFile = useState<XFile?>(null);
    final key = GlobalKey<FormState>();
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
                                            selectedFile.value = result;
                                            
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
                            // Add diagnostic button for storage issues
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  final results = await context.read<ProfileCubit>().runStorageDiagnostics();
                                  print('Storage diagnostics completed. Check console for details.');
                                  context.showSnackbarInfo("Storage diagnostics completed. Check console for details.");
                                } catch (e) {
                                  context.showSnackbarError("Diagnostics failed: ${e.toString()}");
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gray2,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: const Text('Run Storage Diagnostics'),
                            ),
                            10.height,
                            // Add auto-fix button for permanent storage solution
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  context.showSnackbarInfo("Attempting to fix storage issues automatically...");
                                  final success = await context.read<ProfileCubit>().autoFixStorageIssues();
                                  if (success) {
                                    context.showSnackbarSuccess("Storage issues fixed automatically! You can now upload profile pictures.");
                                  } else {
                                    context.showSnackbarError("Automatic fix failed. Please try manual setup or contact support.");
                                  }
                                } catch (e) {
                                  context.showSnackbarError("Auto-fix failed: ${e.toString()}");
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: const Text('Auto-Fix Storage Issues'),
                            ),
                            10.height,
                            // Add test button for database storage
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  context.showSnackbarInfo("Testing new database storage approach...");
                                  final success = await context.read<ProfileCubit>().testDatabaseStorage();
                                  if (success) {
                                    context.showSnackbarSuccess("Database storage test successful! Profile pictures should work now.");
                                  } else {
                                    context.showSnackbarError("Database storage test failed. Check console for details.");
                                  }
                                } catch (e) {
                                  context.showSnackbarError("Test failed: ${e.toString()}");
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.green,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: const Text('Test Database Storage'),
                            ),
                            10.height,
                                                         // Add simplified upload test button
                             ElevatedButton(
                               onPressed: () async {
                                 try {
                                   context.showSnackbarInfo("Testing simplified upload...");
                                   final success = await context.read<ProfileCubit>().testSimpleUpload();
                                   if (success) {
                                     context.showSnackbarSuccess("Simplified upload test successful! Upload system is working.");
                                   } else {
                                     context.showSnackbarError("Simplified upload test failed. Check console for details.");
                                   }
                                 } catch (e) {
                                   context.showSnackbarError("Test failed: ${e.toString()}");
                                 }
                               },
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: AppColors.gray2,
                                 foregroundColor: AppColors.white,
                                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                               ),
                               child: const Text('Test Simplified Upload'),
                             ),
                             10.height,
                             // Add new simplified upload method test
                             ElevatedButton(
                               onPressed: () async {
                                 try {
                                   context.showSnackbarInfo("Testing new simplified upload method...");
                                   // Create a test image file
                                   final tempDir = Directory.systemTemp;
                                   final testFile = File('${tempDir.path}/test_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
                                   await testFile.writeAsBytes(List.generate(1000, (i) => i % 256)); // Create test image data
                                   
                                   try {
                                     final success = await context.read<ProfileCubit>().uploadProfilePictureSimple(
                                       XFile(testFile.path)
                                     );
                                     if (success) {
                                       context.showSnackbarSuccess("New upload method test successful! Profile pictures should work now.");
                                     } else {
                                       context.showSnackbarError("New upload method test failed. Check console for details.");
                                     }
                                   } finally {
                                     // Clean up test file
                                     if (await testFile.exists()) {
                                       await testFile.delete();
                                     }
                                   }
                                 } catch (e) {
                                   context.showSnackbarError("Test failed: ${e.toString()}");
                                 }
                               },
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: AppColors.primary,
                                 foregroundColor: AppColors.white,
                                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                               ),
                               child: const Text('Test New Upload Method'),
                             ),
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
        // Validate file size (max 5MB)
        final file = File(pickResult.path);
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) { // 5MB
          throw Exception('Image file is too large. Please select an image smaller than 5MB.');
        }
        
        // Validate file extension
        final extension = pickResult.path.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
          throw Exception('Please select a valid image file (JPG, PNG, or GIF).');
        }
      }
      
      return pickResult;
    } catch (e) {
      print('Error picking file: $e');
      rethrow;
    }
  }

  void updateImage() async {}
}
