# Vendor App API Documentation

This document covers all vendor-facing endpoints in UniNest backend.

## Base URL

`http://localhost:5000/api/vendor/`

Vendor routes are under:  

`/vendor`

Example full URL:

`http://localhost:5000/api/vendor/profile`

## Authentication

All vendor endpoints require:

- `Authorization: Bearer <jwt_token>`
- Authenticated user role must be `vendor`

### 1. Vendor Signup

- Method: `POST`
- Endpoint: `/api/vendor/auth/register`

Required body fields:

- `name` string (non-empty) - Full name
- `email` string (valid email)
- `password` string (min 6 characters)
- `phone` string (10-digit number)
- `businessName` string (non-empty) - Business name
- `businessType` enum: `canteen | restaurant | cafe | food truck | other`

```bash
curl -X POST "http://localhost:5000/api/vendor/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "vendor@example.com",
    "password": "password123",
    "phone": "9876543210",
    "businessName": "Campus Cafe",
    "businessType": "cafe"
  }'
```

Notes:
- Vendor-specific registration endpoint - automatically sets role to vendor
- Vendor profile is automatically created on signup with provided business details
- Vendor status defaults to `pending` and requires admin approval
- No location or description fields in vendor profile

### 2. Vendor Login

- Method: `POST`
- Endpoint: `/api/vendor/auth/login`

Required body fields:

- `email` string (valid email)
- `password` string

```bash
curl -X POST "http://localhost:5000/api/vendor/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "vendor@example.com",
    "password": "password123"
  }'
```

**Note:** Vendor-specific login endpoint - only allows vendors with role 'vendor' to login

### Authentication Responses

Both signup and login return:

```json
{
  "success": true,
  "message": "Login successful" | "User registered successfully",
  "data": {
    "user": {
      "id": "user_id",
      "name": "Vendor Name",
      "email": "vendor@example.com",
      "role": "vendor",
      "phone": "9876543210"
    },
    "token": "jwt_token_here"
  },
  "timestamp": "2026-03-19T12:00:00.000Z"
}
```

### Authentication Errors

- `400` - Validation errors (missing name, email, password, phone, businessName, or businessType)
- `401` - Invalid credentials, account blocked/inactive
- `404` - User not found

If token is missing/invalid in subsequent API calls, returns `401`.
If role is not vendor, returns `403`.

## Common Response Format

Most vendor controller responses follow:

```json
{
  "success": true,
  "message": "Human-readable message",
  "data": {},
  "timestamp": "2026-03-19T12:00:00.000Z"
}
```

Validation errors (from `express-validator`) follow:

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    {
      "field": "price",
      "message": "Price must be positive",
      "value": -10
    }
  ]
}
```

## 1. Vendor Profile

### 1.1 Get Vendor Profile

- Method: `GET`
- Endpoint: `/api/vendor/profile`

```bash
curl -X GET "http://localhost:5000/api/vendor/profile" \
  -H "Authorization: Bearer <vendor-token>"
```

### 1.2 Update Vendor Profile

- Method: `PUT`
- Endpoint: `/api/vendor/profile`

Request body (all optional):

- `businessName` string (non-empty)
- `businessType` enum: `canteen | restaurant | cafe | food truck | other`
- `contactInfo` object (phone, email)
- `businessHours` object
- `privacySettings` object
- `notificationSettings` object
- `deliveryRadius` integer `1..20` (km)
- `avgPreparationTime` integer `5..120` (minutes)
- `minOrderAmount` number >= 0
- `deliveryFee` number >= 0

**Note:** All essential business fields including delivery settings are now available.

```bash
curl -X PUT "http://localhost:5000/api/vendor/profile" \
  -H "Authorization: Bearer <vendor-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "businessName": "Campus Cafe",
    "businessType": "cafe",
    "deliveryRadius": 8,
    "avgPreparationTime": 25,
    "minOrderAmount": 100,
    "deliveryFee": 20,
    "contactInfo": {
      "phone": "9876543210",
      "email": "vendor@example.com"
    }
  }'
```

## 2. Product Management

### 2.1 Get Vendor Products

- Method: `GET`
- Endpoint: `/api/vendor/products`

Query params:

- `page` integer >= 1 (default `1`)
- `limit` integer `1..100` (default `20`)
- `search` string
- `category` enum: `breakfast | lunch | dinner | snacks | beverages | desserts | combo | other`
- `status` enum: `pending | approved | rejected`
- `isAvailable` boolean (`true`/`false`)
- `sortBy` enum: `name | price | rating | orderCount | createdAt` (default `createdAt`)
- `sortOrder` enum: `asc | desc` (default `desc`)

```bash
curl -X GET "http://localhost:5000/api/vendor/products?page=1&limit=20&status=approved&sortBy=createdAt&sortOrder=desc" \
  -H "Authorization: Bearer <vendor-token>"
```

### 2.2 Get Single Product by ID

- Method: `GET`
- Endpoint: `/api/vendor/products/:id`

Path params:

- `id` (Mongo ObjectId)

```bash
curl -X GET "http://localhost:5000/api/vendor/products/<product-id>" \
  -H "Authorization: Bearer <vendor-token>"
```

### 2.3 Create Product

- Method: `POST`
- Endpoint: `/api/vendor/products`

Required body fields:

- `name` string
- `description` string
- `category` enum: `snacks | beverages | south indian | north indian | chinese | desserts`
- `price` number >= 0
- `images` string array (at least 1)
- `inStock` integer >= 0

Optional fields:

- `discountPrice` number 0-100 (percentage discount)
- `isAvailable` boolean (default true)
- `isFeatured` boolean (default false)

Notes:

- Vendor account status must be `active`.
- New product status is set to `pending` for admin approval.
- `discountPrice` is a percentage (0-100%). The final price is calculated automatically.

```bash
curl -X POST "http://localhost:5000/api/vendor/products" \
  -H "Authorization: Bearer <vendor-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Paneer Wrap",
    "description": "Spicy paneer wrap with vegetables",
    "category": "north indian",
    "price": 120,
    "images": ["/uploads/products/paneer-wrap.jpg"],
    "inStock": 25,
    "discountPrice": 15,
    "isAvailable": true,
    "isFeatured": false
  }'
```

**Response will include calculated fields:**
```json
{
  "success": true,
  "data": {
    "_id": "product_id",
    "name": "Paneer Wrap",
    "price": 120,
    "discountPrice": 15,
    "finalPrice": 102,
    "hasDiscount": true,
    "discountAmount": 18,
    "inStock": 25,
    "isAvailable": true,
    "isFeatured": false
  }
}
```

### 2.4 Update Product

- Method: `PUT`
- Endpoint: `/api/vendor/products/:id`

Path params:

- `id` (Mongo ObjectId)

Any product fields can be sent as optional updates.

Important behavior:

- If any critical field changes (`name`, `description`, `price`, `images`), status resets to `pending`.

```bash
curl -X PUT "http://localhost:5000/api/vendor/products/<product-id>" \
  -H "Authorization: Bearer <vendor-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "price": 130,
    "description": "Updated description"
  }'
```

### 2.5 Delete Product

- Method: `DELETE`
- Endpoint: `/api/vendor/products/:id`

Path params:

- `id` (Mongo ObjectId)

Rule:

- Product cannot be deleted if linked to active orders (`pending`, `confirmed`, `preparing`, `ready`).

```bash
curl -X DELETE "http://localhost:5000/api/vendor/products/<product-id>" \
  -H "Authorization: Bearer <vendor-token>"
```

## 3. Order Management

### 3.1 Get Vendor Orders

- Method: `GET`
- Endpoint: `/api/vendor/orders`

Query params:

- `page` integer >= 1 (default `1`)
- `limit` integer `1..100` (default `20`)
- `status` enum: `pending | confirmed | preparing | ready | out_for_delivery | delivered | cancelled | refunded`
- `dateFrom` ISO8601 date
- `dateTo` ISO8601 date
- `sortBy` enum: `orderNumber | finalAmount | status | createdAt` (default `createdAt`)
- `sortOrder` enum: `asc | desc` (default `desc`)

```bash
curl -X GET "http://localhost:5000/api/vendor/orders?page=1&limit=20&status=pending" \
  -H "Authorization: Bearer <vendor-token>"
```

### 3.2 Get Single Order by ID

- Method: `GET`
- Endpoint: `/api/vendor/orders/:id`

Path params:

- `id` (Mongo ObjectId)

Response includes populated customer details, product information, and customizations.

```bash
curl -X GET "http://localhost:5000/api/vendor/orders/<order-id>" \
  -H "Authorization: Bearer <vendor-token>"
```

### 3.3 Update Order Status

- Method: `PUT`
- Endpoint: `/api/vendor/orders/:id/status`

Path params:

- `id` (Mongo ObjectId)

Body:

- `status` required enum: `confirmed | preparing | ready | out_for_delivery | delivered | cancelled`
- `note` optional string (max 200)
- `estimatedDeliveryTime` optional ISO8601 datetime

Valid transition rules:

- `pending -> confirmed | cancelled`
- `confirmed -> preparing | cancelled`
- `preparing -> ready`
- `ready -> out_for_delivery`
- `out_for_delivery -> delivered`

```bash
curl -X PUT "http://localhost:5000/api/vendor/orders/<order-id>/status" \
  -H "Authorization: Bearer <vendor-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "confirmed",
    "note": "Order accepted",
    "estimatedDeliveryTime": "2026-03-19T18:30:00.000Z"
  }'
```

## 4. Analytics

### 4.1 Get Vendor Analytics

- Method: `GET`
- Endpoint: `/api/vendor/analytics`

Query params:

- `period` optional enum: `daily | weekly | monthly` (default `monthly`)

Response includes:

- `overview` (total orders, revenue, average order value, total products)
- `topProducts`
- `recentOrders`
- `orderStatusStats`

```bash
curl -X GET "http://localhost:5000/api/vendor/analytics?period=monthly" \
  -H "Authorization: Bearer <vendor-token>"
```

## 5. Reviews

### 5.1 Get Vendor Reviews

- Method: `GET`
- Endpoint: `/api/vendor/reviews`

Query params:

- `page` integer >= 1 (default `1`)
- `limit` integer `1..100` (default `20`)
- `rating` integer `1..5`

```bash
curl -X GET "http://localhost:5000/api/vendor/reviews?page=1&limit=20&rating=5" \
  -H "Authorization: Bearer <vendor-token>"
```

### 5.2 Get Product Reviews

- Method: `GET`
- Endpoint: `/api/vendor/reviews/products/:id`

Path params:

- `id` (Mongo ObjectId) - Product ID

Query params (optional):

- `page` integer >= 1 (default: 1)
- `limit` integer 1-100 (default: 10)
- `rating` integer 1-5 (filter by rating)

Response includes reviews for the specific product with user information and pagination.

```bash
curl -X GET "http://localhost:5000/api/vendor/reviews/products/<product-id>?page=1&limit=10" \
  -H "Authorization: Bearer <vendor-token>"
```

**Response:**
```json
{
  "success": true,
  "data": {
    "reviews": [
      {
        "_id": "review_id",
        "user": {
          "_id": "user_id",
          "name": "John Doe",
          "avatar": "avatar_url"
        },
        "rating": 5,
        "comment": "Amazing product! Highly recommended.",
        "images": ["review_image.jpg"],
        "helpful": 12,
        "createdAt": "2026-03-19T18:00:00.000Z",
        "productName": "Hakka Noodles",
        "productId": "product_id"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 25,
      "pages": 3
    },
    "product": {
      "id": "product_id",
      "name": "Hakka Noodles",
      "rating": {
        "average": 4.5,
        "count": 25
      }
    }
  }
}
```

## 6. File Upload APIs

All upload APIs require vendor auth and use `multipart/form-data`.

### 6.1 Upload Avatar

- Method: `POST`
- Endpoint: `/api/vendor/upload/avatar`
- Form key: `avatar` (single file)

```bash
curl -X POST "http://localhost:5000/api/vendor/upload/avatar" \
  -H "Authorization: Bearer <vendor-token>" \
  -F "avatar=@C:/path/to/avatar.jpg"
```

### 6.2 Upload Product Images

- Method: `POST`
- Endpoint: `/api/vendor/upload/product-images`
- Form key: `images` (max 5 files)

```bash
curl -X POST "http://localhost:5000/api/vendor/upload/product-images" \
  -H "Authorization: Bearer <vendor-token>" \
  -F "images=@C:/path/to/product1.jpg" \
  -F "images=@C:/path/to/product2.jpg"
```

### 6.3 Upload Vendor Documents

- Method: `POST`
- Endpoint: `/api/vendor/upload/documents`
- Form key: `documents` (max 3 files)

```bash
curl -X POST "http://localhost:5000/api/vendor/upload/documents" \
  -H "Authorization: Bearer <vendor-token>" \
  -F "documents=@C:/path/to/license.pdf" \
  -F "documents=@C:/path/to/gst.pdf"
```

Allowed file types:

- `jpeg`, `jpg`, `png`, `gif`, `webp`, `pdf`, `doc`, `docx`

Max file size:

- Controlled by env var `MAX_FILE_SIZE` (default `5MB`).

## 7. Vendor Error Scenarios

Common vendor-side business errors:

- `404 Vendor not found`
- `404 Product not found`
- `404 Order not found`
- `400 Vendor account is not active` (while creating product)
- `400 Cannot delete product with active orders`
- `400 Invalid status transition from <current> to <next>`

## 8. Quick Endpoint Index

### Authentication
- `POST /api/vendor/auth/register`
- `POST /api/vendor/auth/login`

### Vendor Profile
- `GET /api/vendor/profile`
- `PUT /api/vendor/profile`

### Product Management
- `GET /api/vendor/products`
- `GET /api/vendor/products/:id`
- `POST /api/vendor/products`
- `PUT /api/vendor/products/:id`
- `DELETE /api/vendor/products/:id`

### Order Management
- `GET /api/vendor/orders`
- `PUT /api/vendor/orders/:id/status`

### Analytics & Reviews
- `GET /api/vendor/analytics`
- `GET /api/vendor/reviews`

### File Upload
- `POST /api/vendor/upload/avatar`
- `POST /api/vendor/upload/product-images`
- `POST /api/vendor/upload/documents`
