import 'package:flutter/material.dart';
import '../models/news.dart';
import '../services/news_service.dart';
import '../widgets/news_card.dart';
import '../widgets/breaking_news.dart';
import '../widgets/article_detail.dart';
import '../constants/app_constants.dart';
import 'new_home_screen.dart';
import 'author_news_screen.dart';

class NewsUpdates extends StatefulWidget {
  const NewsUpdates({super.key});

  @override
  State<NewsUpdates> createState() => _NewsUpdatesState();
}

class _NewsUpdatesState extends State<NewsUpdates> {
  final NewsService _newsService = NewsService();
  final TextEditingController _searchController = TextEditingController();

  List<NewsArticle> _articles = [];
  List<NewsArticle> _ctuDanaoArticles = [];
  List<NewsArticle> _ctuDanaoCrushArticles = [];
  List<NewsArticle> _engineeringArticles = [];
  List<NewsCategory> _categories = [];
  NewsArticle? _breakingNews;
  NewsArticle? _selectedArticle;
  String? _selectedCategory;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load categories and articles in parallel
      final results = await Future.wait([
        _newsService.fetchCategories(),
        _newsService.fetchArticles(
          categoryId: _selectedCategory,
          searchQuery: _searchQuery,
        ),
        _newsService.fetchCTUDanaoArticles(),
        _newsService.fetchCTUDanaoCrushArticles(),
        _newsService.fetchEngineeringArticles(),
      ]);

      final categories = results[0] as List<NewsCategory>;
      final articles = results[1] as List<NewsArticle>;
      final ctuDanaoArticles = results[2] as List<NewsArticle>;
      final ctuDanaoCrushArticles = results[3] as List<NewsArticle>;
      final engineeringArticles = results[4] as List<NewsArticle>;

      // Separate breaking news from regular articles
      final breaking = articles.where((article) => article.isBreaking).toList();
      final regular = articles.where((article) => !article.isBreaking).toList();

      setState(() {
        _categories = categories;
        _breakingNews = breaking.isNotEmpty ? breaking.first : null;
        _articles = regular;
        _ctuDanaoArticles = ctuDanaoArticles;
        _ctuDanaoCrushArticles = ctuDanaoCrushArticles;
        _engineeringArticles = engineeringArticles;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleArticleTap(NewsArticle article) async {
    // Increment view count
    await _newsService.incrementViewCount(article.id);

    setState(() {
      _selectedArticle = article;
    });
  }

  void _handleCategorySelect(String? categoryId) {
    setState(() {
      _selectedCategory = categoryId;
      _searchQuery = '';
      _searchController.clear();
    });
    _loadData();
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
      _selectedCategory = null;
    });
    _loadData();
  }

  void _showNotificationsSheet() {
    if (NewHomeScreen.showNotifications != null) {
      NewHomeScreen.showNotifications!();
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
      appBar: AppBar(
        title: const Text('News & Announcements'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          GestureDetector(
            onTap: _showNotificationsSheet,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
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
                    size: 24,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (NewHomeScreen.unreadCount.value > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      height: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppConstants.brandColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${NewHomeScreen.unreadCount.value}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search news...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _handleSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppConstants.brandColor,
                  ),
                ),
              ),
              onSubmitted: _handleSearch,
            ),
          ),

          // Category Filter
          if (_categories.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: _selectedCategory == null,
                        onSelected: (_) => _handleCategorySelect(null),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        selectedColor: AppConstants.brandColor.withOpacity(0.2),
                        checkmarkColor: AppConstants.brandColor,
                      ),
                    );
                  }

                  final category = _categories[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category.name),
                      selected: _selectedCategory == category.id,
                      onSelected: (_) => _handleCategorySelect(category.id),
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      selectedColor: _parseColor(category.color).withOpacity(0.2),
                      checkmarkColor: _parseColor(category.color),
                    ),
                  );
                },
              ),
            ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image Circle Section
                          if (_breakingNews != null && _searchQuery.isEmpty) ...[
                            const SizedBox(height: 16),
                            _buildImageCircle(),
                            const SizedBox(height: 16),
                          ],

                          // Breaking News Section
                          if (_breakingNews != null && _searchQuery.isEmpty) ...[
                            const Row(
                              children: [
                                Icon(
                                  Icons.emergency,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'CTU NEWS AND ANNOUNCEMENTS',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 250, 142, 1),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            BreakingNews(
                              article: _breakingNews!,
                              onTap: () => _handleArticleTap(_breakingNews!),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Show separated sections when no search/filter is applied
                          if (_searchQuery.isEmpty && _selectedCategory == null) ...[
                            // CTU Danao Section
                            if (_ctuDanaoArticles.isNotEmpty) ...[
                              Row(
                                children: [
                                  Container(
                                    width: 3,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: _parseColor('#FFA500'), // Orange color for CTU
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'CTU Danao',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _ctuDanaoArticles.length,
                                itemBuilder: (context, index) {
                                  final article = _ctuDanaoArticles[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: NewsCard(
                                      article: article,
                                      onTap: () => _handleArticleTap(article),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Engineering Section
                            if (_engineeringArticles.isNotEmpty) ...[
                              Row(
                                children: [
                                  Container(
                                    width: 3,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: _parseColor('#FF0000'), // Red color for Engineering
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Engineering',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _engineeringArticles.length,
                                itemBuilder: (context, index) {
                                  final article = _engineeringArticles[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: NewsCard(
                                      article: article,
                                      onTap: () => _handleArticleTap(article),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                            ],

                            // CTU Danao Crush Section
                            if (_ctuDanaoCrushArticles.isNotEmpty) ...[
                              Row(
                                children: [
                                  Container(
                                    width: 3,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: _parseColor('#FFC0CB'), // Pink color for CTU-D Crush
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'CTU Danao Crush',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _ctuDanaoCrushArticles.length,
                                itemBuilder: (context, index) {
                                  final article = _ctuDanaoCrushArticles[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: NewsCard(
                                      article: article,
                                      onTap: () => _handleArticleTap(article),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                            ],
                          ],

                          // Show filtered/general articles when search or category filter is applied
                          if (_searchQuery.isNotEmpty || _selectedCategory != null) ...[
                            // Articles Section
                            Row(
                              children: [
                                Container(
                                  width: 3,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppConstants.brandColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'Search Results for "$_searchQuery"'
                                      : _selectedCategory != null
                                          ? _categories
                                              .firstWhere(
                                                (c) => c.id == _selectedCategory,
                                              )
                                              .name
                                          : 'Latest News',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Articles List
                            if (_articles.isEmpty)
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                  ],
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _articles.length,
                                itemBuilder: (context, index) {
                                  final article = _articles[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: NewsCard(
                                      article: article,
                                      onTap: () => _handleArticleTap(article),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorString) {
    if (colorString.startsWith('#')) {
      return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
    }
    return Colors.blue;
  }

  Widget _buildImageCircle() {
    final List<String> imageAssets = [
      'lib/assets/images/ctudanao.png',
      'lib/assets/images/engineering.png',
      'lib/assets/images/ctudanaocrush.png',
      'lib/assets/images/technology.png',
      'lib/assets/images/educ.png',
      'lib/assets/images/cme.png',
    ];

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageAssets.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildProfileImage(imageAssets[index], 80),
          );
        },
      ),
    );
  }

  Widget _buildProfileImage(String imagePath, double size) {
    return GestureDetector(
      onTap: () => _navigateToAuthorNews(imagePath),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            imagePath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: size,
                height: size,
                color: Colors.grey[300],
                child: Icon(
                  Icons.person,
                  size: size * 0.5,
                  color: Colors.grey[600],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _navigateToAuthorNews(String imagePath) {
    // Extract author name from image path
    String authorName = _getAuthorNameFromImagePath(imagePath);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AuthorNewsScreen(
          authorName: authorName,
          authorImage: imagePath,
        ),
      ),
    );
  }

  String _getAuthorNameFromImagePath(String imagePath) {
    // Extract author name from image path
    if (imagePath.contains('ctudanao.png')) return 'CTU Danao';
    if (imagePath.contains('engineering.png')) return 'Engineering Department';
    if (imagePath.contains('ctudanaocrush.png')) return 'CTU Danao Crush';
    if (imagePath.contains('technology.png')) return 'Technology Department';
    if (imagePath.contains('educ.png')) return 'Education Department';
    if (imagePath.contains('cme.png')) return 'CME Department';
    return 'Unknown Author';
  }
}
