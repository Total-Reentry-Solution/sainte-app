/*
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reentry/core/theme/colors.dart';

import 'dividerv1.dart';

class RichTextInputField extends StatelessWidget {
  const RichTextInputField({
    required this.controller,
    super.key,
    this.borderColor,
    this.maxHeight,
    this.maxWidth,
    this.padding,
  });

  final Color? borderColor;
  final double? maxHeight;
  final double? maxWidth;
  final QuillController controller;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? AppColors.inputBorderColor;
    return Theme(
      data: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      child: Container(
        constraints: BoxConstraints(
          minHeight: 52,
          maxHeight: maxHeight ?? 376,
          maxWidth: maxWidth ?? double.infinity,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: border, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: QuillEditor.basic(
                controller: controller,
              ),
            ),
            DividerV1(color: border),
            Padding(
              padding: const EdgeInsets.all(8),
              child: QuillToolbar.basic(
                controller: controller,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/
