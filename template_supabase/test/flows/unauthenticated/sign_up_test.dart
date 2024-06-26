import 'package:flow_test/flow_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_test/flutter_test.dart' hide expect;
import 'package:gadfly_flutter_template/blocs/auth/event.dart';
import 'package:gadfly_flutter_template/blocs/recordings/event.dart';
import 'package:gadfly_flutter_template/blocs/sign_up/event.dart';
import 'package:gadfly_flutter_template/pages/authenticated/home/page.dart';
import 'package:gadfly_flutter_template/pages/unauthenticated/sign_up/page.dart';
import 'package:gadfly_flutter_template/pages/unauthenticated/sign_up/widgets/connector/email_input.dart';
import 'package:gadfly_flutter_template/pages/unauthenticated/sign_up/widgets/connector/password_input.dart';
import 'package:gadfly_flutter_template/pages/unauthenticated/sign_up/widgets/connector/sign_up_button.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../util/fakes/supabase_user.dart';
import '../../util/flow_config.dart';
import '../../util/warp/to_home.dart';
import '../../util/warp/to_sign_up.dart';

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
      directoryName: 'sign_up',
      description:
          '''As a user, I should be able to sign up for the application, so that I can use it.''',
      atScreenshotsLevel: true,
    ),
  ];

  group('success', () {
    final successDescription = FTDescription(
      descriptionType: 'AC',
      directoryName: 'success',
      description: '''Signing up is successful''',
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
        await tester.setUp(
          warp: warpToSignUp,
          arrangeBeforePumpApp: arrangeBeforeWarpToSignUp,
        );

        await tester.screenshot(
          description: 'initial state',
          expectations: (expectations) {
            expectations.expect(
              find.byType(SignUp_Page),
              findsOneWidget,
              reason: 'Should be on the SignUp page',
            );
          },
        );

        await tester.screenshot(
          description: 'enter email',
          actions: (actions) async {
            await actions.userAction.enterText(
              find.byType(SignUpC_EmailInput),
              'foo@example.com',
            );
            await actions.testerAction.pumpAndSettle();
          },
        );

        await tester.screenshot(
          description: 'enter password',
          actions: (actions) async {
            await actions.userAction.enterText(
              find.byType(SignUpC_PasswordInput),
              'Pass123!',
            );
            await actions.testerAction.pumpAndSettle();
          },
        );

        await tester.screenshot(
          description: 'tap submit button (pump half)',
          arrangeBeforeActions: (arrange) {
            when(
              () => arrange.mocks.authRepository.signUp(
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
            await actions.userAction.tap(find.byType(SignUpC_SignUpButton));
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
            SignUpEvent_SignUp,
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
      config: createFlowConfig(
        hasAccessToken: false,
      ),
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
        await tester.setUp(
          warp: warpToSignUp,
          arrangeBeforePumpApp: arrangeBeforeWarpToSignUp,
        );

        await tester.screenshot(
          description: 'initial state',
          expectations: (expectations) {
            expectations.expect(
              find.byType(SignUp_Page),
              findsOneWidget,
              reason: 'Should be on the SignUp page',
            );
          },
        );

        await tester.screenshot(
          description: 'enter email',
          actions: (actions) async {
            await actions.userAction.enterText(
              find.byType(SignUpC_EmailInput),
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
            await actions.userAction.testTextInputEnterText('Pass123!');
            await actions.testerAction.pumpAndSettle();
          },
        );

        await tester.screenshot(
          description: 'press enter (pump half)',
          arrangeBeforeActions: (arrange) {
            when(
              () => arrange.mocks.authRepository.signUp(
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
            SignUpEvent_SignUp,
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
      description: '''Signing up is not successful''',
    );

    flowTest(
      'invalid email',
      config: createFlowConfig(
        hasAccessToken: false,
      ),
      descriptions: [
        ...baseDescriptions,
        errorDescription,
        FTDescription(
          descriptionType: 'STATUS',
          directoryName: 'invalid_email',
          description: '''Should see error if invalid email address''',
        ),
      ],
      test: (tester) async {
        await tester.setUp(
          warp: warpToSignUp,
          arrangeBeforePumpApp: arrangeBeforeWarpToSignUp,
        );

        await tester.screenshot(
          description: 'initial state',
          expectations: (expectations) {
            expectations.expect(
              find.byType(SignUp_Page),
              findsOneWidget,
              reason: 'Should be on the SignUp page',
            );
          },
        );

        await tester.screenshot(
          description: 'enter email',
          actions: (actions) async {
            await actions.userAction.enterText(
              find.byType(SignUpC_EmailInput),
              'bad email',
            );
            await actions.testerAction.pumpAndSettle();
          },
        );

        await tester.screenshot(
          description: 'enter password',
          actions: (actions) async {
            await actions.userAction.enterText(
              find.byType(SignUpC_PasswordInput),
              'Pass123!',
            );
            await actions.testerAction.pumpAndSettle();
          },
        );

        await tester.screenshot(
          description: 'tap submit button',
          actions: (actions) async {
            await actions.userAction.tap(find.byType(SignUpC_SignUpButton));
            await actions.testerAction.pumpAndSettle();
          },
          expectations: (expectations) {
            expectations.expect(
              find.byType(Home_Page),
              findsNothing,
              reason: 'Should not be on the Home page yet',
            );
            expectations.expect(
              find.text('Please enter a valid email address.'),
              findsOneWidget,
              reason: 'Should see invalid email error',
            );
          },
          expectedEvents: [],
        );
      },
    );

    flowTest(
      'invalid password',
      config: createFlowConfig(
        hasAccessToken: false,
      ),
      descriptions: [
        ...baseDescriptions,
        errorDescription,
        FTDescription(
          descriptionType: 'STATUS',
          directoryName: 'invalid_password',
          description: '''Should see error if invalid password''',
        ),
      ],
      test: (tester) async {
        await tester.setUp(
          warp: warpToSignUp,
          arrangeBeforePumpApp: arrangeBeforeWarpToSignUp,
        );

        await tester.screenshot(
          description: 'initial state',
          expectations: (expectations) {
            expectations.expect(
              find.byType(SignUp_Page),
              findsOneWidget,
              reason: 'Should be on the SignUp page',
            );
          },
        );

        await tester.screenshot(
          description: 'enter email',
          actions: (actions) async {
            await actions.userAction.enterText(
              find.byType(SignUpC_EmailInput),
              'john@example.com',
            );
            await actions.testerAction.pumpAndSettle();
          },
        );

        await tester.screenshot(
          description: 'enter password',
          actions: (actions) async {
            await actions.userAction.enterText(
              find.byType(SignUpC_PasswordInput),
              'bad password',
            );
            await actions.testerAction.pumpAndSettle();
          },
        );

        await tester.screenshot(
          description: 'tap submit button',
          actions: (actions) async {
            await actions.userAction.tap(find.byType(SignUpC_SignUpButton));
            await actions.testerAction.pumpAndSettle();
          },
          expectations: (expectations) {
            expectations.expect(
              find.byType(Home_Page),
              findsNothing,
              reason: 'Should not be on the Home page yet',
            );
            expectations.expect(
              find.text(
                '''Minimum 8 characters, upper and lower case, with at least one special character.''',
              ),
              findsOneWidget,
              reason: 'Should see invalid password error',
            );
          },
          expectedEvents: [],
        );
      },
    );

    flowTest(
      'http',
      config: createFlowConfig(
        hasAccessToken: false,
      ),
      descriptions: [
        ...baseDescriptions,
        errorDescription,
        FTDescription(
          descriptionType: 'STATUS',
          directoryName: 'http',
          description: '''Should see error snackbar if http error.''',
        ),
      ],
      test: (tester) async {
        await tester.setUp(
          warp: warpToSignUp,
          arrangeBeforePumpApp: arrangeBeforeWarpToSignUp,
        );

        await tester.screenshot(
          description: 'initial state',
          expectations: (expectations) {
            expectations.expect(
              find.byType(SignUp_Page),
              findsOneWidget,
              reason: 'Should be on the SignUp page',
            );
          },
        );

        await tester.screenshot(
          description: 'enter email',
          actions: (actions) async {
            await actions.userAction.enterText(
              find.byType(SignUpC_EmailInput),
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
            await actions.userAction.testTextInputEnterText('Pass123!');
            await actions.testerAction.pumpAndSettle();
          },
        );

        await tester.screenshot(
          description: 'press enter',
          arrangeBeforeActions: (arrange) {
            when(
              () => arrange.mocks.authRepository.signUp(
                email: any(named: 'email'),
                password: any(named: 'password'),
              ),
            ).thenThrow(Exception('BOOM'));
          },
          actions: (actions) async {
            await actions.userAction.testTextInputReceiveDone();
            await actions.testerAction.pumpAndSettle();
          },
          expectations: (expectations) {
            expectations.expect(
              find.byType(Home_Page),
              findsNothing,
              reason: 'Should not be on the Home page yet',
            );
            expectations.expect(
              find.descendant(
                of: find.byType(SnackBar),
                matching: find.text('Could not sign up.'),
              ),
              findsOneWidget,
              reason: 'Should see error snackbar',
            );
          },
          expectedEvents: [
            SignUpEvent_SignUp,
          ],
        );
      },
    );
  });
}
