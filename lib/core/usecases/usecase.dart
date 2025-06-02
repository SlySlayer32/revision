import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:revision/core/error/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams extends Equatable {
  const NoParams(); // Added const constructor

  @override
  List<Object> get props => [];
}
