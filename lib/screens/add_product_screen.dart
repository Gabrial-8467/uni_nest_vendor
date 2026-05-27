import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../state/vendor_provider.dart';
import '../utils/app_theme.dart';
import '../services/image_upload_service.dart';
import '../services/permission_service.dart';
import '../utils/secure_logger.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController();

  String _selectedCategory = 'Snacks';
  String _selectedFoodType = 'Veg';
  bool _isAvailable = true;
  final List<File> _productImageFiles = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Ensure vendor provider is initialized to load auth token and vendor data
    ref.read(vendorProviderProvider.notifier).initialize();
  }

  final List<String> _categories = [
    'Snacks',
    'Beverages',
    'South Indian',
    'North Indian',
    'Chinese',
    'Desserts',
  ];

  final List<String> _foodTypes = ['Veg', 'Non-Veg'];

  static const Map<String, String> _categoryToApiValue = {
    'Snacks': 'snacks',
    'Beverages': 'beverages',
    'South Indian': 'south indian',
    'North Indian': 'north indian',
    'Chinese': 'chinese',
    'Desserts': 'desserts',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  String _toApiCategory(String displayCategory) {
    return _categoryToApiValue[displayCategory] ??
        displayCategory.toLowerCase();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      SecureLogger.info('Starting image pick from source: $source');

      // Request permissions first
      bool hasPermission = false;

      if (source == ImageSource.camera) {
        SecureLogger.info('Requesting camera permission');
        hasPermission = await PermissionService.requestPermission(
          Permission.camera,
        );
      } else {
        SecureLogger.info('Requesting storage permission');
        // Use requestStoragePermission() which handles Android 13+ properly
        hasPermission = await PermissionService.requestStoragePermission();
      }

      SecureLogger.info('Image permission granted: $hasPermission');

      if (!hasPermission) {
        if (mounted) {
          _showPermissionDeniedDialog(source);
        }
        return;
      }

      SecureLogger.info('Opening image picker');
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 800,
        maxHeight: 800,
      );

      SecureLogger.info('Image picked: ${image != null ? 'yes' : 'no'}');

      if (image != null && mounted) {
        final imageFile = File(image.path);
        // Validate and optimize the image
        if (!ImageUploadService.isValidImageFile(imageFile)) {
          SecureLogger.warning('Invalid image file format');
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

        SecureLogger.info(
          'Image added successfully. Total images: ${_productImageFiles.length}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Image added successfully (${_productImageFiles.length} total)',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      SecureLogger.error('Error picking image', error: e);
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

  Future<void> _showPermissionDeniedDialog(ImageSource source) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(
          source == ImageSource.camera
              ? 'Camera permission is needed to take photos. Please enable it in app settings.'
              : 'Storage permission is needed to select images. Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Open app settings
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _showImagePicker() async {
    await showModalBottomSheet(
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
      _productImageFiles.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final vendorProvider = ref.read(vendorProviderProvider);

    // Validate that at least one image is provided
    if (_productImageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one image is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final normalizedCategory = _toApiCategory(_selectedCategory);

      // Prepare product data with proper types
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final discountPrice =
          double.tryParse(_discountController.text.trim()) ?? 0.0;
      final discountPercentage = (price > 0 && discountPrice > 0)
          ? ((price - discountPrice) / price * 100).round()
          : null;

      final productData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': price,
        'category': normalizedCategory,
        'foodType': _selectedFoodType.toLowerCase().replaceAll(' ', '-'),
        ...?discountPercentage != null
            ? {'discountPercentage': discountPercentage}
            : null,
      };

      SecureLogger.info(
        'Creating product with ${_productImageFiles.length} image(s)',
        tag: 'PRODUCTS',
      );

      // Create product with images
      final success = await vendorProvider.createProduct(
        productData,
        imageFiles: _productImageFiles,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(vendorProvider.error ?? 'Failed to create product'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      SecureLogger.error('Error creating product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Add Product'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Images
              _buildImageSection(),
              const SizedBox(height: 24),

              // Basic Information
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'Product Name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Product name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Pricing
              _buildSectionTitle('Pricing'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _priceController,
                      label: 'Price (₹)',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Price is required';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Please enter a valid price';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _discountController,
                      label: 'Discount Price (₹)',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final discountPrice = double.tryParse(value);
                          if (discountPrice == null || discountPrice < 0) {
                            return 'Invalid discount price';
                          }
                          final price = double.tryParse(_priceController.text);
                          if (price != null && discountPrice >= price) {
                            return 'Discount must be less than price';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Category & Stock
              _buildSectionTitle('Category & Stock'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primary),
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedFoodType,
                decoration: InputDecoration(
                  labelText: 'Food Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primary),
                  ),
                ),
                items: _foodTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 12,
                          color: type == 'Veg' ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(type),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFoodType = value!;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Product Status
              _buildSectionTitle('Product Status'),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Available'),
                subtitle: const Text('Product will be visible to customers'),
                value: _isAvailable,
                onChanged: (value) {
                  setState(() {
                    _isAvailable = value;
                  });
                },
                activeThumbColor: AppTheme.primary,
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Creating Product...'),
                          ],
                        )
                      : const Text(
                          'Create Product',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primary),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Product Images'),
        const SizedBox(height: 16),
        if (_productImageFiles.isEmpty)
          InkWell(
            onTap: _showImagePicker,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add product images',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to select images',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _productImageFiles.length + 1,
              itemBuilder: (context, index) {
                if (index == _productImageFiles.length) {
                  // Add image button
                  return Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(right: 12),
                    child: Material(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _showImagePicker,
                        child: Icon(
                          Icons.add,
                          size: 32,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  );
                }

                final imageFile = _productImageFiles[index];
                return Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            imageFile,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.image,
                                  color: Colors.grey[400],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            width: 24,
                            height: 24,
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
              },
            ),
          ),
        const SizedBox(height: 12),
        if (_productImageFiles.isNotEmpty)
          Text(
            '${_productImageFiles.length} image(s) selected',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: AppTheme.primary),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
