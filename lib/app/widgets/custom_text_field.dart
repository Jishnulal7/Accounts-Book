import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:account_book/app/data/constants/data.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;
  final bool? readOnly;
  final Function()? onTap;
  final void Function(String)? onChanged;
  final int? maxLength;
  final int? maxLines;
  final bool? obscureText;
  final FocusNode? focusNode;
  final Function()? onEditingComplete;
  final void Function(String?)? onSaved;
  final void Function(String?)? onFieldSubmitted;
  final bool? filled;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? style;
  final List<TextInputFormatter>? inputFormatters;
  final String? initialValue;
  const CustomTextField({
    super.key,
    this.controller,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.validator,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.maxLength,
    this.maxLines = 1,
    this.labelText,
    this.obscureText = false,
    this.onEditingComplete,
    this.focusNode,
    this.onSaved,
    this.filled = false,
    this.contentPadding,
    this.style,
    this.inputFormatters,
    this.initialValue,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      textInputAction: TextInputAction.go,
      focusNode: focusNode,
      onEditingComplete: onEditingComplete,
      obscureText: obscureText!,
      maxLines: maxLines,
      maxLength: maxLength,
      readOnly: readOnly ?? false,
      controller: controller,
      onSaved: onSaved,
      keyboardType: keyboardType,
      validator: validator,
      onTap: onTap,
      initialValue: initialValue,
      style: style,
      onFieldSubmitted: onFieldSubmitted,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      decoration: InputDecoration(
        contentPadding: contentPadding,
        counterText: '',
        prefixIcon: prefixIcon,
        hintText: hintText,
        labelText: labelText,
        suffixIcon: suffixIcon,
        filled: filled,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(color: ListData().darkorWhite(context)),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }
}

class CustomTextFieldNoBorder extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;
  final Function()? onTap;
  final Function(String)? onChanged;
  final int? maxLength;
  final int? maxLines;
  final bool? readOnly;
  final EdgeInsetsGeometry? contentPadding;

  const CustomTextFieldNoBorder({
    super.key,
    this.controller,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.validator,
    this.suffixIcon,
    this.onTap,
    this.onChanged,
    this.maxLength,
    this.maxLines = 1,
    this.readOnly = false,
    this.labelText,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: readOnly!,
      maxLines: maxLines,
      maxLength: maxLength,
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onTap: onTap,
      onChanged: onChanged,
      decoration: InputDecoration(
        contentPadding: contentPadding,
        counterText: '',
        prefixIcon: prefixIcon,
        hintText: hintText,
        suffixIcon: suffixIcon,
        labelText: labelText,
      ),
    );
  }
}
