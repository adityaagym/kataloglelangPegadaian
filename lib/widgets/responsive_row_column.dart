import 'package:flutter/material.dart';

class ResponsiveRowColumn extends StatelessWidget {
  final Widget left;
  final Widget right;
  final double spacing;
  final bool isPortrait;

  const ResponsiveRowColumn({
    super.key,
    required this.left,
    required this.right,
    required this.isPortrait,
    this.spacing = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (isPortrait) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          left,
          SizedBox(height: spacing),
          right,
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          SizedBox(width: spacing),
          Expanded(child: right),
        ],
      );
    }
  }
}
