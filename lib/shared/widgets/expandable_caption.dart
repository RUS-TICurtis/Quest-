import 'package:flutter/material.dart';

class ExpandableCaption extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;

  const ExpandableCaption({
    super.key,
    required this.text,
    TextStyle? style,
    TextStyle? textStyle,
    this.maxLines = 2,
  }) : style = style ?? textStyle;

  @override
  State<ExpandableCaption> createState() => _ExpandableCaptionState();
}

class _ExpandableCaptionState extends State<ExpandableCaption> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 200),
        crossFadeState: _isExpanded
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        firstChild: Text(
          widget.text,
          style: widget.style,
          maxLines: widget.maxLines,
          overflow: TextOverflow.ellipsis,
        ),
        secondChild: Container(
          // Constraints to prevent taking full height if inside a flexible column
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
          child: SingleChildScrollView(
            child: Text(
              widget.text,
              style: widget.style,
            ),
          ),
        ),
      ),
    );
  }
}
