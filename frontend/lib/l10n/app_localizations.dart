import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_th.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('th'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'She Absolutely Just Did That'**
  String get appTitle;

  /// No description provided for @splashTitle.
  ///
  /// In en, this message translates to:
  /// **'She Absolutely Just Did That'**
  String get splashTitle;

  /// No description provided for @splashBubbleText.
  ///
  /// In en, this message translates to:
  /// **'Your situationship just did something unhinged and you need to debrief immediately. Jess is available. An AI best friend who\'s always awake, always invested, and has genuinely been waiting by the phone. Great questions. Zero judgment. Official ratings. She picked up on the first ring. Start talking.'**
  String get splashBubbleText;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'🔒 Your Privacy Matters'**
  String get privacyTitle;

  /// No description provided for @privacyText.
  ///
  /// In en, this message translates to:
  /// **'All conversations are stored locally on your device only. No accounts. No cloud storage. No data collection. When you delete the app, everything goes with it.'**
  String get privacyText;

  /// No description provided for @githubButton.
  ///
  /// In en, this message translates to:
  /// **'View on GitHub'**
  String get githubButton;

  /// No description provided for @createdByText.
  ///
  /// In en, this message translates to:
  /// **'Created by Janet Jeffus, a solo lesbian developer.\nLearn more: '**
  String get createdByText;

  /// No description provided for @getStartedButton.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStartedButton;

  /// No description provided for @chatScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Debrief'**
  String get chatScreenTitle;

  /// No description provided for @chatScreenHintText.
  ///
  /// In en, this message translates to:
  /// **'Spill the tea...'**
  String get chatScreenHintText;

  /// No description provided for @chatScreenWelcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Hey bestie! So glad you\'re here. What\'s on your mind?'**
  String get chatScreenWelcomeMessage;

  /// No description provided for @chatScreenErrorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get chatScreenErrorUnexpected;

  /// No description provided for @chatScreenErrorRetryInProgress.
  ///
  /// In en, this message translates to:
  /// **'One moment, this is taking longer than normal'**
  String get chatScreenErrorRetryInProgress;

  /// No description provided for @chatScreenErrorJessProblem.
  ///
  /// In en, this message translates to:
  /// **'Jess is having a problem.'**
  String get chatScreenErrorJessProblem;

  /// No description provided for @emptyStateTitle.
  ///
  /// In en, this message translates to:
  /// **'No debriefs yet.'**
  String get emptyStateTitle;

  /// No description provided for @emptyStateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What are you waiting for?'**
  String get emptyStateSubtitle;

  /// No description provided for @emptyStateButton.
  ///
  /// In en, this message translates to:
  /// **'Start Debriefing'**
  String get emptyStateButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'th', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'th':
      return AppLocalizationsTh();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
