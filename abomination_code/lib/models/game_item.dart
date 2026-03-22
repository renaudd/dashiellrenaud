import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum ItemCategory {
  food,
  material,
  specimen,
  reagent,
  medical,
  utility,
  knowledge,
  resource,
  corpse,
}

enum ItemShape { circle, square, triangle, diamond, hexagon, pill }

class GameItem {
  final String id;
  final String name;
  final String type; // e.g., 'egg', 'rat', 'cabbage'
  final ItemCategory category;
  final int quantity;
  final double quality; // 0.0 to 2.0
  final ItemShape shape;
  final Color color;
  final double weight; // in kilograms
  final int value; // base value in funds
  final Map<String, dynamic> metadata;
  bool get isReserved => metadata['isReserved'] == true;

  GameItem({
    required this.id,
    required this.name,
    required this.type,
    required this.category,
    this.quantity = 1,
    this.quality = 1.0,
    required this.shape,
    this.color = Colors.grey,
    this.weight = 0.1,
    this.value = 1,
    this.metadata = const {},
  });

  factory GameItem.create({
    required String name,
    required String type,
    required ItemCategory category,
    int quantity = 1,
    double quality = 1.0,
    double? weight,
    int? value,
    ItemShape? shape,
    Color? color,
    Map<String, dynamic> metadata = const {},
  }) {
    // Determine default shape and color based on type if not provided
    final (ItemShape defShape, Color defColor) = _getVisualsForType(
      type,
      category,
    );

    return GameItem(
      id: const Uuid().v4(),
      name: name,
      type: type,
      category: category,
      quantity: quantity,
      quality: quality,
      shape: shape ?? defShape,
      color: color ?? defColor,
      weight: weight ?? _getDefaultWeightForType(type, category),
      value: value ?? _getDefaultValueForType(type, category),
      metadata: metadata,
    );
  }

  static double _getDefaultWeightForType(String type, ItemCategory category) {
    if (type.contains('egg')) return 0.05;
    if (type.contains('rat')) return 0.3;
    if (type.contains('cabbage')) return 0.5;
    if (type.contains('meat')) return 1.0;
    if (type.contains('grain')) return 0.1;
    if (type.contains('timber')) return 5.0;
    return 0.1;
  }

  static int _getDefaultValueForType(String type, ItemCategory category) {
    if (type.contains('egg')) return 1;
    if (type.contains('rat')) return 2;
    if (type.contains('cabbage')) return 3;
    if (type.contains('meat')) return 5;
    if (type.contains('funds')) return 1;
    if (type.contains('timber')) return 8;
    return 1;
  }

  static (ItemShape, Color) _getVisualsForType(
    String type,
    ItemCategory category,
  ) {
    if (type.contains('egg')) {
      return (ItemShape.circle, Colors.amber.shade100);
    }
    if (type.contains('rat')) {
      return (ItemShape.triangle, Colors.grey.shade600);
    }
    if (type.contains('cabbage')) {
      return (ItemShape.hexagon, Colors.green.shade400);
    }
    if (type.contains('meat')) {
      return (ItemShape.square, Colors.red.shade400);
    }
    if (type.contains('grain') || type.contains('flour')) {
      return (ItemShape.hexagon, Colors.yellow.shade200);
    }
    if (type.contains('note') || type.contains('document')) {
      return (ItemShape.pill, Colors.lightBlue.shade100);
    }
    if (type.contains('medicine')) {
      return (ItemShape.pill, Colors.pink.shade300);
    }
    if (type.contains('corpse')) {
      return (ItemShape.circle, const Color(0xFF4A1A1A)); // Deep dried blood red
    }

    // Fallsbacks by category
    switch (category) {
      case ItemCategory.food:
        return (ItemShape.circle, Colors.orange.shade300);
      case ItemCategory.material:
        return (ItemShape.square, Colors.brown.shade400);
      case ItemCategory.knowledge:
        return (ItemShape.pill, Colors.blue.shade200);
      default:
        return (ItemShape.diamond, Colors.grey);
    }
  }

  GameItem copyWith({
    String? id,
    String? name,
    String? type,
    int? quantity,
    double? quality,
    ItemShape? shape,
    Color? color,
    double? weight,
    int? value,
    Map<String, dynamic>? metadata,
  }) {
    return GameItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      category: category,
      quantity: quantity ?? this.quantity,
      quality: quality ?? this.quality,
      shape: shape ?? this.shape,
      color: color ?? this.color,
      weight: weight ?? this.weight,
      value: value ?? this.value,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'category': category.index,
    'quantity': quantity,
    'quality': quality,
    'shape': shape.index,
    'color': color.toARGB32(),
    'weight': weight,
    'value': value,
    'metadata': metadata,
  };

  factory GameItem.fromJson(Map<String, dynamic> json) => GameItem(
    id: json['id'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    category: ItemCategory.values[json['category'] as int],
    quantity: json['quantity'] as int,
    quality: (json['quality'] as num).toDouble(),
    shape: ItemShape.values[json['shape'] as int? ?? 0],
    color: Color(json['color'] as int? ?? Colors.grey.toARGB32()),
    weight: (json['weight'] as num? ?? 0.1).toDouble(),
    value: json['value'] as int? ?? 1,
    metadata: json['metadata'] as Map<String, dynamic>? ?? {},
  );
}
