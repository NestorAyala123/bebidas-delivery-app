import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/event_service.dart';

abstract class EventServiceRepository {
  Future<Result<List<EventService>, Failure>> getAllServices();
  Future<Result<EventService, Failure>> getServiceById(String id);
  Future<Result<List<EventService>, Failure>> getServicesByProvider(String providerId);
}
