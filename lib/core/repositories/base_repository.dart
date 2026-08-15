/// Base interface for all repositories.
/// Repositories are the single source of truth for data access.
/// They abstract the data source (Supabase, local cache, etc.) from the domain.
abstract interface class BaseRepository {
  /// Releases resources held by this repository.
  void dispose() {}
}
