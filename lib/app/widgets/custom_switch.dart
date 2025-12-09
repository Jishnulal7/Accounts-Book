import 'package:account_book/app/data/constants/colors.dart';
import 'package:flutter/material.dart';

class CustomSwitch extends StatelessWidget {
  final bool isSwitchOn;
  final ValueChanged<bool> onToggle;

  const CustomSwitch({
    super.key,
    required this.isSwitchOn,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Switch(
      activeColor: isSwitchOn ? AppColor.kRed : AppColor.kWhite,
      value: isSwitchOn,
      onChanged: onToggle,
    );
  }
}


class CustomToggleButton extends StatefulWidget {
  final String? text;
  final bool isSelected;
  final VoidCallback onTap;

  const CustomToggleButton({
    super.key,
    this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  CustomToggleButtonState createState() => CustomToggleButtonState();
}

class CustomToggleButtonState extends State<CustomToggleButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 40,
        width: 80,
        decoration: BoxDecoration(
          color: widget.isSelected ? AppColor.kPrimary : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            widget.text!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.isSelected
                  ? AppColor.kWhite
                  : AppColor.kGrayscaleDark100,
            ),
          ),
        ),
      ),
    );
  }
}
