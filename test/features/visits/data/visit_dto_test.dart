import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/features/visits/data/dto/visit_dto.dart';
import 'package:girlsbandtabi_app/features/visits/domain/entities/visit_entities.dart';

void main() {
  test('visit list DTO preserves the server verification status', () {
    final dto = VisitEventDto.fromJson({
      'id': 'visit-1',
      'placeId': 'place-1',
      'visitedAt': '2026-07-16T10:00:00Z',
      'distanceM': 2.5,
      'status': 'verified',
    });
    final visit = VisitEvent.fromDto(dto);

    expect(dto.status, 'verified');
    expect(visit.status, VisitVerificationStatus.verified);
    expect(visit.isVerified, isTrue);
  });

  test('visit detail without status fails closed despite distance', () {
    final dto = VisitEventDetailDto.fromJson({
      'id': 'visit-legacy',
      'placeId': 'place-1',
      'visitedAt': '2026-07-16T10:00:00Z',
      'distanceM': 1,
    });
    final visit = VisitEvent.fromDetailDto(dto);

    expect(visit.status, VisitVerificationStatus.unknown);
    expect(visit.isVerified, isFalse);
    expect(visit.hasGpsVerification, isFalse);
  });
}
