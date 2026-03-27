import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../services/news_service.dart';
import '../../models/news.dart';

class NewsEditor extends StatefulWidget {
  const NewsEditor({super.key});

  @override
  State<NewsEditor> createState() => _NewsEditorState();
}

class _NewsEditorState extends State<NewsEditor> {
  final NewsService _newsService = NewsService();
  final _formKey = GlobalKey<FormState>();
  List<NewsArticle> _articles = [];
  List<NewsCategory> _categories = [];
  bool _isLoading = true;
  bool _isEditing = false;
  NewsArticle? _editingArticle;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _excerptController = TextEditingController();
  String _selectedCategoryId = '';
  bool _isBreaking = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    final articles = await _newsService.fetchArticles();
    final categories = await _newsService.fetchCategories();
    setState(() {
      _articles = articles;
      _categories = categories;
      _isLoading = false;
    });
  }

  void _startNewArticle() {
    setState(() {
      _isEditing = true;
      _editingArticle = null;
      _titleController.clear();
      _contentController.clear();
      _imageUrlController.clear();
      _excerptController.clear();
      _selectedCategoryId = _categories.isNotEmpty ? _categories.first.id : '';
      _isBreaking = false;
    });
  }

  void _editArticle(NewsArticle article) {
    setState(() {
      _isEditing = true;
      _editingArticle = article;
      _titleController.text = article.title;
      _contentController.text = article.content;
      _imageUrlController.text = article.imageUrl;
      _excerptController.text = article.excerpt ?? '';
      _selectedCategoryId = article.newsCategory.id;
      _isBreaking = article.isBreaking;
    });
  }

  Future<void> _saveArticle() async {
    if (!_formKey.currentState!.validate()) return;

    final article = NewsArticle(
      id: _editingArticle?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      excerpt: _excerptController.text.isNotEmpty ? _excerptController.text : null,
      content: _contentController.text,
      imageUrl: _imageUrlController.text,
      publishedAt: DateTime.now().toString(),
      isBreaking: _isBreaking,
      newsCategory: _categories.firstWhere((cat) => cat.id == _selectedCategoryId),
      newsAuthor: NewsAuthor(id: 'admin', name: 'Admin', bio: 'Administrator'),
    );

    bool success;
    if (_editingArticle != null) {
      success = await _newsService.updateNewsArticle(article.id, article);
    } else {
      success = await _newsService.addNewsArticle(article);
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article saved successfully')),
      );
      _loadData();
      _cancelEdit();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save article')),
      );
    }
  }

  Future<void> _deleteArticle(String id) async {
    final success = await _newsService.deleteNewsArticle(id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article deleted successfully')),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete article')),
      );
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _editingArticle = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppConstants.bgColor,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _isEditing
                ? _buildEditForm()
                : _buildArticlesList(),
      ),
      floatingActionButton: !_isEditing
          ? FloatingActionButton(
              onPressed: _startNewArticle,
              backgroundColor: AppConstants.brandColor,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildEditForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _excerptController,
              decoration: const InputDecoration(
                labelText: 'Excerpt (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
              maxLines: 10,
              validator: (value) => value!.isEmpty ? 'Content is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.isEmpty ? 'Image URL is required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Breaking News'),
              value: _isBreaking,
              onChanged: (value) {
                setState(() {
                  _isBreaking = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _saveArticle,
                  child: const Text('Save'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _cancelEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.dangerColor,
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticlesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _articles.length,
      itemBuilder: (context, index) {
        final article = _articles[index];
        return Card(
          color: AppConstants.cardColor,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(
              article.title,
              style: const TextStyle(color: AppConstants.textColor),
            ),
            subtitle: Text(
              article.excerpt ?? article.content.substring(0, 50) + '...',
              style: const TextStyle(color: AppConstants.mutedColor),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: AppConstants.brandColor),
                  onPressed: () => _editArticle(article),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppConstants.dangerColor),
                  onPressed: () => _deleteArticle(article.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
