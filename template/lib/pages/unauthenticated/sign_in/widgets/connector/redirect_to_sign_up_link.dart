import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../../app/router.dart';
import '../../../../../i18n/translations.g.dart';
import '../../../../../theme/theme.dart';

class SignInC_RedirectToSignUpLink extends StatelessWidget {
  const SignInC_RedirectToSignUpLink({super.key});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      context.t.signIn.newUserSignUp(
        tapHere: (link) {
          return TextSpan(
            text: link,
            style: TextStyle(
              color: context.tokens.color.primary.color,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                context.router.navigate(const SignUp_Route());
              },
          );
        },
      ),
      textAlign: TextAlign.left,
    );
  }
}
