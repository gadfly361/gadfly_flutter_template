import 'package:flow_test/flow_test.dart';
import 'package:flutter_test/flutter_test.dart' hide expect;
import 'package:gadfly_flutter_template/blocs/auth/event.dart';
import 'package:gadfly_flutter_template/pages/authenticated/home/widgets/connector/sign_out_button.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../util/fake/auth_change_effect.dart';
import '../../util/util.dart';
import '../../util/warp/to_home.dart';

void main() {
  final baseDescriptions = [
    FTDescription(
      descriptionType: 'EPIC',
      shortDescription: 'authenticated',
      description:
          '''As a user, I need to be able to interact with the appication when I am authenticated.''',
    ),
    FTDescription(
      descriptionType: 'STORY',
      shortDescription: 'sign_out',
      description:
          '''As a user, I should be able to sign out when I am signed in.''',
      atScreenshotsLevel: true,
    ),
  ];

  flowTest(
    'AC1',
    config: createFlowConfig(
      hasAccessToken: true,
    ),
    descriptions: [
      ...baseDescriptions,
      FTDescription(
        descriptionType: 'AC',
        shortDescription: 'success',
        description: '''Sign out successful''',
      ),
    ],
    test: (tester) async {
      await tester.setUp(
        arrangeBeforePumpApp: (arrange) async {
          await arrangeBeforeWarpToHome(arrange);
        },
      );

      await tester.screenshot(
        description: 'initial state',
        actions: (actions) async {
          await actions.testerAction.pumpAndSettle();
        },
        expectations: (expectations) {},
        expectedEvents: [
          'Page: Home',
        ],
      );

      await tester.screenshot(
        description: 'tap sign out button',
        arrangeBeforeActions: (arrange) {
          when(
            () => arrange.mocks.authRepository.signOut(),
          ).thenAnswer((invocation) async {
            final fakeAuthChangeEffect =
                arrange.extras['fakeAuthChangeEffect'] as FakeAuthChangeEffect;
            fakeAuthChangeEffect.streamController?.add(
              supabase.AuthState(
                supabase.AuthChangeEvent.signedOut,
                null,
              ),
            );
            return;
          });
        },
        actions: (actions) async {
          await actions.userAction.tap(find.byType(HomeC_SignOutButton));
          await actions.testerAction.pumpAndSettle();
        },
        expectedEvents: [
          AuthEvent_SignOut,
          'INFO: [auth_change_subscription] signedOut',
          AuthEvent_AccessTokenRemoved,
          'Page: SignIn',
        ],
      );
    },
  );
}