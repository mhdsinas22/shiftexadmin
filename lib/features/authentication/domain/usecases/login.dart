import 'package:shiftexadmin/features/authentication/domain/repositories/authentication_repository.dart';

class Login {
  final AuthenticationRepository repository;
  Login({required this.repository});
  Future<void> execute(String email, String password) async {
    await repository.login(email, password);
  }
}
