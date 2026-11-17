import 'package:flutter/material.dart';

/// Selector de estrellas para calificar una entrega (1 a 5).
///
/// 100% UI pura: la selección se entrega al caso de uso vía callback. No
/// contiene reglas de negocio.
class DeliveryRatingStarsInput extends StatefulWidget {
  final int? initialScore;
  final ValueChanged<int>? onScoreChanged;

  const DeliveryRatingStarsInput({
    super.key,
    this.initialScore,
    this.onScoreChanged,
  });

  @override
  State<DeliveryRatingStarsInput> createState() =>
      _DeliveryRatingStarsInputState();
}

class _DeliveryRatingStarsInputState extends State<DeliveryRatingStarsInput> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialScore ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final value = index + 1;
        final selected = value <= _selected;
        return IconButton(
          key: Key('rating-star-$value'),
          onPressed: () {
            setState(() => _selected = value);
            widget.onScoreChanged?.call(value);
          },
          icon: Icon(
            selected ? Icons.star : Icons.star_border,
            size: 40,
            color: selected ? Colors.amber : Colors.grey.shade400,
          ),
        );
      }),
    );
  }
}
