import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paymint/main.dart' as campfireApp;
import 'package:paymint/widgets/address_book_card.dart';

import 'bot_runners/create_new_wallet_until_pin_confirmation.dart';
import 'bots/addressbook/add_address_book_entry_view_bot.dart';
import 'bots/addressbook/address_book_view_bot.dart';
import 'bots/main_view_bot.dart';
import 'bots/onboarding/backup_key_warning_bot.dart';
import 'bots/onboarding/create_pin_view_bot.dart';
import 'bots/onboarding/name_your_wallet_view_bot.dart';
import 'bots/onboarding/onboarding_view_bot.dart';
import 'bots/onboarding/terms_and_conditions_bot.dart';
import 'bots/settings/settings_view_bot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets("wallet, send, and receive view test", (tester) async {
    campfireApp.main();
    await tester.pumpAndSettle();

    // robots
    final onboardingViewBot = OnboardingViewBot(tester);
    final termsAndConditionsViewBot = TermsAndConditionsViewBot(tester);
    final nameYourWalletViewBot = NameYourWalletViewBot(tester);
    final createPinViewBot = CreatePinViewBot(tester);
    final backupKeyWarningViewBot = BackupKeyWarningViewBot(tester);
    final mainViewBot = MainViewBot(tester);
    final settingsViewBot = SettingsViewBot(tester);
    final addressBookViewBot = AddressBookViewBot(tester);
    final addAddressBookEntryViewBot = AddAddressBookEntryViewBot(tester);

    // tap create new wallet button
    await onboardingViewBot.ensureVisible();
    await onboardingViewBot.tapCreateNewWallet();
    await termsAndConditionsViewBot.ensureVisible();

    await createNewWalletUntilPinConfirmation(
      termsAndConditionsViewBot,
      nameYourWalletViewBot,
      createPinViewBot,
      backupKeyWarningViewBot,
    );

    // wait for wallet generation
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle(Duration(seconds: 10));

    await backupKeyWarningViewBot.ensureVisible();

    // tap skip to load into main wallet view
    await backupKeyWarningViewBot.tapSkip();
    await mainViewBot.ensureVisible();

    // tap settings button
    await mainViewBot.tapSettings();
    await settingsViewBot.ensureVisible();

    // tap address book
    await settingsViewBot.tapAddressBook();
    await addressBookViewBot.ensureVisible();

    // add entry
    await addressBookViewBot.tapAdd();
    await addAddressBookEntryViewBot.ensureVisible();

    // test back and cancel
    await addAddressBookEntryViewBot.tapBack();
    await addressBookViewBot.ensureVisible();
    await addressBookViewBot.tapAdd();
    await addAddressBookEntryViewBot.tapCancel();
    await addressBookViewBot.ensureVisible();

    // now add an entry
    await addressBookViewBot.tapAdd();
    await addAddressBookEntryViewBot.ensureVisible();
    await addAddressBookEntryViewBot
        .enterAddress("aPjLWDTPQsoPHUTxKBNRzoebDALj3eTcfh");
    await addAddressBookEntryViewBot.enterName("john doe");

    // save entry
    await addAddressBookEntryViewBot.tapSave();
    await addressBookViewBot.ensureVisible();
    expect(find.byType(AddressBookCard), findsOneWidget);
  });
}
