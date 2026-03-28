import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/complaint_provider.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const CitySeva());
}

class CitySeva extends StatelessWidget {
  const CitySeva({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ComplaintProvider(),
      child: MaterialApp(
        title: 'CitySeva',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        scaffoldMessengerKey: NotificationService.messengerKey,
        home: const OnboardingScreen(),
      ),
    );
  }
}
