import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../blocs/auth/bloc.dart';
import '../blocs/auth/event.dart';
import '../pages/authenticated/guard.dart';
import '../pages/authenticated/home/page.dart';
import '../pages/authenticated/reset_password/page.dart';
import '../pages/authenticated/router.dart';
import '../pages/unauthenticated/forgot_flow/forgot_password/page.dart';
import '../pages/unauthenticated/forgot_flow/forgot_password_confirmation/guard.dart';
import '../pages/unauthenticated/forgot_flow/forgot_password_confirmation/page.dart';
import '../pages/unauthenticated/forgot_flow/router.dart';
import '../pages/unauthenticated/guard.dart';
import '../pages/unauthenticated/router.dart';
import '../pages/unauthenticated/sign_in/page.dart';
import '../pages/unauthenticated/sign_up/page.dart';

part 'router.gr.dart';

final _log = Logger('router');

@AutoRouterConfig()
class AppRouter extends _$AppRouter {
  AppRouter({
    required this.authBloc,
  });

  final AuthBloc authBloc;

  @override
  RouteType get defaultRouteType => const RouteType.material();

  @override
  late final List<AutoRoute> routes = [
    AutoRoute(
      path: '/anon',
      page: Unauthenticated_Routes.page,
      guards: [UnauthenticatedGuard(authBloc: authBloc)],
      children: [
        AutoRoute(
          path: '',
          initial: true,
          page: SignIn_Route.page,
        ),
        AutoRoute(
          path: 'signUp',
          page: SignUp_Route.page,
        ),
        AutoRoute(
          path: 'forgot',
          page: ForgotFlow_Routes.page,
          children: [
            AutoRoute(
              path: 'password',
              page: ForgotPassword_Route.page,
            ),
            AutoRoute(
              path: 'passwordConfirmation',
              page: ForgotPasswordConfirmation_Route.page,
              guards: [ForgotPasswordConfirgmationGuard()],
            ),
          ],
        ),
        RedirectRoute(path: '*', redirectTo: ''),
      ],
    ),
    AutoRoute(
      path: '/',
      page: Authenticated_Routes.page,
      guards: [AuthenticatedGuard(authBloc: authBloc)],
      children: [
        AutoRoute(
          initial: true,
          path: '',
          page: Home_Route.page,
        ),
        AutoRoute(
          path: 'resetPassword',
          page: ResetPassword_Route.page,
        ),
        RedirectRoute(path: '*', redirectTo: ''),
      ],
    ),
    RedirectRoute(path: '*', redirectTo: '/'),
  ];
}

// coverage:ignore-start
Stream<Uri> deepLinkStreamInit() {
  if (kIsWeb) {
    return const Stream<Uri>.empty();
  }

  return AppLinks().uriLinkStream.map((uriRaw) {
    // To be able to use Supabase's tooling to check for a session in the URI,
    // we need to rebuild the URI with the fragment as the path, and then
    // re-adding the query params.
    final fragment = uriRaw.fragment;

    final rawQueryParams = uriRaw.queryParameters;
    final uri = Uri(path: fragment, queryParameters: rawQueryParams);
    return uri;
  });
}
// coverage:ignore-end

Future<DeepLink> deepLinkBuilder({
  required AuthBloc authBloc,
  required PlatformDeepLink deepLink,
  required String? deepLinkOverride,
}) async {
  _log.info('deeplink: ${deepLink.uri}');

  if (deepLink.path.startsWith('/deep') || deepLinkOverride != null) {
    // coverage:ignore-start
    final path = deepLinkOverride ?? deepLink.path;
    // coverage:ignore-end

    final handledDeepLink = await handleDeepLink(
      uri: deepLink.uri,
      path: path,
      authBloc: authBloc,
    );
    if (handledDeepLink != null) {
      return DeepLink.path(handledDeepLink, includePrefixMatches: true);
    }
  }

  return deepLink;
}

Future<String?> handleDeepLink({
  required Uri uri,
  required String path,
  required AuthBloc authBloc,
}) async {
  switch (path) {
    case '/deep/resetPassword':
      try {
        final completer = Completer<void>();
        authBloc.add(
          AuthEvent_SetSessionFromDeepLink(
            completer: completer,
            uri: uri,
          ),
        );
        await completer.future;
      } catch (_) {}
      return '/resetPassword';
    default:
      return path;
  }
}
