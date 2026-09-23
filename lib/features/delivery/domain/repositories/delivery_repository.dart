import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/delivery_request.dart';

abstract class DeliveryRepository {
  Future<Result<DeliveryRequest, Failure>> createDeliveryRequest(DeliveryRequest request);
  Future<Result<DeliveryRequest, Failure>> getDeliveryRequestById(String id);
  Future<Result<void, Failure>> updateStatus(String id, String status);
}
