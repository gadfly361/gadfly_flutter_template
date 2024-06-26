import 'package:flow_test/flow_test.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_test/flutter_test.dart' hide expect;
import 'package:gadfly_flutter_template/blocs/auth/event.dart';
import 'package:gadfly_flutter_template/blocs/recordings/event.dart';
import 'package:gadfly_flutter_template/blocs/sign_in/event.dart';
import 'package:gadfly_flutter_template/pages/authenticated/home/page.dart';
import 'package:gadfly_flutter_template/pages/unauthenticated/sign_in/page.dart';
import 'package:gadfly_flutter_template/pages/unauthenticated/sign_in/widgets/connector/email_input.dart';
import 'package:gadfly_flutter_template/pages/unauthenticated/sign_in/widgets/connector/password_input.dart';
import 'package:gadfly_flutter_template/pages/unauthenticated/sign_in/widgets/connector/sign_in_button.dart';
import 'package:gadfly_flutter_template/shared/widgets/dumb/button.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../util/fakes/supabase_user.dart';
import '../../util/flow_config.dart';
import '../../util/warp/to_home.dart';

void main() {
  final baseDescriptions = [
    FTDescription(
      descriptionType: 'EPIC',
      directoryName: 'unauthenticated',
      description:
          '''As a user, I need to be able to interact with the appication when I am unauthenticated.''',
    ),
    FTDescription(
      descriptionType: 'STORY',
      directoryName: 'sign_in',
      description:
          '''As a user, I should be able to sign in to the application, so that I can use it.''',
      atScreenshotsLevel: true,
    ),
  ];

  flowTest(
    'already have token',
    config: createFlowConfig(hasAccessToken: true),
    descriptions: [
      ...baseDescriptions,
      FTDescription(
        descriptionType: 'AC',
        directoryName: 'already_have_token',
        description:
            '''As a user, if I already have an auth token, I should not see the SignIn page and should go straight to the Home page.''',
      ),
    ],
    test: (tester) async {
      await tester.setUp(
        arrangeBeforePumpApp: arrangeBeforeWarpToHome,
      );

      await tester.screenshot(
        description: 'initial state',
        actions: (actions) async {
          await actions.testerAction.pump();
        },
        expectations: (expectations) {
          expectations.expect(
            find.byType(Home_Page),
            findsOneWidget,
            reason:
                '''Should be on the Home page because we have an accessToken in local storage''',
          );
        },
        expectedEvents: [
          'INFO: [router] deeplink: /',
          'Page: Home',
          RecordingsEvent_GetMyRecordings,
        ],
      );
    },
  );

  group('success', () {
    final successDescription = FTDescription(
      descriptionType: 'AC',
      directoryName: 'success',
      description: '''Signing in is successful''',
    );

    flowTest(
      'tapping inputs',
      config: createFlowConfig(
        hasAccessToken: false,
      ),
      descriptions: [
        ...baseDescriptions,
        successDescription,
        FTDescription(
          descriptionType: 'SUBMIT',
          directoryName: 'tapping_inputs',
          description:
              '''There are two ways to fill out the form. This covers manually tapping into each input.''',
        ),
      ],
      test: (tester) async {
        await tester.setUp();

        await tester.screenshot(
          description: 'initial state',
          expectations: (expectations) {
            expectations.expect(
              find.byType(SignIn_Page),
              findsOneWidget,
              reason: 'Should be on the SignIn page',
            );
          },
          expectedEvents: [
            'INFO: [router] deeplink: /',
            'INFO: [authenticated_guard] not authenticated',
            'Page: SignIn',
          ],
        );

        await tester.screenshot(
          description: 'enter email',
          actions: (actions) async {
            await actions.userAction.enterText(
              find.byType(SignInC_EmailInput),
              'foo@example.com',
            );
            await actions.testerAction.pumpAndSettle();
          },
        );

        await tester.screenshot(
          description: 'enter password',
          actions: (actions) async {
            await actions.userAction.enterText(
              find.byType(SignInC_PasswordInput),
              'Pass123!',
            );
            await actions.testerAction.pumpAndSettle();
          },
        );

        await tester.screenshot(
          description: 'tap submit button (pump half)',
          arrangeBeforeActions: (arrange) {
            when(
              () => arrange.mocks.authRepository.signIn(
                email: any(named: 'email'),
                password: any(named: 'password'),
              ),
            ).thenAnswer((invocation) async {
              await Future<void>.delayed(const Duration(seconds: 500));

              arrange.mocks.authChangeEffect.streamController?.add(
                supabase.AuthState(
                  supabase.AuthChangeEvent.signedIn,
                  supabase.Session(
                    accessToken: 'fakeAccessToken',
                    tokenType: '',
                    user: FakeSupabaseUser(),
                  ),
                ),
              );

              await arrangeBeforeWarpToHome(arrange);
              return;
            });
          },
          actions: (actions) async {
            await actions.userAction.tap(find.byType(SignInC_SignInButton));
            await actions.testerAction.pump(const Duration(milliseconds: 250));
          },
          expectations: (expectations) {
            expectations.expect(
              find.byType(SpinKitThreeBounce),
              findsOneWidget,
              reason: 'Should see a loading indicator',
            );
            expectations.expect(
              find.byType(Home_Page),
              findsNothing,
              reason: 'Should not be on the Home page yet',
            );
          },
          expectedEvents: [
            SignInEvent_SignIn,
          ],
        );

        await tester.screenshot(
          description: 'tap submit button (pump rest)',
          actions: (actions) async {
            await actions.testerAction.pumpAndSettle();
          },
          expectations: (expectations) {
            expectations.expect(
              find.byType(Home_Page),
              findsOneWidget,
              reason: 'Should be on the Home page',
            );
          },
          expectedEvents: [
            'INFO: [auth_change_subscription] signedIn',
            AuthEvent_AccessTokenAdded,
            'Page: Home',
            RecordingsEvent_GetMyRecordings,
          ],
        );
      },
    );

    flowTest(
      'pressing enter',
      config: createFlowConfig(hasAccessToken: false),
      descriptions: [
        ...baseDescriptions,
        successDescription,
        FTDescription(
          descriptionType: 'SUBMIT',
          directoryName: 'pressing_enter',
          description:
              '''There are two ways to fill out the form. This covers pressing enter to jump to the next input.''',
        ),
      ],
      test: (tester) async {
        await tester.setUp();

        await tester.screenshot(
          description: 'initial state',
          expectations: (expectations) {
            expectations.expect(
              find.byType(SignIn_Page),
              findsOneWidget,
              reason: 'Should be on the SignIn page',
            );
          },
          expectedEvents: [
            'INFO: [router] deeplink: /',
            'INFO: [authenticated_guard] not authenticated',
            'Page: SignIn',
          ],
        );

        await tester.screenshot(
          description: 'enter email',
          actions: (actions) async {
            await actions.userAction.enterText(
              find.byType(SignInC_EmailInput),
              'foo@example.com',
            );
            await actions.testerAction.pumpAndSettle();
          },
        );

        await tester.screenshot(
          description: 'press enter',
          actions: (actions) async {
            await actions.userAction.testTextInputReceiveNext();
            await actions.testerAction.pumpAndSettle();
          },
        );

        await tester.screenshot(
          description: 'enter password',
          actions: (actions) async {
            await actions.userAction.testTextInputEnterText('password');
            await actions.testerAction.pumpAndSettle();
          },
        );

        await tester.screenshot(
          description: 'press enter (pump half)',
          arrangeBeforeActions: (arrange) {
            when(
              () => arrange.mocks.authRepository.signIn(
                email: any(named: 'email'),
                password: any(named: 'password'),
              ),
            ).thenAnswer((invocation) async {
              await Future<void>.delayed(const Duration(seconds: 500));

              arrange.mocks.authChangeEffect.streamController?.add(
                supabase.AuthState(
                  supabase.AuthChangeEvent.signedIn,
                  supabase.Session(
                    accessToken: 'fakeAccessToken',
                    tokenType: '',
                    user: FakeSupabaseUser(),
                  ),
                ),
              );

              await arrangeBeforeWarpToHome(arrange);
              return;
            });
          },
          actions: (actions) async {
            await actions.userAction.testTextInputReceiveDone();
            await actions.testerAction.pump(const Duration(milliseconds: 250));
          },
          expectations: (expectations) {
            expectations.expect(
              find.byType(SpinKitThreeBounce),
              findsOneWidget,
              reason: 'Should see a loading indicator',
            );
            expectations.expect(
              find.byType(Home_Page),
              findsNothing,
              reason: 'Should not be on the Home page yet',
            );
          },
          expectedEvents: [
            SignInEvent_SignIn,
          ],
        );

        await tester.screenshot(
          description: 'press enter (pump rest)',
          actions: (actions) async {
            await actions.testerAction.pumpAndSettle();
          },
          expectations: (expectations) {
            expectations.expect(
              find.byType(Home_Page),
              findsOneWidget,
              reason: 'Should be on the Home page',
            );
          },
          expectedEvents: [
            'INFO: [auth_change_subscription] signedIn',
            AuthEvent_AccessTokenAdded,
            'Page: Home',
            RecordingsEvent_GetMyRecordings,
          ],
        );
      },
    );
  });

  group('error', () {
    final errorDescription = FTDescription(
      descriptionType: 'AC',
      directoryName: 'error',
      description: '''Signing in is not successful''',
    );

    flowTest(
      'empty inputs',
      config: createFlowConfig(hasAccessToken: false),
      descriptions: [
        ...baseDescriptions,
        errorDescription,
        FTDescription(
          descriptionType: 'STATUS',
          directoryName: 'empty_inputs',
          description:
              '''If either of the inputs are empty, should not be able to tap the sign in button''',
        ),
      ],
      test: (tester) async {
        await tester.setUp();
        await tester.screenshot(
          description: 'initial state',
          expectations: (expectations) {
            expectations.expect(
              find.byType(SignIn_Page),
              findsOneWidget,
              reason: 'Should be on the SignIn page',
            );
          },
          expectedEvents: [
            'INFO: [router] deeplink: /',
            'INFO: [authenticated_guard] not authenticated',
            'Page: SignIn',
          ],
        );

        await tester.screenshot(
          description: 'tap submit button',
          actions: (actions) async {
            await actions.userAction.tap(
              find.descendant(
                of: find.byType(SignInC_SignInButton),
                matching: find.byWidgetPredicate((widget) {
                  if (widget is SharedD_Button) {
                    return widget.status == SharedD_ButtonStatus.disabled;
                  }
                  return false;
                }),
              ),
            );
            await actions.testerAction.pumpAndSettle();
          },
          expectations: (expectations) {
            expectations.expect(
              find.byType(SignIn_Page),
              findsOneWidget,
              reason: 'Should still be on SignIn page',
            );
          },
          expectedEvents: [],
        );
      },
    );

    flowTest(
      'invalid email',
      config: createFlowConfig(hasAccessToken: false),
      descriptions: [
        ...baseDescriptions,
        errorDescription,
        FTDescription(
          descriptionType: 'STATUS',
          directoryName: 'invalid_email',
          description:
              '''If you attempt to sign in, but the email is invalid, should see invalid error''',
        ),
      ],
      test: (tester) async {
        await tester.setUp();
        await tester.screenshot(
          description: 'initial state',
          expectations: (expectations) {
            expectations.expect(
              find.byType(SignIn_Page),
              findsOneWidget,
              reason: 'Should be on the SignIn page',
            );
          },
          expectedEvents: [
            'INFO: [router] deeplink: /',
            'INFO: [authenticated_guard] not authenticated',
            'Page: SignIn',
          ],
        );

        await tester.screenshot(
          description: 'enter invalid emaill address',
          actions: (actions) async {
            await actions.userAction.enterText(
              find.byType(SignInC_EmailInput),
              'bad email',
            );
            await actions.testerAction.pumpAndSettle();
          },
        );

        await tester.screenshot(
          description: 'enter password',
          actions: (actions) async {
            await actions.userAction.enterText(
              find.byType(SignInC_PasswordInput),
              'password',
            );
            await actions.testerAction.pumpAndSettle();
          },
        );

        await tester.screenshot(
          description: 'tap submit button',
          actions: (actions) async {
            await actions.userAction.tap(
              find.descendant(
                of: find.byType(SignInC_SignInButton),
                matching: find.byWidgetPredicate((widget) {
                  if (widget is SharedD_Button) {
                    return widget.status == SharedD_ButtonStatus.enabled;
                  }
                  return false;
                }),
              ),
            );
            await actions.testerAction.pumpAndSettle();
          },
          expectations: (expectations) {
            expectations.expect(
              find.byType(SignIn_Page),
              findsOneWidget,
              reason: 'Should still be on SignIn page',
            );
            expectations.expect(
              find.text('Please enter a valid email address.'),
              findsOneWidget,
              reason: 'Should see email invalid error',
            );
          },
        );
      },
    );

    flowTest(
      'http error',
      config: createFlowConfig(hasAccessToken: false),
      descriptions: [
        ...baseDescriptions,
        errorDescription,
        FTDescription(
          descriptionType: 'STATUS',
          directoryName: 'http',
          description:
              '''As a user, even if I fill out the form correctly, I can still hit an http error. If this happens, I should be made aware that something went wrong.''',
        ),
      ],
      test: (tester) async {
        await tester.setUp();
        await tester.screenshot(
          description: 'initial state',
          expectations: (expectations) {
            expectations.expect(
              find.byType(SignIn_Page),
              findsOneWidget,
              reason: 'Should be on the SignIn page',
            );
          },
          expectedEvents: [
            'INFO: [router] deeplink: /',
            'INFO: [authenticated_guard] not authenticated',
            'Page: SignIn',
          ],
        );

        await tester.screenshot(
          description: 'enter email',
          actions: (actions) async {
            await actions.userAction.enterText(
              find.byType(SignInC_EmailInput),
              'foo@example.com',
            );
            await actions.testerAction.pumpAndSettle();
          },
        );

        await tester.screenshot(
          description: 'enter password',
          actions: (actions) async {
            await actions.userAction.enterText(
              find.byType(SignInC_PasswordInput),
              'password',
            );
            await actions.testerAction.pumpAndSettle();
          },
        );

        await tester.screenshot(
          description: 'tap submit button',
          arrangeBeforeActions: (arrange) {
            when(
              () => arrange.mocks.authRepository.signIn(
                email: any(named: 'email'),
                password: any(named: 'password'),
              ),
            ).thenThrow(
              (invocation) async => Exception('BOOM'),
            );
          },
          actions: (actions) async {
            await actions.userAction.tap(find.byType(SignInC_SignInButton));
            await actions.testerAction.pumpAndSettle();
          },
          expectations: (expectations) {
            expectations.expect(
              find.byType(Home_Page),
              findsNothing,
              reason:
                  'Should not be on the Home page because signing in failed',
            );
            expectations.expect(
              find.byType(SignIn_Page),
              findsOneWidget,
              reason: 'Should still be on SignIn page',
            );
            expectations.expect(
              find.text('Could not sign in.'),
              findsOneWidget,
              reason:
                  '''Should see error message letting user know something went wrong.''',
            );
          },
          expectedEvents: [
            SignInEvent_SignIn,
          ],
        );
      },
    );
  });
}
