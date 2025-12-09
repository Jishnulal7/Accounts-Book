import 'package:flutter/material.dart';
import 'package:account_book/app/data/helpers/enums/radiobutton.dart';
import 'package:account_book/app/widgets/custom_listtile.dart';

class SampleRadioButton extends StatefulWidget {
  final Function(SingingCharacter) onOptionSelected;

  const SampleRadioButton({super.key, required this.onOptionSelected});

  @override
  State<SampleRadioButton> createState() => _SampleRadioButtonState();
}

class _SampleRadioButtonState extends State<SampleRadioButton> {
  SingingCharacter? _character = SingingCharacter.option1;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: CustomListTile(
              contentPadding: const EdgeInsets.all(0),
              dense: true,
              title: 'Add Stock',
              onTap: () {
                setState(() {
                  _character = SingingCharacter.option1;
                });
                widget.onOptionSelected(SingingCharacter.option1);
              },
              leading: Radio<SingingCharacter>(
                value: SingingCharacter.option1,
                groupValue: _character,
                onChanged: (SingingCharacter? value) {
                  setState(() {
                    _character = value;
                  });
                  widget.onOptionSelected(value!);
                },
              ),
            ),
          ),
          Expanded(
            child: CustomListTile(
              contentPadding: const EdgeInsets.all(0),
              dense: true,
              title: 'Reduce Stock',
              onTap: () {
                setState(() {
                  _character = SingingCharacter.option2;
                });
                widget.onOptionSelected(SingingCharacter.option2);
              },
              leading: Radio<SingingCharacter>(
                value: SingingCharacter.option2,
                groupValue: _character,
                onChanged: (SingingCharacter? value) {
                  setState(() {
                    _character = value;
                  });
                  widget.onOptionSelected(value!);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
