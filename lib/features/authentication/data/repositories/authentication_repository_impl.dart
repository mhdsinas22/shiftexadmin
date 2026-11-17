import 'package:shiftexadmin/features/authentication/data/datasoucre/authentication_remote_datasoucre.dart';
import 'package:shiftexadmin/features/authentication/domain/repositories/authentication_repository.dart';

class AuthenticationRepositoryImpl implements AuthenticationRepository {
  final AuthenticationRemoteDatasoucre authRemoteDatasoucre;
  AuthenticationRepositoryImpl({required this.authRemoteDatasoucre});
  @override
  Future<void> login(String email, String password) async {
    await authRemoteDatasoucre.login(email, password);
  }
}
