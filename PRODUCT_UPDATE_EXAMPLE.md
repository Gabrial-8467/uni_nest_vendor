# 📸 PRODUCT UPDATE WITH IMAGES - USAGE EXAMPLE

## ✅ FIXED IMPLEMENTATION

Your Flutter app now correctly supports the backend contract:

### **Backend Requirements Met:**
- ✅ **Endpoint**: `PUT /api/vendor/products/:id`
- ✅ **Content-Type**: `multipart/form-data` (auto-set by MultipartRequest)
- ✅ **Auth**: `Bearer Token` 
- ✅ **File field name**: `images` (EXACT MATCH)
- ✅ **Form fields**: All sent as strings
- ✅ **Multiple files**: Up to 5 images supported

---

## 🚀 HOW TO USE

### **1. Update Product WITH Images**

```dart
// In your UI code
final vendorProvider = Provider.of<VendorProvider>(context, listen: false);

// Product data as strings (per backend contract)
final productData = {
  'name': 'Updated Product Name',
  'description': 'Updated description',
  'price': '299.99', // String!
  'category': 'snacks',
  'inStock': '50', // String!
  'isAvailable': 'true', // String!
  'discountPrice': '10', // String!
};

// Image files to upload
final imageFiles = [
  File('/path/to/image1.jpg'),
  File('/path/to/image2.png'),
  // ... up to 5 files
];

// Call the updated method
final success = await vendorProvider.updateProduct(
  'product_id_here',
  productData,
  imageFiles: imageFiles, // New parameter!
);

if (success) {
  print('✅ Product updated with images!');
} else {
  print('❌ Update failed: ${vendorProvider.error}');
}
```

### **2. Update Product WITHOUT Images**

```dart
// Same call but without imageFiles parameter
final success = await vendorProvider.updateProduct(
  'product_id_here',
  productData,
);

// This will use regular JSON PUT request
```

---

## 🔍 DEBUG OUTPUT

The fixed implementation provides comprehensive debugging:

```
=== UPDATE PRODUCT DEBUG ===
URL: http://localhost:5000/api/vendor/products/60f7b3b3b3b3b3b3b3b3b3b3
Method: PUT
Image files count: 2
Field: name = Updated Product Name
Field: price = 299.99
Field: isAvailable = true
Attaching file 1: /path/to/image1.jpg (245678 bytes)
Attaching file 2: /path/to/image2.png (189234 bytes)
Request headers: {Authorization: Bearer eyJhbGciOi..., Accept: application/json}
Request fields count: 6
Request files count: 2
Request file field names: [images, images]
Response status: 200
Response body: {"success":true,"data":{...}}
✅ Product updated successfully with 2 images
```

---

## 🎯 WHAT WAS FIXED

### **BEFORE (Broken):**
```dart
// WRONG: Regular JSON request
static Future<Product> updateProduct(String productId, Map<String, dynamic> productData, String authToken) async {
  return await _makeRequest(ApiMethods.put, endpoint, body: productData); // JSON only!
}
```

### **AFTER (Fixed):**
```dart
// CORRECT: MultipartRequest for files
static Future<Product> updateProduct(
  String productId, 
  Map<String, dynamic> productData, 
  String authToken, {
  List<File>? imageFiles, // New parameter!
}) async {
  if (imageFiles != null && imageFiles.isNotEmpty) {
    final request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = 'Bearer $authToken';
    
    // Add form fields as strings
    productData.forEach((key, value) {
      request.fields[key] = value.toString();
    });
    
    // Attach files with EXACT field name 'images'
    for (final file in imageFiles) {
      request.files.add(await http.MultipartFile.fromPath('images', file.path));
    }
    
    final response = await request.send();
    // ... handle response
  }
}
```

---

## 📊 BACKEND INTEGRATION FLOW

```
Flutter App                    Node.js Backend
┌─────────────────┐            ┌─────────────────┐
│ MultipartRequest│  PUT       │ Express Router  │
│ Field: images   │ ─────────► │ /api/vendor/...│
│ Field: name     │            │                 │
│ Field: price    │            │ Multer Middleware│
│ ...             │            │ req.files.images│
└─────────────────┘            │ Cloudinary     │
         │                      │ Upload         │
         ▼                      │                 │
┌─────────────────┐            │ DB Update      │
│ Files Attached  │            │ Product Model  │
│ Correct Headers │            │                 │
│ Auth Bearer     │            │                 │
└─────────────────┘            └─────────────────┘
```

---

## 🚨 EXPECTED BACKEND LOGS

After the fix, your backend should log:

```bash
📁 Found 2 files in req.files
✅ Images uploaded to Cloudinary
✅ Product updated in database
```

**NOT** the previous:
```bash
📁 Found 0 files in req.files  ❌
```

---

## ✅ VALIDATION CHECKLIST

- [x] **Field name**: `images` (exact match)
- [x] **Request type**: `multipart/form-data`
- [x] **Headers**: `Authorization: Bearer <token>`
- [x] **Data format**: All fields as strings
- [x] **File handling**: Proper MultipartFile attachment
- [x] **Debug logging**: Comprehensive request/response logging
- [x] **Error handling**: Proper exception handling
- [x] **Fallback**: JSON update when no files

---

## 🎯 RESULT

Your Flutter app now **strictly follows** the backend contract:

1. **Correct field names** - `images` exactly
2. **Correct request type** - MultipartRequest for files
3. **Correct data format** - All strings
4. **Correct headers** - Proper auth and content handling
5. **Proper debugging** - Full visibility into request flow

The backend will now receive files correctly and log: `"📁 Found X files in req.files"` instead of 0.
