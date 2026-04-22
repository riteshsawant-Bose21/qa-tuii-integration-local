import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fusion_app/features/authentication/presentation/login_page.dart';
import 'package:fusion_app/features/authentication/presentation/mobile_sign_in_page.dart';
import 'package:fusion_app/features/commission/presentation/network/select_hardware/select_hardware.dart';
import 'package:fusion_app/features/commission/widgets/available_bluetooth_devices.dart';
import 'package:fusion_app/features/commission/presentation/bluetooth/configure_bluetooth_screen.dart';
import 'package:fusion_app/features/commission/presentation/bluetooth/configure_wifi_creds_screen.dart';
import 'package:fusion_app/features/commission/presentation/network/configure_mapping.dart';
import 'package:fusion_app/features/commission/presentation/configure_network.dart';
import 'package:fusion_app/features/commission/presentation/network/search/search_device_screen.dart';
import 'package:fusion_app/features/commission/presentation/network/configure_vip_screen.dart';
import 'package:fusion_app/features/control_pal/presentation/control_pal_screen.dart';
import 'package:fusion_app/features/devices/presentation/devices_screen.dart';
import 'package:fusion_app/features/events/presentation/events_screen.dart';
import 'package:fusion_app/features/landing/presentation/pages/home/home_screen.dart';
import 'package:fusion_app/features/landing/presentation/pages/settings/general_settings_screen.dart';
import 'package:fusion_app/features/landing/presentation/pages/search/search_screen.dart';
import 'package:fusion_app/features/landing/presentation/pages/settings/settings_screen.dart';
import 'package:fusion_app/features/dashboard/presentation/pages/home_screen.dart';
import 'package:fusion_app/features/landing/presentation/pages/settings/updates_screen.dart';
import 'package:fusion_app/features/message_player/presentation/message_player_all.dart';
import 'package:fusion_app/features/message_player/presentation/message_player_playing.dart';
import 'package:fusion_app/features/notification/presentation/notification_screen.dart';
import 'package:fusion_app/features/passcode/passcode_screen.dart';
import 'package:fusion_app/features/profile/presentation/address_information_screen.dart';
import 'package:fusion_app/features/profile/presentation/credentials_information_screen.dart';
import 'package:fusion_app/features/profile/presentation/personal_information_screen.dart';
import 'package:fusion_app/features/landing/presentation/pages/settings/profile_screen.dart';
import 'package:fusion_app/features/profile/presentation/preferences_screen.dart';
import 'package:fusion_app/features/project/presentation/project_screen.dart';
import 'package:fusion_app/features/scanner/qr_scanner.dart';
import 'package:fusion_app/features/snapshots/presentation/snapshot_group_screen.dart';
import 'package:fusion_app/features/wall_controllers/presentation/wall_controllers_screen.dart';
import 'package:fusion_app/features/zones/presentation/zone_volume_control.dart';
import 'package:fusion_app/features/zones/presentation/zones_screen.dart';

import '../../features/project/presentation/building/project_work_area_screen.dart';

class Routes {
  static const String loginPage = '/loginPage';
  static const String mobileSignInPage = '/mobileSignInPage';
  static const String landingPage = '/landingPage';
  static const String qrScannerPage = '/qrScannerPage';
  static const String passcodePage = '/passcodePage';
  static const String homePage = '/homePage';
  static const String searchPage = '/searchPage';
  static const String settingsPage = '/settingsPage';
  static const String generalSettingPage = '/generalSettingPage';
  static const String updatesPage = '/updatesPage';
  static const String notificationPage = '/mobileNotificationPage';
  static const String eventPage = '/eventPage';
  static const String controlPalPage = '/controlPalPage';
  static const String snapshotGroupPage = '/snapshotGroupPage';
  static const String zoneVolumeControlPage = '/zoneVolumeControlPage';
  static const String wallControllerPage = '/wallControllerPage';
  static const String messagePlayerViewPage = '/messagePlayerViewPage';
  static const String messagePlayerPlayingPage = '/messagePlayerPlayingPage';
  static const String zonePage = '/zonePage';
  static const String devicePage = '/devicePage';
  static const String profilePage = '/profilePage';
  static const String personalInfoPage = '/personalInfoPage';
  static const String accountCredentialsInfoPage = '/accountCredentialsInfoPage';
  static const String preferencesPage = '/preferencesPage';
  static const String addressPage = '/addressPage';
  static const String projectPage = '/projectPage';
  static const String mylibraryPage = '/mylibraryPage';

  static const String configureNetwork = '/configureNetworkPage';
  static const String selectHardware = '/selectHardwarePage';
  static const String configureNetworkSearch = '/configureNetworkSearchPage';
  static const String configureVIP = '/configureVIPPage';
  static const String configureMapping = '/configureMappingPage';
  static const String configureSearchBluetooth = '/configureSearchBluetoothPage';
  static const String configureAvailableBluetooth = '/configureAvailableBluetoothPage';
  static const String configureWifiCreds = '/configureWifiCredsPage';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      /// Sign In Page
      // case mobileSignInPage:
      //   return PageRouteBuilder<void>(
      //     pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) =>  MobileSignInPage(),
      //     transitionDuration: Duration.zero,
      //     reverseTransitionDuration: Duration.zero,
      //     settings: const RouteSettings(name: mobileSignInPage),
      //   );

      /// Home Page
      case loginPage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) =>  FusionLoginScreen(),
          settings: const RouteSettings(name: loginPage),
        );

    /// Landing Page
      case landingPage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) =>  HomeScreen(),
          settings: const RouteSettings(name: landingPage),
        );
    /// QR Scanner Page
      case qrScannerPage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) =>  QrScannerScreen(),
          settings: const RouteSettings(name: qrScannerPage),
        );
    /// QR Scanner Page
      case passcodePage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) =>  PasscodeScreen(),
          settings: const RouteSettings(name: passcodePage),
        );

      /// Home Page
      case homePage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) =>  DashboardScreen(),
          settings: const RouteSettings(name: homePage),
        );

    /// Search Projects
      case searchPage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) =>  SearchProjectsScreen(),
          settings: const RouteSettings(name: searchPage),
        );

    /// Settings Page
      case settingsPage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) =>  SettingsScreen(),
          settings: const RouteSettings(name: settingsPage),
        );

    /// Settings Page
      case controlPalPage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) =>  ControlPalScreen(),
          settings: const RouteSettings(name: controlPalPage),
        );

    /// Snapshot Group Page
      case snapshotGroupPage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) =>  SnapshotGroupScreen(),
          settings: const RouteSettings(name: snapshotGroupPage),
        );


      /// Zone Volume Controller Page
      case zoneVolumeControlPage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) =>  ZoneVolumeControl(
           ),
          settings: const RouteSettings(name: zoneVolumeControlPage),
        );




    /// Updates Page
      case updatesPage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) =>  UpdatesScreen(),
          settings: const RouteSettings(name: updatesPage),
        );


    /// General Settings Page
      case generalSettingPage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) =>  GeneralSettingsScreen(),
          settings: const RouteSettings(name: generalSettingPage),
        );


    /// Home Page
      case notificationPage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) =>  NotificationsScreen(),
          settings: const RouteSettings(name: notificationPage),
        );


    /// Profile Page
      case profilePage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) =>  ProfileScreen(),
          settings: const RouteSettings(name: profilePage),
        );

    /// Profile Page
      case accountCredentialsInfoPage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) =>  AccountCredentialScreen(),
          settings: const RouteSettings(name: accountCredentialsInfoPage),
        );

      case preferencesPage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) =>  PreferencesScreen(),
          settings: const RouteSettings(name: preferencesPage),
        );


      case addressPage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) =>  AddressInformationScreen(),
          settings: const RouteSettings(name: addressPage),
        );


    /// Event Page
      case wallControllerPage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) =>  WallControllersScreen(),
          settings: const RouteSettings(name: wallControllerPage),
        );

    /// Event Page
      case eventPage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) =>  EventsScreen(),
          settings: const RouteSettings(name: eventPage),
        );

    /// Message Player View Page
      case messagePlayerViewPage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) =>  MessagePlayerView(),
          settings: const RouteSettings(name: messagePlayerViewPage),
        );

    /// Message PLayer Playing Page
      case messagePlayerPlayingPage:

        Map<String,dynamic> data = routeSettings.arguments as Map<String,dynamic>;

        return CupertinoPageRoute<void>(
          builder: (BuildContext context) =>  MessagePlayerPlaying(title: data['title']),
          settings: const RouteSettings(name: messagePlayerPlayingPage),
        );


    /// Zone Page
      case zonePage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) =>  ZonesScreen(),
          settings: const RouteSettings(name: zonePage),
        );


    /// Profile Page
      case devicePage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) =>  DevicesScreen(),
          settings: const RouteSettings(name: devicePage),
        );


    /// Persona Information Page
      case personalInfoPage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) =>  PersonalInformationScreen(),
          settings: const RouteSettings(name: personalInfoPage),
        );

    /// Project Page
    //   case projectPage:
    //     return CupertinoPageRoute<void>(
    //       builder:
    //           (BuildContext context) => ProjectScreen(),
    //       settings: const RouteSettings(name: projectPage),
    //     );

      /// My Library Page
      case configureNetwork:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) => ConfigureNetworkScreen(),
          settings: const RouteSettings(name: configureNetwork),
        );

        case selectHardware:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) => SelectHardware(),
          settings: const RouteSettings(name: selectHardware),
        );
      case configureNetworkSearch:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) => DeviceSearchingScreen(),
          settings: const RouteSettings(name: configureNetworkSearch),
        );

      case configureVIP:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) => ConfigureVipScreen(),
          settings: const RouteSettings(name: configureVIP),
        );

      case configureMapping:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) => ConfigureDevicesScreen(),
          settings: const RouteSettings(name: configureMapping),
        );

      case configureSearchBluetooth:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) => ConfigureBluetoothSearchingScreen(),
          settings: const RouteSettings(name: configureSearchBluetooth),
        );

      case configureWifiCreds:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) => WifiCredentialsScreen(),
          settings: const RouteSettings(name: configureWifiCreds),
        );

      default:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) =>  FusionLoginScreen(),
          settings: const RouteSettings(name: loginPage),
        );
    }
  }
}
