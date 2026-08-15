/// Base class for all application services.
/// Services coordinate business rules across repositories.
/// They must not contain UI logic or direct data-source calls.
abstract class BaseService {
  /// Releases resources held by this service.
  void dispose() {}
}
