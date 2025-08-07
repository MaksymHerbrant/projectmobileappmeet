import 'package:flutter/material.dart';

class MessageDialog extends StatefulWidget {
  final String userName;
  final bool isEventLike;

  const MessageDialog({
    Key? key,
    required this.userName,
    this.isEventLike = false,
  }) : super(key: key);

  @override
  State<MessageDialog> createState() => _MessageDialogState();
}

class _MessageDialogState extends State<MessageDialog> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF3E5F5)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Color(0xFFE91E63),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEventLike ? 'Лайк події' : 'Лайк користувача',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isEventLike 
                            ? 'Ви лайкнули подію'
                            : 'Ви лайкнули ${widget.userName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Повідомлення
            Text(
              'Додайте повідомлення (необов\'язково)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _messageController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: widget.isEventLike 
                    ? 'Напишіть, чому хочете приєднатися до події...'
                    : 'Напишіть щось приємне...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE91E63)),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Кнопки
            Row(
              children: [
                Expanded(
                  child: _buildButton(
                    text: 'Скасувати',
                    color: Colors.grey,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildButton(
                    text: _isLoading ? 'Відправляємо...' : 'Відправити',
                    color: const Color(0xFFE91E63),
                    onTap: _isLoading ? null : _handleSend,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: onTap != null ? color : color.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _handleSend() async {
    if (_messageController.text.trim().isEmpty) {
      // Відправляємо тільки лайк без повідомлення
      Navigator.of(context).pop({
        'action': 'like',
        'message': null,
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Імітація завантаження
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    Navigator.of(context).pop({
      'action': 'like_with_message',
      'message': _messageController.text.trim(),
    });
  }
} 