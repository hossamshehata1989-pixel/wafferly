/// A source-independent description of a financial intent.
///
/// It represents WHAT the financial domain is asked to do,
/// without carrying:
///
/// - the origin of the request
/// - business decisions
/// - accounting mutations
/// - world state
/// - user resolutions
///
/// It forms the boundary between heterogeneous input sources
/// and the unified financial domain pipeline.
final class NormalizedIntent {
  const NormalizedIntent();
}
