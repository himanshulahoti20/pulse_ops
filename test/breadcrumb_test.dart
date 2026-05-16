import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_ops/pulse_ops.dart';

void main() {
  group('BreadcrumbTrail', () {
    test('appends entries chronologically', () {
      final trail = BreadcrumbTrail(maxEntries: 5);
      trail.log('first');
      trail.log('second');
      trail.log('third');
      expect(trail.entries.map((b) => b.message),
          containsAllInOrder(['first', 'second', 'third']));
    });

    test('evicts oldest entry beyond capacity', () {
      final trail = BreadcrumbTrail(maxEntries: 2);
      trail.log('a');
      trail.log('b');
      trail.log('c');
      expect(trail.entries.length, 2);
      expect(trail.entries.first.message, 'b');
      expect(trail.entries.last.message, 'c');
    });

    test('clear empties the trail', () {
      final trail = BreadcrumbTrail()..log('x');
      trail.clear();
      expect(trail.entries, isEmpty);
    });

    test('records level and data', () {
      final trail = BreadcrumbTrail();
      trail.log('boom', level: BreadcrumbLevel.error, data: {'a': 1});
      final b = trail.entries.single;
      expect(b.level, BreadcrumbLevel.error);
      expect(b.data, {'a': 1});
      expect(b.toMap()['data'], {'a': 1});
    });
  });
}
