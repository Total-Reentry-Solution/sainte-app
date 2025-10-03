import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../components/input/input_field.dart';
import '../../components/buttons/primary_button.dart';

// Citizen form screen - where citizens fill out their profile
class CitizenFormScreen extends StatefulWidget {
  const CitizenFormScreen({super.key});

  @override
  State<CitizenFormScreen> createState() => _CitizenFormScreenState();
}

class _CitizenFormScreenState extends State<CitizenFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      print('Citizen Form Submitted:');
      print('First Name: ${_firstNameController.text}');
      print('Last Name: ${_lastNameController.text}');
      print('Phone: ${_phoneController.text}');
      print('Address: ${_addressController.text}');
      print('City: ${_cityController.text}');
      print('State: ${_stateController.text}');
      print('Zip Code: ${_zipCodeController.text}');
      
      // Navigate to home immediately after successful form submission
      if (mounted) {
        try {
          context.go('/home');
        } catch (e) {
          print('Navigation error: $e');
          // Fallback navigation
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Left side - Dark with single large people image
          Expanded(
            child: Container(
              color: Colors.black,
              child: Stack(
                children: [
                  // Single large people image centered
                  const Center(
                    child: SizedBox(
                      width: 432,
                      child: Image(
                        image: AssetImage('assets/images/People.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  // Dark overlay
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  // Content
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Sainte title at top
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Text(
                            'Sainte',
                            style: TextStyle(
                              color: const Color(0xFF3AE6BD),
                              fontSize: 54,
                              fontFamily: 'InterBold',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // "Everybody is a sainte" text at bottom
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Text(
                            "Everybody is a sainte",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Right side - Light with citizen form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Complete your profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Please provide your personal information to get started',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Personal Information
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // First Name and Last Name in a row
                    Row(
                      children: [
                        Expanded(
                          child: InputField(
                            label: 'First Name',
                            hint: 'Enter your first name',
                            controller: _firstNameController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your first name';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: InputField(
                            label: 'Last Name',
                            hint: 'Enter your last name',
                            controller: _lastNameController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your last name';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    // Phone
                    InputField(
                      label: 'Phone Number',
                      hint: 'Enter your phone number',
                      controller: _phoneController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    // Address Information
                    const Text(
                      'Address Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Address
                    InputField(
                      label: 'Address',
                      hint: 'Enter your address',
                      controller: _addressController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    // City, State, Zip in a row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: InputField(
                            label: 'City',
                            hint: 'Enter your city',
                            controller: _cityController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your city';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: InputField(
                            label: 'State',
                            hint: 'State',
                            controller: _stateController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your state';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: InputField(
                            label: 'Zip Code',
                            hint: 'Zip',
                            controller: _zipCodeController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your zip code';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // Submit button
                    PrimaryButton(
                      text: 'Complete Profile',
                      onPress: _handleSubmit,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
