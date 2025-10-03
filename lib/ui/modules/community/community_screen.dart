import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Clean Community Screen
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _selectedTab = 'posts';

  final List<CommunityPost> _posts = [
    CommunityPost(
      id: '1',
      author: 'John Doe',
      authorAvatar: null,
      content: 'Just completed my first week at my new job! The support from this community has been incredible. Thank you all for the encouragement!',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      likes: 15,
      comments: 8,
      isLiked: false,
    ),
    CommunityPost(
      id: '2',
      author: 'Sarah Johnson',
      authorAvatar: null,
      content: 'Looking for advice on housing options in the downtown area. Any recommendations for affordable apartments?',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      likes: 7,
      comments: 12,
      isLiked: true,
    ),
    CommunityPost(
      id: '3',
      author: 'Mike Wilson',
      authorAvatar: null,
      content: 'Sharing a great resource I found: Free online courses for job skills training. Check out the link in the comments!',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      likes: 23,
      comments: 5,
      isLiked: false,
    ),
  ];

  final List<CommunityEvent> _events = [
    CommunityEvent(
      id: '1',
      title: 'Job Fair 2024',
      description: 'Annual job fair with over 50 employers looking to hire reentry citizens',
      date: DateTime.now().add(const Duration(days: 7)),
      location: 'Convention Center',
      attendees: 150,
      maxAttendees: 200,
    ),
    CommunityEvent(
      id: '2',
      title: 'Financial Literacy Workshop',
      description: 'Learn about budgeting, credit, and financial planning for your future',
      date: DateTime.now().add(const Duration(days: 14)),
      location: 'Community Center',
      attendees: 45,
      maxAttendees: 50,
    ),
    CommunityEvent(
      id: '3',
      title: 'Mentor Meet & Greet',
      description: 'Connect with experienced mentors who can guide you on your journey',
      date: DateTime.now().add(const Duration(days: 21)),
      location: 'Library Meeting Room',
      attendees: 30,
      maxAttendees: 40,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Community',
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
          IconButton(
            onPressed: () => _showCreatePostDialog(context),
            icon: const Icon(Icons.add, color: Colors.black),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildTab('posts', 'Posts'),
                ),
                Expanded(
                  child: _buildTab('events', 'Events'),
                ),
                Expanded(
                  child: _buildTab('groups', 'Groups'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String value, String label) {
    final isSelected = _selectedTab == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF3AE6BD) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? const Color(0xFF3AE6BD) : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 'posts':
        return _buildPostsTab();
      case 'events':
        return _buildEventsTab();
      case 'groups':
        return _buildGroupsTab();
      default:
        return _buildPostsTab();
    }
  }

  Widget _buildPostsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return _buildPostCard(post);
      },
    );
  }

  Widget _buildEventsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildGroupsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Groups feature coming soon!',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF3AE6BD),
                  child: post.authorAvatar != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            post.authorAvatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Text(
                                post.author[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        )
                      : Text(
                          post.author[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatTimestamp(post.timestamp),
                        style: const TextStyle(
                          color: Color(0xFF3AE6BD),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Post Content
            Text(
              post.content,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Actions
            Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleLike(post.id),
                  child: Row(
                    children: [
                      Icon(
                        post.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: post.isLiked ? Colors.red : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post.likes.toString(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () => _showComments(post.id),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.comment_outlined,
                        color: Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post.comments.toString(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _sharePost(post.id),
                  child: const Icon(
                    Icons.share_outlined,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(CommunityEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3AE6BD).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Icon(
                    Icons.event,
                    color: Color(0xFF3AE6BD),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatEventDate(event.date),
                        style: const TextStyle(
                          color: Color(0xFF3AE6BD),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              event.description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  event.location,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  '${event.attendees}/${event.maxAttendees} attending',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _joinEvent(event.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3AE6BD),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text('Join Event'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => _viewEventDetails(event.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3AE6BD),
                    side: const BorderSide(color: Color(0xFF3AE6BD)),
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text('Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatEventDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days from now';
    } else if (difference.inDays == 0) {
      return 'Today';
    } else {
      return '${-difference.inDays} days ago';
    }
  }

  void _toggleLike(String postId) {
    setState(() {
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        final post = _posts[postIndex];
        _posts[postIndex] = CommunityPost(
          id: post.id,
          author: post.author,
          authorAvatar: post.authorAvatar,
          content: post.content,
          timestamp: post.timestamp,
          likes: post.isLiked ? post.likes - 1 : post.likes + 1,
          comments: post.comments,
          isLiked: !post.isLiked,
        );
      }
    });
  }

  void _showComments(String postId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comments feature coming soon!'),
        backgroundColor: Color(0xFF3AE6BD),
      ),
    );
  }

  void _sharePost(String postId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature coming soon!'),
        backgroundColor: Color(0xFF3AE6BD),
      ),
    );
  }

  void _joinEvent(String eventId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Event joining feature coming soon!'),
        backgroundColor: Color(0xFF3AE6BD),
      ),
    );
  }

  void _viewEventDetails(String eventId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Event details feature coming soon!'),
        backgroundColor: Color(0xFF3AE6BD),
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Create Post',
            style: TextStyle(
              color: Color(0xFF3AE6BD),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'This feature will allow you to create posts and share updates with the community.',
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
                'OK',
                style: TextStyle(
                  color: Color(0xFF3AE6BD),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Data Models
class CommunityPost {
  final String id;
  final String author;
  final String? authorAvatar;
  final String content;
  final DateTime timestamp;
  final int likes;
  final int comments;
  final bool isLiked;

  CommunityPost({
    required this.id,
    required this.author,
    this.authorAvatar,
    required this.content,
    required this.timestamp,
    required this.likes,
    required this.comments,
    required this.isLiked,
  });
}

class CommunityEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final int attendees;
  final int maxAttendees;

  CommunityEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.attendees,
    required this.maxAttendees,
  });
}
