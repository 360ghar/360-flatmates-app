import '../data/blog_post_dto.dart';

/// Domain model for a blog post. UI never touches the DTO.
class BlogPost {
  const BlogPost({
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
  });

  final int id;
  final String slug;
  final String title;
  final String body;
  final BlogPostStatus status;
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
  final List<BlogCategory> categories;
  final List<BlogTag> tags;
  final Map<String, dynamic> seoMetadata;

  factory BlogPost.fromDto(BlogPostDto dto) => BlogPost(
        id: dto.id,
        slug: dto.slug,
        title: dto.title,
        body: dto.body,
        status: _mapStatus(dto.status),
        excerpt: dto.excerpt,
        coverImageUrl: dto.coverImageUrl,
        authorName: dto.authorName,
        metaTitle: dto.metaTitle,
        metaDescription: dto.metaDescription,
        focusKeyword: dto.focusKeyword,
        canonicalUrl: dto.canonicalUrl,
        ogImageUrl: dto.ogImageUrl,
        readingTimeMinutes: dto.readingTimeMinutes,
        wordCount: dto.wordCount,
        publishedAt: dto.publishedAt,
        createdAt: dto.createdAt,
        updatedAt: dto.updatedAt,
        sources: dto.sources,
        categories: dto.categories.map(BlogCategory.fromDto).toList(),
        tags: dto.tags.map(BlogTag.fromDto).toList(),
        seoMetadata: dto.seoMetadata,
      );

  static BlogPostStatus _mapStatus(BlogPostStatusDto dto) {
    return switch (dto) {
      BlogPostStatusDto.draft => BlogPostStatus.draft,
      BlogPostStatusDto.published => BlogPostStatus.published,
      BlogPostStatusDto.archived => BlogPostStatus.archived,
      BlogPostStatusDto.scheduled => BlogPostStatus.scheduled,
      BlogPostStatusDto.unknown => BlogPostStatus.unknown,
    };
  }
}

class BlogCategory {
  const BlogCategory({required this.id, required this.name, this.slug});

  final int id;
  final String name;
  final String? slug;

  factory BlogCategory.fromDto(BlogCategoryDto dto) => BlogCategory(
        id: dto.id,
        name: dto.name,
        slug: dto.slug,
      );
}

class BlogTag {
  const BlogTag({required this.id, required this.name, this.slug});

  final int id;
  final String name;
  final String? slug;

  factory BlogTag.fromDto(BlogTagDto dto) => BlogTag(
        id: dto.id,
        name: dto.name,
        slug: dto.slug,
      );
}

enum BlogPostStatus { draft, published, archived, scheduled, unknown; }
