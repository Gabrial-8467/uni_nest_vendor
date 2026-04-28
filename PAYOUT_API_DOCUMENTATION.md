# Vendor Payout API Documentation

## Overview
This document describes the backend API endpoints required to support the vendor payout feature in the UNI NEST Vendor app.

---

## 1. Payout Method Management

### Get Vendor Payout Method
Retrieves the vendor's configured payout method (bank account or UPI).

**Endpoint:** `GET /api/vendor/payouts/method`

**Headers:**
```
Authorization: Bearer {vendor_auth_token}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "type": "bank_transfer",
    "accountHolderName": "John Doe",
    "bankName": "State Bank of India",
    "accountNumber": "123456789012",
    "ifscCode": "SBIN0001234",
    "upiId": null,
    "isVerified": true
  }
}
```

**Response (404 Not Found):**
```json
{
  "success": false,
  "message": "Payout method not found"
}
```

---

### Update Vendor Payout Method
Creates or updates the vendor's payout method.

**Endpoint:** `PUT /api/vendor/payouts/method`

**Headers:**
```
Authorization: Bearer {vendor_auth_token}
Content-Type: application/json
```

**Request Body (Bank Transfer):**
```json
{
  "type": "bank_transfer",
  "accountHolderName": "John Doe",
  "bankName": "State Bank of India",
  "accountNumber": "123456789012",
  "ifscCode": "SBIN0001234",
  "isVerified": true
}
```

**Request Body (UPI):**
```json
{
  "type": "upi",
  "accountHolderName": "John Doe",
  "upiId": "johndoe@upi",
  "isVerified": true
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Payout method updated successfully",
  "data": {
    "type": "bank_transfer",
    "accountHolderName": "John Doe",
    "bankName": "State Bank of India",
    "accountNumber": "123456789012",
    "ifscCode": "SBIN0001234",
    "upiId": null,
    "isVerified": true
  }
}
```

**Validation Rules:**
- `type`: Must be either `"bank_transfer"` or `"upi"`
- `accountHolderName`: Required, max 100 characters
- `bankName`: Required for bank_transfer, max 100 characters
- `accountNumber`: Required for bank_transfer, 9-18 digits
- `ifscCode`: Required for bank_transfer, 11 characters (format: ABCD0123456)
- `upiId`: Required for upi, must contain '@' (format: username@provider)
- `isVerified`: Boolean, default false

---

## 2. Payout Requests

### Request a Payout
Submits a new payout request for the vendor's available balance.

**Endpoint:** `POST /api/vendor/payouts/request`

**Headers:**
```
Authorization: Bearer {vendor_auth_token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "amount": 1500.00
}
```

**Validation:**
- `amount`: Required, must be greater than 0, cannot exceed available balance
- Minimum payout: ₹100
- Vendor must have a verified payout method configured

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Payout request submitted successfully",
  "data": {
    "id": "60f8a2b3c4d5e6f7a8b9c0d1",
    "amount": 1500.00,
    "status": "pending",
    "createdAt": "2026-04-28T10:30:00.000Z",
    "processedAt": null,
    "bankReference": null,
    "failureReason": null
  }
}
```

**Error Responses:**
```json
// 400 - Invalid amount
{
  "success": false,
  "message": "Amount must be at least ₹100"
}

// 400 - Insufficient balance
{
  "success": false,
  "message": "Insufficient available balance"
}

// 400 - No payout method
{
  "success": false,
  "message": "Please configure a payout method first"
}

// 400 - Unverified payout method
{
  "success": false,
  "message": "Payout method not verified"
}

// 429 - Rate limit
{
  "success": false,
  "message": "Please wait before requesting another payout"
}
```

---

### Get Vendor Payouts
Retrieves the list of all payout requests for the vendor.

**Endpoint:** `GET /api/vendor/payouts`

**Headers:**
```
Authorization: Bearer {vendor_auth_token}
```

**Query Parameters:**
- `page` (optional): Page number, default 1
- `limit` (optional): Items per page, default 20, max 100
- `status` (optional): Filter by status - "pending", "processing", "completed", "failed"

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "payouts": [
      {
        "id": "60f8a2b3c4d5e6f7a8b9c0d1",
        "amount": 1500.00,
        "status": "completed",
        "createdAt": "2026-04-28T10:30:00.000Z",
        "processedAt": "2026-04-29T14:20:00.000Z",
        "bankReference": "NEFT/123456789012",
        "failureReason": null
      },
      {
        "id": "60f8a2b3c4d5e6f7a8b9c0d2",
        "amount": 2500.00,
        "status": "pending",
        "createdAt": "2026-04-28T09:00:00.000Z",
        "processedAt": null,
        "bankReference": null,
        "failureReason": null
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 15,
      "totalPages": 1
    }
  }
}
```

---

### Get Payout Details
Retrieves details of a specific payout request.

**Endpoint:** `GET /api/vendor/payouts/:id`

**Headers:**
```
Authorization: Bearer {vendor_auth_token}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": "60f8a2b3c4d5e6f7a8b9c0d1",
    "amount": 1500.00,
    "status": "completed",
    "createdAt": "2026-04-28T10:30:00.000Z",
    "processedAt": "2026-04-29T14:20:00.000Z",
    "bankReference": "NEFT/123456789012",
    "failureReason": null,
    "payoutMethod": {
      "type": "bank_transfer",
      "accountHolderName": "John Doe",
      "bankName": "State Bank of India",
      "accountNumber": "**** **** 9012",
      "ifscCode": "SBIN0001234"
    }
  }
}
```

---

## 3. Data Models

### Vendor Model Update
Add `payoutMethod` field to the Vendor schema:

```javascript
const vendorSchema = new mongoose.Schema({
  // ... existing fields ...
  
  payoutMethod: {
    type: {
      type: String,
      enum: ['bank_transfer', 'upi'],
      default: null
    },
    accountHolderName: {
      type: String,
      trim: true,
      maxlength: 100
    },
    bankName: {
      type: String,
      trim: true,
      maxlength: 100
    },
    accountNumber: {
      type: String,
      // Store encrypted
    },
    ifscCode: {
      type: String,
      uppercase: true,
      trim: true,
      maxlength: 11
    },
    upiId: {
      type: String,
      lowercase: true,
      trim: true
    },
    isVerified: {
      type: Boolean,
      default: false
    },
    verifiedAt: {
      type: Date,
      default: null
    }
  },
  
  // ... other fields ...
});
```

### Payout Model
```javascript
const payoutSchema = new mongoose.Schema({
  vendor: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Vendor',
    required: true,
    index: true
  },
  amount: {
    type: Number,
    required: true,
    min: 100
  },
  status: {
    type: String,
    enum: ['pending', 'processing', 'completed', 'failed', 'cancelled'],
    default: 'pending',
    index: true
  },
  payoutMethod: {
    type: {
      type: String,
      enum: ['bank_transfer', 'upi']
    },
    accountHolderName: String,
    bankName: String,
    accountNumber: String, // masked
    ifscCode: String,
    upiId: String
  },
  bankReference: {
    type: String,
    default: null
  },
  failureReason: {
    type: String,
    default: null
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  processedAt: {
    type: Date,
    default: null
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Vendor',
    required: true
  }
}, {
  timestamps: true
});

// Indexes
payoutSchema.index({ vendor: 1, createdAt: -1 });
payoutSchema.index({ status: 1, createdAt: 1 });
```

---

## 4. Business Logic Requirements

### Payout Method Verification
- Initial `isVerified: false` when first added
- Mark as verified after validating with bank/UPI provider
- Can use micro-deposit verification for bank accounts
- UPI can be verified via UPI validation API

### Payout Processing Flow
1. Vendor requests payout
2. System checks:
   - Available balance >= requested amount
   - Payout method exists and is verified
   - No pending payouts exceeding threshold
   - Rate limit not exceeded
3. Deduct amount from available balance immediately
4. Add to pending balance
5. Process via payment gateway (RazorpayX, Cashfree, etc.)
6. Update status based on response

### Rate Limiting
- Min 5 seconds between payout requests per vendor
- Max 3 pending payouts at a time
- Daily/monthly limits configurable

### Security Requirements
- Encrypt `accountNumber` at rest (AES-256)
- Mask account numbers in logs and responses
- Never return full account numbers in API responses
- Log all payout operations as security events

---

## 5. Error Codes

| Code | Meaning |
|------|---------|
| 400 | Invalid request data |
| 401 | Unauthorized - invalid token |
| 403 | Forbidden - insufficient permissions |
| 404 | Payout/payout method not found |
| 429 | Rate limit exceeded |
| 500 | Server error |

---

## 6. Webhook Support (Optional)

For async payout processing, implement webhooks:

**Endpoint:** `POST /api/vendor/webhooks/payouts`

**Payload:**
```json
{
  "event": "payout.processed",
  "data": {
    "payoutId": "60f8a2b3c4d5e6f7a8b9c0d1",
    "vendorId": "60f8a2b3c4d5e6f7a8b9c0d2",
    "status": "completed",
    "bankReference": "NEFT/123456789012",
    "processedAt": "2026-04-29T14:20:00.000Z"
  }
}
```

---

## 7. Sample Implementation (Node.js/Express)

```javascript
// routes/payoutRoutes.js
const express = require('express');
const router = express.Router();
const { auth, validate } = require('../middleware');
const payoutController = require('../controllers/payoutController');

router.get('/payouts/method', auth, payoutController.getPayoutMethod);
router.put('/payouts/method', auth, validate.payoutMethod, payoutController.updatePayoutMethod);
router.get('/payouts', auth, payoutController.getPayouts);
router.post('/payouts/request', auth, validate.payoutRequest, payoutController.requestPayout);

module.exports = router;

// controllers/payoutController.js
const requestPayout = async (req, res) => {
  try {
    const { amount } = req.body;
    const vendorId = req.vendor._id;
    
    // Check payout method exists and is verified
    const vendor = await Vendor.findById(vendorId);
    if (!vendor.payoutMethod || !vendor.payoutMethod.isVerified) {
      return res.status(400).json({
        success: false,
        message: 'Please configure and verify a payout method first'
      });
    }
    
    // Check available balance
    const ledger = await LedgerService.getVendorLedger(vendorId);
    if (ledger.availableBalance < amount) {
      return res.status(400).json({
        success: false,
        message: 'Insufficient available balance'
      });
    }
    
    // Check minimum amount
    if (amount < 100) {
      return res.status(400).json({
        success: false,
        message: 'Minimum payout amount is ₹100'
      });
    }
    
    // Create payout request
    const payout = await Payout.create({
      vendor: vendorId,
      amount,
      status: 'pending',
      payoutMethod: {
        type: vendor.payoutMethod.type,
        accountHolderName: vendor.payoutMethod.accountHolderName,
        bankName: vendor.payoutMethod.bankName,
        accountNumber: maskAccountNumber(vendor.payoutMethod.accountNumber),
        ifscCode: vendor.payoutMethod.ifscCode,
        upiId: vendor.payoutMethod.upiId
      },
      createdBy: vendorId
    });
    
    // Process via payment gateway (async)
    await PaymentService.processPayout(payout);
    
    res.status(201).json({
      success: true,
      message: 'Payout request submitted successfully',
      data: payout
    });
    
  } catch (error) {
    console.error('Payout request error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to process payout request'
    });
  }
};

module.exports = { requestPayout, /* ... */ };
```

---

## 8. Testing Checklist

- [ ] Get payout method returns 404 when not set
- [ ] Update payout method validates all fields
- [ ] Account numbers 9-18 digits only
- [ ] IFSC code 11 characters format
- [ ] UPI ID contains @ symbol
- [ ] Payout request validates minimum amount
- [ ] Payout request checks available balance
- [ ] Payout request requires verified method
- [ ] Rate limiting works (5 second cooldown)
- [ ] Account numbers encrypted in database
- [ ] Account numbers masked in API responses
- [ ] Payout status transitions work correctly
- [ ] Bank reference captured on completion
- [ ] Failure reason captured on failure

---

For questions or issues, contact the backend team.
