import 'package:flutter/material.dart';

class NoRecordsWidget extends StatelessWidget {
  const NoRecordsWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              'No Records available',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                // color: Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
