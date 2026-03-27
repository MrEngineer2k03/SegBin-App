import '../models/news.dart';

class NewsService {
  // Mock data for categories
  final List<NewsCategory> _mockCategories = [
    NewsCategory(id: '1', name: 'Engineering', color: '#FF0000'),
    NewsCategory(id: '2', name: 'Education', color: '#0000FF'),
    NewsCategory(id: '3', name: 'Technology', color: '#FFFF00'),
    NewsCategory(id: '4', name: 'CME', color: '#00FF00'),
    NewsCategory(id: '5', name: 'CTU', color: '#FFA500'),
    NewsCategory(id: '6', name: 'CTU-D Crush', color: '#FFC0CB'),
  ];

  final List<NewsArticle> _mockArticles = [
    NewsArticle(
      id: '1',
      title: 'City Engineering Office Inspects School Buildings After Earthquake',
      content: 'LOOK: Mayor Nito Durano personally joined the City Engineering Office in inspecting school buildings, starting with Cebu Technological University (CTU) – Danao Campus and RMDSF-STEC, to ensure that classrooms are safe for use following last night’s earthquake.',
      imageUrl: 'lib/assets/images/newspic2.jpg',
      publishedAt: DateTime.now().subtract(const Duration(days: 2)).toString(),
      isBreaking: false,
      newsCategory: NewsCategory(id: '5', name: 'CTU', color: '#FFA500'),
      newsAuthor: NewsAuthor(id: 'ctu_danao', name: 'CTU Danao', bio: 'Cebu Technological University - Danao Campus'),
    ),

    NewsArticle(
      id: '2',
      title: 'BREAKING: 𝗗𝗮𝗻𝗮𝗼 𝗖𝗶𝘁𝘆 𝗚𝗼𝘃𝗲𝗿𝗻𝗺𝗲𝗻𝘁 𝗢𝗿𝗱𝗲𝗿𝘀 𝗦𝘂𝘀𝗽𝗲𝗻𝘀𝗶𝗼𝗻 𝗼𝗳 𝗪𝗼𝗿𝗸 𝗔𝗰𝗿𝗼𝘀𝘀 𝗔𝗹𝗹 𝗚𝗼𝘃𝗲𝗿𝗻𝗺𝗲𝗻𝘁 𝗔𝗴𝗲𝗻𝗰𝗶𝗲𝘀 𝗮𝗻𝗱 𝗢𝗳𝗳𝗶𝗰𝗲𝘀',
      content: 'Due to the recent earthquake at 1:06 AM this morning, recorded at Intensity 4.0, and in compliance with the Danao City Government\'s mandate, work for regular faculty and employees is suspended today, October 13. The Asynchronous Class modality will continue to be implemented to ensure safety and uninterrupted academic progress.',
      imageUrl: 'lib/assets/images/newspic.jpg',
      publishedAt: DateTime.now().subtract(const Duration(hours: 6)).toString(),
      isBreaking: true,
      newsCategory: NewsCategory(id: '5', name: 'CTU', color: '#FFA500'),
      newsAuthor: NewsAuthor(id: 'ctu_danao', name: 'CTU Danao', bio: 'Cebu Technological University - Danao Campus'),
    ),

    NewsArticle(
      id: '3',
      title: 'LOOK: CTU Danao engineering student develops lifesaving earthquake relief map for Northern Cebu',
      content: 'A fourth-year Bachelor of Science in Computer Engineering (BSCpE) student from Cebu Technological University (CTU) Danao Campus has developed a crowdsourced mapping website to help responders and donors locate earthquake-stricken communities in Northern Cebu.\n\nCharles Zoilo A. Yana, 21, of Tayud, Liloan, Cebu, launched the Northern Cebu Earthquake Relief Map Guide on October 2, two days after the 6.9-magnitude earthquake struck the province.\n\nThe platform allows users to pin exact locations and share key details, enabling volunteers and relief groups to coordinate assistance more effectively.\n\nEarthquake Relief Map Guide stands as both a vital humanitarian tool and a proud testament to CTU\'s commitment to nurturing socially responsive and solution-driven technologists.\n\nYana said the project is entirely self-funded and not school-related, but was built purely out of his initiative to assist affected families.\n\nHe explained that the tool works similarly to Google Maps, though not fully precise, as it relies on free online tools and available application programming interfaces (APIs).\n\n"We have two options to pin locations: one is to search the place there could be, suggest and recommend dropdowns or just simply enter and it will try to locate the location," Yana explained.\n\n"Second is manually, by clicking that green icon on the lower right corner, users can just zoom and navigate or find the nearest barangay," he added.\n\nThe developer noted a limitation: since affected residents in the North are mostly offline and lack devices, the platform depends entirely on crowdsourcing from people with relatives or information about those in need.\n\nHe shared that he pushed forward with support from his partner, who tested the platform and helped promote it. Together, they contacted local government units, like Danao, and Facebook influencers to help amplify the tool\'s reach.\n\nLaunching a project for the first time can be challenging, and Yana admits, "My confidence in my project is not that high so I\'m also hoping for developers out there to help me."\n\nAs of this writing, the relief map has recorded more than 500 pinned locations, highlighting its growing role in relief coordination.\n\nThrough this initiative, CTU underscores its pride in Yana\'s innovation and reaffirms its commitment to developing socially responsible and community-driven technologists.',
      imageUrl: 'lib/assets/images/newspic3.jpg',
      publishedAt: DateTime.now().subtract(const Duration(days: 1)).toString(),
      isBreaking: false,
      newsCategory: NewsCategory(id: '1', name: 'Engineering', color: '#FF0000'),
      newsAuthor: NewsAuthor(id: 'engineering', name: 'Engineering Department', bio: 'College of Engineering - Cebu Technological University Danao Campus'),
    ),

    NewsArticle(
      id: '4',
      title: '𝗘𝗦 𝗗𝗘𝗣𝗔𝗥𝗧𝗠𝗘𝗡𝗧𝗔𝗟 𝗣𝗢𝗟𝗢 𝗜𝗦 𝗢𝗨𝗧‼️',
      content: 'The official ES Departmental Polo is finally here, made for comfort and style that stands out. Don\'t miss the chance to showcase your department\'s pride wherever you go.\n\n'
          '𝗗𝗘𝗔𝗗𝗟𝗜𝗡𝗘 𝗙𝗢𝗥 𝗕𝗔𝗧𝗖𝗛 𝟭:\n𝗢𝗖𝗧𝗢𝗕𝗘𝗥 26, 𝟮𝟬𝟮𝟱\n\n'
          '𝗣𝗿𝗶𝗰𝗲\n𝗘𝗦 𝗠𝗲𝗺𝗯𝗲𝗿𝘀: ₱ 450\n𝗡𝗼𝗻 𝗘𝗦 𝗠𝗲𝗺𝗯𝗲𝗿𝘀: ₱480\n\n'
          '𝗚𝘂𝗶𝗱𝗲𝘀 𝗼𝗻 𝗵𝗼𝘄 𝘁𝗼 𝗼𝗿𝗱𝗲𝗿:\n1. Approach and give your order to your class mayors.\n2. Class mayors will give the final list of orders to the Engineering Society Treasurer.\n3. The ES Treasurer will give the orders to the Finance Manager.\n4. And Finance Manager will give it to the supplier.\n\n'
          '𝗧𝗼 𝗰𝗹𝗮𝗶𝗺 𝘆𝗼𝘂𝗿 𝗼𝗿𝗱𝗲𝗿:\n1. The Finance Manager will get it to the supplier, or the supplier will deliver the said orders.\n2. The Finance Manager will give the orders to the ES Treasurer.\n3. The ES Treasurer will give the orders to the class mayors after the inventory of the list of purchases.\n4. The class mayors will then give it to their respective classmates.\n\n'
          '𝐂𝐚𝐩𝐭𝐢𝐨𝐧 𝐛𝐲 𝐓𝐫𝐢𝐬𝐡𝐚 𝐂𝐥𝐚𝐫𝐢𝐬𝐬𝐞 𝐎𝐫𝐥𝐚𝐢𝐧 | 𝐒𝐨𝐜𝐦𝐞𝐝 𝐎𝐩𝐞𝐫𝐚𝐭𝐨𝐫\n𝐋𝐚𝐲𝐨𝐮𝐭 𝐛𝐲 𝐉𝐮𝐥𝐢𝐮𝐬 𝐊𝐨𝐧 | 𝐆𝐫𝐚𝐩𝐡𝐢𝐜 𝐃𝐞𝐬𝐢𝐠𝐧𝐞𝐫\n𝐏𝐮𝐛𝐦𝐚𝐭 𝐛𝐲 𝐑𝐨𝐬𝐞 𝐆𝐰𝐲𝐧𝐞𝐭𝐡 𝐂𝐚𝐦𝐚𝐧𝐜𝐞 | 𝐆𝐫𝐚𝐩𝐡𝐢𝐜 𝐃𝐞𝐬𝐢𝐠𝐧𝐞𝐫',
      imageUrl: 'lib/assets/images/newspic4.jpg',
      publishedAt: DateTime.now().subtract(const Duration(days: 3)).toString(),
      isBreaking: false,
      newsCategory: NewsCategory(id: '1', name: 'Engineering', color: '#FF0000'),
      newsAuthor: NewsAuthor(id: 'engineering', name: 'Engineering Department', bio: 'College of Engineering - Cebu Technological University Danao Campus'),
    ),

    NewsArticle(
      id: '5',
      title: 'GWAPO SPOTTED!!',
      content: 'Pa shoutout sa akong crush nga si Khyle Capuyan 😍👨‍🏫\n\nDili lang siya gwapo, maayo pud kaayo siya magtudlo ug mag-guide sa atong mga estudyante sa Computer Engineering. Crush kaayu tika ay 🙌📚\n\nSana mapansin mo naman ako hehe',
      imageUrl: 'lib/assets/images/khylegwapo.jpg',
      publishedAt: DateTime.now().subtract(const Duration(days: 3)).toString(),
      isBreaking: false,
      newsCategory: NewsCategory(id: '6', name: 'CTU-D Crush', color: '#FFC0CB'),
      newsAuthor: NewsAuthor(id: 'CTU Danao Crush', name: 'Admin Gwapo', bio: 'CTU Danao Crush'),
    ),
  ];

  // Fetch all categories
  Future<List<NewsCategory>> fetchCategories() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockCategories;
  }

  // Fetch articles with optional filtering
  Future<List<NewsArticle>> fetchArticles({
    String? categoryId,
    String? searchQuery,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    var articles = List<NewsArticle>.from(_mockArticles);

    // Apply filters in Dart
    if (categoryId != null && categoryId.isNotEmpty) {
      articles = articles
          .where((article) => article.newsCategory.id == categoryId)
          .toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      articles = articles
          .where(
            (article) =>
                (article.title?.toLowerCase().contains(query) ?? false),
          )
          .toList();
    }

    return articles;
  }

  // Fetch CTU Danao articles separately
  Future<List<NewsArticle>> fetchCTUDanaoArticles() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockArticles
        .where((article) => article.newsCategory.id == '5') // CTU category
        .toList();
  }

  // Fetch CTU Danao Crush articles separately
  Future<List<NewsArticle>> fetchCTUDanaoCrushArticles() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockArticles
        .where((article) => article.newsCategory.id == '6') // CTU-D Crush category
        .toList();
  }

  // Fetch Engineering articles separately
  Future<List<NewsArticle>> fetchEngineeringArticles() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockArticles
        .where((article) => article.newsCategory.id == '1') // Engineering category
        .toList();
  }

  // Fetch breaking news articles
  Future<List<NewsArticle>> fetchBreakingNews() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    return _mockArticles
        .where((article) => article.isBreaking == true)
        .toList();
  }

  // Increment view count for an article
  Future<void> incrementViewCount(String articleId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    // In a real app, you would update this in local storage or send to an API
    print('View count incremented for article $articleId');
  }

  // Get a single article by ID
  Future<NewsArticle?> getArticleById(String articleId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));

    try {
      return _mockArticles.firstWhere((article) => article.id == articleId);
    } catch (e) {
      return null;
    }
  }

  // Search articles
  Future<List<NewsArticle>> searchArticles(String query) async {
    return fetchArticles(searchQuery: query);
  }

  // Admin methods for adding/editing news
  Future<bool> addNewsArticle(NewsArticle article) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    // In a real app, save to database
    _mockArticles.add(article);
    return true;
  }

  Future<bool> updateNewsArticle(String id, NewsArticle updatedArticle) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    // In a real app, update in database
    final index = _mockArticles.indexWhere((article) => article.id == id);
    if (index != -1) {
      _mockArticles[index] = updatedArticle;
      return true;
    }
    return false;
  }

  Future<bool> deleteNewsArticle(String id) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    // In a real app, delete from database
    _mockArticles.removeWhere((article) => article.id == id);
    return true;
  }
}
