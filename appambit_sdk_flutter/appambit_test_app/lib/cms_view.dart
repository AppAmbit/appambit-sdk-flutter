import 'package:appambit_sdk_flutter/appambit_cms.dart';
import 'package:flutter/material.dart';
import 'package:appambit_sdk_flutter_example/models/tech_item.dart';

const String _collection = 'tech_inventory';

class CmsView extends StatefulWidget {
  const CmsView({super.key});

  @override
  State<CmsView> createState() => _CmsViewState();
}

class _CmsViewState extends State<CmsView> {
  final TextEditingController _searchController = TextEditingController();

  List<TechItem> _items = [];
  bool _isLoading = false;
  bool _isEmpty = false;

  final List<String> _filters = [
    "All List",
    "Equals: item_sku = TEC-02",
    "Not Equals: item_sku ≠ TEC-02",
    "In List: category = Cat 1",
    "Boolean: in_stock = true",
    "Contains: product_name contains 'Pro'",
    "Starts With: item_sku starts with 'TEC'",
    "In List: item_sku in [TEC-01, TEC-02]",
    "Not In List: item_sku not in [TEC-01, TEC-02]",
    "Greater Than: price > 500",
    "Greater Or Equal: price >= 500",
    "Less Than: price < 500",
    "Less Or Equal: price <= 500",
    "Order By product_name ASC",
    "Order By product_name DESC",
    "Order By price ASC",
    "Order By price DESC",
    "Pagination: Page 1, 2 per page",
    "Pagination: Page 2, 2 per page",
    "Combined: Search 'Pro' + Page 1 (3/page)",
    "Combined: In Stock + Order price ASC",
    "Combined: category Cat 1 + Order name ASC",
    "Combined: price >= 1000 + In Stock + Page 1 (5/page)",
    "Combined: NOT IN [Cat 1,Cat 2] + Order price DESC",
    "Combined: SKU starts TEC + category Cat 3",
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
    final q = AppAmbitCms.content<TechItem>(
      _collection,
      fromJson: TechItem.fromJson,
    );
    q.search(_searchController.text);
    _loadData(q);
  }

  AppAmbitCmsQuery<TechItem> _buildQuery() {
    final q = AppAmbitCms.content<TechItem>(
      _collection,
      fromJson: TechItem.fromJson,
    );

    switch (_selectedFilter) {
      case "Equals: item_sku = TEC-02":
        q.equals("item_sku", "TEC-02");
        break;
      case "Not Equals: item_sku ≠ TEC-02":
        q.notEquals("item_sku", "TEC-02");
        break;
      case "In List: category = Cat 1":
        q.inList("category", ["Cat 1"]);
        break;
      case "Boolean: in_stock = true":
        q.equals("in_stock", "true");
        break;
      case "Contains: product_name contains 'Pro'":
        q.contains("product_name", "Pro");
        break;
      case "Starts With: item_sku starts with 'TEC'":
        q.startsWith("item_sku", "TEC");
        break;
      case "In List: item_sku in [TEC-01, TEC-02]":
        q.inList("item_sku", ["TEC-01", "TEC-02"]);
        break;
      case "Not In List: item_sku not in [TEC-01, TEC-02]":
        q.notInList("item_sku", ["TEC-01", "TEC-02"]);
        break;
      case "Greater Than: price > 500":
        q.greaterThan("price", 500);
        break;
      case "Greater Or Equal: price >= 500":
        q.greaterThanOrEqual("price", 500);
        break;
      case "Less Than: price < 500":
        q.lessThan("price", 500);
        break;
      case "Less Or Equal: price <= 500":
        q.lessThanOrEqual("price", 500);
        break;
      case "Order By product_name ASC":
        q.orderByAscending("product_name");
        break;
      case "Order By product_name DESC":
        q.orderByDescending("product_name");
        break;
      case "Order By price ASC":
        q.orderByAscending("price");
        break;
      case "Order By price DESC":
        q.orderByDescending("price");
        break;
      case "Pagination: Page 1, 2 per page":
        q.getPage(1).getPerPage(2);
        break;
      case "Pagination: Page 2, 2 per page":
        q.getPage(2).getPerPage(2);
        break;
      case "Combined: Search 'Pro' + Page 1 (3/page)":
        q.search("Pro").getPage(1).getPerPage(3);
        break;
      case "Combined: In Stock + Order price ASC":
        q.equals("in_stock", "true").orderByAscending("price");
        break;
      case "Combined: category Cat 1 + Order name ASC":
        q.inList("category", ["Cat 1"]).orderByAscending("product_name");
        break;
      case "Combined: price >= 1000 + In Stock + Page 1 (5/page)":
        q
            .greaterThanOrEqual("price", 1000)
            .equals("in_stock", "true")
            .getPage(1)
            .getPerPage(5);
        break;
      case "Combined: NOT IN [Cat 1,Cat 2] + Order price DESC":
        q.notInList("category", ["Cat 1", "Cat 2"]).orderByDescending("price");
        break;
      case "Combined: SKU starts TEC + category Cat 3":
        q.startsWith("item_sku", "TEC").inList("category", ["Cat 3"]);
        break;
      default:
        break;
    }
    return q;
  }

  Future<void> _loadData(AppAmbitCmsQuery<TechItem> query) async {
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
      debugPrint("Error loading CMS data: \$e");
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
                    onPressed: () {
                      setState(() {
                        _selectedFilter = "All List";
                      });
                      try {
                        final q = AppAmbitCms.content<TechItem>(
                          _collection,
                          fromJson: TechItem.fromJson,
                        );
                        _loadData(q);
                        final q1 = AppAmbitCms.content<TechItem>(
                          _collection,
                          fromJson: TechItem.fromJson,
                        );

                        _loadData(q1);
                      } catch (e) {
                        debugPrint("Error 1 call");
                      }

                      try {
                        final q2 = AppAmbitCms.content<TechItem>(
                          'sistema_de_gestion_de_propiedades_de_una_marinaclub_nautico',
                          fromJson: TechItem.fromJson,
                        );
                        _loadData(q2);
                      } catch (e) {
                        debugPrint("Error segunda calla");
                      }
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
                      return _ProductCard(item: _items[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final TechItem item;

  const _ProductCard({required this.item});

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
                child: item.productImageUrl?.isNotEmpty == true
                    ? Image.network(
                        item.productImageUrl!,
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
                    item.productName ?? '—',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
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

                  // Description
                  if (item.description?.isNotEmpty == true)
                    Text(
                      item.description!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),

                  // Meta Info (SKU, Price, Stock)
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        item.itemSku ?? '—',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '\$${item.price?.toStringAsFixed(2) ?? "0.00"}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        "Stock: ${item.inStock == true ? 'True' : 'False'}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Email
                  if (item.supportEmail?.isNotEmpty == true)
                    Text(
                      '📧 ${item.supportEmail}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
