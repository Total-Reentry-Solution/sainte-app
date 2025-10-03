import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../components/buttons/primary_button.dart';

// Account type selection screen - where users go after registration
class AccountTypeScreen extends StatefulWidget {
  const AccountTypeScreen({super.key});

  @override
  State<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends State<AccountTypeScreen> {
  String? _selectedAccountType;

  void _handleContinue() {
    if (_selectedAccountType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an account type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('Selected account type: $_selectedAccountType');
    
    // Navigate to the appropriate form based on account type immediately
    if (mounted) {
      try {
        if (_selectedAccountType == 'citizen') {
          context.go('/citizen-form');
        } else if (_selectedAccountType == 'mentor') {
          context.go('/mentor-form');
        } else if (_selectedAccountType == 'admin') {
          context.go('/admin-form');
        }
      } catch (e) {
        print('Navigation error: $e');
        // Fallback navigation
        if (_selectedAccountType == 'citizen') {
          Navigator.of(context).pushReplacementNamed('/citizen-form');
        } else if (_selectedAccountType == 'mentor') {
          Navigator.of(context).pushReplacementNamed('/mentor-form');
        } else if (_selectedAccountType == 'admin') {
          Navigator.of(context).pushReplacementNamed('/admin-form');
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
          // Right side - Light with account type selection
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose your account type',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Select the type of account that best describes you',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Account type options
                  _buildAccountTypeOption(
                    'citizen',
                    'Citizen',
                    'I am looking for support and guidance',
                    Icons.person,
                  ),
                  const SizedBox(height: 20),
                  _buildAccountTypeOption(
                    'mentor',
                    'Mentor',
                    'I want to help and guide others',
                    Icons.school,
                  ),
                  const SizedBox(height: 20),
                  _buildAccountTypeOption(
                    'admin',
                    'Admin',
                    'I manage the platform and users',
                    Icons.admin_panel_settings,
                  ),
                  const SizedBox(height: 40),
                  // Continue button
                  PrimaryButton(
                    text: 'Continue',
                    onPress: _handleContinue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTypeOption(
    String value,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _selectedAccountType == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAccountType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF3AE6BD) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFF3AE6BD).withOpacity(0.1) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF3AE6BD) : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF3AE6BD) : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF3AE6BD),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
