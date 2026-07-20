abstract interface class Planner<
  TResolved extends ResolvedOperation,
> {
  ExecutionPlan plan(TResolved operation);
}