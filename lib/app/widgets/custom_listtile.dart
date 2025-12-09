import 'package:flutter/material.dart';

class CustomListTile extends StatelessWidget {
  final VoidCallback? onTap;
  final String? title;
  final String? subTitle;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsetsGeometry? contentPadding;
  final bool? dense;
  const CustomListTile({
    super.key,
    this.onTap,
    this.title,
    this.leading,
    this.subTitle,
    this.trailing,
    this.contentPadding,
    this.dense,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: dense,
      contentPadding: contentPadding,
      onTap: onTap,
      title: title != null ? Text(title!) : null,
      leading: leading,
      subtitle: subTitle != null ? Text(subTitle!) : null,
      trailing: trailing,
    );
  }
}
