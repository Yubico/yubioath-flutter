import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/app/views/reset_dialog.dart';
import 'package:yubico_authenticator/fido/models.dart';
import 'package:yubico_authenticator/generated/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('NFC reset asks for removal and replacement, then waiting', () {
    expect(
      fidoResetInstruction(
        l10n,
        InteractionEvent.remove,
        nfc: true,
        longTouch: false,
      ),
      l10n.l_remove_yk_from_reader,
    );
    expect(
      fidoResetInstruction(
        l10n,
        InteractionEvent.insert,
        nfc: true,
        longTouch: false,
      ),
      l10n.l_replace_yk_on_reader,
    );
    for (final longTouch in [false, true]) {
      expect(
        fidoResetInstruction(
          l10n,
          InteractionEvent.touch,
          nfc: true,
          longTouch: longTouch,
        ),
        l10n.s_please_wait,
      );
    }
  });

  test('USB reset still asks for a touch', () {
    expect(
      fidoResetInstruction(
        l10n,
        InteractionEvent.touch,
        nfc: false,
        longTouch: false,
      ),
      l10n.l_touch_button_now,
    );
    expect(
      fidoResetInstruction(
        l10n,
        InteractionEvent.touch,
        nfc: false,
        longTouch: true,
      ),
      l10n.l_long_touch_button_now,
    );
  });
}
