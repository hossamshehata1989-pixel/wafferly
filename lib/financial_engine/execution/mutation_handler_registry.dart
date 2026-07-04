import 'financial_mutation_handler.dart';

final class MutationHandlerRegistry {
  final Map<Type, FinancialMutationHandler> _handlers;

  const MutationHandlerRegistry({
    Map<Type, FinancialMutationHandler> handlers = const {},
  }) : _handlers = handlers;

  FinancialMutationHandler handlerFor(Type mutationType) {
    final handler = _handlers[mutationType];

    if (handler == null) {
      throw StateError('No handler registered for $mutationType.');
    }

    return handler;
  }
}
