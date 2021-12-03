import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/circle_timer.dart';
import '../../app/models.dart';
import '../models.dart';
import '../state.dart';

class AccountView extends ConsumerStatefulWidget {
  final DeviceNode device;
  final OathCredential credential;
  final OathCode? code;
  const AccountView(this.device, this.credential, this.code, {Key? key})
      : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AccountViewState();
}

class _AccountViewState extends ConsumerState<AccountView> {
  Timer? _expirationTimer;
  late bool _expired;

  void _scheduleExpiration() {
    final expires = (widget.code?.validTo ?? 0) * 1000;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (expires > now) {
      _expired = false;
      _expirationTimer?.cancel();
      _expirationTimer = Timer(Duration(milliseconds: expires - now), () {
        setState(() {
          _expired = true;
        });
      });
    } else {
      _expired = true;
    }
  }

  @override
  void didUpdateWidget(AccountView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleExpiration();
  }

  @override
  void initState() {
    super.initState();
    _scheduleExpiration();
  }

  @override
  void dispose() {
    _expirationTimer?.cancel();
    super.dispose();
  }

  String get _avatarLetter {
    var name = widget.credential.issuer ?? widget.credential.name;
    return name.substring(0, 1).toUpperCase();
  }

  String get _label =>
      '${widget.credential.issuer} (${widget.credential.name})';

  String get _code {
    var value = widget.code?.value;
    if (value == null) {
      return '••• •••';
    } else if (value.length < 6) {
      return value;
    } else {
      var i = value.length ~/ 2;
      return value.substring(0, i) + ' ' + value.substring(i);
    }
  }

  Color get _color =>
      Colors.primaries.elementAt(_label.hashCode % Colors.primaries.length);

  @override
  Widget build(BuildContext context) {
    final favorite = ref.watch(favoriteProvider(widget.credential.id));

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: _color,
          child: Text(_avatarLetter, style: const TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 8.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_code,
                style: _expired
                    ? Theme.of(context)
                        .textTheme
                        .headline6
                        ?.copyWith(color: Colors.grey)
                    : Theme.of(context).textTheme.headline6),
            Text(_label, style: Theme.of(context).textTheme.caption),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            IconButton(
              onPressed: () {
                ref
                    .read(favoriteProvider(widget.credential.id).notifier)
                    .toggleFavorite();
              },
              icon: Icon(favorite ? Icons.star : Icons.star_border),
            ),
            SizedBox.square(
              dimension: 16,
              child: widget.code != null &&
                      widget.code!.validTo - widget.code!.validFrom < 600
                  ? CircleTimer(
                      widget.code!.validFrom * 1000,
                      widget.code!.validTo * 1000,
                    )
                  : null,
            ),
            if (widget.code == null)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  if (widget.credential.touchRequired) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Touch your YubiKey'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                  ref
                      .read(credentialListProvider(widget.device.path).notifier)
                      .calculate(widget.credential);
                },
              )
          ],
        ),
      ]),
    );
  }
}
