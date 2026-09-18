import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class AttachmentConfig {
  final bool showCamera;
  final bool showGallery;
  final bool showAudio;
  final bool showDoc;
  final bool showContact;
  
  final Function(List<File>)? onCameraFilesPicked;
  final Function(List<File>)? onGalleryFilesPicked;
  final Function(List<File>)? onAudioFilesPicked;
  final Function(List<File>)? onDocFilerPicked; // Matches user doc spelling
  final Function(dynamic)? onContactPicked;

  const AttachmentConfig({
    this.showCamera = true,
    this.showGallery = true,
    this.showAudio = false,
    this.showDoc = false,
    this.showContact = false,
    this.onCameraFilesPicked,
    this.onGalleryFilesPicked,
    this.onAudioFilesPicked,
    this.onDocFilerPicked,
    this.onContactPicked,
  });
}

class WhatsAppTextField extends StatefulWidget {
  final String hintText;
  final dynamic onSendTap; // Can be Function() or Function(String)
  final VoidCallback? onSend; // Alias to match SharedMessageInput
  final Function(List<File>)? onAttachmentTap;
  final VoidCallback? onAttachmentPressed; // Alias to match SharedMessageInput
  final VoidCallback? onToggleEmoji; // Matches SharedMessageInput
  final bool showEmojiPicker; // Toggle for built-in or externally handled
  final bool showEmogyIcon; // User spelling in config examples
  final bool emojiPickerVisible; // Matches SharedMessageInput
  final bool showAttachmentIcon;
  final Color? backgroundColor;
  final Color? sendButtonColor;
  final IconData? sendIcon; // Alias for sendButtonIcon
  final IconData? sendButtonIcon;
  final IconData? emojiIcon;
  final IconData? attachmentIcon;
  final int maxLines;
  final int minLines;
  final List<Widget> attachmentIcons;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autoFocus;
  final bool readOnly;
  final bool enabled;
  final bool isBusy; // Matches SharedMessageInput
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted; // Matches SharedMessageInput
  final AttachmentConfig? attachmentConfig;

  const WhatsAppTextField({
    super.key,
    this.hintText = 'Type a message',
    this.onSendTap,
    this.onSend,
    this.onAttachmentTap,
    this.onAttachmentPressed,
    this.onToggleEmoji,
    this.showEmojiPicker = true,
    this.showEmogyIcon = true,
    this.emojiPickerVisible = false,
    this.showAttachmentIcon = true,
    this.backgroundColor,
    this.sendButtonColor,
    this.sendIcon,
    this.sendButtonIcon,
    this.emojiIcon,
    this.attachmentIcon,
    this.maxLines = 5,
    this.minLines = 1,
    this.attachmentIcons = const [],
    this.controller,
    this.focusNode,
    this.autoFocus = false,
    this.readOnly = false,
    this.enabled = true,
    this.isBusy = false,
    this.onChanged,
    this.onSubmitted,
    this.attachmentConfig,
  });

  @override
  State<WhatsAppTextField> createState() => _WhatsAppTextFieldState();
}

class _WhatsAppTextFieldState extends State<WhatsAppTextField> with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isOwnController = false;
  bool _isOwnFocusNode = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _isOwnController = true;
    }

    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _isOwnFocusNode = true;
    }

    _controller.addListener(_textListener);
    _hasText = _controller.text.isNotEmpty;
  }

  void _textListener() {
    final curHasText = _controller.text.isNotEmpty;
    if (curHasText != _hasText) {
      setState(() {
        _hasText = curHasText;
      });
    }
  }

  @override
  void didUpdateWidget(covariant WhatsAppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.emojiPickerVisible != oldWidget.emojiPickerVisible) {
      if (widget.emojiPickerVisible) {
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      } else {
        _focusNode.requestFocus();
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_textListener);
    if (_isOwnController) _controller.dispose();
    if (_isOwnFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (widget.onSendTap != null) {
      if (widget.onSendTap is Function(String)) {
        widget.onSendTap(text);
      } else if (widget.onSendTap is Function()) {
        widget.onSendTap();
      }
    } else if (widget.onSend != null) {
      widget.onSend!();
    }
    
    _controller.clear();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: source, imageQuality: 85);
      if (file != null) {
        final pickedFile = File(file.path);
        
        // Trigger standard and direct attachment callbacks
        if (widget.onAttachmentTap != null) {
          widget.onAttachmentTap!([pickedFile]);
        }
        
        final config = widget.attachmentConfig;
        if (config != null) {
          if (source == ImageSource.camera && config.onCameraFilesPicked != null) {
            config.onCameraFilesPicked!([pickedFile]);
          } else if (source == ImageSource.gallery && config.onGalleryFilesPicked != null) {
            config.onGalleryFilesPicked!([pickedFile]);
          }
        }
      }
    } catch (e) {
      debugPrint('[WhatsAppTextField] Error picking image: $e');
    }
  }

  void _showAttachmentSheet(BuildContext context) {
    // If a custom attachment sheet logic is registered directly (like _showMediaPicker in chatScreen), use that!
    if (widget.onAttachmentPressed != null) {
      widget.onAttachmentPressed!();
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = widget.attachmentConfig ?? const AttachmentConfig();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              spreadRadius: 1,
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              if (widget.attachmentIcons.isNotEmpty) ...[
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: widget.attachmentIcons,
                ),
              ] else ...[
                Wrap(
                  spacing: 24,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: [
                    if (config.showCamera)
                      _buildSheetItem(
                        icon: Icons.camera_alt_rounded,
                        label: 'Camera',
                        color: Colors.pink,
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                    if (config.showGallery)
                      _buildSheetItem(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        color: Colors.purple,
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                    if (config.showAudio)
                      _buildSheetItem(
                        icon: Icons.headphones_rounded,
                        label: 'Audio',
                        color: Colors.orange,
                        onTap: () {
                          if (config.onAudioFilesPicked != null) {
                            config.onAudioFilesPicked!([]);
                          }
                        },
                      ),
                    if (config.showDoc)
                      _buildSheetItem(
                        icon: Icons.description_rounded,
                        label: 'Document',
                        color: Colors.blue,
                        onTap: () {
                          if (config.onDocFilerPicked != null) {
                            config.onDocFilerPicked!([]);
                          }
                        },
                      ),
                    if (config.showContact)
                      _buildSheetItem(
                        icon: Icons.person_rounded,
                        label: 'Contact',
                        color: Colors.teal,
                        onTap: () {
                          if (config.onContactPicked != null) {
                            config.onContactPicked!(null);
                          }
                        },
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color bgColor = widget.backgroundColor ?? 
        (isDark ? const Color(0xFF1F1F1F) : Colors.white);
    
    final Color sendColor = widget.sendButtonColor ?? const Color(0xFF1A8927);
    final IconData sendIconData = widget.sendIcon ?? widget.sendButtonIcon ?? Icons.send_rounded;
    
    // Toggle between keyboard and sentiment emoji icons
    final IconData emojIconData = widget.emojiIcon ?? 
        (widget.emojiPickerVisible ? Icons.keyboard_rounded : Icons.sentiment_satisfied_alt_rounded);
    
    final IconData attachIconData = widget.attachmentIcon ?? Icons.attach_file_rounded;

    return Container(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 6, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Input Field Box
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Emoji Toggle Button
                  if (widget.showEmogyIcon)
                    IconButton(
                      icon: Icon(emojIconData, size: 24),
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      onPressed: () {
                        if (widget.onToggleEmoji != null) {
                          widget.onToggleEmoji!();
                        }
                      },
                      splashRadius: 20,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                    ),

                  // Expanded Input Text Field
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        autofocus: widget.autoFocus,
                        readOnly: widget.readOnly || widget.emojiPickerVisible,
                        showCursor: true,
                        enabled: widget.enabled,
                        keyboardType: widget.emojiPickerVisible
                            ? TextInputType.none
                            : TextInputType.multiline,
                        maxLines: widget.maxLines,
                        minLines: widget.minLines,
                        onTap: () {
                          if (widget.emojiPickerVisible) {
                            if (widget.onToggleEmoji != null) {
                              widget.onToggleEmoji!();
                            }
                          }
                        },
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                            fontSize: 16,
                          ),
                          filled: false,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (val) {
                          if (widget.onChanged != null) widget.onChanged!(val);
                        },
                        onSubmitted: (val) {
                          if (widget.onSubmitted != null) {
                            widget.onSubmitted!(val);
                          } else {
                            _handleSend();
                          }
                        },
                      ),
                    ),
                  ),

                  // Attachment Button
                  if (widget.showAttachmentIcon)
                    IconButton(
                      icon: widget.isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1A8927),
                              ),
                            )
                          : Transform.rotate(
                              angle: -0.7, // Classic paperclip tilt
                              child: Icon(attachIconData, size: 24),
                            ),
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      onPressed: widget.isBusy ? null : () => _showAttachmentSheet(context),
                      splashRadius: 20,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Detached Circular Send Button (WhatsApp-style!)
          GestureDetector(
            onTap: _handleSend,
            child: AnimatedScale(
              scale: _hasText ? 1.0 : 0.94,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _hasText ? sendColor : (isDark ? Colors.grey[800] : Colors.grey[200]),
                  shape: BoxShape.circle,
                  boxShadow: _hasText
                      ? [
                          BoxShadow(
                            color: sendColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: widget.isBusy && _hasText
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _hasText ? sendIconData : Icons.send_rounded, // Shows Mic when empty like WhatsApp
                          color: _hasText 
                              ? Colors.white 
                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          size: 24,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
