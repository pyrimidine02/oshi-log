import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/feed/application/pending_post_reaction_mutation.dart';

void main() {
  test('PendingPostReactionMutation parses like mutation json', () {
    final mutation = PendingPostReactionMutation.fromJson({
      'projectCode': 'girls-band-cry',
      'postId': 'post-1',
      'type': 'like',
      'enabled': true,
      'queuedAt': '2026-03-13T01:30:00.000Z',
    });

    expect(mutation.projectCode, 'girls-band-cry');
    expect(mutation.postId, 'post-1');
    expect(mutation.type, PostReactionMutationType.like);
    expect(mutation.enabled, true);
    expect(mutation.toJson()['type'], 'like');
  });

  test('PendingPostReactionMutation maps unknown type safely', () {
    final mutation = PendingPostReactionMutation.fromJson({
      'projectCode': 'girls-band-cry',
      'postId': 'post-2',
      'type': 'invalid_type',
      'enabled': false,
      'queuedAt': '2026-03-13T01:30:00.000Z',
    });

    expect(mutation.type, PostReactionMutationType.unknown);
  });
}
