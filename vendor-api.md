# Vendor API Documentation

Base path: `/api/vendor`

This document lists every vendor-facing API endpoint currently defined in:

- `src/routes/vendor/index.js`
- `src/routes/vendor/auth.js`

## Authentication

- Vendor auth routes under `/api/vendor/auth/*`
- All other `/api/vendor/*` routes require:
  - `Authorization: Bearer <token>`
  - authenticated user role = `vendor`

## Standard Response Pattern

Most vendor endpoints return a shape like:

```json
{
  "success": true,
  "message": "Human readable message",
  "data": {}
}
```

Some upload endpoints return `urls` or `data.images` directly, so check each endpoint section below.

## Vendor Auth APIs

### 1. Register Vendor

- Method: `POST`
- Endpoint: `/api/vendor/auth/register`
- Auth required: `No`

Request body:

```json
{
  "name": "Vendor Name",
  "email": "vendor@example.com",
  "password": "secret123",
  "phone": "9876543210",
  "businessName": "Campus Cafe",
  "businessType": "cafe"
}
```

Validation:

- `name` is required
- `email` must be valid
- `password` minimum 6 chars
- `phone` must be 10 digits
- `businessName` is required
- `businessType` must be one of:
  - `canteen`
  - `restaurant`
  - `cafe`
  - `food truck`
  - `other`

Success response:

```json
{
  "success": true,
  "message": "Vendor registered successfully",
  "data": {
    "user": {},
    "token": "jwt-token"
  }
}
```

Notes:

- Creates a `User` with role `vendor`
- Creates a linked `Vendor` profile
- Sends admin notification for vendor approval review

### 2. Vendor Login

- Method: `POST`
- Endpoint: `/api/vendor/auth/login`
- Auth required: `No`

Request body:

```json
{
  "email": "vendor@example.com",
  "password": "secret123"
}
```

Validation:

- `email` must be valid
- `password` is required

Success response:

```json
{
  "success": true,
  "message": "Vendor login successful",
  "data": {
    "user": {
      "_id": "userId",
      "name": "Vendor Name",
      "email": "vendor@example.com",
      "role": "vendor"
    },
    "token": "jwt-token"
  }
}
```

Failure cases:

- invalid credentials
- user exists but is not a vendor
- blocked account
- inactive account

### 3. Change Password

- Method: `POST`
- Endpoint: `/api/vendor/auth/change-password`
- Auth required: `Yes`

Request body:

```json
{
  "currentPassword": "oldpass123",
  "newPassword": "newpass123"
}
```

Validation:

- `currentPassword` is required
- `newPassword` minimum 6 chars

Success response:

```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

## Profile APIs

### 4. Get Vendor Profile

- Method: `GET`
- Endpoint: `/api/vendor/profile`
- Auth required: `Yes`

Success response:

```json
{
  "success": true,
  "message": "Vendor profile retrieved successfully",
  "data": {
    "_id": "vendorId",
    "businessName": "Campus Cafe",
    "businessType": "cafe",
    "user": {
      "name": "Vendor Name",
      "email": "vendor@example.com",
      "phone": "9876543210",
      "avatar": "/uploads/..."
    }
  }
}
```

### 5. Update Vendor Profile

- Method: `PUT`
- Endpoint: `/api/vendor/profile`
- Auth required: `Yes`

Request body fields:

- `businessName`
- `businessType`
- `description`
- `location`
- `contactInfo`
- `businessHours`
- `documents`
- `bankDetails`
- `privacySettings`
- `notificationSettings`
- `deliveryRadius`
- `avgPreparationTime`
- `minOrderAmount`
- `deliveryFee`

Validation highlights:

- `businessType` in `canteen | restaurant | cafe | food truck | other`
- `contactInfo.phone` must be 10 digits
- `contactInfo.email` must be valid email
- `businessHours`, `privacySettings`, `notificationSettings` must be objects
- `deliveryRadius` between `1` and `20`
- `avgPreparationTime` between `5` and `120`
- `minOrderAmount >= 0`
- `deliveryFee >= 0`
- `location.coordinates` must be `[longitude, latitude]`
- `location.pincode` must be 6 digits

Success response:

```json
{
  "success": true,
  "message": "Vendor profile updated successfully",
  "data": {}
}
```

### 6. Activate Vendor Account

- Method: `POST`
- Endpoint: `/api/vendor/activate-account`
- Auth required: `Yes`

Purpose:

- Development-only helper route that sets vendor status to `active`

Request body:

```json
{}
```

Validation:

- No body content allowed

## Dashboard API

### 7. Get Vendor Dashboard

- Method: `GET`
- Endpoint: `/api/vendor/dashboard`
- Auth required: `Yes`

Returns:

- `overview.totalProducts`
- `overview.activeProducts`
- `overview.totalOrders`
- `overview.pendingOrders`
- `overview.completedOrders`
- `overview.totalRevenue`
- `recentOrders`
- basic vendor summary

Important note:

- In `vendorController`, dashboard revenue is currently summed from orders with statuses:
  - `confirmed`
  - `preparing`
  - `ready`
  - `out_for_delivery`
  - `delivered`
- This vendor dashboard revenue logic is different from the stricter admin revenue logic.

## Product APIs

### 8. Get Vendor Products

- Method: `GET`
- Endpoint: `/api/vendor/products`
- Auth required: `Yes`

Query params:

- `page`
- `limit`
- `search`
- `category`
- `status`
- `availability`
- `isFeatured`
- `sortBy`
- `sortOrder`

Allowed values:

- `category`: `snacks | beverages | south indian | north indian | chinese | desserts`
- `status`: `pending | approved | rejected`
- `availability`: `in_stock | out_of_stock`
- `sortBy`: `name | price | rating | orderCount | createdAt`
- `sortOrder`: `asc | desc`

Success response:

```json
{
  "success": true,
  "message": "Products retrieved successfully",
  "data": {
    "products": [],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 0,
      "pages": 0
    }
  }
}
```

### 9. Get Product By ID

- Method: `GET`
- Endpoint: `/api/vendor/products/:id`
- Auth required: `Yes`

Path params:

- `id`: MongoDB product id

### 10. Create Product

- Method: `POST`
- Endpoint: `/api/vendor/products`
- Auth required: `Yes`
- Content type: `multipart/form-data` or JSON with image URLs

Accepted upload keys:

- `image`
- `images`

Request fields:

- `name`
- `description`
- `category`
- `price`
- `availability` optional
- `stock` optional
- `isFeatured` optional
- `images` optional as JSON string or array when not uploading files

Validation:

- `name` required
- `description` required
- `category` in `snacks | beverages | south indian | north indian | chinese | desserts`
- `price >= 0`
- `availability` in `in_stock | out_of_stock`
- `isFeatured` boolean

Important behavior:

- Vendor must exist
- Vendor account must be `active`
- At least one product image is required
- Response message says product is submitted for moderation

Success response:

```json
{
  "success": true,
  "message": "Product created successfully and submitted for moderation",
  "data": {}
}
```

### 11. Update Product With PUT

- Method: `PUT`
- Endpoint: `/api/vendor/products/:id`
- Auth required: `Yes`
- Content type: `multipart/form-data` or JSON

Path params:

- `id`: MongoDB product id

Allowed body fields:

- `name`
- `description`
- `category`
- `price`
- `availability`
- `stock`
- `images`
- `isFeatured`

Blocked field:

- `status` cannot be updated by vendor

Notes:

- If new images are uploaded, they replace previous images
- If `images` is passed in body, it is parsed and used
- If neither is sent, existing images are kept

### 12. Update Product With PATCH

- Method: `PATCH`
- Endpoint: `/api/vendor/products/:id`
- Auth required: `Yes`

This uses the same controller and same validation behavior as `PUT /products/:id`.

### 13. Delete Product

- Method: `DELETE`
- Endpoint: `/api/vendor/products/:id`
- Auth required: `Yes`

Path params:

- `id`: MongoDB product id

Important behavior:

- Vendor can delete only own product
- Product cannot be deleted if it has active orders with statuses:
  - `pending`
  - `confirmed`
  - `preparing`
  - `ready`
- Best-effort cleanup for uploaded images is attempted before DB deletion

Success response:

```json
{
  "success": true,
  "message": "Product deleted successfully"
}
```

## Order APIs

### 14. Get Vendor Orders

- Method: `GET`
- Endpoint: `/api/vendor/orders`
- Auth required: `Yes`

Query params:

- `page`
- `limit`
- `status`
- `dateFrom`
- `dateTo`
- `sortBy`
- `sortOrder`

Allowed values:

- `status`: `pending | confirmed | preparing | ready | out_for_delivery | delivered | cancelled | refunded`
- `sortBy`: `orderNumber | finalAmount | status | createdAt`
- `sortOrder`: `asc | desc`

Success response:

```json
{
  "success": true,
  "message": "Orders retrieved successfully",
  "data": {
    "orders": [],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 0,
      "pages": 0
    }
  }
}
```

### 15. Get Order By ID Or Order Number

- Method: `GET`
- Endpoint: `/api/vendor/orders/:id`
- Auth required: `Yes`

Path params:

- `id` can be:
  - MongoDB ObjectId
  - order number starting with `ORD`

Response includes populated:

- customer basic details
- product basic details

### 16. Update Order Status

- Method: `PUT`
- Endpoint: `/api/vendor/orders/:id/status`
- Auth required: `Yes`

Path params:

- `id` can be:
  - MongoDB ObjectId
  - order number starting with `ORD`

Request body:

```json
{
  "status": "confirmed",
  "note": "Preparing now",
  "estimatedDeliveryTime": "2026-04-05T12:30:00.000Z",
  "otp": "123456"
}
```

Allowed status values from route validation:

- `confirmed`
- `preparing`
- `ready`
- `out_for_delivery`
- `delivered`
- `cancelled`

Actual controller transition rules:

- `pending -> confirmed | cancelled`
- `confirmed -> preparing | cancelled`
- `preparing -> ready`
- `ready -> out_for_delivery`
- `out_for_delivery -> delivered`

Important notes:

- Invalid transitions return `400`
- Updates order timeline
- Sets `estimatedDeliveryTime` if provided
- Sends a customer notification after status update
- **OTP is required** when marking as `delivered` (4-6 digits)
- When marking as `out_for_delivery`, a delivery OTP is generated and returned in the response

Success response:

```json
{
  "success": true,
  "message": "Order status updated successfully",
  "data": {}
}
```

## Ledger & Payout APIs

### 17. Get Vendor Ledger

- Method: `GET`
- Endpoint: `/api/vendor/ledger`
- Auth required: `Yes`

Returns vendor settlement ledger summary including:
- `totalSales` - Total sales amount
- `totalCommission` - Total commission deducted
- `totalPenalties` - Any penalties applied
- `netBalance` - Net balance available
- `lastSettlementDate` - Date of last settlement
- `pendingAmount` - Amount pending for next settlement

Success response:

```json
{
  "success": true,
  "message": "Vendor ledger retrieved successfully",
  "data": {
    "vendorId": "vendorId",
    "totalSales": 50000,
    "totalCommission": 5000,
    "totalPenalties": 0,
    "netBalance": 45000,
    "pendingAmount": 5000,
    "lastSettlementDate": "2026-04-01T00:00:00.000Z"
  }
}
```

### 18. Get Vendor Payouts

- Method: `GET`
- Endpoint: `/api/vendor/payouts`
- Auth required: `Yes`

Returns vendor payout history sorted by newest first.

Success response:

```json
{
  "success": true,
  "message": "Vendor payouts retrieved successfully",
  "data": [
    {
      "_id": "payoutId",
      "vendorId": "vendorId",
      "amount": 45000,
      "status": "completed",
      "method": "bank_transfer",
      "transactionId": "TXN123456",
      "createdAt": "2026-04-01T00:00:00.000Z"
    }
  ]
}
```

## Analytics API

### 19. Get Vendor Analytics

- Method: `GET`
- Endpoint: `/api/vendor/analytics`
- Auth required: `Yes`

Query params:

- `period`

Allowed values:

- `daily`
- `weekly`
- `monthly`

Returns:

- `overview.totalOrders`
- `overview.totalRevenue`
- `overview.averageOrderValue`
- `overview.totalProducts`
- `topProducts`
- `recentOrders`
- `orderStatusStats`

Current period logic:

- `daily`: from today 00:00
- `weekly`: last 7 days
- `monthly`: from current month start

Important note:

- Vendor analytics revenue also uses statuses:
  - `confirmed`
  - `preparing`
  - `ready`
  - `out_for_delivery`
  - `delivered`
- It does not currently use the admin-side delivered-and-paid revenue rule.

## Review APIs

### 20. Get All Vendor Reviews

- Method: `GET`
- Endpoint: `/api/vendor/reviews`
- Auth required: `Yes`

Query params:

- `page`
- `limit`
- `rating`

Behavior:

- Collects reviews from all products belonging to vendor
- Adds `productName` and `productId` to each review
- Sorts newest first
- Applies pagination in memory

Success response:

```json
{
  "success": true,
  "message": "Reviews retrieved successfully",
  "data": {
    "reviews": [
      {
        "_id": "reviewId",
        "user": "userId",
        "rating": 5,
        "comment": "Great food!",
        "productName": "Burger",
        "productId": "productId",
        "createdAt": "2026-04-01T00:00:00.000Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 10,
      "pages": 1
    }
  }
}
```

### 21. Get Reviews For One Product

- Method: `GET`
- Endpoint: `/api/vendor/reviews/products/:id`
- Auth required: `Yes`

Path params:

- `id`: MongoDB product id

Query params:

- `page`
- `limit`
- `rating`

Behavior:

- Confirms the product belongs to current vendor
- Returns product metadata with reviews
- Tries to populate review user info with `name` and `avatar`

Success response:

```json
{
  "success": true,
  "message": "Product reviews retrieved successfully",
  "data": {
    "reviews": [
      {
        "_id": "reviewId",
        "user": {
          "name": "John Doe",
          "avatar": "/uploads/avatar.jpg"
        },
        "rating": 5,
        "comment": "Great food!",
        "productName": "Burger",
        "productId": "productId",
        "createdAt": "2026-04-01T00:00:00.000Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 5,
      "pages": 1
    },
    "product": {
      "id": "productId",
      "name": "Burger",
      "rating": 4.5
    }
  }
}
```

## Notification APIs

### 22. Get Vendor Notifications

- Method: `GET`
- Endpoint: `/api/vendor/notifications`
- Auth required: `Yes`

Query params:

- `page`
- `limit`
- `type`
- `read`

Allowed `type` values:

- `order`
- `vendor_status`
- `review`
- `payment`
- `system`
- `account_alert`

Behavior:

- Filters notifications for the current vendor user
- Returns unread count
- If `read=true` is passed, unread notifications are also marked as read

Success response:

```json
{
  "success": true,
  "message": "Notifications retrieved successfully",
  "data": {
    "notifications": [],
    "unreadCount": 0,
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 0,
      "pages": 0
    }
  }
}
```

### 23. Mark All Notifications Read

- Method: `PUT`
- Endpoint: `/api/vendor/notifications/mark-all-read`
- Auth required: `Yes`

Success response:

```json
{
  "success": true,
  "message": "Marked X notifications as read",
  "data": {
    "modifiedCount": 3
  }
}
```

### 24. Clear All Notifications

- Method: `DELETE`
- Endpoint: `/api/vendor/notifications/clear-all`
- Auth required: `Yes`

Success response:

```json
{
  "success": true,
  "message": "Cleared X notifications",
  "data": {
    "deletedCount": 10
  }
}
```

### 25. Delete Individual Notification

- Method: `DELETE`
- Endpoint: `/api/vendor/notifications/:id`
- Auth required: `Yes`

Path params:

- `id`: MongoDB notification id

Success response:

```json
{
  "success": true,
  "message": "Notification deleted successfully",
  "data": {}
}
```

## Upload APIs

### 26. Upload Vendor Avatar

- Method: `POST`
- Endpoint: `/api/vendor/upload/avatar`
- Auth required: `Yes`
- Content type: `multipart/form-data`

Form-data key:

- `avatar`

Success response:

```json
{
  "success": true,
  "urls": ["https://..."]
}
```

Notes:

- Requires Cloudinary to be configured

### 27. Upload Product Images

- Method: `POST`
- Endpoint: `/api/vendor/upload/product-images`
- Auth required: `Yes`
- Content type: `multipart/form-data`

Accepted form-data keys:

- `images`
- `image`
- `product`
- `file`

Max upload count:

- up to 5 files

Success response:

```json
{
  "success": true,
  "data": {
    "images": [
      {
        "url": "https://...",
        "alt": "filename.jpg"
      }
    ]
  }
}
```

Notes:

- Requires Cloudinary to be configured

### 28. Upload Vendor Documents

- Method: `POST`
- Endpoint: `/api/vendor/upload/documents`
- Auth required: `Yes`
- Content type: `multipart/form-data`

Form-data key:

- `documents`

Max upload count:

- up to 3 files

Success response:

```json
{
  "success": true,
  "urls": ["https://..."]
}
```

Notes:

- Requires Cloudinary to be configured

## Quick Endpoint Index

```text
POST   /api/vendor/auth/register
POST   /api/vendor/auth/login
POST   /api/vendor/auth/change-password

GET    /api/vendor/profile
PUT    /api/vendor/profile
POST   /api/vendor/activate-account
GET    /api/vendor/dashboard

GET    /api/vendor/products
GET    /api/vendor/products/:id
POST   /api/vendor/products
PUT    /api/vendor/products/:id
PATCH  /api/vendor/products/:id
DELETE /api/vendor/products/:id

GET    /api/vendor/orders
GET    /api/vendor/orders/:id
PUT    /api/vendor/orders/:id/status

GET    /api/vendor/analytics

GET    /api/vendor/reviews
GET    /api/vendor/reviews/products/:id

GET    /api/vendor/notifications
PUT    /api/vendor/notifications/mark-all-read
DELETE /api/vendor/notifications/clear-all
DELETE /api/vendor/notifications/:id

POST   /api/vendor/upload/avatar
POST   /api/vendor/upload/product-images
POST   /api/vendor/upload/documents

GET    /api/vendor/ledger
GET    /api/vendor/payouts
```

## Implementation Reference

For future updates, these docs should stay aligned with:

- [src/routes/vendor/index.js](d:/backend/UniNest-Backend/src/routes/vendor/index.js)
- [src/routes/vendor/auth.js](d:/backend/UniNest-Backend/src/routes/vendor/auth.js)
- [src/controllers/vendorController.js](d:/backend/UniNest-Backend/src/controllers/vendorController.js)
