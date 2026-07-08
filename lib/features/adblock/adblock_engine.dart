import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 广告过滤规则类型
enum RuleType {
  urlBlock,      // URL拦截
  urlAllow,      // URL白名单
  cssHide,       // CSS元素隐藏
  cssAllow,      // CSS元素白名单
  scriptInject,  // 脚本注入
  headerModify,  // 头修改
}

/// 单条广告过滤规则
class AdBlockRule {
  final String id;
  final RuleType type;
  final String pattern;          // 匹配模式（正则或通配符）
  final List<String> domains;    // 适用域名（空=所有域名）
  final List<String> excludeDomains; // 排除域名
  final String? cssSelector;     // CSS选择器（cssHide类型使用）
  final bool isRegex;            // 是否正则表达式
  final bool isImportant;        // 是否!important
  final String source;           // 规则来源

  AdBlockRule({
    required this.id,
    required this.type,
    required this.pattern,
    this.domains = const [],
    this.excludeDomains = const [],
    this.cssSelector,
    this.isRegex = false,
    this.isImportant = false,
    this.source = 'custom',
  });

  AdBlockRule copyWith({
    String? id,
    RuleType? type,
    String? pattern,
    List<String>? domains,
    List<String>? excludeDomains,
    String? cssSelector,
    bool? isRegex,
    bool? isImportant,
    String? source,
  }) {
    return AdBlockRule(
      id: id ?? this.id,
      type: type ?? this.type,
      pattern: pattern ?? this.pattern,
      domains: domains ?? this.domains,
      excludeDomains: excludeDomains ?? this.excludeDomains,
      cssSelector: cssSelector ?? this.cssSelector,
      isRegex: isRegex ?? this.isRegex,
      isImportant: isImportant ?? this.isImportant,
      source: source ?? this.source,
    );
  }
}

/// 布隆过滤器（轻量级实现）
class BloomFilter {
  final List<int> _bits;
  final int size;
  final int hashCount;

  BloomFilter(this.size, this.hashCount) : _bits = List<int>.filled((size / 32).ceil(), 0);

  int _hash(String value, int seed) {
    var hash = seed * 2654435761;
    for (var i = 0; i < value.length; i++) {
      hash ^= value.codeUnitAt(i);
      hash *= 2654435761;
    }
    return (hash & 0x7fffffff) % size;
  }

  void add(String value) {
    for (var i = 0; i < hashCount; i++) {
      final position = _hash(value, i + 1);
      final index = position ~/ 32;
      final bit = position % 32;
      _bits[index] |= (1 << bit);
    }
  }

  bool mightContain(String value) {
    for (var i = 0; i < hashCount; i++) {
      final position = _hash(value, i + 1);
      final index = position ~/ 32;
      final bit = position % 32;
      if ((_bits[index] & (1 << bit)) == 0) {
        return false;
      }
    }
    return true;
  }

  void clear() {
    for (var i = 0; i < _bits.length; i++) {
      _bits[i] = 0;
    }
  }
}

/// 广告过滤引擎状态
class AdBlockState {
  final bool enabled;
  final List<AdBlockRule> rules;
  final int blockedCount;
  final List<String> recentBlocked;
  final Map<String, int> blockStats;

  AdBlockState({
    this.enabled = true,
    this.rules = const [],
    this.blockedCount = 0,
    this.recentBlocked = const [],
    this.blockStats = const {},
  });

  AdBlockState copyWith({
    bool? enabled,
    List<AdBlockRule>? rules,
    int? blockedCount,
    List<String>? recentBlocked,
    Map<String, int>? blockStats,
  }) {
    return AdBlockState(
      enabled: enabled ?? this.enabled,
      rules: rules ?? this.rules,
      blockedCount: blockedCount ?? this.blockedCount,
      recentBlocked: recentBlocked ?? this.recentBlocked,
      blockStats: blockStats ?? this.blockStats,
    );
  }
}

/// 广告过滤引擎
class AdBlockEngine extends StateNotifier<AdBlockState> {
  BloomFilter? _urlBloomFilter;
  Map<String, List<AdBlockRule>> _domainRuleCache = {};
  List<AdBlockRule> _cssRules = [];
  List<AdBlockRule> _urlBlockRules = [];
  List<AdBlockRule> _urlAllowRules = [];

  AdBlockEngine() : super(AdBlockState());

  /// 初始化引擎，加载默认规则
  Future<void> initialize() async {
    _urlBloomFilter = BloomFilter(200000, 5);
    await _loadDefaultRules();
  }

  /// 加载默认规则（内置基础规则集）
  Future<void> _loadDefaultRules() async {
    final defaultRules = _getBuiltInRules();
    await loadRules(defaultRules);
  }

  /// 内置基础规则
  List<AdBlockRule> _getBuiltInRules() {
    final rules = <AdBlockRule>[];
    var id = 0;

    // 常见广告域名通配
    final adDomains = [
      '*.doubleclick.net',
      '*.googlesyndication.com',
      '*.googleadservices.com',
      '*.adnxs.com',
      '*.adroll.com',
      '*.adsrvr.org',
      '*.advertising.com',
      '*.admob.com',
      '*.adsense.com',
      '*.adform.net',
      '*.exoclick.com',
      '*.outbrain.com',
      '*.taboola.com',
      '*.mgid.com',
      '*.adsafeprotected.com',
      '*.scorecardresearch.com',
      '*.quantcount.com',
      '*.facebook.com/tr',
      '*.pixelsdk.com',
      '*.chartbeat.com',
    ];

    for (final domain in adDomains) {
      rules.add(AdBlockRule(
        id: 'builtin_url_${id++}',
        type: RuleType.urlBlock,
        pattern: domain,
        source: 'builtin',
      ));
    }

    // 常见广告元素CSS选择器
    final cssSelectors = [
      '.ad',
      '.ads',
      '.advertisement',
      '.advertising',
      '.ad-banner',
      '.ad-container',
      '.ad-wrapper',
      '.ad-box',
      '.ad-block',
      '.ad-placement',
      '.google-ad',
      '.google_ads',
      'div[class*="ad-"]',
      'div[class*="-ad"]',
      'iframe[src*="ads"]',
      '.banner-ads',
      '.popup-ads',
      '.floating-ad',
      '.sidebar-ad',
      '#ad_banner',
    ];

    for (final selector in cssSelectors) {
      rules.add(AdBlockRule(
        id: 'builtin_css_${id++}',
        type: RuleType.cssHide,
        pattern: selector,
        cssSelector: selector,
        source: 'builtin',
      ));
    }

    return rules;
  }

  /// 加载规则集
  Future<void> loadRules(List<AdBlockRule> newRules) async {
    _urlBloomFilter?.clear();
    _domainRuleCache.clear();
    _cssRules = [];
    _urlBlockRules = [];
    _urlAllowRules = [];

    for (final rule in newRules) {
      switch (rule.type) {
        case RuleType.urlBlock:
          _urlBlockRules.add(rule);
          _urlBloomFilter?.add(rule.pattern);
          break;
        case RuleType.urlAllow:
          _urlAllowRules.add(rule);
          break;
        case RuleType.cssHide:
        case RuleType.cssAllow:
          _cssRules.add(rule);
          break;
        case RuleType.scriptInject:
        case RuleType.headerModify:
          break;
      }

      // 按域名分组缓存
      for (final domain in rule.domains) {
        _domainRuleCache.putIfAbsent(domain, () => []).add(rule);
      }
    }

    state = state.copyWith(rules: newRules);
  }

  /// 检查URL是否应该被拦截
  bool shouldBlock(String url, String pageUrl) {
    if (!state.enabled) return false;

    final pageDomain = _extractDomain(pageUrl);

    // 先检查白名单
    for (final rule in _urlAllowRules) {
      if (_matchDomainRule(rule, pageDomain) && _matchUrlPattern(rule.pattern, url)) {
        return false;
      }
    }

    // 快速检查布隆过滤器
    if (_urlBloomFilter != null) {
      if (!_urlBloomFilter!.mightContain(url) &&
          !_urlBloomFilter!.mightContain(_extractDomain(url))) {
        // 可能未命中，但不能确定，继续精确匹配
      }
    }

    // 精确匹配URL拦截规则
    for (final rule in _urlBlockRules) {
      if (rule.domains.isNotEmpty && !_matchDomainRule(rule, pageDomain)) {
        continue;
      }

      if (_matchUrlPattern(rule.pattern, url)) {
        _recordBlock(url, rule);
        return true;
      }
    }

    return false;
  }

  /// 获取当前页面需要注入的CSS隐藏规则
  List<String> getCssHideSelectors(String pageUrl) {
    if (!state.enabled) return [];

    final pageDomain = _extractDomain(pageUrl);
    final selectors = <String>[];

    for (final rule in _cssRules) {
      if (rule.type != RuleType.cssHide) continue;

      // 检查域名限制
      if (rule.domains.isNotEmpty && !_matchDomainRule(rule, pageDomain)) {
        continue;
      }

      // 检查排除域名
      if (rule.excludeDomains.isNotEmpty && _matchExcludeDomain(rule, pageDomain)) {
        continue;
      }

      if (rule.cssSelector != null) {
        selectors.add(rule.cssSelector!);
      }
    }

    return selectors;
  }

  /// 生成CSS注入代码
  String generateCssInjection(String pageUrl) {
    final selectors = getCssHideSelectors(pageUrl);
    if (selectors.isEmpty) return '';

    return '''
${selectors.join(',\n')} {
  display: none !important;
  visibility: hidden !important;
  opacity: 0 !important;
  width: 0 !important;
  height: 0 !important;
  margin: 0 !important;
  padding: 0 !important;
}
''';
  }

  /// URL模式匹配
  bool _matchUrlPattern(String pattern, String url) {
    if (pattern.contains('*')) {
      // 通配符匹配
      final regex = _wildcardToRegex(pattern);
      return RegExp(regex, caseSensitive: false).hasMatch(url);
    } else {
      // 精确包含匹配
      return url.toLowerCase().contains(pattern.toLowerCase());
    }
  }

  /// 域名规则匹配
  bool _matchDomainRule(AdBlockRule rule, String pageDomain) {
    if (rule.domains.isEmpty) return true;

    for (final domain in rule.domains) {
      if (domain.startsWith('*.')) {
        final baseDomain = domain.substring(2);
        if (pageDomain == baseDomain || pageDomain.endsWith('.$baseDomain')) {
          return true;
        }
      } else {
        if (pageDomain == domain || pageDomain.endsWith('.$domain')) {
          return true;
        }
      }
    }
    return false;
  }

  /// 排除域名匹配
  bool _matchExcludeDomain(AdBlockRule rule, String pageDomain) {
    for (final domain in rule.excludeDomains) {
      if (domain.startsWith('*.')) {
        final baseDomain = domain.substring(2);
        if (pageDomain == baseDomain || pageDomain.endsWith('.$baseDomain')) {
          return true;
        }
      } else {
        if (pageDomain == domain || pageDomain.endsWith('.$domain')) {
          return true;
        }
      }
    }
    return false;
  }

  /// 提取域名
  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (_) {
      return url;
    }
  }

  /// 通配符转正则
  String _wildcardToRegex(String pattern) {
    final escaped = pattern
        .replaceAll('.', r'\.')
        .replaceAll('*', '.*')
        .replaceAll('?', '.');
    return '^$escaped\$';
  }

  /// 记录拦截
  void _recordBlock(String url, AdBlockRule rule) {
    final newRecent = List<String>.from(state.recentBlocked);
    newRecent.insert(0, url);
    if (newRecent.length > 50) newRecent.removeLast();

    final newStats = Map<String, int>.from(state.blockStats);
    final domain = _extractDomain(url);
    newStats[domain] = (newStats[domain] ?? 0) + 1;

    state = state.copyWith(
      blockedCount: state.blockedCount + 1,
      recentBlocked: newRecent,
      blockStats: newStats,
    );
  }

  /// 启用/禁用广告过滤
  void setEnabled(bool enabled) {
    state = state.copyWith(enabled: enabled);
  }

  /// 添加自定义规则
  void addRule(AdBlockRule rule) {
    final newRules = List<AdBlockRule>.from(state.rules);
    newRules.add(rule);
    loadRules(newRules);
  }

  /// 移除规则
  void removeRule(String ruleId) {
    final newRules = state.rules.where((r) => r.id != ruleId).toList();
    loadRules(newRules);
  }

  /// 清空统计
  void clearStats() {
    state = state.copyWith(
      blockedCount: 0,
      recentBlocked: [],
      blockStats: {},
    );
  }
}

final adBlockEngineProvider =
    StateNotifierProvider<AdBlockEngine, AdBlockState>((ref) {
  final engine = AdBlockEngine();
  engine.initialize();
  return engine;
});