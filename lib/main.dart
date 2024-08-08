// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:asset_inspections/Models/camera_model.dart';
import 'package:asset_inspections/phone_id.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
//import 'package:asset_inspections/database_helper.dart';
import 'package:flutter/material.dart'; // Import MaterialApp and Key
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Import FlutterScreenUtil
import 'package:provider/provider.dart'; // Import ChangeNotifierProvider

import 'package:asset_inspections/Pokit_Multimeter/Providers/multimeterservice.dart'; // Import the MultimeterService and related classes
import 'package:asset_inspections/Util/cycle_settings_notifier.dart';
import 'package:asset_inspections/mainpage_ui.dart';
//import 'package:sqflite/sqflite.dart';

import 'ISO_OVP/isokit_page.dart'; // Import the ISOPage
import 'Models/project_model.dart'; // Import the ProjectModel
import 'Pokit_Multimeter/Providers/bluetooth_manager_notifier.dart'; // Import the BluetoothManager
import 'Rectifier/rec_changeNotifier.dart'; // Import the RectifierNotifier
import 'Rectifier/rectifiers_page.dart'; // Import the RectifiersPage
import 'Tanks/tanks_page.dart'; // Import the TanksPage
import 'Test_Station/ts_notifier.dart'; // Import the TestStationNotifier
import 'Test_Station/ts_page.dart'; // Import the TestStationsPage
//import 'Models/camera_model.dart'; // Import the CameraSettings

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock the device orientation to portrait up and portrait down
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await DeviceInfo().initPlatformState();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CycleSettingsModel()),
        ChangeNotifierProvider(create: (context) => CameraSettings()),
        ChangeNotifierProvider(create: (context) => ProjectModel()),
        ChangeNotifierProvider(
            create: (context) => RectifierNotifier(
                  Provider.of<ProjectModel>(context, listen: false),
                )),
        ChangeNotifierProvider(
            create: (context) => TSNotifier(
                  Provider.of<ProjectModel>(context, listen: false),
                )),
        ChangeNotifierProvider(create: (context) => BluetoothManager.instance),
        ChangeNotifierProvider(create: (context) => MultimeterService.instance),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(384, 824),
      child: MaterialApp(
        home: MainPage(key: UniqueKey()),
        routes: {
          '/test_stations': (context) => const TestStationsPage(),
          '/rectifiers': (context) => RectifiersPage(),
          '/tanks': (context) => TanksPage(),
          '/iso': (context) => ISOPage(),
        },
        theme: FlexThemeData.light(
          colors: const FlexSchemeColor(
            primary: Color(0xff002b5c),
            primaryContainer: Color(0xffd0e4ff),
            secondary: Color(0xfff78f1e),
            secondaryContainer: Color(0xfffcd3a7),
            tertiary: Color(0xff32bfe8),
            tertiaryContainer: Color(0xffb0e6f6),
            appBarColor: Color(0xfffcd3a7),
            error: Color(0xffb00020),
          ),
          surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
          blendLevel: 10,
          subThemesData: const FlexSubThemesData(
            blendOnLevel: 13,
            useTextTheme: true,
            useM2StyleDividerInM3: true,
            outlinedButtonBorderWidth: 1.0,
            outlinedButtonPressedBorderWidth: 2.0,
            segmentedButtonBorderWidth: 1.0,
            sliderTrackHeight: 7,
            alignedDropdown: true,
            useInputDecoratorThemeInDialogs: true,
          ),
          useMaterial3ErrorColors: true,
          visualDensity: FlexColorScheme.comfortablePlatformDensity,
          useMaterial3: true,
          // To use the Playground font, add GoogleFonts package and uncomment
          // fontFamily: GoogleFonts.notoSans().fontFamily,
        ),
        darkTheme: FlexThemeData.dark(
          colors: const FlexSchemeColor(
            primary: Color(0xff002b5c),
            primaryContainer: Color(0xffd0e4ff),
            secondary: Color(0xfff78f1e),
            secondaryContainer: Color(0xfffcd3a7),
            tertiary: Color(0xff32bfe8),
            tertiaryContainer: Color(0xffb0e6f6),
            appBarColor: Color(0xfffcd3a7),
            error: Color(0xffb00020),
          ).defaultError.toDark(10, true),
          surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
          blendLevel: 8,
          subThemesData: const FlexSubThemesData(
            blendOnLevel: 20,
            useTextTheme: true,
            useM2StyleDividerInM3: true,
            outlinedButtonBorderWidth: 1.0,
            outlinedButtonPressedBorderWidth: 2.0,
            segmentedButtonBorderWidth: 1.0,
            sliderTrackHeight: 7,
            alignedDropdown: true,
            useInputDecoratorThemeInDialogs: true,
          ),
          useMaterial3ErrorColors: true,
          visualDensity: FlexColorScheme.comfortablePlatformDensity,
          useMaterial3: true,
          // To use the Playground font, add GoogleFonts package and uncomment
          // fontFamily: GoogleFonts.notoSans().fontFamily,
        ),
        // uncomment this line to let the device system mode control the theme mode:
        themeMode: ThemeMode.system,
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  MainPageUI createState() => MainPageUI();
}
