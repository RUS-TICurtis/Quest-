// ignore_for_file: implementation_imports

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:emoji_picker_flutter/src/emoji_picker_internal_utils.dart';
import 'package:emoji_picker_flutter/locales/default_emoji_set_locale.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quest/core/theme/app_colors_extension.dart';

/// A themed, app-wide emoji picker backed by [emoji_picker_flutter].
///
/// Styled similarly to the ProVideoEditorScreen's emoji picker with
/// ButtonMode.CUPERTINO and a dark/black theme.
///
/// Refined with persistent custom skin tone selection on first tap,
/// and long press fallback for changing preferences.
///
/// **Usage:**
/// ```dart
/// if (_showEmojiPicker)
///   AppEmojiPicker(
///     textEditingController: _textEditingController,
///     onEmojiSelected: (emoji) => setState(() => _text += emoji),
///   )
/// ```
class AppEmojiPicker extends StatefulWidget {
  /// Called with the raw emoji string (e.g. "😀") when the user taps one.
  final ValueChanged<String> onEmojiSelected;

  /// Optional text controller to automatically handle insertions and backspaces.
  final TextEditingController? textEditingController;

  /// Height of the picker widget. Defaults to 300.
  final double height;

  const AppEmojiPicker({
    super.key,
    required this.onEmojiSelected,
    this.textEditingController,
    this.height = 300,
  });

  @override
  State<AppEmojiPicker> createState() => _AppEmojiPickerState();
}

class _AppEmojiPickerState extends State<AppEmojiPicker> {
  bool _isLoaded = false;
  Map<String, String> _preferredSkinTones = {};
  EmojiViewState? _currentPickerState;
  AppCustomSearchViewState? _currentSearchViewState;

  final List<String> _skinToneModifiers = [
    '🏻', // Type-1-2 (\u{1F3FB})
    '🏼', // Type-3 (\u{1F3FC})
    '🏽', // Type-4 (\u{1F3FD})
    '🏾', // Type-5 (\u{1F3FE})
    '🏿', // Type-6 (\u{1F3FF})
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('app_emoji_skin_tone_preferences');
      if (jsonStr != null) {
        final Map<String, dynamic> data = json.decode(jsonStr) as Map<String, dynamic>;
        setState(() {
          _preferredSkinTones = data.map((key, value) => MapEntry(key, value.toString()));
          _isLoaded = true;
        });
      } else {
        setState(() {
          _isLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading emoji preferences: $e');
      setState(() {
        _isLoaded = true;
      });
    }
  }

  Future<void> _savePreference(String baseEmoji, String skinTonedEmoji) async {
    setState(() {
      _preferredSkinTones[baseEmoji] = skinTonedEmoji;
    });

    // Update the CategoryEmoji grid in place to immediately shift the cell's visually rendered emoji
    final pickerState = _currentPickerState;
    if (pickerState != null) {
      for (var i = 0; i < pickerState.categoryEmoji.length; i++) {
        final categoryEmoji = pickerState.categoryEmoji[i];
        final emojiList = categoryEmoji.emoji;
        for (var j = 0; j < emojiList.length; j++) {
          final currentEmoji = emojiList[j];
          if (_getBaseEmoji(currentEmoji.emoji) == baseEmoji) {
            emojiList[j] = currentEmoji.copyWith(emoji: skinTonedEmoji);
          }
        }
      }
    }

    // Update the active search view results list in place if active
    final searchViewState = _currentSearchViewState;
    if (searchViewState != null) {
      for (var i = 0; i < searchViewState.results.length; i++) {
        final currentEmoji = searchViewState.results[i];
        if (_getBaseEmoji(currentEmoji.emoji) == baseEmoji) {
          searchViewState.results[i] = currentEmoji.copyWith(emoji: skinTonedEmoji);
          searchViewState.links[skinTonedEmoji] = LayerLink();
        }
      }
      // Trigger repaint of search results
      searchViewState.setState(() {});
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_emoji_skin_tone_preferences', json.encode(_preferredSkinTones));
    } catch (e) {
      debugPrint('Error saving emoji preferences: $e');
    }
  }

  bool _hasSkinToneModifier(String text) {
    for (final modifier in _skinToneModifiers) {
      if (text.contains(modifier)) return true;
    }
    return false;
  }

  String _getBaseEmoji(String text) {
    final emojiObj = Emoji(text, '');
    final internalUtils = EmojiPickerInternalUtils();
    return internalUtils.removeSkinTone(emojiObj).emoji;
  }

  List<CategoryEmoji> _getCustomEmojiSet(Locale locale) {
    final defaultSet = getDefaultEmojiLocale(locale);
    return defaultSet.map((categoryEmoji) {
      final updatedEmojis = categoryEmoji.emoji.map((emoji) {
        final base = _getBaseEmoji(emoji.emoji);
        if (_preferredSkinTones.containsKey(base)) {
          final preferred = _preferredSkinTones[base]!;
          return emoji.copyWith(emoji: preferred);
        }
        return emoji;
      }).toList();
      return CategoryEmoji(categoryEmoji.category, updatedEmojis);
    }).toList();
  }

  void _selectEmoji(String emojiStr) {
    if (widget.textEditingController != null) {
      final controller = widget.textEditingController!;
      final value = controller.value;
      final start = value.selection.start;
      final end = value.selection.end;

      if (start < 0 || end < 0) {
        controller.text = controller.text + emojiStr;
        controller.selection = TextSelection.collapsed(offset: controller.text.length);
      } else {
        final newText = value.text.replaceRange(start, end, emojiStr);
        controller.value = value.copyWith(
          text: newText,
          selection: TextSelection.collapsed(offset: start + emojiStr.length),
        );
      }
    }

    widget.onEmojiSelected(emojiStr);
  }

  void _handleEmojiSelected(Category? category, Emoji emoji) {
    final rawEmoji = emoji.emoji;
    final supportsSkinTone = emoji.hasSkinTone;

    if (!supportsSkinTone) {
      _selectEmoji(rawEmoji);
      return;
    }

    final hasModifier = _hasSkinToneModifier(rawEmoji);
    final baseEmoji = _getBaseEmoji(rawEmoji);

    // Check if the tap came from the native long-press popup dialog
    final stackTraceStr = StackTrace.current.toString();
    final isFromPopup = stackTraceStr.contains('_onSkinTonedEmojiSelected') ||
                        stackTraceStr.contains('SkinToneOverlay') ||
                        stackTraceStr.contains('skin_tone_overlay');

    if (isFromPopup || (hasModifier && rawEmoji != _preferredSkinTones[baseEmoji])) {
      // User chose a specific variant (or default/yellow) from the native long-press popup,
      // or clicked a new variant from a sheet.
      _savePreference(baseEmoji, rawEmoji);
      _selectEmoji(rawEmoji);
      return;
    }

    // It's the base emoji (e.g. yellow thumbs up)
    if (_preferredSkinTones.containsKey(baseEmoji)) {
      final preferred = _preferredSkinTones[baseEmoji]!;
      _selectEmoji(preferred);
    } else {
      // First time selecting this skin-tone emoji!
      _showSkinToneBottomSheet(context, baseEmoji);
    }
  }

  void _showSkinToneBottomSheet(BuildContext context, String baseEmoji) {
    final utils = EmojiPickerUtils();
    final baseEmojiObj = Emoji(baseEmoji, '');

    final variants = [
      baseEmoji,
      utils.applySkinTone(baseEmojiObj, SkinTone.light).emoji,
      utils.applySkinTone(baseEmojiObj, SkinTone.mediumLight).emoji,
      utils.applySkinTone(baseEmojiObj, SkinTone.medium).emoji,
      utils.applySkinTone(baseEmojiObj, SkinTone.mediumDark).emoji,
      utils.applySkinTone(baseEmojiObj, SkinTone.dark).emoji,
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 16,
                spreadRadius: 4,
              ),
            ],
            border: Border.all(
              color: context.colors.border,
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Choose Skin Tone',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'This will be saved as your default. Long press to change it later.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: context.colors.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: variants.map((variant) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              _savePreference(baseEmoji, variant);
                              _selectEmoji(variant);
                            },
                            borderRadius: BorderRadius.circular(16),
                            hoverColor: context.colors.questBlue.withValues(alpha: 0.1),
                            highlightColor: context.colors.questBlue.withValues(alpha: 0.15),
                            splashColor: context.colors.questBlue.withValues(alpha: 0.1),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: context.colors.border,
                                  width: 1,
                                ),
                                color: context.colors.surface.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                variant,
                                style: const TextStyle(fontSize: 30),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fallback widget if mapping preferences are not loaded yet
    if (!_isLoaded) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(context.colors.questBlue),
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: EmojiPicker(
        onEmojiSelected: _handleEmojiSelected,
        customWidget: (config, state, showSearchBar) {
          _currentPickerState = state;
          return DefaultEmojiPickerView(config, state, showSearchBar);
        },
        onBackspacePressed: () {
          if (widget.textEditingController != null) {
            final controller = widget.textEditingController!;
            final text = controller.value.text;
            var cursorPosition = controller.selection.base.offset;

            if (cursorPosition < 0) {
              controller.selection = TextSelection.collapsed(offset: text.length);
              cursorPosition = text.length;
            }

            if (cursorPosition > 0) {
              final selection = controller.value.selection;
              final newTextBeforeCursor =
                  selection.textBefore(text).characters.skipLast(1).toString();
              controller.value = controller.value.copyWith(
                text: newTextBeforeCursor + selection.textAfter(text),
                selection: TextSelection.fromPosition(
                  TextPosition(offset: newTextBeforeCursor.length),
                ),
              );
            }
          }
        },
        config: Config(
          checkPlatformCompatibility: false,
          emojiSet: _getCustomEmojiSet,
          emojiViewConfig: EmojiViewConfig(
            buttonMode: ButtonMode.CUPERTINO,
            backgroundColor: context.colors.background,
          ),
          categoryViewConfig: CategoryViewConfig(
            indicatorColor: context.colors.questBlue,
            iconColorSelected: context.colors.questBlue,
            iconColor: context.colors.textMuted,
            backgroundColor: context.colors.background,
          ),
          bottomActionBarConfig: BottomActionBarConfig(
            backgroundColor: context.colors.surface,
            buttonColor: Colors.transparent,
            buttonIconColor: context.colors.textPrimary,
          ),
          searchViewConfig: SearchViewConfig(
            backgroundColor: context.colors.surface,
            buttonIconColor: context.colors.textPrimary,
            inputTextStyle: TextStyle(
              color: context.colors.textPrimary,
            ),
            hintText: 'Search emojis...',
            hintTextStyle: TextStyle(
              color: context.colors.textMuted,
            ),
            customSearchView: (config, state, showEmojiView) {
              return AppCustomSearchView(config, state, showEmojiView);
            },
          ),
          skinToneConfig: SkinToneConfig(
            enabled: true,
            dialogBackgroundColor: context.colors.surface,
            indicatorColor: context.colors.questBlue,
          ),
        ),
      ),
    );
  }
}

class AppCustomSearchView extends SearchView {
  const AppCustomSearchView(super.config, super.state, super.showEmojiView, {super.key});

  @override
  AppCustomSearchViewState createState() => AppCustomSearchViewState();
}

class AppCustomSearchViewState extends SearchViewState {
  @override
  void initState() {
    super.initState();
    final pickerState = context.findAncestorStateOfType<_AppEmojiPickerState>();
    if (pickerState != null) {
      pickerState._currentSearchViewState = this;
    }
  }

  @override
  void dispose() {
    final pickerState = context.findAncestorStateOfType<_AppEmojiPickerState>();
    if (pickerState != null && pickerState._currentSearchViewState == this) {
      pickerState._currentSearchViewState = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final emojiSize =
          widget.config.emojiViewConfig.getEmojiSize(constraints.maxWidth);
      final emojiBoxSize =
          widget.config.emojiViewConfig.getEmojiBoxSize(constraints.maxWidth);

      return Container(
        color: widget.config.searchViewConfig.backgroundColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              child: SizedBox(
                height: emojiBoxSize + 8.0,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  scrollDirection: Axis.horizontal,
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    return buildEmoji(
                      results[index],
                      emojiSize,
                      emojiBoxSize,
                    );
                  },
                ),
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    widget.showEmojiView();
                  },
                  color: widget.config.searchViewConfig.buttonIconColor,
                  icon: const Icon(
                    Icons.arrow_back,
                  ),
                ),
                Expanded(
                  child: TextField(
                    onChanged: onTextInputChanged,
                    focusNode: focusNode,
                    style: widget.config.searchViewConfig.inputTextStyle,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: widget.config.searchViewConfig.hintText,
                      hintStyle: widget.config.searchViewConfig.hintTextStyle,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 20), // Reduces the textfield width by 20px
              ],
            ),
          ],
        ),
      );
    });
  }
}
