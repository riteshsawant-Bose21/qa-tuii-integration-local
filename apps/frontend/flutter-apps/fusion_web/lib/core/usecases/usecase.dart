// Base UseCase interface following Clean Architecture principles
abstract class UseCase<Type, Params> {
  Future<Type> call(Params params);
}

// For use cases that don't require parameters
class NoParams {
  const NoParams();
}
