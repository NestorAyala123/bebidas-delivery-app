import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../users/domain/entities/identity_contract.dart';
import '../../../users/domain/entities/role.dart';
import '../../domain/entities/delivery_offer.dart';
import '../../domain/entities/delivery_request.dart';
import '../../domain/entities/delivery_status.dart';
import '../../domain/entities/offer_status.dart';
import '../../domain/use_cases/accept_delivery_offer_use_case.dart';
import '../../domain/use_cases/get_delivery_offers_use_case.dart';
import '../../domain/use_cases/get_delivery_rating_use_case.dart';
import '../../domain/use_cases/reject_delivery_offer_use_case.dart';
import '../../domain/use_cases/register_delivery_rating_use_case.dart';
import '../../domain/use_cases/submit_delivery_offer_use_case.dart';
import '../../../ratings/domain/entities/rating.dart';
import '../utils/delivery_formatters.dart';
import '../widgets/delivery_offer_card.dart';
import '../widgets/delivery_rating_stars.dart';
import '../widgets/delivery_status_chip.dart';

/// Detalle de una solicitud de delivery con su negociación:
/// comparación de ofertas, envío de propuestas y aceptación/rechazo.
///
/// La pantalla no decide reglas de negocio: delega en los casos de uso. Las
/// condiciones que se evalúan aquí solo controlan qué acciones se muestran.
class DeliveryRequestDetailPage extends StatefulWidget {
  final DeliveryRequest request;
  final IdentityContract identity;
  final GetDeliveryOffersUseCase? getOffersUseCase;
  final SubmitDeliveryOfferUseCase? submitOfferUseCase;
  final AcceptDeliveryOfferUseCase? acceptOfferUseCase;
  final RejectDeliveryOfferUseCase? rejectOfferUseCase;
  final GetDeliveryRatingUseCase? getDeliveryRatingUseCase;
  final RegisterDeliveryRatingUseCase? registerDeliveryRatingUseCase;

  const DeliveryRequestDetailPage({
    super.key,
    required this.request,
    required this.identity,
    this.getOffersUseCase,
    this.submitOfferUseCase,
    this.acceptOfferUseCase,
    this.rejectOfferUseCase,
    this.getDeliveryRatingUseCase,
    this.registerDeliveryRatingUseCase,
  });

  @override
  State<DeliveryRequestDetailPage> createState() =>
      _DeliveryRequestDetailPageState();
}

class _DeliveryRequestDetailPageState extends State<DeliveryRequestDetailPage> {
  late DeliveryRequest _request;
  bool _isLoading = true;
  bool _isWorking = false;
  String? _errorMessage;
  List<DeliveryOffer> _offers = const [];
  Rating? _rating;
  bool _isRatingLoading = false;
  bool _isRatingSubmitting = false;

  GetDeliveryOffersUseCase get _getOffers =>
      widget.getOffersUseCase ?? sl.get<GetDeliveryOffersUseCase>();

  SubmitDeliveryOfferUseCase get _submitOffer =>
      widget.submitOfferUseCase ?? sl.get<SubmitDeliveryOfferUseCase>();

  AcceptDeliveryOfferUseCase get _acceptOffer =>
      widget.acceptOfferUseCase ?? sl.get<AcceptDeliveryOfferUseCase>();

  RejectDeliveryOfferUseCase get _rejectOffer =>
      widget.rejectOfferUseCase ?? sl.get<RejectDeliveryOfferUseCase>();

  GetDeliveryRatingUseCase? get _getDeliveryRating {
    if (widget.getDeliveryRatingUseCase != null) {
      return widget.getDeliveryRatingUseCase;
    }
    if (sl.isRegistered<GetDeliveryRatingUseCase>()) {
      return sl.get<GetDeliveryRatingUseCase>();
    }
    return null;
  }

  RegisterDeliveryRatingUseCase? get _registerDeliveryRating {
    if (widget.registerDeliveryRatingUseCase != null) {
      return widget.registerDeliveryRatingUseCase;
    }
    if (sl.isRegistered<RegisterDeliveryRatingUseCase>()) {
      return sl.get<RegisterDeliveryRatingUseCase>();
    }
    return null;
  }

  bool get _isDriver => widget.identity.rbacRole == Role.driver;

  bool get _isOwnerRequester {
    final role = widget.identity.rbacRole;
    final id = widget.identity.id;
    return (role == Role.client && id == _request.customerId) ||
        (role == Role.store && id == _request.storeId);
  }

  bool get _isPendingRequest =>
      _request.status == DeliveryStatus.pendingOffer &&
      _request.assignedDriverId == null;

  List<DeliveryOffer> get _myOffers =>
      _offers.where((o) => o.driverId == widget.identity.id).toList();

  /// Refleja en la interfaz el límite de 2 ofertas y la prohibición de tener
  /// dos pendientes simultáneas. La validación definitiva sigue en el caso de uso.
  bool get _canSubmitOffer {
    if (!_isDriver || !_isPendingRequest) return false;
    final mine = _myOffers;
    if (mine.any((o) => o.status == OfferStatus.pending)) return false;
    if (mine.length >= 2) return false;
    if (mine.length == 1 && mine.single.status != OfferStatus.rejected) {
      return false;
    }
    return true;
  }

  String get _offerButtonLabel =>
      _myOffers.isEmpty ? 'Enviar oferta' : 'Enviar segunda oferta';

  String? get _driverHint {
    if (!_isDriver || !_isPendingRequest || _canSubmitOffer) return null;
    final mine = _myOffers;
    if (mine.any((o) => o.status == OfferStatus.pending)) {
      return 'Tu oferta está pendiente de respuesta.';
    }
    if (mine.length >= 2) {
      return 'Has alcanzado el límite de 2 ofertas para esta solicitud.';
    }
    if (mine.length == 1) {
      return switch (mine.single.status) {
        OfferStatus.accepted => 'Tu oferta fue aceptada.',
        OfferStatus.discarded => 'Tu oferta anterior fue descartada.',
        OfferStatus.pending => 'Tu oferta está pendiente de respuesta.',
        OfferStatus.rejected => null,
      };
    }
    return null;
  }

  DeliveryOffer? get _winningOffer {
    for (final offer in _offers) {
      if (offer.status == OfferStatus.accepted) return offer;
    }
    return null;
  }

  String? get _bestOfferId {
    for (final offer in _offers) {
      if (offer.isPending) return offer.id;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _request = widget.request;
    _loadOffers();
    if (_request.status == DeliveryStatus.delivered) {
      _loadRating();
    }
  }

  Future<void> _loadOffers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _getOffers(_request.id);

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _offers = _sortOffers(result.dataOrNull ?? const []);
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage =
            result.failureOrNull?.message ?? 'Error al cargar las ofertas';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRating() async {
    final useCase = _getDeliveryRating;
    if (useCase == null) return;

    setState(() {
      _isRatingLoading = true;
    });

    try {
      final result = await useCase(
        deliveryRequestId: _request.id,
        requesterIdentity: widget.identity,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        setState(() {
          _rating = result.dataOrNull;
          _isRatingLoading = false;
        });
      } else {
        setState(() {
          _isRatingLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isRatingLoading = false;
        });
      }
    }
  }

  Future<void> _submitRating(int score, String comment) async {
    final useCase = _registerDeliveryRating;
    if (useCase == null) {
      _showSnackBar('El servicio de calificaciones no está disponible.');
      return;
    }

    setState(() => _isRatingSubmitting = true);

    try {
      final result = await useCase(
        deliveryRequestId: _request.id,
        score: score,
        comment: comment,
        customerIdentity: widget.identity,
      );

      if (!mounted) {
        setState(() => _isRatingSubmitting = false);
        return;
      }

      setState(() => _isRatingSubmitting = false);

      if (result.isSuccess) {
        setState(() => _rating = result.dataOrNull);
        _showSnackBar('Calificación registrada correctamente.');
        await _loadRating();
      } else {
        _showSnackBar(
          result.failureOrNull?.message ??
              'No se pudo registrar la calificación.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isRatingSubmitting = false);
        _showSnackBar('Error al registrar la calificación.');
      }
    }
  }

  Future<void> _showRateDialog() async {
    final input = await showDialog<_RatingInput>(
      context: context,
      builder: (_) => const _RateDeliveryDialog(),
    );

    if (input == null) return;

    await _submitRating(input.score, input.comment);
  }

  /// Ordena para comparar: pendientes primero y, dentro de ellas, la tarifa
  /// más baja primero. Las ofertas cerradas quedan al final.
  List<DeliveryOffer> _sortOffers(List<DeliveryOffer> offers) {
    final sorted = [...offers];
    sorted.sort((a, b) {
      if (a.isPending != b.isPending) return a.isPending ? -1 : 1;
      final byFare = a.offeredFareInCents.compareTo(b.offeredFareInCents);
      if (byFare != 0) return byFare;
      return a.createdAt.compareTo(b.createdAt);
    });
    return sorted;
  }

  bool _canRespondTo(DeliveryOffer offer) =>
      _isOwnerRequester &&
      _isPendingRequest &&
      offer.status == OfferStatus.pending;

  Future<void> _submitOfferAction() async {
    final input = await showDialog<_OfferInput>(
      context: context,
      builder: (_) => const _SubmitOfferDialog(),
    );

    if (input == null || !mounted) return;

    setState(() => _isWorking = true);

    final result = await _submitOffer(
      deliveryRequestId: _request.id,
      driverId: widget.identity.id,
      driverIdentity: widget.identity,
      offeredFareText: input.amount,
      comment: input.comment.trim().isEmpty ? null : input.comment.trim(),
    );

    if (!mounted) return;

    setState(() => _isWorking = false);

    if (result.isSuccess) {
      _showSnackBar('Oferta enviada correctamente.');
      await _loadOffers();
    } else {
      _showSnackBar(
        result.failureOrNull?.message ?? 'No se pudo enviar la oferta.',
      );
    }
  }

  Future<void> _respondToOffer(
    DeliveryOffer offer, {
    required bool accept,
  }) async {
    if (accept) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Aceptar oferta'),
          content: Text(
            '¿Aceptar la propuesta de ${offer.driverName} por '
            '${formatCents(offer.offeredFareInCents)}? '
            'Las demás ofertas pendientes se cerrarán.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Volver'),
            ),
            FilledButton(
              key: const Key('confirm-accept-offer'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Aceptar oferta'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;
    }

    setState(() => _isWorking = true);

    if (accept) {
      final result = await _acceptOffer(
        offerId: offer.id,
        requesterIdentity: widget.identity,
      );

      if (!mounted) return;
      setState(() => _isWorking = false);

      if (result.isSuccess) {
        final updated = result.dataOrNull;
        if (updated != null) {
          setState(() => _request = updated);
        }
        _showSnackBar('Oferta aceptada. Repartidor asignado.');
      } else {
        _showSnackBar(
          result.failureOrNull?.message ?? 'No se pudo aceptar la oferta.',
        );
      }
    } else {
      final result = await _rejectOffer(
        offerId: offer.id,
        requesterIdentity: widget.identity,
      );

      if (!mounted) return;
      setState(() => _isWorking = false);

      if (result.isSuccess) {
        _showSnackBar('Oferta rechazada.');
      } else {
        _showSnackBar(
          result.failureOrNull?.message ?? 'No se pudo rechazar la oferta.',
        );
      }
    }

    // Refresca estados posibles: oferta descartada por indisponibilidad,
    // ofertas rivales cerradas o rechazo aplicado.
    if (mounted) {
      await _loadOffers();
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Negociación de Delivery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
            onPressed: _isLoading || _isWorking ? null : _loadOffers,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade700),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade900, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadOffers,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_isWorking) const LinearProgressIndicator(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadOffers,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildRequestCard(),
                const SizedBox(height: 8),
                _buildNegotiationSummary(),
                const SizedBox(height: 8),
                _buildRatingSection(),
                const SizedBox(height: 8),
                _buildOffersHeader(),
                ..._buildOffers(),
                const SizedBox(height: 8),
                _buildDriverActions(),
                _buildRequesterHint(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Solicitud #${_request.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                DeliveryStatusChip(status: _request.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('Pedido asociado: ${_request.orderId}'),
            const Divider(height: 20),
            Text('Origen: ${_request.originAddress}'),
            const SizedBox(height: 4),
            Text('Destino: ${_request.destinationAddress}'),
            const SizedBox(height: 4),
            Text('Modalidad: ${deliveryModeLabel(_request.deliveryMode.name)}'),
            const SizedBox(height: 4),
            Text(
              _request.distanceInKm != null
                  ? 'Distancia: ${_request.distanceInKm} km'
                  : 'Distancia no especificada',
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tarifa de referencia'),
                Text(
                  formatMoney(_request.referenceFare),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNegotiationSummary() {
    final (color, icon, title, lines) = switch (_request.status) {
      DeliveryStatus.pendingOffer => (
        Colors.blue.shade50,
        Icons.handshake_outlined,
        'Negociación en curso',
        [
          '${_offers.where((o) => o.isPending).length} oferta(s) pendiente(s) de respuesta.',
          'Compara las tarifas y acepta una para asignar al repartidor.',
        ],
      ),
      DeliveryStatus.cancelled => (
        Colors.grey.shade200,
        Icons.block,
        'Solicitud cancelada',
        ['No se admiten nuevas ofertas ni asignaciones.'],
      ),
      DeliveryStatus.delivered => (
        Colors.green.shade50,
        Icons.check_circle_outline,
        'Entrega completada',
        _assignmentLines(),
      ),
      _ => (
        Colors.green.shade50,
        Icons.assignment_turned_in_outlined,
        'Repartidor asignado',
        _assignmentLines(),
      ),
    };

    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.grey.shade800),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  for (final line in lines) ...[
                    const SizedBox(height: 4),
                    Text(line),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _assignmentLines() {
    final winner = _winningOffer;
    final driverName = winner?.driverName ?? _request.assignedDriverId ?? '—';
    final agreedFare = _request.agreedFareInCents != null
        ? formatCents(_request.agreedFareInCents!)
        : winner != null
        ? formatCents(winner.offeredFareInCents)
        : '—';

    return [
      'Repartidor: $driverName',
      'ID: ${_request.assignedDriverId ?? '—'}',
      'Tarifa acordada: $agreedFare',
      'Estado de entrega: ${deliveryStatusLabel(_request.status)}',
    ];
  }

  Widget _buildRatingSection() {
    if (_request.status != DeliveryStatus.delivered) {
      return const SizedBox.shrink();
    }

    if (_isRatingLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_rating != null) {
      return _buildRegisteredRatingCard();
    }

    final canRateAsClient =
        widget.identity.rbacRole == Role.client && _isOwnerRequester;

    if (!canRateAsClient) {
      // El repartidor puede ver la calificación registrada; si aún no existe,
      // no se expone el formulario de calificación.
      return const SizedBox.shrink();
    }

    return _buildRatingForm();
  }

  Widget _buildRegisteredRatingCard() {
    final rating = _rating!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text(
                  'Calificación registrada',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  Icons.star,
                  size: 22,
                  color: index < rating.score
                      ? Colors.amber
                      : Colors.grey.shade300,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Puntuación: ${rating.score} / 5'),
            if (rating.hasComment) ...[
              const SizedBox(height: 4),
              Text('Comentario: ${rating.comment}'),
            ],
            const SizedBox(height: 4),
            Text('Fecha: ${formatDateTime(rating.createdAt)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calificar al repartidor',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'La entrega se completó exitosamente. Califica la experiencia.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 220,
              child: FilledButton(
                key: const Key('open-rating-dialog'),
                onPressed: _isRatingSubmitting ? null : _showRateDialog,
                child: const Text('Calificar entrega'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOffersHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ofertas recibidas (${_offers.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Comparación por tarifa: primero las propuestas pendientes, '
            'de menor a mayor precio.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOffers() {
    if (_offers.isEmpty) {
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: 40,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(height: 8),
                Text(
                  _isDriver
                      ? 'Aún no hay ofertas. Envía la primera propuesta.'
                      : 'Aún no hay ofertas para esta solicitud.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return _offers
        .map(
          (offer) => DeliveryOfferCard(
            offer: offer,
            isBestOffer: offer.id == _bestOfferId,
            canRespond: _canRespondTo(offer),
            isWorking: _isWorking,
            onAccept: () => _respondToOffer(offer, accept: true),
            onReject: () => _respondToOffer(offer, accept: false),
          ),
        )
        .toList();
  }

  Widget _buildDriverActions() {
    if (!_isDriver || !_isPendingRequest) return const SizedBox.shrink();

    if (_canSubmitOffer) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: FilledButton.icon(
          key: const Key('submit-offer'),
          onPressed: _isWorking ? null : _submitOfferAction,
          icon: const Icon(Icons.send),
          label: Text(_offerButtonLabel),
        ),
      );
    }

    final hint = _driverHint;
    if (hint == null) return const SizedBox.shrink();

    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(hint)),
          ],
        ),
      ),
    );
  }

  Widget _buildRequesterHint() {
    if (_isDriver) return const SizedBox.shrink();
    if (widget.identity.rbacRole != Role.client &&
        widget.identity.rbacRole != Role.store) {
      return const SizedBox.shrink();
    }

    if (!_isOwnerRequester) {
      return Card(
        color: Colors.grey.shade100,
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Solo el cliente o comercio propietario puede aceptar o rechazar '
            'estas ofertas.',
          ),
        ),
      );
    }

    if (_isPendingRequest && _offers.any((o) => o.isPending)) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          'Aceptar una oferta asigna al repartidor y descarta automáticamente '
          'las demás propuestas pendientes.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _RatingInput {
  final int score;
  final String comment;

  const _RatingInput({required this.score, required this.comment});
}

class _RateDeliveryDialog extends StatefulWidget {
  const _RateDeliveryDialog();

  @override
  State<_RateDeliveryDialog> createState() => _RateDeliveryDialogState();
}

class _RateDeliveryDialogState extends State<_RateDeliveryDialog> {
  int _score = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_score < 1) return; // Requires at least 1 star
    Navigator.pop(
      context,
      _RatingInput(score: _score, comment: _commentController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Calificar entrega'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Selecciona una puntuación de 1 a 5 estrellas.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            DeliveryRatingStarsInput(
              key: const Key('rating-stars-input'),
              onScoreChanged: (v) => setState(() => _score = v),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('rating-comment-field'),
              controller: _commentController,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comentario (opcional)',
                hintText: 'Cuéntanos tu experiencia...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('confirm-rating'),
          onPressed: _score >= 1 ? _confirm : null,
          child: const Text('Enviar calificación'),
        ),
      ],
    );
  }
}

class _OfferInput {
  final String amount;
  final String comment;

  const _OfferInput({required this.amount, required this.comment});
}

class _SubmitOfferDialog extends StatefulWidget {
  const _SubmitOfferDialog();

  @override
  State<_SubmitOfferDialog> createState() => _SubmitOfferDialogState();
}

class _SubmitOfferDialogState extends State<_SubmitOfferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _OfferInput(
        amount: _amountController.text.trim(),
        comment: _commentController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enviar oferta'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('offer-amount-field'),
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Monto ofertado',
                hintText: 'Ej. 3.50',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa un monto.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('offer-comment-field'),
              controller: _commentController,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Comentario (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('confirm-submit-offer'),
          onPressed: _confirm,
          child: const Text('Confirmar oferta'),
        ),
      ],
    );
  }
}
