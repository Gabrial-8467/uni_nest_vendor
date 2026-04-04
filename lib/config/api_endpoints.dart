import 'vendor_config.dart';

class ApiEndpoints {
  // Base URL
  static String get baseUrl => VendorConfig.apiBaseUrl;

  // Authentication Endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String changePassword = '/auth/change-password';

  // Profile Endpoints
  static const String profile = '/profile';
  static const String dashboard = '/dashboard';
  static const String ledger = '/ledger';
  static const String payouts = '/payouts';

  // Product Endpoints
  static const String products = '/products';
  static String productById(String id) => '/products/$id';

  // Order Endpoints
  static const String orders = '/orders';
  static String orderById(String id) => '/orders/$id';
  static String updateOrderStatus(String id) => '/orders/$id/status';

  // Analytics Endpoints
  static const String analytics = '/analytics';

  // Reviews Endpoints
  static const String reviews = '/reviews';
  static String productReviews(String productId) =>
      '/reviews/products/$productId';

  // Upload Endpoints
  static const String uploadAvatar = '/upload/avatar';
  static const String uploadProductImages = '/upload/product-images';
  static const String uploadDocuments = '/upload/documents';

  // Notification Endpoints
  static const String notifications = '/notifications';
  static String notificationById(String id) => '/notifications/$id';
  static const String markAllNotificationsRead = '/notifications/mark-all-read';
  static const String clearAllNotifications = '/notifications/clear-all';
  static String markNotificationRead(String id) => '/notifications/$id/read';
  static const String notificationSettings = '/notifications/settings';
  static const String sendNotification = '/notifications/send';

  // Version Check Endpoint
  static const String versionCheck = '/version/check';
}

class ApiMethods {
  static const String get = 'GET';
  static const String post = 'POST';
  static const String put = 'PUT';
  static const String delete = 'DELETE';
  static const String patch = 'PATCH';
}

class ApiHeaders {
  static const String contentType = 'Content-Type';
  static const String authorization = 'Authorization';
  static const String accept = 'Accept';
  static const String userAgent = 'User-Agent';
  static const String platform = 'Platform';

  static const String applicationJson = 'application/json';
  static const String multipartFormData = 'multipart/form-data';
}

class QueryParameters {
  // Pagination
  static const String page = 'page';
  static const String limit = 'limit';

  // Product Filters
  static const String search = 'search';
  static const String category = 'category';
  static const String status = 'status';
  static const String isAvailable = 'isAvailable';
  static const String sortBy = 'sortBy';
  static const String sortOrder = 'sortOrder';

  // Order Filters
  static const String dateFrom = 'dateFrom';
  static const String dateTo = 'dateTo';

  // Analytics
  static const String period = 'period';

  // Reviews
  static const String rating = 'rating';
}

class ApiStatusCodes {
  static const int ok = 200;
  static const int created = 201;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int conflict = 409;
  static const int unprocessableEntity = 422;
  static const int internalServerError = 500;
  static const int serviceUnavailable = 503;
}

class BusinessTypes {
  static const String canteen = 'canteen';
  static const String restaurant = 'restaurant';
  static const String cafe = 'cafe';
  static const String foodTruck = 'food_truck';
  static const String other = 'other';
}

class ProductCategories {
  static const String breakfast = 'breakfast';
  static const String lunch = 'lunch';
  static const String dinner = 'dinner';
  static const String snacks = 'snacks';
  static const String beverages = 'beverages';
  static const String desserts = 'desserts';
  static const String combo = 'combo';
  static const String other = 'other';
  static const String southIndian = 'south indian';
  static const String northIndian = 'north indian';
  static const String chinese = 'chinese';
}

class OrderStatus {
  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String preparing = 'preparing';
  static const String ready = 'ready';
  static const String outForDelivery = 'out_for_delivery';
  static const String delivered = 'delivered';
  static const String cancelled = 'cancelled';
  static const String refunded = 'refunded';
}

class ProductStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
}

class AnalyticsPeriod {
  static const String daily = 'daily';
  static const String weekly = 'weekly';
  static const String monthly = 'monthly';
}

class SortOptions {
  static const String asc = 'asc';
  static const String desc = 'desc';
}

class ProductSortBy {
  static const String name = 'name';
  static const String price = 'price';
  static const String rating = 'rating';
  static const String orderCount = 'orderCount';
  static const String createdAt = 'createdAt';
}

class OrderSortBy {
  static const String orderNumber = 'orderNumber';
  static const String finalAmount = 'finalAmount';
  static const String status = 'status';
  static const String createdAt = 'createdAt';
}

class NotificationTypes {
  static const String order = 'order';
  static const String product = 'product';
  static const String payment = 'payment';
  static const String system = 'system';
  static const String promotion = 'promotion';
}

class NotificationStatus {
  static const String unread = 'unread';
  static const String read = 'read';
  static const String archived = 'archived';
}
