import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_ops/pulse_ops.dart';

void main() {
  group('GraphQLInfo', () {
    test('parses a named mutation with variables', () {
      final info = GraphQLInfo.tryParse({
        'query':
            'mutation CreatePost(\$t: String!) { create(title: \$t) { id } }',
        'variables': {'t': 'hi'},
      }, const {})!;
      expect(info.type, 'mutation');
      expect(info.operationName, 'CreatePost');
      expect(info.variables, {'t': 'hi'});
    });

    test('operationName field wins and anonymous shorthand is a query', () {
      final info = GraphQLInfo.tryParse(
        {'query': '{ me { id } }', 'operationName': 'Me'},
        const {},
      )!;
      expect(info.type, 'query');
      expect(info.operationName, 'Me');
    });

    test('reads GET query string and batched arrays', () {
      expect(
        GraphQLInfo.tryParse(null, {'query': 'query A { a }'})?.operationName,
        'A',
      );
      final batch = GraphQLInfo.tryParse([
        {'query': 'query A { a }'},
        {'query': 'query B { b }'},
      ], const {})!;
      expect(batch.batchSize, 2);
      expect(batch.operationName, 'A');
    });

    test('rejects non-GraphQL payloads', () {
      expect(GraphQLInfo.tryParse({'query': 'shoes'}, const {}), isNull);
      expect(GraphQLInfo.tryParse({'name': 'x'}, const {}), isNull);
      expect(GraphQLInfo.tryParse('plain', const {}), isNull);
    });
  });
}
