import 'package:account_book/app/screens/transactions/export.dart';

class NoResultsFound extends StatelessWidget {
  final TextEditingController controller;

  const NoResultsFound({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('No results found'),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateParty(nameController: controller),
              ),
            );
          },
          child: const Text('Add New Party'),
        ),
      ],
    );
  }
}
