/// DTO + serialization for a blog post + its categories/tags.
///
/// Mirrors the backend's `BlogPost`, `BlogCategory`, `BlogTag`, and the
/// admin `BlogPostPreviewResponse` shapes — the wire envelopes are nearly
/// identical for these endpoints, so we use a single class with two named
/// factories (`fromJson`, `fromPreviewJson`) to cover both.
class BlogPostDto {
  const BlogPostDto({
    required this.id,
    required this.slug,
    required this.title,
    required this.body,
    required this.status,
    this.excerpt,
    this.coverImageUrl,
    this.authorName,
    this.metaTitle,
    this.metaDescription,
    this.focusKeyword,
    this.canonicalUrl,
    this.ogImageUrl,
    this.readingTimeMinutes,
    this.wordCount,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
    this.sources = const [],
    this.categories = const [],
    this.tags = const [],
    this.seoMetadata = const <String, dynamic>{},
    this.raw = const <String, dynamic>{},
  });

  final int id;
  final String slug;
  final String title;
  final String body;
  final BlogPostStatusDto status;
  final String? excerpt;
  final String? coverImageUrl;
  final String? authorName;
  final String? metaTitle;
  final String? metaDescription;
  final String? focusKeyword;
  final String? canonicalUrl;
  final String? ogImageUrl;
  final int? readingTimeMinutes;
  final int? wordCount;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> sources;
  final List<BlogCategoryDto> categories;
  final List<BlogTagDto> tags;
  final Map<String, dynamic> seoMetadata;
  final Map<String, dynamic> raw;

  factory BlogPostDto.fromJson(Map<String, dynamic> json) {
    return BlogPostDto._fromMap(json, preview: false);
  }

  /// Same shape, but tolerates missing fields that are not exposed on the
  /// preview endpoint (e.g. published metadata may be absent).
  factory BlogPostDto.fromPreviewJson(Map<String, dynamic> json) {
    return BlogPostDto._fromMap(json, preview: true);
  }

  factory BlogPostDto._fromMap(
    Map<String, dynamic> json, {
    required bool preview,
  }) {
    final sources = (json['sources'] as List?)
            ?.map((item) => item.toString())
            .toList() ??
        const <String>[];
    final rawCategories = json['categories'] as List? ?? const [];
    final rawTags = json['tags'] as List? ?? const [];
    final seo = json['seo_metadata'];
    return BlogPostDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      status: BlogPostStatusDto.fromWire(json['status'] as String?),
      excerpt: json['excerpt'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      authorName: json['author_name'] as String?,
      metaTitle: json['meta_title'] as String?,
      metaDescription: json['meta_description'] as String?,
      focusKeyword: json['focus_keyword'] as String?,
      canonicalUrl: json['canonical_url'] as String?,
      ogImageUrl: json['og_image_url'] as String?,
      readingTimeMinutes: (json['reading_time_minutes'] as num?)?.toInt(),
      wordCount: (json['word_count'] as num?)?.toInt(),
      publishedAt: DateTime.tryParse(json['published_at']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      sources: sources,
      categories: rawCategories
          .whereType<Map>()
          .map(
            (c) => BlogCategoryDto.fromJson(Map<String, dynamic>.from(c)),
          )
          .toList(),
      tags: rawTags
          .whereType<Map>()
          .map((t) => BlogTagDto.fromJson(Map<String, dynamic>.from(t)))
          .toList(),
      seoMetadata: seo is Map
          ? Map<String, dynamic>.from(seo)
          : const <String, dynamic>{},
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'title': title,
        'body': body,
        'status': status.wire,
        if (excerpt != null) 'excerpt': excerpt,
        if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
        if (authorName != null) 'author_name': authorName,
        if (metaTitle != null) 'meta_title': metaTitle,
        if (metaDescription != null) 'meta_description': metaDescription,
        if (focusKeyword != null) 'focus_keyword': focusKeyword,
        if (canonicalUrl != null) 'canonical_url': canonicalUrl,
        if (ogImageUrl != null) 'og_image_url': ogImageUrl,
        if (readingTimeMinutes != null)
          'reading_time_minutes': readingTimeMinutes,
        if (wordCount != null) 'word_count': wordCount,
        if (publishedAt != null) 'published_at': publishedAt!.toIso8601String(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
        'sources': sources,
        'categories': categories.map((c) => c.toJson()).toList(),
        'tags': tags.map((t) => t.toJson()).toList(),
        'seo_metadata': seoMetadata,
      };
}

class BlogCategoryDto {
  const BlogCategoryDto({required this.id, required this.name, this.slug});

  final int id;
  final String name;
  final String? slug;

  factory BlogCategoryDto.fromJson(Map<String, dynamic> json) {
    return BlogCategoryDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (slug != null) 'slug': slug,
      };
}

class BlogTagDto {
  const BlogTagDto({required this.id, required this.name, this.slug});

  final int id;
  final String name;
  final String? slug;

  factory BlogTagDto.fromJson(Map<String, dynamic> json) {
    return BlogTagDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (slug != null) 'slug': slug,
      };
}

enum BlogPostStatusDto { draft, published, archived, scheduled, unknown;

  String get wire => switch (this) {
        BlogPostStatusDto.draft => 'draft',
        BlogPostStatusDto.published => 'published',
        BlogPostStatusDto.archived => 'archived',
        BlogPostStatusDto.scheduled => 'scheduled',
        BlogPostStatusDto.unknown => 'unknown',
      };

  static BlogPostStatusDto fromWire(String? raw) {
    switch (raw) {
      case 'draft':
        return BlogPostStatusDto.draft;
      case 'published':
        return BlogPostStatusDto.published;
      case 'archived':
        return BlogPostStatusDto.archived;
      case 'scheduled':
        return BlogPostStatusDto.scheduled;
      default:
        return BlogPostStatusDto.unknown;
    }
  }
}
