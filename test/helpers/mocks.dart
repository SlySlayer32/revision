import 'package:mocktail/mocktail.dart';
import 'package:revision/features/authentication/domain/usecases/get_auth_state_changes_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_out_usecase.dart';

class MockGetAuthStateChangesUseCase extends Mock
    implements GetAuthStateChangesUseCase {}

class MockSignOutUseCase extends Mock implements SignOutUseCase {}
