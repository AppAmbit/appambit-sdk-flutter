import 'package:appambit_sdk_flutter/appambit_cms.dart';
import 'package:flutter/material.dart';
import 'package:appambit_sdk_flutter_example/models/cms_example_model.dart';

const String _collection = 'blog_extended';

class CmsView extends StatefulWidget {
  const CmsView({super.key});

  @override
  State<CmsView> createState() => _CmsViewState();
}

class _CmsViewState extends State<CmsView> {
  final TextEditingController _searchController = TextEditingController();

  List<ArticleItem> _items = [];
  bool _isLoading = false;
  bool _isEmpty = false;

  final List<String> _filters = [
    "All List",
    "Equals: is_published = true",
    "Not Equals: is_published ≠ true",
    "In List: category = [fashion]",
    "Contains: title contains 'iOS'",
    "Starts With: title starts with 'Hack'",
    "In List: category in [fashion, science]",
    "Not In List: category not in [fashion]",
    "Greater Than: views_count > 700",
    "Greater Or Equal: views_count >= 760",
    "Less Than: views_count < 760",
    "Less Or Equal: views_count <= 760",
    "Order By title ASC",
    "Order By title DESC",
    "Order By views_count ASC",
    "Order By views_count DESC",
    "Pagination: Page 1, 2 per page",
    "Pagination: Page 2, 2 per page",
    "Combined: Search 'Swift' + Page 1 (3/page)",
    "Combined: is_published=true + Order views_count ASC",
    "Combined: category [fashion] + Order title ASC",
    "Combined: views_count >= 700 + is_published=true + Page 1 (5/page)",
    "Combined: NOT IN category [fashion] + Order views_count DESC",
    "Combined: title starts 'Monetización' + category [tech]",
  ];
  late String _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = _filters.first;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchItems() {
    if (_searchController.text.isEmpty) return;
    final q = AppAmbitCms.content<ArticleItem>(
      _collection,
      fromJson: ArticleItem.fromJson,
    );
    q.search(_searchController.text);
    _loadData(q);
  }

  AppAmbitCmsQuery<ArticleItem> _buildQuery() {
    final q = AppAmbitCms.content<ArticleItem>(
      _collection,
      fromJson: ArticleItem.fromJson,
    );

    switch (_selectedFilter) {
      case "Equals: is_published = true":
        q.equals("is_published", "true");
        break;
      case "Not Equals: is_published ≠ true":
        q.notEquals("is_published", "true");
        break;
      case "In List: category = [fashion]":
        q.inList("category", ["fashion"]);
        break;
      case "Contains: title contains 'iOS'":
        q.contains("title", "iOS");
        break;
      case "Starts With: title starts with 'Hack'":
        q.startsWith("title", "Hack");
        break;
      case "In List: category in [fashion, science]":
        q.inList("category", ["fashion", "science"]);
        break;
      case "Not In List: category not in [fashion]":
        q.notInList("category", ["fashion"]);
        break;
      case "Greater Than: views_count > 700":
        q.greaterThan("views_count", 700);
        break;
      case "Greater Or Equal: views_count >= 760":
        q.greaterThanOrEqual("views_count", 760);
        break;
      case "Less Than: views_count < 760":
        q.lessThan("views_count", 760);
        break;
      case "Less Or Equal: views_count <= 760":
        q.lessThanOrEqual("views_count", 760);
        break;
      case "Order By title ASC":
        q.orderByAscending("title");
        break;
      case "Order By title DESC":
        q.orderByDescending("title");
        break;
      case "Order By views_count ASC":
        q.orderByAscending("views_count");
        break;
      case "Order By views_count DESC":
        q.orderByDescending("views_count");
        break;
      case "Pagination: Page 1, 2 per page":
        q.getPage(1).getPerPage(2);
        break;
      case "Pagination: Page 2, 2 per page":
        q.getPage(2).getPerPage(2);
        break;
      case "Combined: Search 'Swift' + Page 1 (3/page)":
        q.search("Swift").getPage(1).getPerPage(3);
        break;
      case "Combined: is_published=true + Order views_count ASC":
        q.equals("is_published", "true").orderByAscending("views_count");
        break;
      case "Combined: category [fashion] + Order title ASC":
        q.inList("category", ["fashion"]).orderByAscending("title");
        break;
      case "Combined: views_count >= 700 + is_published=true + Page 1 (5/page)":
        q
            .greaterThanOrEqual("views_count", 700)
            .equals("is_published", "true")
            .getPage(1)
            .getPerPage(5);
        break;
      case "Combined: NOT IN category [fashion] + Order views_count DESC":
        q.notInList("category", ["fashion"]).orderByDescending("views_count");
        break;
      case "Combined: title starts 'Monetización' + category [tech]":
        q.startsWith("title", "Monetización").inList("category", ["tech"]);
        break;
      default:
        break;
    }
    return q;
  }

  Future<void> _loadData(AppAmbitCmsQuery<ArticleItem> query) async {
    setState(() {
      _isLoading = true;
      _isEmpty = false;
    });

    try {
      final results = await query.getList();
      if (!mounted) return;
      setState(() {
        _items = results;
        _isEmpty = results.isEmpty;
      });
    } catch (e) {
      debugPrint("Error loading CMS data: $e");
      if (!mounted) return;
      setState(() {
        _items = [];
        _isEmpty = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Controls
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              spacing: 12,
              children: [
                // Filter dropdown and apply
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        // ignore: deprecated_member_use
                        value: _selectedFilter,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(),
                        ),
                        items: _filters.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedFilter = newValue;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _loadData(_buildQuery()),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      child: const Text('Apply'),
                    ),
                  ],
                ),

                // Search bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search term...',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onSubmitted: (_) => _searchItems(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _searchItems,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      child: const Text('Search'),
                    ),
                  ],
                ),

                // Get All
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      setState(() {
                        _selectedFilter = "All List";
                      });
                      final q = AppAmbitCms.content<ArticleItem>(
                        _collection,
                        fromJson: ArticleItem.fromJson,
                      );
                      await _loadData(q);
                    },
                    child: const Text('Get All List'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'No results found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      return _ArticleCard(item: _items[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final ArticleItem item;

  const _ArticleCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Box
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                color: Colors.grey[200],
                child: item.featuredImageUrl?.isNotEmpty == true
                    ? Image.network(
                        item.featuredImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    item.title ?? '—',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.category.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: item.category
                          .map(
                            (cat) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(30),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.blue.withAlpha(80),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                cat,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 6),

                  // Body
                  if (item.body?.isNotEmpty == true)
                    Text(
                      item.body!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),

                  // Meta Info (views, published, event date)
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Views: ${item.viewsCount ?? 0}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey,
                        ),
                      ),
                      Text(
                        item.isPublished == true ? 'Published' : 'Unpublished',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: item.isPublished == true
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                      if (item.eventDate?.isNotEmpty == true)
                        Text(
                          'Event: ${item.eventDate}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),

                  const Divider(height: 12, thickness: 1),

                  // ID
                  Text(
                    "ID: ${item.id ?? '-'}",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Dates Grid
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Cr: ${_formatDate(item.createdAt)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Pub: ${_formatDate(item.publishedAt)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Upd: ${_formatDate(item.updatedAt)}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '-';
    try {
      final date = DateTime.parse(isoString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return isoString;
    }
  }
}
