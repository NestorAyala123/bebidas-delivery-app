import '../../../../core/di/service_locator.dart';
import '../../ratings/domain/repositories/rating_repository.dart';
import '../../ratings/infrastructure/repositories/mock_rating_repository.dart';
import '../domain/repositories/delivery_repository.dart';
import '../domain/use_cases/accept_delivery_offer_use_case.dart';
import '../domain/use_cases/get_delivery_history_use_case.dart';
import '../domain/use_cases/get_delivery_offers_use_case.dart';
import '../domain/use_cases/get_delivery_rating_use_case.dart';
import '../domain/use_cases/get_driver_ratings_use_case.dart';
import '../domain/use_cases/get_driver_availability_use_case.dart';
import '../domain/use_cases/get_pending_delivery_requests_use_case.dart';
import '../domain/use_cases/register_delivery_rating_use_case.dart';
import '../domain/use_cases/reject_delivery_offer_use_case.dart';
import '../domain/use_cases/set_driver_availability_use_case.dart';
import '../domain/use_cases/submit_delivery_offer_use_case.dart';
import '../infrastructure/repositories/mock_delivery_repository.dart';

/// Módulo de inyección de dependencias del feature Delivery.
///
/// Registra el repositorio en memoria existente y los casos de uso del flujo
/// de ofertas. No se introduce Firebase/Firestore en esta etapa.
class DeliveryDi implements FeatureDiModule {
  @override
  void registerDependencies(ServiceLocator locator) {
    if (!locator.isRegistered<DeliveryRepository>()) {
      locator.registerLazySingleton<DeliveryRepository>(
        MockDeliveryRepository.new,
      );
    }

    if (!locator.isRegistered<GetPendingDeliveryRequestsUseCase>()) {
      locator.registerFactory<GetPendingDeliveryRequestsUseCase>(
        () => GetPendingDeliveryRequestsUseCase(
          locator.get<DeliveryRepository>(),
        ),
      );
    }

    if (!locator.isRegistered<GetDeliveryOffersUseCase>()) {
      locator.registerFactory<GetDeliveryOffersUseCase>(
        () => GetDeliveryOffersUseCase(locator.get<DeliveryRepository>()),
      );
    }

    if (!locator.isRegistered<GetDeliveryHistoryUseCase>()) {
      locator.registerFactory<GetDeliveryHistoryUseCase>(
        () => GetDeliveryHistoryUseCase(locator.get<DeliveryRepository>()),
      );
    }

    if (!locator.isRegistered<SubmitDeliveryOfferUseCase>()) {
      locator.registerFactory<SubmitDeliveryOfferUseCase>(
        () => SubmitDeliveryOfferUseCase(
          repository: locator.get<DeliveryRepository>(),
        ),
      );
    }

    if (!locator.isRegistered<AcceptDeliveryOfferUseCase>()) {
      locator.registerFactory<AcceptDeliveryOfferUseCase>(
        () => AcceptDeliveryOfferUseCase(locator.get<DeliveryRepository>()),
      );
    }

    if (!locator.isRegistered<RejectDeliveryOfferUseCase>()) {
      locator.registerFactory<RejectDeliveryOfferUseCase>(
        () => RejectDeliveryOfferUseCase(locator.get<DeliveryRepository>()),
      );
    }

    if (!locator.isRegistered<RatingRepository>()) {
      locator.registerLazySingleton<RatingRepository>(
        () => MockRatingRepository(),
      );
    }

    if (!locator.isRegistered<RegisterDeliveryRatingUseCase>()) {
      locator.registerFactory<RegisterDeliveryRatingUseCase>(
        () => RegisterDeliveryRatingUseCase(
          deliveryRepository: locator.get<DeliveryRepository>(),
          ratingRepository: locator.get<RatingRepository>(),
        ),
      );
    }

    if (!locator.isRegistered<GetDeliveryRatingUseCase>()) {
      locator.registerFactory<GetDeliveryRatingUseCase>(
        () => GetDeliveryRatingUseCase(
          deliveryRepository: locator.get<DeliveryRepository>(),
          ratingRepository: locator.get<RatingRepository>(),
        ),
      );
    }

    if (!locator.isRegistered<GetDriverRatingsUseCase>()) {
      locator.registerFactory<GetDriverRatingsUseCase>(
        () => GetDriverRatingsUseCase(
          ratingRepository: locator.get<RatingRepository>(),
        ),
      );
    }

    if (!locator.isRegistered<GetDriverAvailabilityUseCase>()) {
      locator.registerFactory<GetDriverAvailabilityUseCase>(
        () => GetDriverAvailabilityUseCase(locator.get<DeliveryRepository>()),
      );
    }

    if (!locator.isRegistered<SetDriverAvailabilityUseCase>()) {
      locator.registerFactory<SetDriverAvailabilityUseCase>(
        () => SetDriverAvailabilityUseCase(locator.get<DeliveryRepository>()),
      );
    }
  }
}
