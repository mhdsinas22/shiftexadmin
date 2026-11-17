import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftexadmin/features/authentication/domain/usecases/login.dart';
import 'package:shiftexadmin/features/authentication/presentation/bloc/authentication_event.dart';
import 'package:shiftexadmin/features/authentication/presentation/bloc/authentication_state.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  final Login login;
  AuthenticationBloc({required this.login}) : super(AuthenticationState()) {
    on<LoginEvent>(_onLoginEvent);
  }
  Future<void> _onLoginEvent(
    LoginEvent event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(state.copyWith(status: AuthenticationStatus.loading));
    try {
      await login.execute(event.email, event.password);
      emit(state.copyWith(status: AuthenticationStatus.authenticated));
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthenticationStatus.unauthenticated,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
