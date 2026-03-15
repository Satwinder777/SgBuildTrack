import 'package:equatable/equatable.dart';
import '../../../core/services/material_calculator.dart';

/// Material category enum matching app strings.
enum MaterialCategory {
  foundationMaterial,
  brick,
  cement,
  sand,
  aggregate,
  steel,
  slabMaterial,
  plasterMaterial,
  flooring,
  doors,
  windows,
  other,
}

extension MaterialCategoryX on MaterialCategory {
  String get displayName {
    switch (this) {
      case MaterialCategory.foundationMaterial:
        return 'Foundation Material';
      case MaterialCategory.brick:
        return 'Brick';
      case MaterialCategory.cement:
        return 'Cement';
      case MaterialCategory.sand:
        return 'Sand';
      case MaterialCategory.aggregate:
        return 'Aggregate (Bajri)';
      case MaterialCategory.steel:
        return 'Steel (Sariya)';
      case MaterialCategory.slabMaterial:
        return 'Slab Material';
      case MaterialCategory.plasterMaterial:
        return 'Plaster Material';
      case MaterialCategory.flooring:
        return 'Flooring';
      case MaterialCategory.doors:
        return 'Doors';
      case MaterialCategory.windows:
        return 'Windows';
      case MaterialCategory.other:
        return 'Other';
    }
  }

  static MaterialCategory fromString(String value) {
    return MaterialCategory.values.firstWhere(
      (e) => e.name == value || e.displayName == value,
      orElse: () => MaterialCategory.other,
    );
  }
}

/// Supported unit types for materials. Stored in Firestore as [code].
/// Strict unit-based calculations: totalCost = quantity × pricePerUnit.
enum MaterialUnit {
  piece,
  bag,
  kg,
  g,
  ton,
  liter,
  meter,
  squareMeter,
  cubicMeter,
}

extension MaterialUnitX on MaterialUnit {
  /// Firestore storage code (backward compat: sqm/cum accepted in fromString).
  String get code {
    switch (this) {
      case MaterialUnit.squareMeter:
        return 'squareMeter';
      case MaterialUnit.cubicMeter:
        return 'cubicMeter';
      default:
        return name;
    }
  }

  String get displayName {
    switch (this) {
      case MaterialUnit.piece:
        return 'Piece';
      case MaterialUnit.bag:
        return 'Bag';
      case MaterialUnit.kg:
        return 'Kilogram (kg)';
      case MaterialUnit.g:
        return 'Gram (g)';
      case MaterialUnit.ton:
        return 'Ton';
      case MaterialUnit.liter:
        return 'Liter';
      case MaterialUnit.meter:
        return 'Meter';
      case MaterialUnit.squareMeter:
        return 'Square Meter';
      case MaterialUnit.cubicMeter:
        return 'Cubic Meter';
    }
  }

  static MaterialUnit fromString(String? value) {
    if (value == null || value.isEmpty) return MaterialUnit.piece;
    final lower = value.trim().toLowerCase();
    if (lower == 'sqm') return MaterialUnit.squareMeter;
    if (lower == 'cum') return MaterialUnit.cubicMeter;
    for (final e in MaterialUnit.values) {
      if (e.name == lower || e.code.toLowerCase() == lower) return e;
    }
    return MaterialUnit.piece;
  }
}

/// Category-to-unit mapping and validation for compile-time safety.
extension MaterialCategoryUnitMapping on MaterialCategory {
  /// Default (and often only) allowed unit for this category.
  MaterialUnit get defaultUnit {
    switch (this) {
      case MaterialCategory.brick:
        return MaterialUnit.piece;
      case MaterialCategory.cement:
        return MaterialUnit.bag;
      case MaterialCategory.sand:
        return MaterialUnit.cubicMeter;
      case MaterialCategory.aggregate:
        return MaterialUnit.ton;
      case MaterialCategory.steel:
        return MaterialUnit.kg;
      case MaterialCategory.slabMaterial:
        return MaterialUnit.cubicMeter;
      case MaterialCategory.plasterMaterial:
        return MaterialUnit.bag;
      case MaterialCategory.flooring:
        return MaterialUnit.squareMeter;
      case MaterialCategory.doors:
        return MaterialUnit.piece;
      case MaterialCategory.windows:
        return MaterialUnit.piece;
      case MaterialCategory.foundationMaterial:
        return MaterialUnit.cubicMeter;
      case MaterialCategory.other:
        return MaterialUnit.piece;
    }
  }

  /// All allowed units for this category (e.g. Steel: kg or ton). "Other" allows all.
  List<MaterialUnit> get allowedUnits {
    switch (this) {
      case MaterialCategory.steel:
        return [MaterialUnit.kg, MaterialUnit.ton];
      case MaterialCategory.other:
        return MaterialUnit.values;
      default:
        return [defaultUnit];
    }
  }

  /// Whether unit is locked (single allowed unit).
  bool get isUnitLocked => allowedUnits.length == 1;

  /// Throws if [unit] is not allowed for this category.
  void validateUnit(MaterialUnit unit) {
    if (allowedUnits.contains(unit)) return;
    final allowed = allowedUnits.map((u) => u.displayName).join(' or ');
    throw MaterialUnitException('$displayName must use unit: $allowed');
  }
}

/// Exception for invalid category–unit combination.
class MaterialUnitException implements Exception {
  MaterialUnitException(this.message);
  final String message;
  @override
  String toString() => message;
}

class MaterialModel extends Equatable {
  const MaterialModel({
    required this.id,
    required this.category,
    required this.materialName,
    required this.quantity,
    required this.unitType,
    required this.pricePerUnit,
    required this.totalPrice,
    this.supplierName,
    this.purchaseDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.supplierPhone,
    this.billImageUrl,
  });

  final String id;
  final MaterialCategory category;
  final String materialName;
  final double quantity;
  final MaterialUnit unitType;
  final double pricePerUnit;
  final double totalPrice;
  final String? supplierName;
  final DateTime? purchaseDate;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? supplierPhone;
  final String? billImageUrl;

  /// Unit as string for Firestore/display.
  String get unit => unitType.code;

  /// Total cost (same as totalPrice). Strict rule: totalCost = quantity × pricePerUnit.
  double get totalCost => totalPrice;

  /// Date of purchase (alias for purchaseDate).
  DateTime? get date => purchaseDate;

  MaterialModel copyWith({
    String? id,
    MaterialCategory? category,
    String? materialName,
    double? quantity,
    MaterialUnit? unitType,
    double? pricePerUnit,
    double? totalPrice,
    String? supplierName,
    DateTime? purchaseDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? supplierPhone,
    String? billImageUrl,
  }) {
    return MaterialModel(
      id: id ?? this.id,
      category: category ?? this.category,
      materialName: materialName ?? this.materialName,
      quantity: quantity ?? this.quantity,
      unitType: unitType ?? this.unitType,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      totalPrice: totalPrice ?? this.totalPrice,
      supplierName: supplierName ?? this.supplierName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      supplierPhone: supplierPhone ?? this.supplierPhone,
      billImageUrl: billImageUrl ?? this.billImageUrl,
    );
  }

  /// Recalculate total: totalCost = quantity × pricePerUnit (strict rule).
  MaterialModel recalculateTotal() {
    final total = MaterialCalculator.calculateMaterialCost(
      quantity: quantity,
      pricePerUnit: pricePerUnit,
    );
    return copyWith(totalPrice: total);
  }

  /// Validates that unit is allowed for this category. Throws [MaterialUnitException] if not.
  void validateUnitForCategory() {
    category.validateUnit(unitType);
  }

  Map<String, dynamic> toFirestore() {
    final total = quantity * pricePerUnit;
    return {
      'id': id,
      'category': category.name,
      'materialName': materialName,
      'name': materialName,
      'quantity': quantity,
      'unit': unitType.code,
      'unitType': unitType.code,
      'pricePerUnit': pricePerUnit,
      'price_per_unit': pricePerUnit,
      'totalPrice': total,
      'total_cost': total,
      'date': purchaseDate?.toIso8601String(),
      'supplierName': supplierName,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      if (supplierPhone != null) 'supplierPhone': supplierPhone,
      if (billImageUrl != null) 'billImageUrl': billImageUrl,
    };
  }

  factory MaterialModel.fromFirestore(Map<String, dynamic> map) {
    final purchaseDate = map['purchaseDate'] ?? map['date'];
    final createdAt = map['createdAt'];
    final updatedAt = map['updatedAt'];
    final unitRaw = map['unitType'] as String? ?? map['unit'] as String?;
    final quantity = (map['quantity'] as num?)?.toDouble() ?? 0.0;
    final pricePerUnit = (map['pricePerUnit'] as num?)?.toDouble() ?? (map['price_per_unit'] as num?)?.toDouble() ?? 0.0;
    final totalPrice = (map['totalPrice'] as num?)?.toDouble() ?? (map['total_cost'] as num?)?.toDouble() ?? (quantity * pricePerUnit);
    final materialName = map['materialName'] as String? ?? map['name'] as String? ?? '';
    return MaterialModel(
      id: map['id'] as String? ?? '',
      category: MaterialCategoryX.fromString((map['category'] as String?) ?? 'other'),
      materialName: materialName,
      quantity: quantity,
      unitType: MaterialUnitX.fromString(unitRaw),
      pricePerUnit: pricePerUnit,
      totalPrice: totalPrice,
      supplierName: map['supplierName'] as String?,
      purchaseDate: purchaseDate != null ? DateTime.tryParse(purchaseDate.toString()) : null,
      notes: map['notes'] as String?,
      createdAt: createdAt != null ? DateTime.tryParse(createdAt.toString()) : null,
      updatedAt: updatedAt != null ? DateTime.tryParse(updatedAt.toString()) : null,
      supplierPhone: map['supplierPhone'] as String?,
      billImageUrl: map['billImageUrl'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, category, materialName, quantity, unitType, pricePerUnit, totalPrice];
}
