import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/rating.dart';

abstract class RatingRepository {
  Future<Result<void, Failure>> submitRating(Rating rating);
  Future<Result<List<Rating>, Failure>> getRatingsForUser(String userId);
}
