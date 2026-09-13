import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/places/data/dto/place_dto.dart';
import 'package:oshi_log/features/places/data/mappers/place_entities_mappers.dart';

void main() {
  test('PlaceSummaryDto parses flexible keys', () {
    final json = {
      'id': 'place-1',
      'name': 'Shibuya',
      'types': ['SCENE', 'LANDMARK'],
      'tags': ['애니', '도쿄'],
      'latitude': 35.6595,
      'longitude': 139.7004,
      'introText': 'Famous crossing',
      'thumbnailUrl': 'https://example.com/thumb.jpg',
      'directions': {
        'countryCode': 'JPN',
        'providers': [
          {
            'provider': 'google_maps',
            'label': 'Google Maps',
            'url': 'https://maps.example.com/dir/1',
          },
        ],
      },
    };

    final dto = PlaceSummaryDto.fromJson(json);
    expect(dto.id, 'place-1');
    expect(dto.name, 'Shibuya');
    expect(dto.types, ['SCENE', 'LANDMARK']);
    expect(dto.tags, ['애니', '도쿄']);
    expect(dto.latitude, 35.6595);
    expect(dto.longitude, 139.7004);
    expect(dto.introText, 'Famous crossing');
    expect(dto.thumbnailUrl, 'https://example.com/thumb.jpg');
    expect(dto.directions?.countryCode, 'JPN');
    expect(dto.directions?.providers.length, 1);
    expect(dto.directions?.providers.first.provider, 'google_maps');
  });

  test('PlaceDetailDto parses tags and images', () {
    final json = {
      'id': 'place-2',
      'name': 'Studio',
      'types': ['STUDIO'],
      'latitude': 34.6937,
      'longitude': 135.5022,
      'address': 'Osaka',
      'description': 'Great place',
      'tags': ['Band A', 'Band B'],
      'directions': {
        'countryCode': 'JPN',
        'providers': [
          {
            'provider': 'apple_maps',
            'label': 'Apple Maps',
            'url': 'https://maps.example.com/dir/2',
          },
          {
            'provider': 'yahoo_maps',
            'label': 'Yahoo! Maps',
            'url': 'https://maps.example.com/dir/3',
          },
        ],
      },
      'images': [
        {
          'imageId': 'img-1',
          'url': 'a.jpg',
          'filename': 'a.jpg',
          'contentType': 'image/jpeg',
          'fileSize': 1024,
          'isPrimary': true,
        },
        {
          'imageId': 'img-2',
          'url': 'b.jpg',
          'filename': 'b.jpg',
          'contentType': 'image/jpeg',
          'fileSize': 2048,
          'isPrimary': false,
        },
      ],
    };

    final dto = PlaceDetailDto.fromJson(json);
    expect(dto.id, 'place-2');
    expect(dto.name, 'Studio');
    expect(dto.address, 'Osaka');
    expect(dto.description, 'Great place');
    expect(dto.images.length, 2);
    expect(dto.tags.length, 2);
    expect(dto.images.first.url, 'a.jpg');
    expect(dto.directions?.countryCode, 'JPN');
    expect(dto.directions?.providers.length, 2);
    expect(dto.directions?.providers.first.provider, 'apple_maps');
  });

  test(
    'PlaceDetailDto preserves related IDs and markdown through cache roundtrip',
    () {
      final sourceJson = {
        'id': 'place-related',
        'name': 'Related place',
        'types': ['STUDIO'],
        'latitude': 35.0,
        'longitude': 139.0,
        'address': 'Tokyo',
        'descriptionMarkdown': '## Official place description',
        'tags': const <String>[],
        'unitIds': ['unit-place'],
        'projectIds': ['project-place'],
        'characterIds': ['character-place'],
        'images': const <Map<String, dynamic>>[],
      };

      final dto = PlaceDetailDto.fromJson(sourceJson);
      final restoredDto = PlaceDetailDto.fromJson(dto.toJson());
      final detail = restoredDto.toDomain();

      expect(restoredDto.unitIds, ['unit-place']);
      expect(restoredDto.projectIds, ['project-place']);
      expect(restoredDto.characterIds, ['character-place']);
      expect(detail.unitIds, ['unit-place']);
      expect(detail.projectIds, ['project-place']);
      expect(detail.characterIds, ['character-place']);
      expect(detail.description, '## Official place description');
    },
  );
}
