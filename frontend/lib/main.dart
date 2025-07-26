import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/forum_screen.dart';
import 'screens/food_capture_widget.dart';
import 'screens/chat_screen.dart';
import 'screens/profile_screen.dart';

// Services, ViewModels, etc.
import 'services/auth_service.dart';
import 'services/forum_service.dart';
import 'services/api_service.dart';
import 'services/assessment_service.dart';
import 'view_models/home_view_model.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await dotenv.load(fileName: ".env");

  // Inisialisasi Workmanager dan NotificationService
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  NotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => ApiService()),
        ProxyProvider<AuthService, ForumService>(
          update: (_, auth, __) => ForumService(headers: auth.getAuthHeaders()),
        ),
        ProxyProvider<AuthService, AssessmentService>(
          update: (_, auth, __) =>
              AssessmentService(headers: auth.getAuthHeaders()),
        ),
        ChangeNotifierProxyProvider3<AuthService, ApiService, AssessmentService,
            HomeViewModel>(
          create: (ctx) => HomeViewModel(
            authService: Provider.of<AuthService>(ctx, listen: false),
            apiService: Provider.of<ApiService>(ctx, listen: false),
            assessmentService:
                Provider.of<AssessmentService>(ctx, listen: false),
          ),
          update: (_, auth, api, assessment, previous) =>
              previous ??
              HomeViewModel(
                authService: auth,
                apiService: api,
                assessmentService: assessment,
              ),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/home':
              final int initialIndex = (settings.arguments as int?) ?? 0;
              return MaterialPageRoute(
                  builder: (_) =>
                      MainNavigationScreen(initialIndex: initialIndex));
            case '/onboarding':
              return MaterialPageRoute(
                  builder: (_) => const OnboardingScreen());
            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            case '/register':
              return MaterialPageRoute(builder: (_) => const RegisterScreen());
            default:
              return MaterialPageRoute(
                builder: (_) => Scaffold(
                  body: Center(
                      child: Text('Halaman tidak ditemukan: ${settings.name}')),
                ),
              );
          }
        },
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({Key? key, this.initialIndex = 0})
      : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _selectedIndex;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id.toString() ?? 'default_user';

    _screens = [
      const HomeScreen(),
      const ForumScreen(),
      Container(),
      ChatScreen(userId: userId),
      const ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const FoodCapture()));
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.secondaryTextColor,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: AppConstants.homeTab),
          BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined),
              activeIcon: Icon(Icons.forum),
              label: AppConstants.forumTab),
          BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined),
              activeIcon: Icon(Icons.camera_alt),
              label: 'Tracker'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: AppConstants.chatTab),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: AppConstants.profileTab),
        ],
      ),
    );
  }
}
