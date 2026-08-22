import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_uk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
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
    Locale('es'),
    Locale('pl'),
    Locale('pt'),
    Locale('uk')
  ];

  /// No description provided for @app_name.
  ///
  /// In en, this message translates to:
  /// **'Bondee'**
  String get app_name;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @no_chats_yet.
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get no_chats_yet;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @registration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get registration;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @login_title.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get login_title;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get step;

  /// No description provided for @of_text.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get of_text;

  /// No description provided for @phone_number.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phone_number;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirm_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirm_password;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @about_me.
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get about_me;

  /// No description provided for @hobbies.
  ///
  /// In en, this message translates to:
  /// **'Hobbies'**
  String get hobbies;

  /// No description provided for @continue_text.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_text;

  /// No description provided for @enter.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get enter;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgot_password;

  /// No description provided for @already_have_account.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get already_have_account;

  /// No description provided for @for_you.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get for_you;

  /// No description provided for @events_nearby.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events_nearby;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @dislike.
  ///
  /// In en, this message translates to:
  /// **'Dislike'**
  String get dislike;

  /// No description provided for @super_like.
  ///
  /// In en, this message translates to:
  /// **'Super like'**
  String get super_like;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @my_profile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get my_profile;

  /// No description provided for @edit_profile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get edit_profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @less.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get less;

  /// No description provided for @chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @typing.
  ///
  /// In en, this message translates to:
  /// **'Typing...'**
  String get typing;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @new_message.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get new_message;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @event_details.
  ///
  /// In en, this message translates to:
  /// **'Event details'**
  String get event_details;

  /// No description provided for @participants.
  ///
  /// In en, this message translates to:
  /// **'participants'**
  String get participants;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @search_preferences.
  ///
  /// In en, this message translates to:
  /// **'Search preferences'**
  String get search_preferences;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @enable_notifications.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get enable_notifications;

  /// No description provided for @new_matches.
  ///
  /// In en, this message translates to:
  /// **'New matches'**
  String get new_matches;

  /// No description provided for @messages_notifications.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages_notifications;

  /// No description provided for @events_nearby_notifications.
  ///
  /// In en, this message translates to:
  /// **'Events nearby'**
  String get events_nearby_notifications;

  /// No description provided for @location_access.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location_access;

  /// No description provided for @dark_mode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get dark_mode;

  /// No description provided for @max_distance.
  ///
  /// In en, this message translates to:
  /// **'Max distance'**
  String get max_distance;

  /// No description provided for @age_range.
  ///
  /// In en, this message translates to:
  /// **'Age range'**
  String get age_range;

  /// No description provided for @years_old.
  ///
  /// In en, this message translates to:
  /// **'years old'**
  String get years_old;

  /// No description provided for @change_password.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get change_password;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @delete_account.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get delete_account;

  /// No description provided for @language_changed.
  ///
  /// In en, this message translates to:
  /// **'Language changed'**
  String get language_changed;

  /// No description provided for @confirm_delete.
  ///
  /// In en, this message translates to:
  /// **'Confirm deletion'**
  String get confirm_delete;

  /// No description provided for @delete_account_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account?'**
  String get delete_account_confirm;

  /// No description provided for @account_deleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get account_deleted;

  /// No description provided for @account_deleted_message.
  ///
  /// In en, this message translates to:
  /// **'Your account has been successfully deleted'**
  String get account_deleted_message;

  /// No description provided for @coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get coming_soon;

  /// No description provided for @feature_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'This feature will be available soon'**
  String get feature_coming_soon;

  /// No description provided for @gaming.
  ///
  /// In en, this message translates to:
  /// **'Gaming'**
  String get gaming;

  /// No description provided for @board_games.
  ///
  /// In en, this message translates to:
  /// **'Board games'**
  String get board_games;

  /// No description provided for @lofi_music.
  ///
  /// In en, this message translates to:
  /// **'Lo-Fi Music'**
  String get lofi_music;

  /// No description provided for @camping.
  ///
  /// In en, this message translates to:
  /// **'Camping'**
  String get camping;

  /// No description provided for @fantasy_books.
  ///
  /// In en, this message translates to:
  /// **'Fantasy books'**
  String get fantasy_books;

  /// No description provided for @photography.
  ///
  /// In en, this message translates to:
  /// **'Photography'**
  String get photography;

  /// No description provided for @travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get travel;

  /// No description provided for @cooking.
  ///
  /// In en, this message translates to:
  /// **'Cooking'**
  String get cooking;

  /// No description provided for @sport.
  ///
  /// In en, this message translates to:
  /// **'Sport'**
  String get sport;

  /// No description provided for @reading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get reading;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @dancing.
  ///
  /// In en, this message translates to:
  /// **'Dancing'**
  String get dancing;

  /// No description provided for @drawing.
  ///
  /// In en, this message translates to:
  /// **'Drawing'**
  String get drawing;

  /// No description provided for @programming.
  ///
  /// In en, this message translates to:
  /// **'Programming'**
  String get programming;

  /// No description provided for @yoga.
  ///
  /// In en, this message translates to:
  /// **'Yoga'**
  String get yoga;

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get running;

  /// No description provided for @cycling.
  ///
  /// In en, this message translates to:
  /// **'Cycling'**
  String get cycling;

  /// No description provided for @swimming.
  ///
  /// In en, this message translates to:
  /// **'Swimming'**
  String get swimming;

  /// No description provided for @enter_name.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enter_name;

  /// No description provided for @enter_location.
  ///
  /// In en, this message translates to:
  /// **'Enter location'**
  String get enter_location;

  /// No description provided for @enter_age.
  ///
  /// In en, this message translates to:
  /// **'Enter your age'**
  String get enter_age;

  /// No description provided for @enter_valid_age.
  ///
  /// In en, this message translates to:
  /// **'Enter valid age (18-100)'**
  String get enter_valid_age;

  /// No description provided for @enter_password.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enter_password;

  /// No description provided for @passwords_not_match.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwords_not_match;

  /// No description provided for @enter_phone.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get enter_phone;

  /// No description provided for @max_hobbies.
  ///
  /// In en, this message translates to:
  /// **'You can select up to 8 hobbies'**
  String get max_hobbies;

  /// No description provided for @no_events_found.
  ///
  /// In en, this message translates to:
  /// **'No events found'**
  String get no_events_found;

  /// No description provided for @no_hobbies_found.
  ///
  /// In en, this message translates to:
  /// **'No hobbies found'**
  String get no_hobbies_found;

  /// No description provided for @try_different_search.
  ///
  /// In en, this message translates to:
  /// **'Try a different search'**
  String get try_different_search;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'2 km away'**
  String get distance;

  /// No description provided for @km_away.
  ///
  /// In en, this message translates to:
  /// **'km away'**
  String get km_away;

  /// No description provided for @search_contacts.
  ///
  /// In en, this message translates to:
  /// **'Search contacts'**
  String get search_contacts;

  /// No description provided for @active_contacts.
  ///
  /// In en, this message translates to:
  /// **'Active contacts'**
  String get active_contacts;

  /// No description provided for @create_group.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get create_group;

  /// No description provided for @join_group.
  ///
  /// In en, this message translates to:
  /// **'Join group'**
  String get join_group;

  /// No description provided for @private_group.
  ///
  /// In en, this message translates to:
  /// **'Private group'**
  String get private_group;

  /// No description provided for @public_group.
  ///
  /// In en, this message translates to:
  /// **'Public group'**
  String get public_group;

  /// No description provided for @group_name.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get group_name;

  /// No description provided for @group_description.
  ///
  /// In en, this message translates to:
  /// **'Group description'**
  String get group_description;

  /// No description provided for @group_members.
  ///
  /// In en, this message translates to:
  /// **'Group members'**
  String get group_members;

  /// No description provided for @group_joined.
  ///
  /// In en, this message translates to:
  /// **'Group joined successfully'**
  String get group_joined;

  /// No description provided for @test_language_change.
  ///
  /// In en, this message translates to:
  /// **'Test language change'**
  String get test_language_change;

  /// No description provided for @morning_coffee.
  ///
  /// In en, this message translates to:
  /// **'Morning coffee with mountain view'**
  String get morning_coffee;

  /// No description provided for @guitar.
  ///
  /// In en, this message translates to:
  /// **'Guitar playing'**
  String get guitar;

  /// No description provided for @meditation.
  ///
  /// In en, this message translates to:
  /// **'Meditation'**
  String get meditation;

  /// No description provided for @art.
  ///
  /// In en, this message translates to:
  /// **'Art'**
  String get art;

  /// No description provided for @fitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get fitness;

  /// No description provided for @mountains.
  ///
  /// In en, this message translates to:
  /// **'Mountains'**
  String get mountains;

  /// No description provided for @boxing.
  ///
  /// In en, this message translates to:
  /// **'Boxing'**
  String get boxing;

  /// No description provided for @healthy_nutrition.
  ///
  /// In en, this message translates to:
  /// **'Healthy nutrition'**
  String get healthy_nutrition;

  /// No description provided for @motivation.
  ///
  /// In en, this message translates to:
  /// **'Motivation'**
  String get motivation;

  /// No description provided for @find_your_wave.
  ///
  /// In en, this message translates to:
  /// **'Find those who are on your wave'**
  String get find_your_wave;

  /// No description provided for @become_part_of_community.
  ///
  /// In en, this message translates to:
  /// **'Become part of your community'**
  String get become_part_of_community;

  /// No description provided for @lets_start.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Start'**
  String get lets_start;

  /// No description provided for @continue_with.
  ///
  /// In en, this message translates to:
  /// **'Continue with'**
  String get continue_with;

  /// No description provided for @swipe_end.
  ///
  /// In en, this message translates to:
  /// **'No more cards'**
  String get swipe_end;

  /// No description provided for @language_changed_message.
  ///
  /// In en, this message translates to:
  /// **'App language changed to {language}. Changes applied instantly!'**
  String language_changed_message(Object language);

  /// No description provided for @change_email.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get change_email;

  /// No description provided for @delete_account_message.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action is irreversible.'**
  String get delete_account_message;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @user_profile.
  ///
  /// In en, this message translates to:
  /// **'User profile'**
  String get user_profile;

  /// No description provided for @not_interested.
  ///
  /// In en, this message translates to:
  /// **'Not interested'**
  String get not_interested;

  /// No description provided for @group_created.
  ///
  /// In en, this message translates to:
  /// **'Group created successfully!'**
  String get group_created;

  /// No description provided for @location_updated.
  ///
  /// In en, this message translates to:
  /// **'Location updated'**
  String get location_updated;

  /// No description provided for @hobbies_not_found.
  ///
  /// In en, this message translates to:
  /// **'Hobbies not found'**
  String get hobbies_not_found;

  /// No description provided for @create_event.
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get create_event;

  /// No description provided for @event_title.
  ///
  /// In en, this message translates to:
  /// **'Event Title'**
  String get event_title;

  /// No description provided for @event_location.
  ///
  /// In en, this message translates to:
  /// **'Event Location'**
  String get event_location;

  /// No description provided for @event_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get event_description;

  /// No description provided for @event_created.
  ///
  /// In en, this message translates to:
  /// **'Event created!'**
  String get event_created;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @my_events.
  ///
  /// In en, this message translates to:
  /// **'My Events'**
  String get my_events;

  /// No description provided for @joined_events.
  ///
  /// In en, this message translates to:
  /// **'Events I Joined'**
  String get joined_events;

  /// No description provided for @event_invitations.
  ///
  /// In en, this message translates to:
  /// **'Event Invitations'**
  String get event_invitations;

  /// No description provided for @search_people.
  ///
  /// In en, this message translates to:
  /// **'Search People'**
  String get search_people;

  /// No description provided for @invite_to_event.
  ///
  /// In en, this message translates to:
  /// **'Invite to Event'**
  String get invite_to_event;

  /// No description provided for @invitation_sent.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent!'**
  String get invitation_sent;

  /// No description provided for @accept_invitation.
  ///
  /// In en, this message translates to:
  /// **'Accept Invitation'**
  String get accept_invitation;

  /// No description provided for @decline_invitation.
  ///
  /// In en, this message translates to:
  /// **'Decline Invitation'**
  String get decline_invitation;

  /// No description provided for @invitation_accepted.
  ///
  /// In en, this message translates to:
  /// **'Invitation accepted!'**
  String get invitation_accepted;

  /// No description provided for @invitation_declined.
  ///
  /// In en, this message translates to:
  /// **'Invitation declined'**
  String get invitation_declined;

  /// No description provided for @leave_event.
  ///
  /// In en, this message translates to:
  /// **'Leave Event'**
  String get leave_event;

  /// No description provided for @event_left.
  ///
  /// In en, this message translates to:
  /// **'You left the event'**
  String get event_left;

  /// No description provided for @remove_from_profile.
  ///
  /// In en, this message translates to:
  /// **'Remove from Profile'**
  String get remove_from_profile;

  /// No description provided for @remove_from_messages.
  ///
  /// In en, this message translates to:
  /// **'Remove from Messages'**
  String get remove_from_messages;

  /// No description provided for @event_removed.
  ///
  /// In en, this message translates to:
  /// **'Event removed'**
  String get event_removed;

  /// No description provided for @my_participating_events.
  ///
  /// In en, this message translates to:
  /// **'Events I\'m Participating In'**
  String get my_participating_events;

  /// No description provided for @no_participating_events.
  ///
  /// In en, this message translates to:
  /// **'You\'re not participating in any events'**
  String get no_participating_events;

  /// No description provided for @event_participants.
  ///
  /// In en, this message translates to:
  /// **'Event Participants'**
  String get event_participants;

  /// No description provided for @send_event_invitation.
  ///
  /// In en, this message translates to:
  /// **'Send Event Invitation'**
  String get send_event_invitation;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @enter_phone_for_sms.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number to receive SMS code'**
  String get enter_phone_for_sms;

  /// No description provided for @sms_code.
  ///
  /// In en, this message translates to:
  /// **'SMS Code'**
  String get sms_code;

  /// No description provided for @enter_code_sent_to.
  ///
  /// In en, this message translates to:
  /// **'Enter the code we sent to number'**
  String get enter_code_sent_to;

  /// No description provided for @send_code_again.
  ///
  /// In en, this message translates to:
  /// **'Send code again'**
  String get send_code_again;

  /// No description provided for @enter_your_email.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get enter_your_email;

  /// No description provided for @create_strong_password.
  ///
  /// In en, this message translates to:
  /// **'Create a strong password'**
  String get create_strong_password;

  /// No description provided for @what_is_your_name.
  ///
  /// In en, this message translates to:
  /// **'What is your name?'**
  String get what_is_your_name;

  /// No description provided for @hello_how_are_you.
  ///
  /// In en, this message translates to:
  /// **'Hello! How are you?'**
  String get hello_how_are_you;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @no_new_requests.
  ///
  /// In en, this message translates to:
  /// **'No new requests'**
  String get no_new_requests;

  /// No description provided for @no_new_requests_subtitle.
  ///
  /// In en, this message translates to:
  /// **'When someone likes you, you\'ll see it here'**
  String get no_new_requests_subtitle;

  /// No description provided for @common_interests.
  ///
  /// In en, this message translates to:
  /// **'Common interests'**
  String get common_interests;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @like_user.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like_user;

  /// No description provided for @like_sent.
  ///
  /// In en, this message translates to:
  /// **'Like sent!'**
  String get like_sent;

  /// No description provided for @user_rejected.
  ///
  /// In en, this message translates to:
  /// **'User rejected'**
  String get user_rejected;

  /// No description provided for @no_created_events.
  ///
  /// In en, this message translates to:
  /// **'No created events'**
  String get no_created_events;

  /// No description provided for @no_created_events_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an event to see participation requests'**
  String get no_created_events_subtitle;

  /// No description provided for @view_requests.
  ///
  /// In en, this message translates to:
  /// **'View requests'**
  String get view_requests;

  /// No description provided for @view_profile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get view_profile;

  /// No description provided for @block_user.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get block_user;

  /// No description provided for @block_user_title.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get block_user_title;

  /// No description provided for @block_user_message.
  ///
  /// In en, this message translates to:
  /// **'We\'re sorry, but we won\'t suggest {userName} in recommendations anymore.'**
  String block_user_message(Object userName);

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @event_requests.
  ///
  /// In en, this message translates to:
  /// **'Event requests'**
  String get event_requests;

  /// No description provided for @no_event_requests.
  ///
  /// In en, this message translates to:
  /// **'No event requests'**
  String get no_event_requests;

  /// No description provided for @no_event_requests_subtitle.
  ///
  /// In en, this message translates to:
  /// **'When someone wants to join your event, you\'ll see it here'**
  String get no_event_requests_subtitle;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @about_me_section.
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get about_me_section;

  /// No description provided for @event_filters.
  ///
  /// In en, this message translates to:
  /// **'Event filters'**
  String get event_filters;

  /// No description provided for @filter_by_date.
  ///
  /// In en, this message translates to:
  /// **'Filter by date'**
  String get filter_by_date;

  /// No description provided for @filter_by_distance.
  ///
  /// In en, this message translates to:
  /// **'Filter by distance'**
  String get filter_by_distance;

  /// No description provided for @filter_by_tags.
  ///
  /// In en, this message translates to:
  /// **'Filter by tags'**
  String get filter_by_tags;

  /// No description provided for @select_date_range.
  ///
  /// In en, this message translates to:
  /// **'Select date range'**
  String get select_date_range;

  /// No description provided for @select_distance.
  ///
  /// In en, this message translates to:
  /// **'Select distance'**
  String get select_distance;

  /// No description provided for @select_tags.
  ///
  /// In en, this message translates to:
  /// **'Select tags'**
  String get select_tags;

  /// No description provided for @apply_filters.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get apply_filters;

  /// No description provided for @clear_filters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clear_filters;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @this_week.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get this_week;

  /// No description provided for @this_month.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get this_month;

  /// No description provided for @next_month.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get next_month;

  /// No description provided for @within_1_km.
  ///
  /// In en, this message translates to:
  /// **'Within 1 km'**
  String get within_1_km;

  /// No description provided for @within_5_km.
  ///
  /// In en, this message translates to:
  /// **'Within 5 km'**
  String get within_5_km;

  /// No description provided for @within_10_km.
  ///
  /// In en, this message translates to:
  /// **'Within 10 km'**
  String get within_10_km;

  /// No description provided for @within_25_km.
  ///
  /// In en, this message translates to:
  /// **'Within 25 km'**
  String get within_25_km;

  /// No description provided for @within_50_km.
  ///
  /// In en, this message translates to:
  /// **'Within 50 km'**
  String get within_50_km;

  /// No description provided for @all_tags.
  ///
  /// In en, this message translates to:
  /// **'All tags'**
  String get all_tags;

  /// No description provided for @selected_tags.
  ///
  /// In en, this message translates to:
  /// **'Selected tags: {count}'**
  String selected_tags(Object count);

  /// No description provided for @no_tags_selected.
  ///
  /// In en, this message translates to:
  /// **'No tags selected'**
  String get no_tags_selected;

  /// No description provided for @logout_title.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logout_title;

  /// No description provided for @logout_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get logout_confirm;

  /// No description provided for @delete_account_title.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get delete_account_title;

  /// No description provided for @delete_forever.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get delete_forever;

  /// No description provided for @delete_account_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the account'**
  String get delete_account_failed;

  /// No description provided for @sign_out.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get sign_out;

  /// No description provided for @notification_settings.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notification_settings;

  /// No description provided for @privacy_settings.
  ///
  /// In en, this message translates to:
  /// **'Privacy settings'**
  String get privacy_settings;

  /// No description provided for @feed_empty_title.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get feed_empty_title;

  /// No description provided for @feed_empty_radius.
  ///
  /// In en, this message translates to:
  /// **'Nobody found within {km} km.'**
  String feed_empty_radius(int km);

  /// No description provided for @feed_empty_no_location.
  ///
  /// In en, this message translates to:
  /// **'We do not know where you are, so we are showing everyone.\nTurn on location to see people nearby.'**
  String get feed_empty_no_location;

  /// No description provided for @search_within_km.
  ///
  /// In en, this message translates to:
  /// **'Search within {km} km'**
  String search_within_km(int km);

  /// No description provided for @radius_km.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String radius_km(int km);

  /// No description provided for @feed_finished_title.
  ///
  /// In en, this message translates to:
  /// **'That is everyone for today'**
  String get feed_finished_title;

  /// No description provided for @search_again.
  ///
  /// In en, this message translates to:
  /// **'Search again'**
  String get search_again;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @try_again.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get try_again;

  /// No description provided for @request_approved.
  ///
  /// In en, this message translates to:
  /// **'Request approved'**
  String get request_approved;

  /// No description provided for @match_chat_created.
  ///
  /// In en, this message translates to:
  /// **'It is a match! Chat with {name} created'**
  String match_chat_created(String name);

  /// No description provided for @awaiting_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Awaiting confirmation'**
  String get awaiting_confirmation;

  /// No description provided for @chat_create_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the chat'**
  String get chat_create_failed;

  /// No description provided for @participants_count.
  ///
  /// In en, this message translates to:
  /// **'{count} participants'**
  String participants_count(int count);

  /// No description provided for @send_message.
  ///
  /// In en, this message translates to:
  /// **'Send a message'**
  String get send_message;

  /// No description provided for @events_finished_title.
  ///
  /// In en, this message translates to:
  /// **'That is all for now'**
  String get events_finished_title;

  /// No description provided for @events_finished_body.
  ///
  /// In en, this message translates to:
  /// **'Events matching your interests have run out. Try changing the filters or wait for new ones.'**
  String get events_finished_body;

  /// No description provided for @join_message_hint.
  ///
  /// In en, this message translates to:
  /// **'Hi! I would like to join…'**
  String get join_message_hint;

  /// No description provided for @add_message_optional.
  ///
  /// In en, this message translates to:
  /// **'Add a message (optional)'**
  String get add_message_optional;

  /// No description provided for @write_first_message.
  ///
  /// In en, this message translates to:
  /// **'Write the first message 👋'**
  String get write_first_message;

  /// No description provided for @message_hint.
  ///
  /// In en, this message translates to:
  /// **'Message…'**
  String get message_hint;

  /// No description provided for @enter_valid_phone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get enter_valid_phone;

  /// No description provided for @wrong_phone_or_password.
  ///
  /// In en, this message translates to:
  /// **'Wrong number or password'**
  String get wrong_phone_or_password;

  /// No description provided for @account_exists_title.
  ///
  /// In en, this message translates to:
  /// **'Account already exists'**
  String get account_exists_title;

  /// No description provided for @account_exists_body.
  ///
  /// In en, this message translates to:
  /// **'You are already registered. Please sign in or use a different number.'**
  String get account_exists_body;

  /// No description provided for @change_number.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get change_number;

  /// No description provided for @step_of.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String step_of(int current, int total);

  /// No description provided for @recovery_step_of.
  ///
  /// In en, this message translates to:
  /// **'Recovery: step {current} of {total}'**
  String recovery_step_of(int current, int total);

  /// No description provided for @your_name.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get your_name;

  /// No description provided for @pick_birth_date.
  ///
  /// In en, this message translates to:
  /// **'Choose your date of birth'**
  String get pick_birth_date;

  /// No description provided for @change_password_title.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get change_password_title;

  /// No description provided for @new_password.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get new_password;

  /// No description provided for @confirm_new_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirm_new_password;

  /// No description provided for @save_password.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get save_password;

  /// No description provided for @password_too_short.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get password_too_short;

  /// No description provided for @passwords_do_not_match.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwords_do_not_match;

  /// No description provided for @password_changed.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get password_changed;

  /// No description provided for @create_new_password_hint.
  ///
  /// In en, this message translates to:
  /// **'Create a new strong password for your account.'**
  String get create_new_password_hint;

  /// No description provided for @no_photos_tap_to_add.
  ///
  /// In en, this message translates to:
  /// **'No photos.\nTap to add'**
  String get no_photos_tap_to_add;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme_system.
  ///
  /// In en, this message translates to:
  /// **'Same as phone'**
  String get theme_system;

  /// No description provided for @theme_light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get theme_light;

  /// No description provided for @theme_dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get theme_dark;

  /// No description provided for @language_system.
  ///
  /// In en, this message translates to:
  /// **'Same as phone'**
  String get language_system;

  /// No description provided for @interest_it.
  ///
  /// In en, this message translates to:
  /// **'IT'**
  String get interest_it;

  /// No description provided for @interest_running.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get interest_running;

  /// No description provided for @interest_cycling.
  ///
  /// In en, this message translates to:
  /// **'Cycling'**
  String get interest_cycling;

  /// No description provided for @interest_party.
  ///
  /// In en, this message translates to:
  /// **'Parties'**
  String get interest_party;

  /// No description provided for @interest_gaming.
  ///
  /// In en, this message translates to:
  /// **'Gaming'**
  String get interest_gaming;

  /// No description provided for @interest_mountains.
  ///
  /// In en, this message translates to:
  /// **'Mountains'**
  String get interest_mountains;

  /// No description provided for @interest_yoga.
  ///
  /// In en, this message translates to:
  /// **'Yoga'**
  String get interest_yoga;

  /// No description provided for @interest_coffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get interest_coffee;

  /// No description provided for @interest_cooking.
  ///
  /// In en, this message translates to:
  /// **'Cooking'**
  String get interest_cooking;

  /// No description provided for @interest_cinema.
  ///
  /// In en, this message translates to:
  /// **'Cinema'**
  String get interest_cinema;

  /// No description provided for @interest_drawing.
  ///
  /// In en, this message translates to:
  /// **'Drawing'**
  String get interest_drawing;

  /// No description provided for @interest_art.
  ///
  /// In en, this message translates to:
  /// **'Art'**
  String get interest_art;

  /// No description provided for @interest_music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get interest_music;

  /// No description provided for @interest_lofi.
  ///
  /// In en, this message translates to:
  /// **'Lo-Fi music'**
  String get interest_lofi;

  /// No description provided for @interest_board_games.
  ///
  /// In en, this message translates to:
  /// **'Board games'**
  String get interest_board_games;

  /// No description provided for @interest_learning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get interest_learning;

  /// No description provided for @interest_swimming.
  ///
  /// In en, this message translates to:
  /// **'Swimming'**
  String get interest_swimming;

  /// No description provided for @interest_travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get interest_travel;

  /// No description provided for @interest_hiking.
  ///
  /// In en, this message translates to:
  /// **'Hiking'**
  String get interest_hiking;

  /// No description provided for @interest_camping.
  ///
  /// In en, this message translates to:
  /// **'Camping'**
  String get interest_camping;

  /// No description provided for @interest_nature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get interest_nature;

  /// No description provided for @interest_programming.
  ///
  /// In en, this message translates to:
  /// **'Programming'**
  String get interest_programming;

  /// No description provided for @interest_sport.
  ///
  /// In en, this message translates to:
  /// **'Sport'**
  String get interest_sport;

  /// No description provided for @interest_dancing.
  ///
  /// In en, this message translates to:
  /// **'Dancing'**
  String get interest_dancing;

  /// No description provided for @interest_fantasy_books.
  ///
  /// In en, this message translates to:
  /// **'Fantasy books'**
  String get interest_fantasy_books;

  /// No description provided for @interest_photography.
  ///
  /// In en, this message translates to:
  /// **'Photography'**
  String get interest_photography;

  /// No description provided for @interest_fitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get interest_fitness;

  /// No description provided for @interest_reading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get interest_reading;

  /// No description provided for @ev_fill_required.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields'**
  String get ev_fill_required;

  /// No description provided for @ev_enter_title.
  ///
  /// In en, this message translates to:
  /// **'Enter the event name'**
  String get ev_enter_title;

  /// No description provided for @ev_title_min.
  ///
  /// In en, this message translates to:
  /// **'The name must be at least 3 characters'**
  String get ev_title_min;

  /// No description provided for @ev_add_description.
  ///
  /// In en, this message translates to:
  /// **'Add an event description'**
  String get ev_add_description;

  /// No description provided for @ev_desc_min.
  ///
  /// In en, this message translates to:
  /// **'The description must be at least 10 characters'**
  String get ev_desc_min;

  /// No description provided for @ev_set_location.
  ///
  /// In en, this message translates to:
  /// **'Set a location'**
  String get ev_set_location;

  /// No description provided for @ev_set_participants.
  ///
  /// In en, this message translates to:
  /// **'Set the number of participants'**
  String get ev_set_participants;

  /// No description provided for @ev_min_participants.
  ///
  /// In en, this message translates to:
  /// **'At least 2 participants'**
  String get ev_min_participants;

  /// No description provided for @ev_max_participants.
  ///
  /// In en, this message translates to:
  /// **'Maximum 100 participants'**
  String get ev_max_participants;

  /// No description provided for @ev_pick_photo.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one photo'**
  String get ev_pick_photo;

  /// No description provided for @ev_max_tags.
  ///
  /// In en, this message translates to:
  /// **'You can pick up to 5 tags'**
  String get ev_max_tags;

  /// No description provided for @ev_create_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the event. Please try again.'**
  String get ev_create_failed;

  /// No description provided for @ev_lets_create.
  ///
  /// In en, this message translates to:
  /// **'Let\'s create something special ✨'**
  String get ev_lets_create;

  /// No description provided for @ev_fill_info.
  ///
  /// In en, this message translates to:
  /// **'Fill in your event details so others can join'**
  String get ev_fill_info;

  /// No description provided for @ev_basic_info.
  ///
  /// In en, this message translates to:
  /// **'Basic information'**
  String get ev_basic_info;

  /// No description provided for @ev_title_label.
  ///
  /// In en, this message translates to:
  /// **'Event name'**
  String get ev_title_label;

  /// No description provided for @ev_title_hint.
  ///
  /// In en, this message translates to:
  /// **'For example: Party in the city centre'**
  String get ev_title_hint;

  /// No description provided for @ev_desc_label.
  ///
  /// In en, this message translates to:
  /// **'Event description'**
  String get ev_desc_label;

  /// No description provided for @ev_desc_hint.
  ///
  /// In en, this message translates to:
  /// **'Tell people more about your event…'**
  String get ev_desc_hint;

  /// No description provided for @ev_date_time.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get ev_date_time;

  /// No description provided for @ev_pick_datetime.
  ///
  /// In en, this message translates to:
  /// **'Choose the date and time'**
  String get ev_pick_datetime;

  /// No description provided for @ev_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get ev_date;

  /// No description provided for @ev_time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get ev_time;

  /// No description provided for @ev_pick_date.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get ev_pick_date;

  /// No description provided for @ev_pick_time.
  ///
  /// In en, this message translates to:
  /// **'Choose a time'**
  String get ev_pick_time;

  /// No description provided for @ev_type.
  ///
  /// In en, this message translates to:
  /// **'Event type'**
  String get ev_type;

  /// No description provided for @ev_public.
  ///
  /// In en, this message translates to:
  /// **'Public event'**
  String get ev_public;

  /// No description provided for @ev_public_hint.
  ///
  /// In en, this message translates to:
  /// **'Visible to everyone'**
  String get ev_public_hint;

  /// No description provided for @ev_private_party.
  ///
  /// In en, this message translates to:
  /// **'Private event'**
  String get ev_private_party;

  /// No description provided for @ev_private_hint.
  ///
  /// In en, this message translates to:
  /// **'Extra details are shown only to invited people'**
  String get ev_private_hint;

  /// No description provided for @ev_private_info.
  ///
  /// In en, this message translates to:
  /// **'Private information'**
  String get ev_private_info;

  /// No description provided for @ev_private_note.
  ///
  /// In en, this message translates to:
  /// **'This is shown only after a join request is approved'**
  String get ev_private_note;

  /// No description provided for @ev_general_location.
  ///
  /// In en, this message translates to:
  /// **'General area'**
  String get ev_general_location;

  /// No description provided for @ev_area_hint.
  ///
  /// In en, this message translates to:
  /// **'District or general area'**
  String get ev_area_hint;

  /// No description provided for @ev_exact_address.
  ///
  /// In en, this message translates to:
  /// **'Exact address'**
  String get ev_exact_address;

  /// No description provided for @ev_exact_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter the exact address'**
  String get ev_exact_hint;

  /// No description provided for @ev_address_example.
  ///
  /// In en, this message translates to:
  /// **'1 Main Street, apt. 10'**
  String get ev_address_example;

  /// No description provided for @ev_meeting_point.
  ///
  /// In en, this message translates to:
  /// **'Meeting point'**
  String get ev_meeting_point;

  /// No description provided for @ev_meeting_example.
  ///
  /// In en, this message translates to:
  /// **'By the main entrance to the mall'**
  String get ev_meeting_example;

  /// No description provided for @ev_extra_info.
  ///
  /// In en, this message translates to:
  /// **'Additional information'**
  String get ev_extra_info;

  /// No description provided for @ev_extra_hint.
  ///
  /// In en, this message translates to:
  /// **'What to bring, dress code and so on'**
  String get ev_extra_hint;

  /// No description provided for @ev_message_title.
  ///
  /// In en, this message translates to:
  /// **'Message for participants'**
  String get ev_message_title;

  /// No description provided for @ev_message_hint.
  ///
  /// In en, this message translates to:
  /// **'A personal note the invited people will see'**
  String get ev_message_hint;

  /// No description provided for @ev_tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get ev_tags;

  /// No description provided for @ev_tags_hint.
  ///
  /// In en, this message translates to:
  /// **'Choose the tags that best describe your event (up to 5)'**
  String get ev_tags_hint;

  /// No description provided for @ev_photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get ev_photos;

  /// No description provided for @ev_photos_hint.
  ///
  /// In en, this message translates to:
  /// **'Add your own photos from the gallery (up to 5)'**
  String get ev_photos_hint;

  /// No description provided for @ev_max_participants_label.
  ///
  /// In en, this message translates to:
  /// **'Maximum participants'**
  String get ev_max_participants_label;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @pr_edit_title.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get pr_edit_title;

  /// No description provided for @pr_your_photos.
  ///
  /// In en, this message translates to:
  /// **'Your photos'**
  String get pr_your_photos;

  /// No description provided for @pr_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get pr_name;

  /// No description provided for @pr_enter_name.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get pr_enter_name;

  /// No description provided for @pr_birth_date.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get pr_birth_date;

  /// No description provided for @pr_pick_birth.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get pr_pick_birth;

  /// No description provided for @pr_need_birth.
  ///
  /// In en, this message translates to:
  /// **'Please enter your date of birth'**
  String get pr_need_birth;

  /// No description provided for @pr_location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get pr_location;

  /// No description provided for @pr_enter_location.
  ///
  /// In en, this message translates to:
  /// **'Enter your location'**
  String get pr_enter_location;

  /// No description provided for @pr_enter_city.
  ///
  /// In en, this message translates to:
  /// **'Enter a city'**
  String get pr_enter_city;

  /// No description provided for @pr_about.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get pr_about;

  /// No description provided for @pr_about_hint.
  ///
  /// In en, this message translates to:
  /// **'Tell people about yourself…'**
  String get pr_about_hint;

  /// No description provided for @pr_hobbies.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get pr_hobbies;

  /// No description provided for @pr_search_hobby.
  ///
  /// In en, this message translates to:
  /// **'Search interests…'**
  String get pr_search_hobby;

  /// No description provided for @pr_no_hobbies.
  ///
  /// In en, this message translates to:
  /// **'No interests found'**
  String get pr_no_hobbies;

  /// No description provided for @pr_try_other_query.
  ///
  /// In en, this message translates to:
  /// **'Try a different search'**
  String get pr_try_other_query;

  /// No description provided for @pr_save_changes.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get pr_save_changes;

  /// No description provided for @pr_saved.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get pr_saved;

  /// No description provided for @pr_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the profile'**
  String get pr_save_failed;

  /// No description provided for @pr_max_hobbies.
  ///
  /// In en, this message translates to:
  /// **'You can pick up to 8 interests'**
  String get pr_max_hobbies;

  /// No description provided for @pr_limit.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get pr_limit;

  /// No description provided for @rg_meet.
  ///
  /// In en, this message translates to:
  /// **'Getting to know you'**
  String get rg_meet;

  /// No description provided for @rg_how_to_call.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get rg_how_to_call;

  /// No description provided for @rg_your_phone.
  ///
  /// In en, this message translates to:
  /// **'Your number'**
  String get rg_your_phone;

  /// No description provided for @rg_check_free.
  ///
  /// In en, this message translates to:
  /// **'We’ll send a confirmation code. Only you can see your number.'**
  String get rg_check_free;

  /// No description provided for @rg_sms_title.
  ///
  /// In en, this message translates to:
  /// **'Code from SMS'**
  String get rg_sms_title;

  /// No description provided for @rg_enter_6.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6 digits sent to your number'**
  String get rg_enter_6;

  /// No description provided for @rg_code_incomplete.
  ///
  /// In en, this message translates to:
  /// **'Enter the full code'**
  String get rg_code_incomplete;

  /// No description provided for @rg_age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get rg_age;

  /// No description provided for @rg_adults_only.
  ///
  /// In en, this message translates to:
  /// **'Adults only (18+)'**
  String get rg_adults_only;

  /// No description provided for @rg_need_birth.
  ///
  /// In en, this message translates to:
  /// **'Enter your date of birth'**
  String get rg_need_birth;

  /// No description provided for @rg_protect.
  ///
  /// In en, this message translates to:
  /// **'Secure your account'**
  String get rg_protect;

  /// No description provided for @rg_strong_password.
  ///
  /// In en, this message translates to:
  /// **'Create a strong password'**
  String get rg_strong_password;

  /// No description provided for @rg_password_short.
  ///
  /// In en, this message translates to:
  /// **'Password is too short'**
  String get rg_password_short;

  /// No description provided for @fp_title.
  ///
  /// In en, this message translates to:
  /// **'Account recovery'**
  String get fp_title;

  /// No description provided for @fp_enter_phone.
  ///
  /// In en, this message translates to:
  /// **'Enter the number linked to the account'**
  String get fp_enter_phone;

  /// No description provided for @fp_not_found.
  ///
  /// In en, this message translates to:
  /// **'No account found with this number'**
  String get fp_not_found;

  /// No description provided for @fp_new_strong.
  ///
  /// In en, this message translates to:
  /// **'Create a new strong password'**
  String get fp_new_strong;

  /// No description provided for @el_title.
  ///
  /// In en, this message translates to:
  /// **'Likes on my events'**
  String get el_title;

  /// No description provided for @el_who_wants.
  ///
  /// In en, this message translates to:
  /// **'People who want to come:'**
  String get el_who_wants;

  /// No description provided for @el_no_likes.
  ///
  /// In en, this message translates to:
  /// **'No likes yet'**
  String get el_no_likes;

  /// No description provided for @el_no_events.
  ///
  /// In en, this message translates to:
  /// **'You have no events yet'**
  String get el_no_events;

  /// No description provided for @el_create_hint.
  ///
  /// In en, this message translates to:
  /// **'Create an event to start receiving likes'**
  String get el_create_hint;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @likes_count.
  ///
  /// In en, this message translates to:
  /// **'{count} likes'**
  String likes_count(int count);

  /// No description provided for @user_accepted.
  ///
  /// In en, this message translates to:
  /// **'{name} was accepted to the event'**
  String user_accepted(String name);

  /// No description provided for @user_declined.
  ///
  /// In en, this message translates to:
  /// **'Request from {name} declined'**
  String user_declined(String name);

  /// No description provided for @request_sent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get request_sent;

  /// No description provided for @request_sent_msg.
  ///
  /// In en, this message translates to:
  /// **'Request sent with your message'**
  String get request_sent_msg;

  /// No description provided for @m_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get m_pending;

  /// No description provided for @m_accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get m_accepted;

  /// No description provided for @m_no_pending.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get m_no_pending;

  /// No description provided for @m_no_accepted.
  ///
  /// In en, this message translates to:
  /// **'No accepted invitations'**
  String get m_no_accepted;

  /// No description provided for @m_requests_here.
  ///
  /// In en, this message translates to:
  /// **'Your requests will appear here'**
  String get m_requests_here;

  /// No description provided for @md_like_user.
  ///
  /// In en, this message translates to:
  /// **'Like a person'**
  String get md_like_user;

  /// No description provided for @md_like_event.
  ///
  /// In en, this message translates to:
  /// **'Like an event'**
  String get md_like_event;

  /// No description provided for @md_liked_user.
  ///
  /// In en, this message translates to:
  /// **'You liked {name}'**
  String md_liked_user(String name);

  /// No description provided for @md_liked_event.
  ///
  /// In en, this message translates to:
  /// **'You liked the event'**
  String get md_liked_event;

  /// No description provided for @md_nice_hint.
  ///
  /// In en, this message translates to:
  /// **'Write something nice…'**
  String get md_nice_hint;

  /// No description provided for @md_join_hint.
  ///
  /// In en, this message translates to:
  /// **'Write why you want to join the event…'**
  String get md_join_hint;

  /// No description provided for @md_sending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get md_sending;

  /// No description provided for @ch_now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get ch_now;

  /// No description provided for @ch_yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get ch_yesterday;

  /// No description provided for @ch_unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get ch_unknown;

  /// No description provided for @ch_user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get ch_user;

  /// No description provided for @no_name.
  ///
  /// In en, this message translates to:
  /// **'No name'**
  String get no_name;

  /// No description provided for @loading_info.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading_info;

  /// No description provided for @no_description.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get no_description;

  /// No description provided for @err_rate_limit.
  ///
  /// In en, this message translates to:
  /// **'Too many actions in a row. Please try again a bit later.'**
  String get err_rate_limit;

  /// No description provided for @err_forbidden.
  ///
  /// In en, this message translates to:
  /// **'You do not have access to this data.'**
  String get err_forbidden;

  /// No description provided for @err_save.
  ///
  /// In en, this message translates to:
  /// **'Could not save the changes. Please try again.'**
  String get err_save;

  /// No description provided for @err_storage.
  ///
  /// In en, this message translates to:
  /// **'Could not upload the photo. Check the file size and format.'**
  String get err_storage;

  /// No description provided for @err_network.
  ///
  /// In en, this message translates to:
  /// **'No connection to the server. Check your internet.'**
  String get err_network;

  /// No description provided for @err_unknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get err_unknown;

  /// No description provided for @err_not_authed.
  ///
  /// In en, this message translates to:
  /// **'You are not signed in'**
  String get err_not_authed;

  /// No description provided for @err_sms_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the SMS'**
  String get err_sms_failed;

  /// No description provided for @err_wrong_code.
  ///
  /// In en, this message translates to:
  /// **'Wrong code'**
  String get err_wrong_code;

  /// No description provided for @err_update_password.
  ///
  /// In en, this message translates to:
  /// **'Could not update the password'**
  String get err_update_password;

  /// No description provided for @err_delete_account.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the account'**
  String get err_delete_account;

  /// No description provided for @loc_updated.
  ///
  /// In en, this message translates to:
  /// **'Location updated'**
  String get loc_updated;

  /// No description provided for @loc_disabled.
  ///
  /// In en, this message translates to:
  /// **'Location is turned off in your phone settings'**
  String get loc_disabled;

  /// No description provided for @loc_denied.
  ///
  /// In en, this message translates to:
  /// **'Without location access we cannot show people nearby'**
  String get loc_denied;

  /// No description provided for @loc_denied_forever.
  ///
  /// In en, this message translates to:
  /// **'Location access was denied. Turn it on in your phone settings'**
  String get loc_denied_forever;

  /// No description provided for @loc_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not determine your location. Please try again'**
  String get loc_failed;

  /// No description provided for @settings_button.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_button;

  /// No description provided for @deleted_user.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted_user;

  /// No description provided for @ae_going.
  ///
  /// In en, this message translates to:
  /// **'You are going to this event 🎉'**
  String get ae_going;

  /// No description provided for @ae_accepted_on.
  ///
  /// In en, this message translates to:
  /// **'Accepted {date}'**
  String ae_accepted_on(String date);

  /// No description provided for @ae_about.
  ///
  /// In en, this message translates to:
  /// **'About the event'**
  String get ae_about;

  /// No description provided for @ae_organizer.
  ///
  /// In en, this message translates to:
  /// **'Organiser'**
  String get ae_organizer;

  /// No description provided for @ae_organizer_msg.
  ///
  /// In en, this message translates to:
  /// **'Message from the organiser'**
  String get ae_organizer_msg;

  /// No description provided for @ae_participants.
  ///
  /// In en, this message translates to:
  /// **'Participants ({count})'**
  String ae_participants(int count);

  /// No description provided for @ae_participants_of.
  ///
  /// In en, this message translates to:
  /// **'Participants: {joined}/{total}'**
  String ae_participants_of(int joined, int total);

  /// No description provided for @ae_route.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get ae_route;

  /// No description provided for @ae_event_chat.
  ///
  /// In en, this message translates to:
  /// **'Event chat'**
  String get ae_event_chat;

  /// No description provided for @ae_opening_route.
  ///
  /// In en, this message translates to:
  /// **'Opening directions to \"{place}\"'**
  String ae_opening_route(String place);

  /// No description provided for @ae_opening_chat.
  ///
  /// In en, this message translates to:
  /// **'Opening the chat for \"{title}\"'**
  String ae_opening_chat(String title);

  /// No description provided for @ae_sharing.
  ///
  /// In en, this message translates to:
  /// **'Sharing \"{title}\"'**
  String ae_sharing(String title);

  /// No description provided for @ae_remind.
  ///
  /// In en, this message translates to:
  /// **'Remind me an hour before'**
  String get ae_remind;

  /// No description provided for @ae_reminder_set.
  ///
  /// In en, this message translates to:
  /// **'Reminder set for an hour before the event 🔔'**
  String get ae_reminder_set;

  /// No description provided for @ae_leave_review.
  ///
  /// In en, this message translates to:
  /// **'Leave a review'**
  String get ae_leave_review;

  /// No description provided for @ae_how_was_it.
  ///
  /// In en, this message translates to:
  /// **'How was the event?'**
  String get ae_how_was_it;

  /// No description provided for @ae_thanks_review.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your review ⭐'**
  String get ae_thanks_review;

  /// No description provided for @ae_finished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get ae_finished;

  /// No description provided for @ae_event_over.
  ///
  /// In en, this message translates to:
  /// **'The event has ended'**
  String get ae_event_over;

  /// No description provided for @ae_today.
  ///
  /// In en, this message translates to:
  /// **'The event is today'**
  String get ae_today;

  /// No description provided for @ae_now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get ae_now;

  /// No description provided for @ae_days_left.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String ae_days_left(int days);

  /// No description provided for @ae_in_days.
  ///
  /// In en, this message translates to:
  /// **'In {days} d'**
  String ae_in_days(int days);

  /// No description provided for @ae_in_hours.
  ///
  /// In en, this message translates to:
  /// **'In {hours} h'**
  String ae_in_hours(int hours);

  /// No description provided for @ae_in_minutes.
  ///
  /// In en, this message translates to:
  /// **'In {minutes} min'**
  String ae_in_minutes(int minutes);

  /// No description provided for @ae_days_ago.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String ae_days_ago(int days);

  /// No description provided for @ae_members_only.
  ///
  /// In en, this message translates to:
  /// **'This is visible only to event participants'**
  String get ae_members_only;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get yesterday;

  /// No description provided for @today_lc.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get today_lc;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @typing_now.
  ///
  /// In en, this message translates to:
  /// **'typing…'**
  String get typing_now;

  /// No description provided for @st_end_session.
  ///
  /// In en, this message translates to:
  /// **'End the current session'**
  String get st_end_session;

  /// No description provided for @st_delete_data.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your data'**
  String get st_delete_data;

  /// No description provided for @st_update_password.
  ///
  /// In en, this message translates to:
  /// **'Update your password'**
  String get st_update_password;

  /// No description provided for @ev_created_ok.
  ///
  /// In en, this message translates to:
  /// **'Event \"{title}\" created 🎉'**
  String ev_created_ok(String title);

  /// No description provided for @sign_in_title.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get sign_in_title;

  /// No description provided for @ended_badge.
  ///
  /// In en, this message translates to:
  /// **'ENDED'**
  String get ended_badge;

  /// No description provided for @default_bio.
  ///
  /// In en, this message translates to:
  /// **'Hi! I am new here…'**
  String get default_bio;

  /// No description provided for @default_country.
  ///
  /// In en, this message translates to:
  /// **'Ukraine'**
  String get default_country;

  /// No description provided for @city_prefix.
  ///
  /// In en, this message translates to:
  /// **'{city}'**
  String city_prefix(String city);

  /// No description provided for @landing_headline.
  ///
  /// In en, this message translates to:
  /// **'Your people are closer than you think'**
  String get landing_headline;

  /// No description provided for @landing_sub.
  ///
  /// In en, this message translates to:
  /// **'We show people nearby who are into the same things. Then it is coffee, mountains or a quiz night.'**
  String get landing_sub;

  /// No description provided for @landing_eyebrow.
  ///
  /// In en, this message translates to:
  /// **'friends nearby'**
  String get landing_eyebrow;

  /// No description provided for @terms_line.
  ///
  /// In en, this message translates to:
  /// **'By continuing you accept the {terms} and {privacy}'**
  String terms_line(String terms, String privacy);

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get terms;

  /// No description provided for @privacy_policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacy_policy;

  /// No description provided for @have_account.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get have_account;

  /// No description provided for @continue_with_phone.
  ///
  /// In en, this message translates to:
  /// **'Continue with phone number'**
  String get continue_with_phone;

  /// No description provided for @or_divider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or_divider;

  /// No description provided for @social_soon.
  ///
  /// In en, this message translates to:
  /// **'Google and Apple sign-in are coming soon'**
  String get social_soon;

  /// No description provided for @rg_phone_note.
  ///
  /// In en, this message translates to:
  /// **'We never show your number to anyone else, and we never send ads.'**
  String get rg_phone_note;

  /// No description provided for @rg_sms_sent_to.
  ///
  /// In en, this message translates to:
  /// **'Sent to {phone}'**
  String rg_sms_sent_to(String phone);

  /// No description provided for @rg_resend_in.
  ///
  /// In en, this message translates to:
  /// **'You can resend in {time}'**
  String rg_resend_in(String time);

  /// No description provided for @rg_resend_now.
  ///
  /// In en, this message translates to:
  /// **'Resend the code'**
  String get rg_resend_now;

  /// No description provided for @rg_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get rg_confirm;

  /// No description provided for @rg_next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get rg_next;

  /// No description provided for @rg_about_title.
  ///
  /// In en, this message translates to:
  /// **'What’s your name'**
  String get rg_about_title;

  /// No description provided for @rg_about_sub.
  ///
  /// In en, this message translates to:
  /// **'Others will see your name and age. No surname needed.'**
  String get rg_about_sub;

  /// No description provided for @rg_name_label.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get rg_name_label;

  /// No description provided for @rg_birth_label.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get rg_birth_label;

  /// No description provided for @rg_pick_date.
  ///
  /// In en, this message translates to:
  /// **'pick a date'**
  String get rg_pick_date;

  /// No description provided for @rg_age_gate.
  ///
  /// In en, this message translates to:
  /// **'The app is for adults only. We check your age when you sign up.'**
  String get rg_age_gate;

  /// No description provided for @rg_password_note.
  ///
  /// In en, this message translates to:
  /// **'A password lets you sign in even if you lose access to your number.'**
  String get rg_password_note;

  /// No description provided for @login_sub.
  ///
  /// In en, this message translates to:
  /// **'Sign in the same way you signed up — otherwise you’ll end up with a second profile.'**
  String get login_sub;

  /// No description provided for @or_by_phone.
  ///
  /// In en, this message translates to:
  /// **'or by phone'**
  String get or_by_phone;

  /// No description provided for @phone_label.
  ///
  /// In en, this message translates to:
  /// **'phone'**
  String get phone_label;

  /// No description provided for @show_password.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show_password;

  /// No description provided for @hide_password.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide_password;

  /// No description provided for @nav_feed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get nav_feed;

  /// No description provided for @nav_chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get nav_chats;

  /// No description provided for @nav_matches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get nav_matches;

  /// No description provided for @nav_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get nav_profile;

  /// No description provided for @match_percent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% match'**
  String match_percent(int percent);

  /// No description provided for @likes_you.
  ///
  /// In en, this message translates to:
  /// **'Likes you'**
  String get likes_you;

  /// No description provided for @dist_km_short.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String dist_km_short(String km);

  /// No description provided for @search_events.
  ///
  /// In en, this message translates to:
  /// **'Search events'**
  String get search_events;

  /// No description provided for @seats_of.
  ///
  /// In en, this message translates to:
  /// **'{taken} of {total} seats'**
  String seats_of(int taken, int total);

  /// No description provided for @online_now.
  ///
  /// In en, this message translates to:
  /// **'Online now'**
  String get online_now;

  /// No description provided for @profile_add_about.
  ///
  /// In en, this message translates to:
  /// **'Tell people about yourself →'**
  String get profile_add_about;

  /// No description provided for @profile_add_interests.
  ///
  /// In en, this message translates to:
  /// **'Add your interests →'**
  String get profile_add_interests;

  /// No description provided for @feed_empty_radius_title.
  ///
  /// In en, this message translates to:
  /// **'No one within {km} km'**
  String feed_empty_radius_title(int km);

  /// No description provided for @feed_empty_widen_hint.
  ///
  /// In en, this message translates to:
  /// **'It’s quiet around here. Try a wider radius — people are usually happy to travel half an hour.'**
  String get feed_empty_widen_hint;

  /// No description provided for @or_word.
  ///
  /// In en, this message translates to:
  /// **'Or'**
  String get or_word;

  /// No description provided for @feed_empty_events_link.
  ///
  /// In en, this message translates to:
  /// **'check out the events — people join those'**
  String get feed_empty_events_link;

  /// No description provided for @feed_finished_body.
  ///
  /// In en, this message translates to:
  /// **'You’ve seen everyone nearby. New people show up every day.'**
  String get feed_finished_body;

  /// No description provided for @seg_invites.
  ///
  /// In en, this message translates to:
  /// **'Invites'**
  String get seg_invites;

  /// No description provided for @m_accepted_chip.
  ///
  /// In en, this message translates to:
  /// **'accepted'**
  String get m_accepted_chip;

  /// No description provided for @m_pending_chip.
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get m_pending_chip;

  /// No description provided for @m_chat_open.
  ///
  /// In en, this message translates to:
  /// **'chat open'**
  String get m_chat_open;

  /// No description provided for @pr_update_location.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get pr_update_location;

  /// No description provided for @of_count.
  ///
  /// In en, this message translates to:
  /// **'of {total}'**
  String of_count(int total);

  /// No description provided for @continue_with_email.
  ///
  /// In en, this message translates to:
  /// **'Continue with email'**
  String get continue_with_email;

  /// No description provided for @rg_email_title.
  ///
  /// In en, this message translates to:
  /// **'Your email'**
  String get rg_email_title;

  /// No description provided for @rg_email_sub.
  ///
  /// In en, this message translates to:
  /// **'We’ll email you a code. Only we see your email — it’s not shown on your profile.'**
  String get rg_email_sub;

  /// No description provided for @email_label.
  ///
  /// In en, this message translates to:
  /// **'email'**
  String get email_label;

  /// No description provided for @rg_password_hint.
  ///
  /// In en, this message translates to:
  /// **'at least 6 characters'**
  String get rg_password_hint;

  /// No description provided for @rg_email_note.
  ///
  /// In en, this message translates to:
  /// **'No newsletters — only sign-in and the notifications you turn on yourself.'**
  String get rg_email_note;

  /// No description provided for @rg_email_code_title.
  ///
  /// In en, this message translates to:
  /// **'Code from the email'**
  String get rg_email_code_title;

  /// No description provided for @rg_spam_hint.
  ///
  /// In en, this message translates to:
  /// **'Didn’t arrive? Check your Spam folder.'**
  String get rg_spam_hint;

  /// No description provided for @enter_valid_email.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enter_valid_email;

  /// No description provided for @or_by_email.
  ///
  /// In en, this message translates to:
  /// **'or by email'**
  String get or_by_email;

  /// No description provided for @account_exists_email_body.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Sign in with your password — or reset it if you forgot.'**
  String get account_exists_email_body;

  /// No description provided for @feed_enable_location.
  ///
  /// In en, this message translates to:
  /// **'We don’t know where you are — showing everyone'**
  String get feed_enable_location;

  /// No description provided for @feed_enable_location_action.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get feed_enable_location_action;

  /// No description provided for @feed_location_denied.
  ///
  /// In en, this message translates to:
  /// **'Without location permission we can’t show distance'**
  String get feed_location_denied;
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
      <String>['en', 'es', 'pl', 'pt', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
