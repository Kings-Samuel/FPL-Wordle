import 'package:flutter/material.dart';
import 'package:fplwordle/providers/auth_provider.dart';
import 'package:fplwordle/screens/email_verification_screen.dart';
import 'package:fplwordle/screens/game_play_screen.dart';
import 'package:fplwordle/screens/home_screen.dart';
import 'package:fplwordle/screens/onboarding_screen.dart';
import 'package:fplwordle/screens/profile_screen.dart';
import 'package:fplwordle/screens/settings_screen.dart';
import 'package:fplwordle/screens/shop_screen.dart';
import 'package:fplwordle/screens/signin_screen.dart';
import 'package:fplwordle/screens/signup_screen.dart';
import 'package:fplwordle/screens/tutorial_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../consts/routes.dart';
import '../../providers/profile_provider.dart';
import '../../screens/not_found_page.dart';
import '../widgets/web_page_transitioner.dart';
import 'color_palette.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter _router = GoRouter(
  initialLocation: Routes.home,
  navigatorKey: _rootNavigatorKey,
  errorBuilder: (context, state) => Title(
      key: const Key('not_found_page'), title: '404 - Not Found', color: Palette.primary, child: const NotFoundPage()),
  routes: [
    GoRoute(
      path: Routes.home,
      redirect: (context, state) async {
        final authProvider = context.read<AuthProvider>();
        bool isLoggedIn = await authProvider.isLoggedIn();
        bool isOnboardingComplete = await authProvider.isOnboardingComplete();

        if (!isOnboardingComplete) {
          return Routes.onboarding;
        }

        if (isLoggedIn) {
          if (!authProvider.user!.emailVerification!) {
            return "${Routes.verifyAccount}/${authProvider.user!.id}?email=${authProvider.user!.email}&name=${authProvider.user!.name}";
          } else {
            return null;
          }
        } else {
          return null;
        }
      },
      builder: (context, state) => const HomeScreen(),
      pageBuilder: (context, state) => webPageTransitioner<void>(
        context: context,
        state: state,
        child: const HomeScreen(),
        title: 'FFG - Home',
      ),
    ),
    GoRoute(
      path: Routes.signin,
      redirect: (context, state) async {
        final authProvider = context.read<AuthProvider>();
        bool isLoggedIn = await authProvider.isLoggedIn();

        if (isLoggedIn) {
          if (!authProvider.user!.emailVerification!) {
            return "${Routes.verifyAccount}/${authProvider.user!.id}?email=${authProvider.user!.email}&name=${authProvider.user!.name}";
          } else {
            return Routes.home;
          }
        } else {
          return null;
        }
      },
      builder: (context, state) => const SignInScreen(),
      pageBuilder: (context, state) => webPageTransitioner<void>(
        context: context,
        state: state,
        child: const SignInScreen(),
        title: 'FFG - Sign In',
      ),
    ),
    GoRoute(
      path: Routes.signup,
      redirect: (context, state) async {
        final authProvider = context.read<AuthProvider>();
        bool isLoggedIn = await authProvider.isLoggedIn();

        if (isLoggedIn) {
          if (!authProvider.user!.emailVerification!) {
            return "${Routes.verifyAccount}/${authProvider.user!.id}?email=${authProvider.user!.email}&name=${authProvider.user!.name}";
          } else {
            return Routes.home;
          }
        } else {
          return null;
        }
      },
      builder: (context, state) => const SignupScreen(),
      pageBuilder: (context, state) => webPageTransitioner<void>(
        context: context,
        state: state,
        child: const SignupScreen(),
        title: 'FFG - Sign Up',
      ),
    ),
    GoRoute(
        name: Routes.verifyAccount.replaceAll("/", ""),
        path: "${Routes.verifyAccount}/:userId",
        redirect: (context, state) async {
          if (state.pathParameters.isEmpty || state.queryParameters.isEmpty) {
            return Routes.home;
          }

          final authProvider = context.read<AuthProvider>();
          bool isLoggedIn = await authProvider.isLoggedIn();

          if (isLoggedIn) {
            if (!authProvider.user!.emailVerification!) {
              return null;
            } else {
              return Routes.home;
            }
          } else {
            return Routes.signin;
          }
        },
        builder: (context, state) {
          Map<String, String> pathParams = state.pathParameters;
          String userId = pathParams["userId"]!;
          Map<String, String> queryParams = state.queryParameters;
          String email = queryParams["email"]!;
          String name = queryParams["name"]!;

          return EmailVerificationScreen(email: email, name: name, userId: userId);
        },
        pageBuilder: (context, state) {
          Map<String, String> pathParams = state.pathParameters;
          String userId = pathParams["userId"]!;
          Map<String, String> queryParams = state.queryParameters;
          String email = queryParams["email"]!;
          String name = queryParams["name"]!;

          return webPageTransitioner<void>(
            context: context,
            state: state,
            child: EmailVerificationScreen(email: email, name: name, userId: userId),
            title: 'FFG - Verify Your Email',
          );
        }),
    GoRoute(
      path: Routes.onboarding,
      redirect: (context, state) async {
        final authProvider = context.read<AuthProvider>();
        bool isLoggedIn = await authProvider.isLoggedIn();

        if (isLoggedIn) {
          if (!authProvider.user!.emailVerification!) {
            return "${Routes.verifyAccount}/${authProvider.user!.id}?email=${authProvider.user!.email}&name=${authProvider.user!.name}";
          } else {
            return null;
          }
        } else {
          return null;
        }
      },
      builder: (context, state) => const OnboardingScreen(),
      pageBuilder: (context, state) => webPageTransitioner<void>(
        context: context,
        state: state,
        child: const OnboardingScreen(),
        title: 'FFG - Onboarding',
      ),
    ),
    GoRoute(
      path: Routes.shop,
      redirect: (context, state) async {
        final authProvider = context.read<AuthProvider>();
        final profileProvider = context.read<ProfileProvider>();
        bool isLoggedIn = await authProvider.isLoggedIn();

        if (isLoggedIn) {
          if (!authProvider.user!.emailVerification!) {
            return "${Routes.verifyAccount}/${authProvider.user!.id}?email=${authProvider.user!.email}&name=${authProvider.user!.name}";
          } else {
            await profileProvider.createOrConfirmProfile(user: authProvider.user);
            return null;
          }
        } else {
          return null;
        }
      },
      builder: (context, state) => const ShopScreen(),
      pageBuilder: (context, state) => webPageTransitioner<void>(
        context: context,
        state: state,
        child: const ShopScreen(),
        title: 'FFG - Shop',
      ),
    ),
    GoRoute(
      path: Routes.settings,
      redirect: (context, state) async {
        final authProvider = context.read<AuthProvider>();
        final profileProvider = context.read<ProfileProvider>();
        bool isLoggedIn = await authProvider.isLoggedIn();

        if (isLoggedIn) {
          if (!authProvider.user!.emailVerification!) {
            return "${Routes.verifyAccount}/${authProvider.user!.id}?email=${authProvider.user!.email}&name=${authProvider.user!.name}";
          } else {
            await profileProvider.createOrConfirmProfile(user: authProvider.user);
            return null;
          }
        } else {
          return null;
        }
      },
      builder: (context, state) => const SettingsScreen(),
      pageBuilder: (context, state) => webPageTransitioner<void>(
        context: context,
        state: state,
        child: const SettingsScreen(),
        title: 'FFG - Settings',
      ),
    ),
    GoRoute(
      path: Routes.tutorial,
      redirect: (context, state) async {
        final authProvider = context.read<AuthProvider>();
        final profileProvider = context.read<ProfileProvider>();
        bool isLoggedIn = await authProvider.isLoggedIn();

        if (isLoggedIn) {
          if (!authProvider.user!.emailVerification!) {
            return "${Routes.verifyAccount}/${authProvider.user!.id}?email=${authProvider.user!.email}&name=${authProvider.user!.name}";
          } else {
            await profileProvider.createOrConfirmProfile(user: authProvider.user);
            return null;
          }
        } else {
          return null;
        }
      },
      builder: (context, state) => const TutorialScreen(),
      pageBuilder: (context, state) => webPageTransitioner<void>(
        context: context,
        state: state,
        child: const TutorialScreen(),
        title: 'FFG - How to play',
      ),
    ),
    GoRoute(
      path: Routes.profile,
      redirect: (context, state) async {
        final authProvider = context.read<AuthProvider>();
        final profileProvider = context.read<ProfileProvider>();
        bool isLoggedIn = await authProvider.isLoggedIn();

        if (isLoggedIn) {
          if (!authProvider.user!.emailVerification!) {
            return "${Routes.verifyAccount}/${authProvider.user!.id}?email=${authProvider.user!.email}&name=${authProvider.user!.name}";
          } else {
            await profileProvider.createOrConfirmProfile(user: authProvider.user);
            return null;
          }
        } else {
          return null;
        }
      },
      builder: (context, state) => const ProfileScreen(),
      pageBuilder: (context, state) => webPageTransitioner<void>(
        context: context,
        state: state,
        child: const ProfileScreen(),
        title: 'FFG - My Profile',
      ),
    ),
    GoRoute(
      path: Routes.play,
      redirect: (context, state) async {
        final authProvider = context.read<AuthProvider>();
        final profileProvider = context.read<ProfileProvider>();
        bool isLoggedIn = await authProvider.isLoggedIn();

        if (isLoggedIn) {
          if (!authProvider.user!.emailVerification!) {
            return "${Routes.verifyAccount}/${authProvider.user!.id}?email=${authProvider.user!.email}&name=${authProvider.user!.name}";
          } else {
            await profileProvider.createOrConfirmProfile(user: authProvider.user);
            return null;
          }
        } else {
          return null;
        }
      },
      builder: (context, state) => const GamePlayScreen(),
      pageBuilder: (context, state) => webPageTransitioner<void>(
        context: context,
        state: state,
        child: const GamePlayScreen(),
        title: 'Fantasy Football Guesser',
      ),
    ),
  ],
);

GoRouter get router => _router;
