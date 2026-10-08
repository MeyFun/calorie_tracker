import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/food_template.dart';

class CatalogProduct {
  const CatalogProduct({
    required this.fdcId,
    required this.template,
    required this.searchTerms,
    required this.sourceDescription,
  });

  final String fdcId;
  final FoodTemplate template;
  final List<String> searchTerms;
  final String sourceDescription;

  factory CatalogProduct.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Элемент каталога должен быть объектом.');
    }
    final map = Map<String, Object?>.from(value);
    final fdcId = map['fdcId'];
    final name = map['name'];
    final rawSearchTerms = map['searchTerms'];
    final sourceDescription = map['sourceDescription'];
    if (fdcId is! String ||
        name is! String ||
        name.trim().isEmpty ||
        sourceDescription is! String ||
        rawSearchTerms is! List ||
        rawSearchTerms.any((term) => term is! String)) {
      throw const FormatException('Некорректные сведения о продукте.');
    }

    double readNumber(String key) {
      final value = map[key];
      if (value is! num || !value.isFinite || value < 0) {
        throw FormatException('Некорректное значение «$key» у продукта $fdcId.');
      }
      return value.toDouble();
    }

    return CatalogProduct(
      fdcId: fdcId,
      template: FoodTemplate(
        name: name,
        calories: readNumber('calories'),
        protein: readNumber('protein'),
        fat: readNumber('fat'),
        carbs: readNumber('carbs'),
        baseWeight: 100,
      ),
      searchTerms: List<String>.unmodifiable(rawSearchTerms.cast<String>()),
      sourceDescription: sourceDescription,
    );
  }
}

class ProductCatalogService {
  static const _assetPath = 'assets/data/common_foods_ru.json';

  Future<List<CatalogProduct>> loadCatalog() async {
    final json = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(json);
    if (decoded is! List) {
      throw const FormatException('Каталог продуктов должен быть списком.');
    }
    return List<CatalogProduct>.unmodifiable(
      decoded.map(CatalogProduct.fromJson),
    );
  }

  List<CatalogProduct> search(
    List<CatalogProduct> catalog,
    String query, {
    int limit = 12,
  }) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return catalog.take(limit).toList();

    final queryTerms = normalizedQuery.split(RegExp(r'\s+'));
    return catalog
        .where((product) {
          final searchableText = _normalize(
            '${product.template.name} ${product.searchTerms.join(' ')}',
          );
          return queryTerms.every(searchableText.contains);
        })
        .take(limit)
        .toList();
  }

  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll('ё', 'е');
}
