// =============================================================================
// PRODUCTS SCREEN
// =============================================================================
//
// Purpose: Comprehensive product management for vendor inventory
// Features:
// - Product catalog display with search and filtering
// - Add/edit/delete product functionality
// - Image upload and management
// - Category-based organization
// - Real-time inventory updates
// - Bulk operations support
//
// Sections:
// 1. Image Helper Functions - Image processing and URL management
// 2. Product Management State - Controllers and data management
// 3. UI Components - Search, filters, and product cards
// 4. Product Forms - Add/Edit product dialogs
// 5. Image Handling - Camera/gallery integration
// =============================================================================

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../config/api_endpoints.dart';
import '../config/vendor_config.dart';
import '../state/vendor_provider.dart';
import '../utils/app_theme.dart';
import '../utils/product_image_helper.dart';
import '../services/image_upload_service.dart';
import '../utils/secure_logger.dart';

// =============================================================================
// IMAGE HELPER FUNCTIONS
// =============================================================================

bool _isLocalFilePath(String path) => ProductImageHelper.isLocalFilePath(path);

String _normalizeImagePath(String rawPath) =>
    ProductImageHelper.normalizeImagePath(rawPath);

String _resolveImageUrl(String rawPath, {String? cacheBustKey}) =>
    ProductImageHelper.safeRenderUrl(
      rawPath,
      apiBaseUrl: VendorConfig.apiBaseUrl,
      cacheBustKey: cacheBustKey,
    ) ??
    '';

// =============================================================================
// PRODUCT MANAGEMENT STATE
// =============================================================================

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  late final VoidCallback _searchListener;
  Timer? _searchDebounce;
  static const Map<String, List<String>> _categoryAliases = {
    'Snacks': ['snacks', 'snack'],
    'Beverages': ['beverages', 'beverage', 'drinks', 'drink'],
    'South Indian': ['south indian', 'south_indian', 'south-indian'],
    'North Indian': ['north indian', 'north_indian', 'north-indian'],
    'Chinese': ['chinese'],
    'Desserts': ['desserts', 'dessert', 'sweet', 'sweets'],
  };

  String _normalizeCategory(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _matchesCategory(
    String productCategory,
    String selectedDisplayCategory,
  ) {
    final normalizedProductCategory = _normalizeCategory(productCategory);
    final aliases =
        _categoryAliases[selectedDisplayCategory]?.map(_normalizeCategory) ??
        const <String>[];
    return aliases.contains(normalizedProductCategory);
  }

  String _normalizeSearch(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  @override
  void initState() {
    super.initState();
    _searchListener = () {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 180), () {
        if (mounted) {
          setState(() {});
        }
      });
    };
    _searchController.addListener(_searchListener);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_searchListener);
    _searchController.dispose();
    super.dispose();
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddProductDialog(),
    );
  }

  void _showEditProductDialog(dynamic product) {
    showDialog(
      context: context,
      builder: (context) => AddProductDialog(product: product),
    );
  }

  void _showDeleteConfirmDialog(dynamic product) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${product.name ?? 'this product'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final vendorProvider = Provider.of<VendorProvider>(
                context,
                listen: false,
              );
              final success = await vendorProvider.deleteProduct(product.id);

              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        vendorProvider.error ?? 'Failed to delete product',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VendorProvider>(
      builder: (context, vendorProvider, child) {
        final searchQuery = _normalizeSearch(_searchController.text);
        final shouldBypassFilters =
            searchQuery.isEmpty && _selectedCategory == 'All';

        final filteredProducts = shouldBypassFilters
            ? vendorProvider.products
            : vendorProvider.products.where((product) {
                final name = product.name.toString().toLowerCase();
                final description = product.description
                    .toString()
                    .toLowerCase();
                final category = product.category.toString();
                final normalizedCategory = _normalizeCategory(category);
                final searchableText = _normalizeSearch(
                  '$name $description $normalizedCategory',
                );

                final matchesSearch =
                    searchQuery.isEmpty || searchableText.contains(searchQuery);

                final matchesCategory =
                    _selectedCategory == 'All' ||
                    _matchesCategory(category, _selectedCategory);

                return matchesSearch && matchesCategory;
              }).toList();

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.surface,
            elevation: 0,
            foregroundColor: AppTheme.textPrimary,
            toolbarHeight: 10,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddProductDialog,
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
          body: Column(
            children: [
              // Search and Filter
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.trim().isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Category Filter
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children:
                            [
                              'All',
                              'Snacks',
                              'Beverages',
                              'South Indian',
                              'North Indian',
                              'Chinese',
                              'Desserts',
                            ].map((category) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(category),
                                  selected: _selectedCategory == category,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = selected
                                          ? category
                                          : 'All';
                                    });
                                  },
                                  backgroundColor: Colors.white,
                                  selectedColor: AppTheme.primary,
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              // Products List
              Expanded(
                child: vendorProvider.isLoadingProducts
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      )
                    : filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              vendorProvider.products.isNotEmpty
                                  ? 'No matching products'
                                  : 'No products found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              vendorProvider.products.isNotEmpty
                                  ? 'Try clearing search or selecting All category'
                                  : 'Tap the + button to add your first product',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          return ProductCard(
                            product: filteredProducts[index],
                            onEdit: () =>
                                _showEditProductDialog(filteredProducts[index]),
                            onDelete: () => _showDeleteConfirmDialog(
                              filteredProducts[index],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  final dynamic product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  String? _extractImageValue(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      final normalized = _normalizeImagePath(value);
      return normalized.isEmpty ? null : normalized;
    }

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      return _extractImageValue(
        map['url'] ??
            map['secure_url'] ??
            map['location'] ??
            map['imageUrl'] ??
            map['assetUrl'] ??
            map['image'] ??
            map['thumbnail'] ??
            map['path'] ??
            map['src'],
      );
    }

    return null;
  }

  String? _primaryImagePath() {
    dynamic images;
    try {
      images = product.images;
    } catch (_) {
      images = product is Map ? product['images'] : null;
    }

    if (images is List && images.isNotEmpty) {
      for (final image in images) {
        final resolved = _extractImageValue(image);
        if (resolved != null) return resolved;
      }
    }

    if (product is Map) {
      return _extractImageValue(
        product['image'] ?? product['imageUrl'] ?? product['thumbnail'],
      );
    }

    return null;
  }

  Widget _buildProductImage(String imagePath, {String? cacheBustKey}) {
    final trimmedPath = _normalizeImagePath(imagePath);

    if (_isLocalFilePath(trimmedPath)) {
      return Image.file(
        File(trimmedPath.replaceFirst('file://', '')),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.image_not_supported, color: Colors.grey[400]);
        },
      );
    }

    final resolvedUrl = _resolveImageUrl(
      trimmedPath,
      cacheBustKey: cacheBustKey,
    );
    if (resolvedUrl.isEmpty) {
      return Icon(Icons.image_not_supported, color: Colors.grey[400]);
    }

    return Image.network(
      resolvedUrl,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
      cacheWidth: 240,
      cacheHeight: 240,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.image_not_supported, color: Colors.grey[400]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryImagePath = _primaryImagePath();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000), // Black with 5% opacity
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Product Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: primaryImagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildProductImage(
                          primaryImagePath,
                          cacheBustKey:
                              product.updatedAt?.millisecondsSinceEpoch
                                  .toString() ??
                              product.createdAt.millisecondsSinceEpoch
                                  .toString(),
                        ),
                      )
                    : Icon(Icons.image_not_supported, color: Colors.grey[400]),
              ),
              const SizedBox(width: 12),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name ?? 'Unknown Product',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category ?? 'Uncategorized',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '₹${product.price?.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (product.discountPercentage != null &&
                            product.discountPercentage! > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              '₹${product.discountedPrice?.toStringAsFixed(2) ?? '0.00'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[600],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: product.isAvailable == true
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  product.isAvailable == true ? 'Available' : 'Unavailable',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: product.isAvailable == true
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stock and Actions
          Row(
            children: [
              Icon(Icons.inventory, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Stock: ${product.stockQuantity ?? 0}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const Spacer(),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                color: AppTheme.primary,
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                color: AppTheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AddProductDialog extends StatefulWidget {
  final dynamic product; // null for add, non-null for edit

  const AddProductDialog({super.key, this.product});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _discountController = TextEditingController();

  String _selectedCategory = 'Snacks';
  bool _isAvailable = true;
  bool _isFeatured = false;
  final List<File> _productImageFiles = [];
  List<String> _uploadedImageUrls = [];
  final ImagePicker _imagePicker = ImagePicker();
  late String _imageCacheBustKey;

  final List<String> _categories = [
    'Snacks',
    'Beverages',
    'South Indian',
    'North Indian',
    'Chinese',
    'Desserts',
  ];

  static const Map<String, String> _categoryToApiValue = {
    'Snacks': 'snacks',
    'Beverages': 'beverages',
    'South Indian': 'south indian',
    'North Indian': 'north indian',
    'Chinese': 'chinese',
    'Desserts': 'desserts',
  };

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    _imageCacheBustKey = DateTime.now().millisecondsSinceEpoch.toString();
    if (_isEdit) {
      _populateFields();
    }
  }

  void _populateFields() {
    final product = widget.product;
    _nameController.text = product.name ?? '';
    _descriptionController.text = product.description ?? '';
    _priceController.text = product.price?.toString() ?? '';
    _stockController.text = product.stockQuantity?.toString() ?? '';
    _discountController.text = product.discountPercentage?.toString() ?? '';
    _selectedCategory = _toDisplayCategory(
      product.category?.toString() ?? 'snacks',
    );
    _isAvailable = product.isAvailable ?? true;
    _isFeatured = product.isFeatured ?? false;

    // Handle existing images - convert URLs to display
    final existingImages = product.images ?? [];
    _uploadedImageUrls = List<String>.from(existingImages);
  }

  String _toApiCategory(String displayCategory) {
    return _categoryToApiValue[displayCategory] ??
        displayCategory.toLowerCase();
  }

  String _toDisplayCategory(String apiCategory) {
    final normalized = apiCategory.trim().toLowerCase();
    for (final entry in _categoryToApiValue.entries) {
      if (entry.value == normalized) {
        return entry.key;
      }
    }
    return 'Snacks';
  }

  Widget _buildPreviewImage(dynamic imageSource) {
    if (imageSource is File) {
      // Handle local file
      return Image.file(
        imageSource,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Icon(Icons.image, color: Colors.grey[400]),
          );
        },
      );
    } else if (imageSource is String) {
      // Handle URL string
      final trimmedPath = _normalizeImagePath(imageSource);

      if (_isLocalFilePath(trimmedPath)) {
        return Image.file(
          File(trimmedPath.replaceFirst('file://', '')),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: Icon(Icons.image, color: Colors.grey[400]),
            );
          },
        );
      }

      final resolvedUrl = _resolveImageUrl(
        trimmedPath,
        cacheBustKey: _imageCacheBustKey,
      );
      if (resolvedUrl.isEmpty) {
        return Container(
          color: Colors.grey[200],
          child: Icon(Icons.image, color: Colors.grey[400]),
        );
      }

      return Image.network(
        resolvedUrl,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
        cacheWidth: 320,
        cacheHeight: 320,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Icon(Icons.image, color: Colors.grey[400]),
          );
        },
      );
    }

    // Fallback for unsupported types
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.image, color: Colors.grey[400]),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image != null && mounted) {
        final imageFile = File(image.path);

        // Validate and optimize the image
        if (!ImageUploadService.isValidImageFile(imageFile)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Please select a valid image file (JPG, PNG, or WebP)',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _productImageFiles.add(imageFile);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Product Image',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ImagePickerOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _ImagePickerOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      if (index < _productImageFiles.length) {
        _productImageFiles.removeAt(index);
      } else {
        // Remove from uploaded URLs if index is in that range
        final urlIndex = index - _productImageFiles.length;
        if (urlIndex >= 0 && urlIndex < _uploadedImageUrls.length) {
          _uploadedImageUrls.removeAt(urlIndex);
        }
      }
    });
  }

  List<String> _normalizeImageUrls(Iterable<dynamic> urls) {
    final merged = <String>[];
    for (final item in urls) {
      final value = item?.toString().trim() ?? '';
      if (value.isEmpty) continue;
      if (!merged.contains(value)) {
        merged.add(value);
      }
    }
    return merged;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text('Uploading images and saving product...')),
          ],
        ),
      ),
    );

    try {
      // Validate that at least one image is provided
      if (_productImageFiles.isEmpty && _uploadedImageUrls.isEmpty) {
        navigator.pop(); // Close loading dialog
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('At least one image is required'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final stockQuantity = int.tryParse(_stockController.text.trim()) ?? 0;
      final normalizedCategory = _toApiCategory(_selectedCategory);
      bool success;
      if (_isEdit) {
        // Edit flow keeps URL-based image handling.
        final existingImageUrls = _normalizeImageUrls(_uploadedImageUrls);
        final newlyUploadedImageUrls = <String>[];
        SecureLogger.info(
          'Starting image upload. Product images: ${_productImageFiles.length}, Uploaded URLs: ${_uploadedImageUrls.length}',
        );
        SecureLogger.info('Base URL: ${ApiEndpoints.baseUrl}');
        SecureLogger.info('Endpoint: ${ApiEndpoints.uploadProductImages}');
        SecureLogger.info(
          'Existing images before upload merge: $existingImageUrls',
          tag: 'PRODUCTS',
        );

        if (_productImageFiles.isNotEmpty) {
          final authToken = vendorProvider.authToken;
          if (authToken == null) {
            throw Exception('Not authenticated');
          }

          final uploadResults = await ImageUploadService.uploadImages(
            _productImageFiles,
            authToken: authToken,
            baseUrl: ApiEndpoints.baseUrl,
            endpoint: ApiEndpoints.uploadProductImages,
          );

          SecureLogger.info(
            'Upload results: ${uploadResults.length} items processed',
          );

          for (final result in uploadResults) {
            if (result.success && result.imageUrl != null) {
              final newImageUrl = result.imageUrl!.trim();
              if (newImageUrl.isNotEmpty &&
                  !newlyUploadedImageUrls.contains(newImageUrl)) {
                newlyUploadedImageUrls.add(newImageUrl);
              }
              SecureLogger.info(
                'Successfully uploaded image: ${result.imageUrl}',
              );
            } else {
              SecureLogger.warning('Failed to upload image: ${result.error}');
            }
          }

          final failedUploads = uploadResults.where((r) => !r.success).toList();
          if (failedUploads.isNotEmpty) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(
                  '${failedUploads.length} images failed to upload',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }

          if (newlyUploadedImageUrls.isEmpty && _uploadedImageUrls.isEmpty) {
            navigator.pop(); // Close loading dialog
            final firstError = failedUploads.isNotEmpty
                ? (failedUploads.first.error ?? 'Upload failed')
                : 'Upload failed';
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Image upload failed: $firstError'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }

        final finalImageUrls = _normalizeImageUrls([
          ...newlyUploadedImageUrls,
          ...existingImageUrls,
        ]);
        if (finalImageUrls.isEmpty) {
          navigator.pop(); // Close loading dialog
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text(
                'At least one uploaded image URL is required to save product',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        SecureLogger.info(
          'Final images array for PUT /api/vendor/products/${widget.product.id}: $finalImageUrls',
          tag: 'PRODUCTS',
        );
        SecureLogger.info(
          'Final images count for update: ${finalImageUrls.length}',
          tag: 'PRODUCTS',
        );

        final productData = {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'price': double.parse(_priceController.text),
          'category': normalizedCategory,
          'images': finalImageUrls,
          'availability': _isAvailable ? 'in_stock' : 'out_of_stock',
          'stock': stockQuantity,
          'isFeatured': _isFeatured,
        };

        success = await vendorProvider.updateProduct(
          widget.product.id,
          productData,
        );
      } else {
        // Create flow now posts multipart directly to /products with `images` files.
        final productData = {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'price': double.parse(_priceController.text),
          'category': normalizedCategory,
          'availability': _isAvailable ? 'in_stock' : 'out_of_stock',
          'stock': stockQuantity,
          'isFeatured': _isFeatured,
        };

        success = await vendorProvider.createProduct(
          productData,
          imageFiles: _productImageFiles,
        );
      }

      // Close loading dialog
      navigator.pop();

      if (success) {
        setState(() {
          _imageCacheBustKey = DateTime.now().millisecondsSinceEpoch.toString();
        });
        navigator.pop();
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                _isEdit
                    ? 'Product updated successfully!'
                    : 'Product added successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                vendorProvider.error ??
                    'Failed to ${_isEdit ? 'update' : 'add'} product',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (navigator.canPop()) {
        navigator.pop();
      }

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isEdit ? Icons.edit : Icons.add_circle,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEdit ? 'Edit Product' : 'Add New Product',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3436),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isEdit
                              ? 'Update product information'
                              : 'Fill in the details to add a new product',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                    splashRadius: 24,
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Section
                      _buildImageSection(),
                      const SizedBox(height: 32),

                      // Product Name
                      _buildFormField(
                        'Product Name',
                        _nameController,
                        Icons.restaurant_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Product name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Description
                      _buildFormField(
                        'Description',
                        _descriptionController,
                        Icons.description_outlined,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Description is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Category
                      _buildCategoryField(),
                      const SizedBox(height: 20),

                      // Price and Stock Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormField(
                              'Price (₹)',
                              _priceController,
                              Icons.attach_money_outlined,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (double.tryParse(value) == null ||
                                    double.parse(value) <= 0) {
                                  return 'Invalid price';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFormField(
                              'Stock',
                              _stockController,
                              Icons.inventory_outlined,
                              keyboardType: TextInputType.number,
                              hintText: 'Optional',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return null;
                                }
                                if (int.tryParse(value.trim()) == null ||
                                    int.parse(value.trim()) < 0) {
                                  return 'Invalid stock';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Discount
                      _buildFormField(
                        'Discount %',
                        _discountController,
                        Icons.percent_outlined,
                        keyboardType: TextInputType.number,
                        hintText: 'Optional',
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (double.tryParse(value) == null ||
                                double.parse(value) < 0 ||
                                double.parse(value) > 100) {
                              return '0-100';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Toggle Switches
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            // Available Toggle
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _isAvailable
                                          ? AppTheme.primary.withValues(
                                              alpha: 0.1,
                                            )
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.check_circle,
                                      color: _isAvailable
                                          ? AppTheme.primary
                                          : Colors.grey[400],
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Available',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: _isAvailable
                                                ? AppTheme.primary
                                                : Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Product is available for order',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Transform.scale(
                                    scale: 1.2,
                                    child: Switch(
                                      value: _isAvailable,
                                      onChanged: (value) =>
                                          setState(() => _isAvailable = value),
                                      activeThumbColor: AppTheme.primary,
                                      activeTrackColor: AppTheme.primary
                                          .withValues(alpha: 0.3),
                                      inactiveThumbColor: Colors.grey[400],
                                      inactiveTrackColor: Colors.grey[300],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Featured Toggle
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _isFeatured
                                          ? Colors.amber.withValues(alpha: 0.1)
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.star,
                                      color: _isFeatured
                                          ? Colors.amber
                                          : Colors.grey[400],
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Featured',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: _isFeatured
                                                ? Colors.amber
                                                : Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Show in featured products',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Transform.scale(
                                    scale: 1.2,
                                    child: Switch(
                                      value: _isFeatured,
                                      onChanged: (value) =>
                                          setState(() => _isFeatured = value),
                                      activeThumbColor: Colors.amber,
                                      activeTrackColor: Colors.amber.withValues(
                                        alpha: 0.3,
                                      ),
                                      inactiveThumbColor: Colors.grey[400],
                                      inactiveTrackColor: Colors.grey[300],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isEdit ? Icons.edit : Icons.add, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _isEdit ? 'Update Product' : 'Add Product',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_library_outlined, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(
              'Product Images',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3436),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount:
                _productImageFiles.length + _uploadedImageUrls.length + 1,
            itemBuilder: (context, index) {
              final totalImages =
                  _productImageFiles.length + _uploadedImageUrls.length;

              if (index == totalImages) {
                // Add Image Button
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: _showImagePicker,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 32,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add Image',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                // Image Preview
                dynamic imageSource;
                if (index < _productImageFiles.length) {
                  imageSource = _productImageFiles[index];
                } else {
                  imageSource =
                      _uploadedImageUrls[index - _productImageFiles.length];
                }

                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildPreviewImage(imageSource),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3436),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: AppTheme.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3436),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategory,
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.category_outlined,
              color: AppTheme.primary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: _categories.map((category) {
            return DropdownMenuItem(value: category, child: Text(category));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value!;
            });
          },
        ),
      ],
    );
  }
}

class _ImagePickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImagePickerOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppTheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
