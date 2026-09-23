enum EventServiceType {
  bartender,
  iceAndCoolers,
  soundAndDj,
  customCocktailBar,
  other,
}

class EventService {
  final String id;
  final String providerId;
  final String title;
  final String description;
  final EventServiceType serviceType;
  final double estimatedPrice;
  final bool isAvailable;

  const EventService({
    required this.id,
    required this.providerId,
    required this.title,
    required this.description,
    required this.serviceType,
    required this.estimatedPrice,
    this.isAvailable = true,
  });
}
