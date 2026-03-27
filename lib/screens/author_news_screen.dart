import 'package:flutter/material.dart';
import '../models/news.dart';
import '../services/news_service.dart';
import '../widgets/news_card.dart';
import '../widgets/article_detail.dart';
import '../constants/app_constants.dart';

class AuthorNewsScreen extends StatefulWidget {
  final String authorName;
  final String authorImage;

  const AuthorNewsScreen({
    super.key,
    required this.authorName,
    required this.authorImage,
  });

  @override
  State<AuthorNewsScreen> createState() => _AuthorNewsScreenState();
}

class _AuthorNewsScreenState extends State<AuthorNewsScreen>
    with TickerProviderStateMixin {
  final NewsService _newsService = NewsService();
  List<NewsArticle> _articles = [];
  bool _isLoading = true;
  NewsArticle? _selectedArticle;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadAuthorArticles();
    _setupAnimations();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    _fadeController.forward();
  }

  Future<void> _loadAuthorArticles() async {
    setState(() => _isLoading = true);

    try {
      // Filter articles by author ID
      final allArticles = await _newsService.fetchArticles();
      final authorArticles = allArticles.where((article) {
        return article.newsAuthor.id == _getAuthorIdFromName(widget.authorName);
      }).toList();

      setState(() {
        _articles = authorArticles;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading author articles: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getAuthorIdFromName(String authorName) {
    // Map author names to their respective IDs based on original articles
    if (authorName.contains('CTU Danao Crush')) return 'CTU Danao Crush';
    if (authorName.contains('CTU Danao')) return 'ctu_danao';
    if (authorName.contains('Engineering')) return 'engineering';
    if (authorName.contains('Technology')) return 'technology';
    if (authorName.contains('Education')) return 'education';
    if (authorName.contains('CME')) return 'cme';
    return 'unknown';
  }

  Future<void> _handleArticleTap(NewsArticle article) async {
    await _newsService.incrementViewCount(article.id);
    setState(() {
      _selectedArticle = article;
    });
  }

  String _getAuthorBio() {
    // Return appropriate bio based on author
    if (widget.authorName.contains('CTU Danao Crush')) {
      return 'CTU Danao Crush - Your source for campus crushes, student spotlights, and fun community content.';
    } else if (widget.authorName.contains('CTU Danao')) {
      return 'Cebu Technological University - Danao Campus. Leading innovation and excellence in education and technology.';
    } else if (widget.authorName.contains('Engineering')) {
      return 'College of Engineering - Pioneering technological advancement and engineering excellence in Cebu.';
    } else if (widget.authorName.contains('Technology')) {
      return 'Department of Information and Communication Technology - Shaping the future of digital innovation.';
    } else if (widget.authorName.contains('Education')) {
      return 'College of Education - Nurturing the next generation of educators and leaders.';
    } else if (widget.authorName.contains('CME')) {
      return 'Computer and Mechanical Engineering - Bridging theory and practice in modern engineering.';
    } else {
      return 'Official news and announcements from ${widget.authorName}.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedArticle != null) {
      return ArticleDetail(
        article: _selectedArticle!,
        onClose: () => setState(() => _selectedArticle = null),
      );
    }

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 0,
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                widget.authorName,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: true,
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.notifications_none,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),

            // Profile Section
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Large Profile Picture
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppConstants.brandColor,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          widget.authorImage,
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 120,
                              height: 120,
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Author Name
                    Text(
                      widget.authorName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // Author Bio
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _getAuthorBio(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Article Count
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppConstants.brandColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_articles.length} Articles',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.brandColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Articles List
            _isLoading
                ? const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                : _articles.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.article_outlined,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No articles found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Check back later for updates from ${widget.authorName}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final article = _articles[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 300),
                                  opacity: 1.0,
                                  child: NewsCard(
                                    article: article,
                                    onTap: () => _handleArticleTap(article),
                                  ),
                                ),
                              );
                            },
                            childCount: _articles.length,
                          ),
                        ),
                      ),
          ],
        ),
      ),
    );
  }
}
