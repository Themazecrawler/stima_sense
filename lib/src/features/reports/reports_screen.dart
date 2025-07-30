import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stima_sense/src/components/shared/gradient_button.dart';
import 'package:stima_sense/src/services/firebase_service.dart';
import 'package:stima_sense/src/components/shared/bottom_nav_bar.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  double _predictionConfidence = 0;
  String _predictionRiskLevel = 'Medium';
  double _predictedDuration = 2.0;
  int _currentIndex = 1;
  List<Map<String, dynamic>> _reports = [];
  Map<String, bool> _likedReports = {};
  Map<String, List<Map<String, dynamic>>> _reportComments = {};

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reports')
          .orderBy('timestamp', descending: true)
          .get();

      final reports = <Map<String, dynamic>>[];
      final likedReports = <String, bool>{};
      final reportComments = <String, List<Map<String, dynamic>>>{};

      for (final doc in snapshot.docs) {
        final report = doc.data();
        report['id'] = doc.id;
        reports.add(report);

        // Check if current user liked this report
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          final likeDoc = await FirebaseFirestore.instance
              .collection('reports')
              .doc(doc.id)
              .collection('likes')
              .doc(userId)
              .get();
          likedReports[doc.id] = likeDoc.exists;
        }

        // Load comments for this report
        final commentsSnapshot = await FirebaseFirestore.instance
            .collection('reports')
            .doc(doc.id)
            .collection('comments')
            .orderBy('timestamp', descending: true)
            .get();

        final comments = <Map<String, dynamic>>[];
        for (final commentDoc in commentsSnapshot.docs) {
          final comment = commentDoc.data();
          comment['id'] = commentDoc.id;
          comments.add(comment);
        }
        reportComments[doc.id] = comments;
      }

      if (mounted) {
        setState(() {
          _reports = reports;
          _likedReports = likedReports;
          _reportComments = reportComments;
        });
      }
    } catch (e) {
      debugPrint('Error loading reports: $e');
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final reportData = {
        'userId': user.uid,
        'username': user.displayName ?? user.email?.split('@')[0] ?? 'User',
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
      };

      // Submit to Firebase
      await FirebaseService.submitReport(reportData);

      // Get AI prediction
      final predictionData = {
        'Event Month': DateTime.now().month,
        'Event Hour': DateTime.now().hour,
        'Outage Duration (hrs)': 2.0,
      };

      final prediction = await FirebaseService.predictOutage(predictionData);
      if (prediction.containsKey('confidence')) {
        setState(() {
          _predictionConfidence = prediction['confidence'] * 100;
          _predictionRiskLevel = prediction['riskLevel'] ?? 'Medium';
          _predictedDuration = prediction['predictedDuration'] ?? 2.0;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _formKey.currentState!.reset();
        _descriptionController.clear();
        _locationController.clear();

        // Reload reports
        _loadReports();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _likeReport(String reportId) async {
    try {
      await FirebaseService.likeReport(reportId);

      // Update local state immediately for better UX
      setState(() {
        _likedReports[reportId] = !(_likedReports[reportId] ?? false);
      });

      // Reload reports to get updated counts
      _loadReports();
    } catch (e) {
      debugPrint('Error liking report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error liking report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addComment(String reportId, String comment) async {
    try {
      await FirebaseService.addComment(reportId, {'text': comment});

      // Reload reports to update comments
      _loadReports();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCommentDialog(String reportId) {
    _commentController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(
          controller: _commentController,
          decoration: const InputDecoration(
            hintText: 'Enter your comment...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_commentController.text.trim().isNotEmpty) {
                _addComment(reportId, _commentController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        // Already on reports
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/map');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/history');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/account');
        break;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return 'Just now';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Reports',
          style: TextStyle(
            color: Color(0xFF8B2192),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Form
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Report Outage',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          hintText: 'Describe the outage...',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please describe the outage';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          border: OutlineInputBorder(),
                          hintText: 'Enter location...',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter location';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      GradientButton(
                        onPressed: _isSubmitting ? null : _submitReport,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Submit Report',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                      if (_predictionConfidence > 0) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _predictionConfidence > 70
                                ? Colors.orange.shade50
                                : _predictionConfidence > 40
                                    ? Colors.yellow.shade50
                                    : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _predictionConfidence > 70
                                  ? Colors.orange
                                  : _predictionConfidence > 40
                                      ? Colors.yellow.shade700
                                      : Colors.green,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Prediction: ${_predictionConfidence.toStringAsFixed(1)}% confidence',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('Risk Level: $_predictionRiskLevel'),
                              Text(
                                  'Predicted Duration: ${_predictedDuration.toStringAsFixed(1)} hours'),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Recent Reports
            const Text(
              'Recent Reports',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Reports List
            ..._reports.map((report) {
              final isLiked = _likedReports[report['id']] ?? false;
              final comments = _reportComments[report['id']] ?? [];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF8B2192),
                            child: Text(
                              report['username'][0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  report['username'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _formatTimestamp(report['timestamp']),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
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
                        report['description'],
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        report['location'],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Engagement buttons
                      Row(
                        children: [
                          InkWell(
                            onTap: () => _likeReport(report['id']),
                            child: Row(
                              children: [
                                Icon(
                                  isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isLiked ? Colors.red : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${report['likes']?.length ?? 0}',
                                  style: TextStyle(
                                    color: isLiked ? Colors.red : Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          InkWell(
                            onTap: () => _showCommentDialog(report['id']),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.comment,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${comments.length}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Show comments if any
                      if (comments.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        ...comments.take(3).map((comment) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.grey.shade300,
                                    child: Text(
                                      comment['username']?[0]?.toUpperCase() ??
                                          'U',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          comment['username'] ?? 'User',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          comment['text'] ?? '',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        Text(
                                          _formatTimestamp(
                                              comment['timestamp']),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        if (comments.length > 3)
                          TextButton(
                            onPressed: () {
                              // Show all comments dialog
                            },
                            child: Text('View all ${comments.length} comments'),
                          ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
