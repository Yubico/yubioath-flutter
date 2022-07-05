import 'package:flutter/material.dart';

class ListTitle extends StatelessWidget {
  final String title;

  const ListTitle(this.title, {super.key});
  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall,
        ),
      );
}
