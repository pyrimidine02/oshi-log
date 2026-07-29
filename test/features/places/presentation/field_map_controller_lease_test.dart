import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/places/presentation/widgets/field_map_controller_lease.dart';

void main() {
  test('release clears the reference before disposing the controller', () {
    final lease = FieldMapControllerLease<_FakeMapController>();
    final controller = _FakeMapController();
    lease.attach(controller);

    lease.release(
      dispose: (released) {
        expect(lease.controller, isNull);
        released.dispose();
      },
    );

    expect(controller.isDisposed, isTrue);
    expect(lease.controller, isNull);
  });

  test('safe call skips work after an inactive transition', () async {
    final lease = FieldMapControllerLease<_FakeMapController>();
    var calls = 0;
    lease
      ..attach(_FakeMapController())
      ..release();

    await lease.run((_) async => calls += 1);

    expect(calls, 0);
  });

  test('safe call clears controllers that throw disposed errors', () async {
    final errors = <Object>[
      StateError('used after being disposed'),
      MissingPluginException('platform view removed'),
      PlatformException(code: 'channel-error'),
    ];

    for (final error in errors) {
      final lease = FieldMapControllerLease<_FakeMapController>()
        ..attach(_FakeMapController());

      await lease.run((_) => Future<void>.error(error));

      expect(lease.controller, isNull, reason: error.runtimeType.toString());
    }
  });

  test('late stale failure cannot clear a newly attached controller', () async {
    final lease = FieldMapControllerLease<_FakeMapController>();
    final oldController = _FakeMapController();
    final newController = _FakeMapController();
    final pending = Completer<void>();
    lease.attach(oldController);

    final call = lease.run((_) => pending.future);
    lease.attach(newController);
    pending.completeError(StateError('old controller disposed'));
    await call;

    expect(lease.controller, same(newController));
  });

  test('unexpected controller errors remain visible to callers', () async {
    final lease = FieldMapControllerLease<_FakeMapController>()
      ..attach(_FakeMapController());

    await expectLater(
      lease.run((_) => Future<void>.error(ArgumentError('bad camera target'))),
      throwsArgumentError,
    );
    expect(lease.controller, isNotNull);
  });
}

class _FakeMapController {
  bool isDisposed = false;

  void dispose() {
    isDisposed = true;
  }
}
