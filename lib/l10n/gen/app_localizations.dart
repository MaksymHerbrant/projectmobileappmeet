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
  /// **'Login'**
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
  /// **'Events nearby'**
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
