import 'package:flutter_test/flutter_test.dart';

import 'package:calorie_tracker/services/product_catalog_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProductCatalogService service;

  setUp(() {
    service = ProductCatalogService();
  });

  test('loads compact USDA catalogue with nutrition per 100 grams', () async {
    final catalog = await service.loadCatalog();
    final oats = catalog.singleWhere((product) => product.fdcId == '173904');

    expect(catalog.length, greaterThanOrEqualTo(30));
    expect(oats.template.name, 'Овсяные хлопья сухие');
    expect(oats.template.baseWeight, 100);
    expect(oats.template.calories, 379);
    expect(oats.template.protein, 13.15);
    expect(oats.template.fat, 6.52);
    expect(oats.template.carbs, 67.7);
    expect(oats.sourceDescription, contains('Cereals, oats'));
  });

  test(
    'searches Russian and English aliases without case sensitivity',
    () async {
      final catalog = await service.loadCatalog();

      expect(
        service.search(catalog, 'КУРИЦА').single.template.name,
        'Куриная грудка без кожи, запечённая',
      );
      expect(service.search(catalog, 'chicken breast').single.fdcId, '171477');
      expect(service.search(catalog, 'МЕД').single.template.name, 'Мёд');
    },
  );

  test('shows a short popular list for an empty query', () async {
    final catalog = await service.loadCatalog();

    expect(service.search(catalog, ''), hasLength(12));
  });
}
