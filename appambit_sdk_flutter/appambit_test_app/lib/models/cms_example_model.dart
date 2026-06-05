class ArticleItem {
  final String? id;
  final String? title;
  final String? body;
  final List<String> category;
  final String? eventDate;
  final int? viewsCount;
  final bool? isPublished;
  final String? featuredImageUrl;
  final String? scheduledPublishAt;
  final String? createdAt;
  final String? publishedAt;
  final String? updatedAt;

  ArticleItem({
    this.id,
    this.title,
    this.body,
    this.category = const [],
    this.eventDate,
    this.viewsCount,
    this.isPublished,
    this.featuredImageUrl,
    this.scheduledPublishAt,
    this.createdAt,
    this.publishedAt,
    this.updatedAt,
  });

  factory ArticleItem.fromJson(Map<String, dynamic> json) {
    List<String> cats = [];
    final rawCat = json['category'];
    if (rawCat is List) cats = rawCat.map((e) => e.toString()).toList();

    return ArticleItem(
      id: json['id']?.toString(),
      title: json['title']?.toString(),
      body: json['body']?.toString(),
      category: cats,
      eventDate: json['event_date']?.toString(),
      viewsCount: (json['views_count'] as num?)?.toInt(),
      isPublished: json['is_published'] as bool?,
      featuredImageUrl: json['featured_image_url']?.toString(),
      scheduledPublishAt: json['scheduled_publish_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      publishedAt: json['published_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}
