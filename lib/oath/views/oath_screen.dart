import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/models.dart';
import '../state.dart';
import 'account_list.dart';

class OathScreen extends ConsumerWidget {
  final YubiKeyData deviceData;
  const OathScreen(this.deviceData, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(oathStateProvider(deviceData.node.path));

    if (state == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (state.locked) {
      return ListView(
        children: [
          _UnlockForm(
            onSubmit: (password, remember) async {
              final result = await ref
                  .read(oathStateProvider(deviceData.node.path).notifier)
                  .unlock(password, remember: remember);
              if (!result) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Wrong password'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ],
      );
    } else {
      final accounts = ref.watch(credentialListProvider(deviceData.node.path));
      if (accounts == null) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Center(child: CircularProgressIndicator()),
          ],
        );
      }
      return AccountList(
        deviceData,
        ref.watch(filteredCredentialsProvider(accounts)),
        ref.watch(favoritesProvider),
      );
    }
  }
}

class _UnlockForm extends StatefulWidget {
  final Function(String, bool) onSubmit;
  const _UnlockForm({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _UnlockFormState();
}

class _UnlockFormState extends State<_UnlockForm> {
  String _password = '';
  bool _remember = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      //mainAxisAlignment: MainAxisAlignment.center,
      //crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  'Unlock YubiKey',
                  style: Theme.of(context).textTheme.headline5,
                ),
              ),
              const Text(
                'Enter the password for your YubiKey. If you don\'t know your password, you\'ll need to reset the YubiKey.',
              ),
              TextField(
                autofocus: true,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                onChanged: (value) {
                  setState(() {
                    _password = value;
                  });
                },
                onSubmitted: (value) {
                  widget.onSubmit(value, _remember);
                },
              ),
            ],
          ),
        ),
        CheckboxListTile(
          title: const Text('Remember password'),
          controlAffinity: ListTileControlAffinity.leading,
          value: _remember,
          onChanged: (value) {
            setState(() {
              _remember = value ?? false;
            });
          },
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            child: const Text('Unlock'),
            onPressed: () {
              widget.onSubmit(_password, _remember);
            },
          ),
        ),
      ],
    );
  }
}
