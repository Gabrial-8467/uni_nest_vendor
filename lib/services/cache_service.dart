import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../config/vendor_config.dart';
import '../utils/logger.dart';

class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;
  final String? etag;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.ttl,
    this.etag,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'ttl': ttl.inMilliseconds,
      'etag': etag,
    };
  }

  factory CacheEntry.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJson,
  ) {
    return CacheEntry<T>(
      data: fromJson(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      ttl: Duration(milliseconds: json['ttl']),
      etag: json['etag'],
    );
  }
}

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Logger _logger = Logger();
  SharedPreferences? _prefs;
  final Map<String, Timer> _cleanupTimers = {};

  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _logger.info('Cache service initialized', tag: 'CACHE');

      // Start periodic cleanup
      _startPeriodicCleanup();
    } catch (e) {
      _logger.error(
        'Failed to initialize cache service',
        tag: 'CACHE',
        context: {'error': e.toString()},
      );
    }
  }

  void _startPeriodicCleanup() {
    Timer.periodic(const Duration(hours: 1), (_) => cleanupExpiredEntries());
  }

  String _generateKey(String key, {Map<String, String>? params}) {
    if (params == null || params.isEmpty) return key;

    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    final paramString = sortedParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    final fullKey = '$key?$paramString';
    return sha256.convert(utf8.encode(fullKey)).toString();
  }

  Future<T?> get<T>(
    String key, {
    T Function(dynamic)? fromJson,
    Map<String, String>? params,
  }) async {
    if (_prefs == null) return null;

    try {
      final cacheKey = _generateKey(key, params: params);
      final cachedData = _prefs!.getString(cacheKey);

      if (cachedData == null) return null;

      final entryData = jsonDecode(cachedData) as Map<String, dynamic>;
      final entry = CacheEntry<T>.fromJson(
        entryData,
        fromJson ?? (data) => data,
      );

      if (entry.isExpired) {
        await remove(key, params: params);
        _logger.debug(
          'Cache entry expired and removed',
          tag: 'CACHE',
          context: {'key': cacheKey},
        );
        return null;
      }

      _logger.debug('Cache hit', tag: 'CACHE', context: {'key': cacheKey});

      return entry.data;
    } catch (e) {
      _logger.error(
        'Failed to get from cache',
        tag: 'CACHE',
        context: {'key': key, 'error': e.toString()},
      );
      return null;
    }
  }

  Future<void> set<T>(
    String key,
    T data, {
    Duration? ttl,
    String? etag,
    Map<String, String>? params,
    T Function(dynamic)? toJson,
  }) async {
    if (_prefs == null) return;

    try {
      final cacheKey = _generateKey(key, params: params);
      final cacheTtl = ttl ?? VendorConfig.cacheExpiration;

      final entry = CacheEntry<T>(
        data: data,
        timestamp: DateTime.now(),
        ttl: cacheTtl,
        etag: etag,
      );

      final serializedData = jsonEncode(entry.toJson());
      await _prefs!.setString(cacheKey, serializedData);

      // Set up cleanup timer for this entry
      _scheduleCleanup(cacheKey, cacheTtl);

      _logger.debug(
        'Data cached',
        tag: 'CACHE',
        context: {'key': cacheKey, 'ttl': cacheTtl.inMinutes},
      );
    } catch (e) {
      _logger.error(
        'Failed to cache data',
        tag: 'CACHE',
        context: {'key': key, 'error': e.toString()},
      );
    }
  }

  Future<void> remove(String key, {Map<String, String>? params}) async {
    if (_prefs == null) return;

    try {
      final cacheKey = _generateKey(key, params: params);
      await _prefs!.remove(cacheKey);

      _cleanupTimers.remove(cacheKey)?.cancel();

      _logger.debug(
        'Cache entry removed',
        tag: 'CACHE',
        context: {'key': cacheKey},
      );
    } catch (e) {
      _logger.error(
        'Failed to remove from cache',
        tag: 'CACHE',
        context: {'key': key, 'error': e.toString()},
      );
    }
  }

  Future<void> clear({String? prefix}) async {
    if (_prefs == null) return;

    try {
      if (prefix == null || prefix.isEmpty) {
        final keys = _prefs!.getKeys();
        for (final key in keys) {
          await _prefs!.remove(key);
          _cleanupTimers.remove(key)?.cancel();
        }
      } else {
        final keys = _prefs!.getKeys();
        for (final key in keys) {
          if (key.startsWith(prefix)) {
            await _prefs!.remove(key);
            _cleanupTimers.remove(key)?.cancel();
          }
        }
      }

      _logger.info(
        'Cache cleared',
        tag: 'CACHE',
        context: {'prefix': prefix ?? 'all'},
      );
    } catch (e) {
      _logger.error(
        'Failed to clear cache',
        tag: 'CACHE',
        context: {'prefix': prefix, 'error': e.toString()},
      );
    }
  }

  void _scheduleCleanup(String key, Duration ttl) {
    _cleanupTimers[key]?.cancel();

    _cleanupTimers[key] = Timer(ttl, () async {
      await remove(key);
    });
  }

  Future<void> cleanupExpiredEntries() async {
    if (_prefs == null) return;

    try {
      final keys = _prefs!.getKeys();
      int removedCount = 0;

      for (final key in keys) {
        final cachedData = _prefs!.getString(key);
        if (cachedData == null) continue;

        try {
          final entryData = jsonDecode(cachedData) as Map<String, dynamic>;
          final timestamp = DateTime.parse(entryData['timestamp']);
          final ttl = Duration(milliseconds: entryData['ttl']);

          if (DateTime.now().difference(timestamp) > ttl) {
            await _prefs!.remove(key);
            _cleanupTimers.remove(key)?.cancel();
            removedCount++;
          }
        } catch (e) {
          // Remove invalid entries
          await _prefs!.remove(key);
          _cleanupTimers.remove(key)?.cancel();
          removedCount++;
        }
      }

      if (removedCount > 0) {
        _logger.info(
          'Cleaned up expired cache entries',
          tag: 'CACHE',
          context: {'removed': removedCount},
        );
      }
    } catch (e) {
      _logger.error(
        'Failed to cleanup expired entries',
        tag: 'CACHE',
        context: {'error': e.toString()},
      );
    }
  }

  Future<CacheStats> getStats() async {
    if (_prefs == null) return CacheStats();

    try {
      final keys = _prefs!.getKeys();
      int totalEntries = 0;
      int expiredEntries = 0;
      int totalSize = 0;

      for (final key in keys) {
        final cachedData = _prefs!.getString(key);
        if (cachedData == null) continue;

        totalEntries++;
        totalSize += cachedData.length;

        try {
          final entryData = jsonDecode(cachedData) as Map<String, dynamic>;
          final timestamp = DateTime.parse(entryData['timestamp']);
          final ttl = Duration(milliseconds: entryData['ttl']);

          if (DateTime.now().difference(timestamp) > ttl) {
            expiredEntries++;
          }
        } catch (e) {
          expiredEntries++;
        }
      }

      return CacheStats(
        totalEntries: totalEntries,
        expiredEntries: expiredEntries,
        totalSize: totalSize,
      );
    } catch (e) {
      _logger.error(
        'Failed to get cache stats',
        tag: 'CACHE',
        context: {'error': e.toString()},
      );
      return CacheStats();
    }
  }

  void dispose() {
    for (final timer in _cleanupTimers.values) {
      timer.cancel();
    }
    _cleanupTimers.clear();
  }
}

class CacheStats {
  final int totalEntries;
  final int expiredEntries;
  final int totalSize;

  CacheStats({
    this.totalEntries = 0,
    this.expiredEntries = 0,
    this.totalSize = 0,
  });

  int get validEntries => totalEntries - expiredEntries;

  double get expirationRate =>
      totalEntries > 0 ? expiredEntries / totalEntries : 0.0;

  String get formattedSize {
    if (totalSize < 1024) {
      return '${totalSize}B';
    }
    if (totalSize < 1024 * 1024) {
      return '${(totalSize / 1024).toStringAsFixed(1)}KB';
    }
    return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
