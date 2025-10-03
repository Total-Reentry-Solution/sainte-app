import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../components/input/input_field.dart';
import '../../components/buttons/primary_button.dart';

// Clean Support Screen
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'general';

  final List<SupportCategory> _categories = [
    SupportCategory(id: 'general', name: 'General Support', icon: Icons.help_outline),
    SupportCategory(id: 'technical', name: 'Technical Issues', icon: Icons.bug_report),
    SupportCategory(id: 'account', name: 'Account Issues', icon: Icons.account_circle),
    SupportCategory(id: 'billing', name: 'Billing & Payments', icon: Icons.payment),
    SupportCategory(id: 'feature', name: 'Feature Request', icon: Icons.lightbulb_outline),
    SupportCategory(id: 'other', name: 'Other', icon: Icons.more_horiz),
  ];

  final List<FAQ> _faqs = [
    FAQ(
      id: '1',
      question: 'How do I reset my password?',
      answer: 'To reset your password, go to the login screen and click "Forgot Password". Enter your email address and follow the instructions sent to your email.',
    ),
    FAQ(
      id: '2',
      question: 'How do I update my profile information?',
      answer: 'You can update your profile information by going to the Profile section in the app. Click the edit button and make your changes.',
    ),
    FAQ(
      id: '3',
      question: 'How do I schedule an appointment?',
      answer: 'To schedule an appointment, go to the Appointments section and click the "+" button. Select your preferred date and time.',
    ),
    FAQ(
      id: '4',
      question: 'How do I contact my mentor?',
      answer: 'You can contact your mentor through the Messages section. Find your mentor in the conversations list and start a new message.',
    ),
    FAQ(
      id: '5',
      question: 'What resources are available?',
      answer: 'We have a comprehensive resource library including job training, housing assistance, education programs, and more. Check the Resources section.',
    ),
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Support',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Support Options
            _buildSupportOptions(),
            
            const SizedBox(height: 32),
            
            // FAQ Section
            _buildFAQSection(),
            
            const SizedBox(height: 32),
            
            // Contact Form
            _buildContactForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Get Help',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildSupportCard(
                icon: Icons.phone,
                title: 'Call Support',
                subtitle: '24/7 Phone Support',
                color: const Color(0xFF3AE6BD),
                onTap: () => _callSupport(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSupportCard(
                icon: Icons.email,
                title: 'Email Support',
                subtitle: 'Get help via email',
                color: const Color(0xFF3498DB),
                onTap: () => _emailSupport(),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildSupportCard(
                icon: Icons.chat,
                title: 'Live Chat',
                subtitle: 'Chat with support',
                color: const Color(0xFFE74C3C),
                onTap: () => _liveChat(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSupportCard(
                icon: Icons.video_call,
                title: 'Video Call',
                subtitle: 'Face-to-face support',
                color: const Color(0xFF9B59B6),
                onTap: () => _videoCall(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSupportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frequently Asked Questions',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        ..._faqs.map((faq) => _buildFAQItem(faq)).toList(),
      ],
    );
  }

  Widget _buildFAQItem(FAQ faq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ExpansionTile(
        title: Text(
          faq.question,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              faq.answer,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Us',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Form(
          key: _formKey,
          child: Column(
            children: [
              // Category Selection
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category.id,
                    child: Row(
                      children: [
                        Icon(category.icon, size: 20),
                        const SizedBox(width: 8),
                        Text(category.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Subject
              InputField(
                controller: _subjectController,
                label: 'Subject',
                hint: 'Enter subject',
                validator: (value) => value?.isEmpty == true ? 'Subject is required' : null,
              ),
              
              const SizedBox(height: 16),
              
              // Message
              InputField(
                controller: _messageController,
                label: 'Message',
                hint: 'Enter your message',
                validator: (value) => value?.isEmpty == true ? 'Message is required' : null,
              ),
              
              const SizedBox(height: 24),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: 'Send Message',
                  onPress: _submitSupportRequest,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _callSupport() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Call Support',
            style: TextStyle(
              color: Color(0xFF3AE6BD),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Call our support team at (555) 123-4567 for immediate assistance.',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implement phone call functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening phone app...'),
                    backgroundColor: Color(0xFF3AE6BD),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3AE6BD),
                foregroundColor: Colors.white,
              ),
              child: const Text('Call'),
            ),
          ],
        );
      },
    );
  }

  void _emailSupport() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Email Support',
            style: TextStyle(
              color: Color(0xFF3AE6BD),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Send us an email at support@sainte.com and we\'ll get back to you within 24 hours.',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implement email functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening email app...'),
                    backgroundColor: Color(0xFF3AE6BD),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3AE6BD),
                foregroundColor: Colors.white,
              ),
              child: const Text('Email'),
            ),
          ],
        );
      },
    );
  }

  void _liveChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Live chat feature coming soon!'),
        backgroundColor: Color(0xFF3AE6BD),
      ),
    );
  }

  void _videoCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Video call feature coming soon!'),
        backgroundColor: Color(0xFF3AE6BD),
      ),
    );
  }

  void _submitSupportRequest() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement support request submission
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Support request submitted successfully!'),
          backgroundColor: Color(0xFF3AE6BD),
        ),
      );
      
      // Clear form
      _subjectController.clear();
      _messageController.clear();
      setState(() {
        _selectedCategory = 'general';
      });
    }
  }
}

// Data Models
class SupportCategory {
  final String id;
  final String name;
  final IconData icon;

  SupportCategory({
    required this.id,
    required this.name,
    required this.icon,
  });
}

class FAQ {
  final String id;
  final String question;
  final String answer;

  FAQ({
    required this.id,
    required this.question,
    required this.answer,
  });
}
