import 'package:flutter/material.dart';
import 'package:account_book/app/data/constants/colors.dart';
import 'package:account_book/app/widgets/custom_text_field.dart';

class ListData {
  final List<String> states = [
    'Select State',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  final unitData = [
    'None',
    'Add Unit',
    'Bags (Bag)',
    'Bottles (Btl)',
    'Box (Box)',
    'Bundles (Bdl)',
    'Cans (Can)',
    'Dozens (Dzn)',
    'Grammes (Gm)',
    'Kilograms (Kg)',
    'Litre (Ltr)',
    'Meters (Mtr)',
    'Millilitre (Ml)',
    'Numbers (Nos)',
    'Packs (Pac)',
    'Pairs (Prs)',
    'Quintal (Qtl)',
    'Rolls (Rol)',
    'Square feet (Sqf)',
    'Square meters (Sqm)',
    'Tablets (Tbs)',
  ];

  final unitDataMap = {
    "Bags": "Bag",
    "Bottles": "Btl",
    "Box": "Box",
    "Bundles": "Bdl",
    "Cans": "Can",
    "Dozens": "Dzn",
    "Grammes": "Gm",
    "Kilograms": "Kg",
    "Litre": "Ltr",
    "Meters": "Mtr",
    "Millilitre": "Ml",
    "Numbers": "Nos",
    "Packs": "Pac",
    "Pairs": "Prs",
    "Quintal": "Qtl",
    "Rolls": "Rol",
    "Square feet": "Sqf",
    "Square meters": "Sqm",
    "Tablets": "Tbs"
  };

  List<String> taxRates = [
    'None',
    'Exempted',
    'GST 0%',
    'GST 5%',
    'GST 12%',
    'GST 18%',
    'GST 28%'
  ];

  List<String> days = [
    'None',
    '7 Days',
    '15 Days',
    '30 Days',
    '45 Days',
    '60 Days',
    'Custom'
  ];
  List<String> list = [
    'Cash',
    'Cheque',
    'Bank',
  ];

  double fontSizeForDropDown(width) {
    double fontSize;
    if (width < 421) {
      fontSize = 11;
    } else {
      fontSize = 13;
    }
    return fontSize;
  }

  Widget buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String hintText,
    required String text,
    TextInputType keyboardType = TextInputType.text,
    bool? readOnly,
    String? Function(String?)? validator,
    Widget? prefixIcon,
    Widget? suffixIcon,
    int? maxLength,
    int? maxLines,
    dynamic Function()? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle(text),
        const SizedBox(height: 5),
        CustomTextField(
          onTap: onTap,
          maxLines: maxLines,
          controller: controller,
          keyboardType: keyboardType,
          hintText: hintText,
          validator: validator,
          prefixIcon: prefixIcon,
          maxLength: maxLength,
          suffixIcon: suffixIcon,
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Color darkorWhite(BuildContext context) {
    ThemeData currentTheme = Theme.of(context);

    if (currentTheme.brightness == Brightness.dark) {
      return AppColor.kWhite;
    } else {
      return AppColor.kGrayscaleDark100;
    }
  }

  Color whiteOrDark(BuildContext context) {
    ThemeData currentTheme = Theme.of(context);

    if (currentTheme.brightness == Brightness.dark) {
      return AppColor.kGrayscaleDark100;
    } else {
      return AppColor.kWhite;
    }
  }
}
