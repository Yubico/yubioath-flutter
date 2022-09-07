import 'package:flutter/material.dart';

class ListTitle extends StatelessWidget {
  final String title;

  const ListTitle(this.title, {super.key});
  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      );
}
