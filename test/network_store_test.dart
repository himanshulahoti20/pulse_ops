import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_ops/pulse_ops.dart';

void main() {
  group('InMemoryNetworkStore', () {
    late InMemoryNetworkStore store;

    setUp(() => store = InMemoryNetworkStore(maxRecords: 3));
    tearDown(() => store.dispose());

    NetworkRecord rec(String id) => NetworkRecord(
          id: id,
          method: 'GET',
          url: 'https://example.com/$id',
          startedAt: DateTime.now(),
        );

    test('prepends new records (newest first)', () {
      store.add(rec('a'));
      store.add(rec('b'));
      expect(store.records.map((e) => e.id), ['b', 'a']);
    });

    test('caps records at maxRecords', () {
      store.add(rec('a'));
      store.add(rec('b'));
      store.add(rec('c'));
      store.add(rec('d'));
      expect(store.records.length, 3);
      expect(store.records.first.id, 'd');
      expect(store.records.last.id, 'b');
    });

    test('update replaces existing record by id', () {
      store.add(rec('a'));
      store.update(rec('a').copyWith(statusCode: 200, status: NetworkStatus.success));
      expect(store.records.single.statusCode, 200);
      expect(store.records.single.status, NetworkStatus.success);
    });

    test('findById returns matching record', () {
      store.add(rec('a'));
      store.add(rec('b'));
      expect(store.findById('a')?.id, 'a');
      expect(store.findById('missing'), isNull);
    });

    test('stream emits on add and clear', () async {
      final events = <int>[];
      final sub = store.stream.listen((r) => events.add(r.length));
      store.add(rec('a'));
      store.add(rec('b'));
      store.clear();
      await Future<void>.delayed(Duration.zero);
      expect(events, containsAllInOrder(<int>[1, 2, 0]));
      await sub.cancel();
    });
  });
}
