class TechItem {
  final String? id;
  final String? productName;
  final String? description;
  final double? price;
  final bool? inStock;
  final String? itemSku;
  final String? entryDate;
  final List<String> category;
  final String? productImageUrl;
  final Map<String, String> technicalSpecs;
  final String? supportEmail;
  final String? createdAt;
  final String? publishedAt;
  final String? updatedAt;

  TechItem({
    this.id,
    this.productName,
    this.description,
    this.price,
    this.inStock,
    this.itemSku,
    this.entryDate,
    this.category = const [],
    this.productImageUrl,
    this.technicalSpecs = const {},
    this.supportEmail,
    this.createdAt,
    this.publishedAt,
    this.updatedAt,
  });

  factory TechItem.fromJson(Map<String, dynamic> json) {
    List<String> cats = [];
    final rawCat = json['category'];
    if (rawCat is List) cats = rawCat.map((e) => e.toString()).toList();

    Map<String, String> specs = {};
    final rawSpecs = json['technical_specs'];
    if (rawSpecs is Map) {
      specs = rawSpecs.map((k, v) => MapEntry(k.toString(), v.toString()));
    }

    return TechItem(
      id: json['id']?.toString(),
      productName: json['product_name']?.toString(),
      description: json['description']?.toString(),
      price: (json['price'] as num?)?.toDouble(),
      inStock: json['in_stock'] as bool?,
      itemSku: json['item_sku']?.toString(),
      entryDate: json['entry_date']?.toString(),
      category: cats,
      productImageUrl: json['product_image_url']?.toString(),
      technicalSpecs: specs,
      supportEmail: json['support_email']?.toString(),
      createdAt: json['created_at']?.toString(),
      publishedAt: json['published_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}
