import 'package:flutter/material.dart';

import '../../../../../i18n/translations.g.dart';

class ResetPasswordC_NewPasswordTextField extends StatelessWidget {
  const ResetPasswordC_NewPasswordTextField({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String value) onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      onFieldSubmitted: onSubmitted,
      obscureText: true,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        label: Text(context.t.resetPassword.form.newPassword.placeholder),
      ),
    );
  }
}