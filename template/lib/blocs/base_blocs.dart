import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth/event.dart';
import 'auth/state.dart';
import 'sign_in/event.dart';
import 'sign_in/state.dart';

sealed class AppBaseBloc<Event, State> extends Bloc<Event, State> {
  AppBaseBloc(super.initialState);
}

class AuthBaseBloc extends AppBaseBloc<AuthEvent, AuthState> {
  AuthBaseBloc(super.initialState);
}

class SignInBaseBloc extends AppBaseBloc<SignInEvent, SignInState> {
  SignInBaseBloc(super.initialState);
}
