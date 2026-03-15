import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class LiveChatScreen extends StatefulWidget {
  const LiveChatScreen({super.key});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isTyping = false;
  final bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _addInitialMessages();
    _scrollToBottom();
  }

  void _addInitialMessages() {
    setState(() {
      _messages.addAll([
        ChatMessage(
          message:
              'Hello! Welcome to UNI NEST Support. How can I help you today?',
          isUser: false,
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        ChatMessage(
          message:
              'My name is Alex, and I\'ll be assisting you with your vendor account.',
          isUser: false,
          timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
        ),
      ]);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(
        ChatMessage(
          message: userMessage,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
    });

    _scrollToBottom();

    // Simulate support response
    _simulateSupportResponse(userMessage);
  }

  void _simulateSupportResponse(String userMessage) {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      String response = _generateResponse(userMessage);

      setState(() {
        _messages.add(
          ChatMessage(
            message: response,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isTyping = false;
      });

      _scrollToBottom();
    });
  }

  String _generateResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('profile') || lowerMessage.contains('update')) {
      return 'I can help you update your profile! Go to the Profile tab and tap the edit button. You can update your business information, contact details, and other settings there. Is there anything specific about your profile you need help with?';
    } else if (lowerMessage.contains('product') ||
        lowerMessage.contains('add')) {
      return 'To add new products, navigate to the Products tab and tap the "+" button. You\'ll need to provide product details like name, description, price, and images. Make sure to follow our product guidelines. Would you like more specific guidance?';
    } else if (lowerMessage.contains('order') ||
        lowerMessage.contains('customer')) {
      return 'You can view all customer orders in the Orders tab. Each order shows customer details, items ordered, and current status. You can update order statuses and track deliveries from there. Are you having trouble with a specific order?';
    } else if (lowerMessage.contains('password') ||
        lowerMessage.contains('login')) {
      return 'For password changes, go to Profile > Account Actions > Change Password. If you\'re having login issues, I can help reset your password or troubleshoot the problem. What specific issue are you experiencing?';
    } else if (lowerMessage.contains('payment') ||
        lowerMessage.contains('money')) {
      return 'Payment-related questions are handled by our finance team. You can check your payment history in the Payments section. For specific payment issues, I\'ll need to connect you with our finance specialist. Can you provide more details about your payment concern?';
    } else {
      return 'I understand you need help with: "$userMessage". Let me assist you with this. Could you provide more details so I can give you the best solution? If this is about a specific issue, please include any error messages or reference numbers you have.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Live Chat Support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3436),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppTheme.textPrimary),
            onPressed: _showChatInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _isConnected
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: _isConnected ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  _isConnected
                      ? 'Connected to support team'
                      : 'Reconnecting...',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isConnected ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  'Avg response time: 2 min',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                if (index < _messages.length) {
                  return _buildMessageBubble(_messages[index]);
                }
                return const SizedBox.shrink();
              },
            ),
          ),

          // Quick Replies
          _buildQuickReplies(),

          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.support_agent,
                size: 18,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser ? AppTheme.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: message.isUser
                        ? null
                        : Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: message.isUser
                          ? Colors.white
                          : AppTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, size: 18, color: AppTheme.primary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.support_agent, size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        final delay = index * 0.2;
        final animValue = (value - delay).clamp(0.0, 1.0);
        return Transform.scale(
          scale: 0.5 + (animValue * 0.5),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickReplies() {
    final quickReplies = [
      'How to update profile?',
      'Add new products',
      'View orders',
      'Payment issues',
      'Technical support',
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: quickReplies.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton(
              onPressed: () {
                _messageController.text = quickReplies[index];
                _sendMessage();
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: Text(
                quickReplies[index],
                style: TextStyle(fontSize: 12, color: AppTheme.primary),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: AppTheme.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _showChatInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat Support Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Support Team: Alex'),
            const SizedBox(height: 8),
            const Text('Status: Online'),
            const SizedBox(height: 8),
            const Text('Average Response Time: 2 minutes'),
            const SizedBox(height: 8),
            const Text('Working Hours: 24/7'),
            const SizedBox(height: 16),
            Text(
              'This is a simulated chat for demonstration purposes. In production, this would connect to a real chat service.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String message;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.message,
    required this.isUser,
    required this.timestamp,
  });
}
