import 'package:account_book/app/data/constants/colors.dart';
import 'package:flutter/material.dart';

class InfoText extends StatelessWidget {
  final String title;
  final String value;
  final TextStyle? titleStyle;
  final TextStyle? valueStyle;

  const InfoText({
    super.key,
    required this.title,
    required this.value,
    this.titleStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: titleStyle ??
              TextStyle(
                fontSize: 14,
                color: AppColor.kGrayscale40,
              ),
        ),
        Text(
          value,
          style: valueStyle ??
              TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColor.kGrayscale100,
              ),
        ),
      ],
    );
  }
}
