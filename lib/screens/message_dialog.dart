import 'package:dating_app/l10n/gen/app_localizations.dart';
import '../theme/app_theme.dart';
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.backgroundGradient(context),
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
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.favorite,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEventLike
                            ? AppLocalizations.of(context)!.md_like_event
                            : AppLocalizations.of(context)!.md_like_user,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isEventLike
                            ? AppLocalizations.of(context)!.md_liked_event
                            : AppLocalizations.of(context)!
                                .md_liked_user(widget.userName),
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
              AppLocalizations.of(context)!.add_message_optional,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _messageController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: widget.isEventLike
                    ? AppLocalizations.of(context)!.md_join_hint
                    : AppLocalizations.of(context)!.md_nice_hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),

            const SizedBox(height: 24),

            // Кнопки
            Row(
              children: [
                Expanded(
                  child: _buildButton(
                    text: AppLocalizations.of(context)!.cancel,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildButton(
                    text: _isLoading
                        ? AppLocalizations.of(context)!.md_sending
                        : AppLocalizations.of(context)!.send,
                    color: Theme.of(context).colorScheme.primary,
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
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
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
