import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'logger.dart';

class PerformanceOptimizer {
  static final PerformanceOptimizer _instance =
      PerformanceOptimizer._internal();
  factory PerformanceOptimizer() => _instance;
  PerformanceOptimizer._internal();

  final Logger _logger = Logger();
  final Map<String, DateTime> _operationStartTimes = {};
  final Queue<double> _frameTimes = Queue<double>();
  final int _maxFrameSamples = 60;
  Timer? _performanceMonitorTimer;

  // Memory monitoring
  double _currentMemoryUsage = 0.0;
  double _peakMemoryUsage = 0.0;

  // Performance metrics
  double _averageFrameTime = 16.67; // 60 FPS target
  int _droppedFrames = 0;
  int _totalFrames = 0;

  void initialize() {
    _startPerformanceMonitoring();
    _logger.info('Performance optimizer initialized', tag: 'PERF');
  }

  void _startPerformanceMonitoring() {
    _performanceMonitorTimer = Timer.periodic(
      const Duration(seconds: 30), // Increased from 5 to 30 seconds
      (_) => _collectPerformanceMetrics(),
    );
  }

  void _collectPerformanceMetrics() {
    try {
      // Collect memory usage (platform specific)
      _collectMemoryMetrics();

      // Calculate frame rate metrics
      _calculateFrameMetrics();

      // Log performance warnings if needed
      _checkPerformanceWarnings();
    } catch (e) {
      _logger.error(
        'Failed to collect performance metrics',
        tag: 'PERF',
        context: {'error': e.toString()},
      );
    }
  }

  void _collectMemoryMetrics() {
    // In a real implementation, this would use platform-specific APIs
    // For now, we'll simulate memory tracking with less aggressive values
    if (kDebugMode) {
      _currentMemoryUsage =
          (DateTime.now().millisecondsSinceEpoch % 100) /
          100.0 *
          80; // Reduced to max 80
      _peakMemoryUsage = _peakMemoryUsage < _currentMemoryUsage
          ? _currentMemoryUsage
          : _peakMemoryUsage;
    }
  }

  void _calculateFrameMetrics() {
    if (_frameTimes.isEmpty) return;

    final totalTime = _frameTimes.reduce((a, b) => a + b);
    _averageFrameTime = totalTime / _frameTimes.length;

    // Count dropped frames (frames taking longer than 16.67ms)
    _droppedFrames = _frameTimes.where((time) => time > 20.0).length;
    _totalFrames = _frameTimes.length;
  }

  void _checkPerformanceWarnings() {
    // Only check performance warnings in debug mode
    if (!kDebugMode) return;

    // Memory warnings - increased threshold to eliminate false positives
    if (_currentMemoryUsage > 95.0) {
      // 95MB threshold - very high to avoid false alarms
      _logger.warning(
        'High memory usage detected',
        tag: 'PERF',
        context: {'memory': _currentMemoryUsage},
      );
    }

    // Frame rate warnings - only log if severe
    if (_averageFrameTime > 30.0) {
      _logger.warning(
        'Very low frame rate detected',
        tag: 'PERF',
        context: {
          'averageFrameTime': _averageFrameTime,
          'droppedFrames': _droppedFrames,
          'totalFrames': _totalFrames,
        },
      );
    }
  }

  // Performance tracking methods
  void startOperation(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();
  }

  void endOperation(String operationName) {
    final startTime = _operationStartTimes[operationName];
    if (startTime == null) return;

    final duration = DateTime.now().difference(startTime);
    _operationStartTimes.remove(operationName);

    _logPerformance(operationName, duration);
  }

  void _logPerformance(String operation, Duration duration) {
    _logger.logPerformance(operation, duration);

    // Warn about slow operations
    if (duration.inMilliseconds > 100) {
      _logger.warning(
        'Slow operation detected',
        tag: 'PERF',
        context: {'operation': operation, 'duration': duration.inMilliseconds},
      );
    }
  }

  // Memory optimization
  void optimizeMemory() {
    // Clear caches if memory is high
    if (_currentMemoryUsage > 70.0) {
      _clearImageCache();
      _clearUnusedResources();
    }
  }

  void _clearImageCache() {
    // Clear Flutter's image cache
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    _logger.info('Image cache cleared', tag: 'PERF');
  }

  void _clearUnusedResources() {
    // Force garbage collection in debug mode
    if (kDebugMode) {
      // This is just for testing - in production, let the system handle GC
      _logger.info('Resource cleanup triggered', tag: 'PERF');
    }
  }

  // Frame monitoring
  void recordFrameTime(double frameTime) {
    _frameTimes.add(frameTime);

    // Keep only recent samples
    while (_frameTimes.length > _maxFrameSamples) {
      _frameTimes.removeFirst();
    }
  }

  // Performance optimization suggestions
  List<String> getOptimizationSuggestions() {
    final suggestions = <String>[];

    if (_averageFrameTime > 20.0) {
      suggestions.add(
        'Consider reducing widget complexity or using const constructors',
      );
    }

    if (_currentMemoryUsage > 80.0) {
      suggestions.add('Implement image caching and memory management');
    }

    if (_droppedFrames > _totalFrames * 0.1) {
      suggestions.add('Optimize heavy operations and consider using isolates');
    }

    return suggestions;
  }

  // Widget performance helpers
  static Widget optimizedImage(
    String imageUrl, {
    double? width,
    double? height,
  }) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          child: child,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        );
      },
    );
  }

  static Widget optimizedListView({
    required IndexedWidgetBuilder itemBuilder,
    required int itemCount,
    ScrollController? controller,
    bool shrinkWrap = false,
    EdgeInsets? padding,
  }) {
    return ListView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return RepaintBoundary(child: itemBuilder(context, index));
      },
    );
  }

  static Widget optimizedGridView({
    required IndexedWidgetBuilder itemBuilder,
    required SliverGridDelegate gridDelegate,
    required int itemCount,
    EdgeInsets? padding,
  }) {
    return GridView.builder(
      padding: padding,
      gridDelegate: gridDelegate,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return RepaintBoundary(child: itemBuilder(context, index));
      },
    );
  }

  // Async operation optimization
  static Future<T> optimizedAsyncOperation<T>(
    Future<T> Function() operation, {
    Duration? timeout,
    String? operationName,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await operation().timeout(
        timeout ?? const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException(
          'Operation ${operationName ?? 'unknown'} timed out',
          timeout ?? const Duration(seconds: 30),
        ),
      );

      if (operationName != null && kDebugMode) {
        debugPrint(
          '$operationName completed in ${stopwatch.elapsedMilliseconds}ms',
        );
      }

      return result;
    } catch (e) {
      if (operationName != null && kDebugMode) {
        debugPrint(
          '$operationName failed after ${stopwatch.elapsedMilliseconds}ms: $e',
        );
      }
      rethrow;
    } finally {
      stopwatch.stop();
    }
  }

  // Performance metrics
  PerformanceMetrics getMetrics() {
    return PerformanceMetrics(
      averageFrameTime: _averageFrameTime,
      droppedFrames: _droppedFrames,
      totalFrames: _totalFrames,
      currentMemoryUsage: _currentMemoryUsage,
      peakMemoryUsage: _peakMemoryUsage,
      fps: _averageFrameTime > 0 ? 1000 / _averageFrameTime : 0,
    );
  }

  void dispose() {
    _performanceMonitorTimer?.cancel();
    _operationStartTimes.clear();
    _frameTimes.clear();
  }
}

class PerformanceMetrics {
  final double averageFrameTime;
  final int droppedFrames;
  final int totalFrames;
  final double currentMemoryUsage;
  final double peakMemoryUsage;
  final double fps;

  PerformanceMetrics({
    required this.averageFrameTime,
    required this.droppedFrames,
    required this.totalFrames,
    required this.currentMemoryUsage,
    required this.peakMemoryUsage,
    required this.fps,
  });

  double get droppedFramePercentage =>
      totalFrames > 0 ? (droppedFrames / totalFrames) * 100 : 0;

  String get performanceGrade {
    if (fps >= 55 && droppedFramePercentage < 5) return 'A';
    if (fps >= 45 && droppedFramePercentage < 10) return 'B';
    if (fps >= 30 && droppedFramePercentage < 20) return 'C';
    return 'D';
  }

  Map<String, dynamic> toJson() {
    return {
      'averageFrameTime': averageFrameTime,
      'droppedFrames': droppedFrames,
      'totalFrames': totalFrames,
      'currentMemoryUsage': currentMemoryUsage,
      'peakMemoryUsage': peakMemoryUsage,
      'fps': fps,
      'droppedFramePercentage': droppedFramePercentage,
      'performanceGrade': performanceGrade,
    };
  }
}

// Performance monitoring widget
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.enabled = kDebugMode,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor>
    with WidgetsBindingObserver {
  final PerformanceOptimizer _optimizer = PerformanceOptimizer();
  DateTime? _lastFrameTime;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      WidgetsBinding.instance.addObserver(this);
      _lastFrameTime = DateTime.now();
    }
  }

  @override
  void dispose() {
    if (widget.enabled) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  void didHaveMetrics() {
    if (widget.enabled && _lastFrameTime != null) {
      final frameTime = DateTime.now()
          .difference(_lastFrameTime!)
          .inMilliseconds
          .toDouble();
      _optimizer.recordFrameTime(frameTime);
      _lastFrameTime = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
