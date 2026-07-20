abstract interface class OperationResolver<
  TOperation extends FinancialOperation,
  TResolved extends ResolvedOperation,
> {
  Future<TResolved> resolve(TOperation operation);
}