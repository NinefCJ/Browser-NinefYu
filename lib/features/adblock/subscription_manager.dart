import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'adblock_engine.dart';

/// 规则订阅源
class RuleSubscription {
  final String id;
  final String name;
  final String url;
  final String description;
  final bool enabled;
  final String? lastUpdated;
  final int? ruleCount;
  final String? version;

  RuleSubscription({
    required this.id,
    required this.name,
    required this.url,
    this.description = '',
    this.enabled = true,
    this.lastUpdated,
    this.ruleCount,
    this.version,
  });

  RuleSubscription copyWith({
    String? id,
    String? name,
    String? url,
    String? description,
    bool? enabled,
    String? lastUpdated,
    int? ruleCount,
    String? version,
  }) {
    return RuleSubscription(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      ruleCount: ruleCount ?? this.ruleCount,
      version: version ?? this.version,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'description': description,
    'enabled': enabled,
    'lastUpdated': lastUpdated,
    'ruleCount': ruleCount,
    'version': version,
  };
}

/// 预置的规则订阅源
class BuiltInSubscriptions {
  static final List<RuleSubscription> all = [
    RuleSubscription(
      id: 'easylist',
      name: 'EasyList',
      url: 'https://easylist.to/easylist/easylist.txt',
      description: '通用广告过滤规则，适用于大部分英文网站',
    ),
    RuleSubscription(
      id: 'easyprivacy',
      name: 'EasyPrivacy',
      url: 'https://easylist.to/easylist/easyprivacy.txt',
      description: '隐私保护规则，拦截追踪和统计脚本',
    ),
    RuleSubscription(
      id: 'adguard_base',
      name: 'AdGuard Base',
      url: 'https://filters.adtidy.org/extension/chromium/filters/2.txt',
      description: 'AdGuard 基础广告过滤规则',
    ),
    RuleSubscription(
      id: 'ublock_filters',
      name: 'uBlock Origin Filters',
      url: 'https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt',
      description: 'uBlock Origin 内置过滤规则',
    ),
    RuleSubscription(
      id: 'easylist_china',
      name: 'EasyList China',
      url: 'https://easylist-downloads.adblockplus.org/easylistchina.txt',
      description: '中文网站广告过滤规则',
    ),
    RuleSubscription(
      id: 'cjx_annoyance',
      name: 'CJX\'s Annoyance List',
      url: 'https://raw.githubusercontent.com/cjx82630/cjxlist/master/cjx-annoyance.txt',
      description: '国内常见骚扰元素过滤规则',
    ),
  ];
}

/// 规则解析器 - 解析 Adblock Plus 格式的规则文件
class AdBlockRuleParser {
  /// 解析规则文件内容
  List<AdBlockRule> parse(String content, String source) {
    final rules = <AdBlockRule>[];
    final lines = LineSplitter.split(content);
    var id = 0;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('!') || trimmed.startsWith('[Adblock')) {
        continue;
      }

      final rule = _parseLine(trimmed, '${source}_${id++}', source);
      if (rule != null) {
        rules.add(rule);
      }
    }

    return rules;
  }

  /// 解析单行规则
  AdBlockRule? _parseLine(String line, String id, String source) {
    // 检查是否是CSS元素隐藏规则
    if (line.contains('##') || line.contains('#@#')) {
      return _parseElementHidingRule(line, id, source);
    }

    // URL过滤规则
    return _parseUrlRule(line, id, source);
  }

  /// 解析元素隐藏规则
  AdBlockRule? _parseElementHidingRule(String line, String id, String source) {
    bool isException = false;
    String domainsPart = '';
    String selectorPart = '';

    if (line.contains('#@#')) {
      // 例外规则
      isException = true;
      final parts = line.split('#@#');
      domainsPart = parts.first;
      selectorPart = parts.last;
    } else {
      // 普通隐藏规则
      final parts = line.split('##');
      domainsPart = parts.first;
      selectorPart = parts.last;
    }

    final domains = <String>[];
    final excludeDomains = <String>[];

    if (domainsPart.isNotEmpty) {
      final domainList = domainsPart.split(',');
      for (final d in domainList) {
        final domain = d.trim();
        if (domain.startsWith('~')) {
          excludeDomains.add(domain.substring(1));
        } else {
          domains.add(domain);
        }
      }
    }

    return AdBlockRule(
      id: id,
      type: isException ? RuleType.cssAllow : RuleType.cssHide,
      pattern: selectorPart,
      cssSelector: selectorPart,
      domains: domains,
      excludeDomains: excludeDomains,
      source: source,
    );
  }

  /// 解析URL过滤规则
  AdBlockRule? _parseUrlRule(String line, String id, String source) {
    var pattern = line;
    final domains = <String>[];
    final excludeDomains = <String>[];
    var isImportant = false;
    var isException = false;

    // 检查是否是白名单规则
    if (pattern.startsWith('@@')) {
      isException = true;
      pattern = pattern.substring(2);
    }

    // 检查$选项
    final dollarIndex = pattern.indexOf('\$');
    if (dollarIndex > 0) {
      final options = pattern.substring(dollarIndex + 1);
      pattern = pattern.substring(0, dollarIndex);

      // 解析选项
      final optionList = options.split(',');
      for (final opt in optionList) {
        final trimmed = opt.trim();
        if (trimmed == 'important') {
          isImportant = true;
        } else if (trimmed.startsWith('domain=')) {
          final domainStr = trimmed.substring(7);
          final domainList = domainStr.split('|');
          for (final d in domainList) {
            if (d.startsWith('~')) {
              excludeDomains.add(d.substring(1));
            } else {
              domains.add(d);
            }
          }
        }
      }
    }

    // 去除首尾的分隔符
    var isRegex = false;
    if (pattern.startsWith('/') && pattern.endsWith('/') && pattern.length > 2) {
      isRegex = true;
      pattern = pattern.substring(1, pattern.length - 1);
    }

    return AdBlockRule(
      id: id,
      type: isException ? RuleType.urlAllow : RuleType.urlBlock,
      pattern: pattern,
      domains: domains,
      excludeDomains: excludeDomains,
      isRegex: isRegex,
      isImportant: isImportant,
      source: source,
    );
  }
}

/// 订阅管理器状态
class SubscriptionManagerState {
  final List<RuleSubscription> subscriptions;
  final bool isUpdating;
  final String? lastUpdateTime;
  final String? errorMessage;

  SubscriptionManagerState({
    this.subscriptions = const [],
    this.isUpdating = false,
    this.lastUpdateTime,
    this.errorMessage,
  });

  SubscriptionManagerState copyWith({
    List<RuleSubscription>? subscriptions,
    bool? isUpdating,
    String? lastUpdateTime,
    String? errorMessage,
  }) {
    return SubscriptionManagerState(
      subscriptions: subscriptions ?? this.subscriptions,
      isUpdating: isUpdating ?? this.isUpdating,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// 订阅管理器
class SubscriptionManager extends StateNotifier<SubscriptionManagerState> {
  final Dio _dio;
  final AdBlockEngine _adBlockEngine;
  final AdBlockRuleParser _parser = AdBlockRuleParser();

  SubscriptionManager(this._dio, this._adBlockEngine)
      : super(SubscriptionManagerState(subscriptions: BuiltInSubscriptions.all));

  /// 添加订阅
  void addSubscription(RuleSubscription subscription) {
    final subs = List<RuleSubscription>.from(state.subscriptions);
    subs.add(subscription);
    state = state.copyWith(subscriptions: subs);
  }

  /// 移除订阅
  void removeSubscription(String id) {
    final subs = state.subscriptions.where((s) => s.id != id).toList();
    state = state.copyWith(subscriptions: subs);
  }

  /// 切换订阅启用状态
  void toggleSubscription(String id) {
    final subs = state.subscriptions.map((s) {
      if (s.id == id) {
        return s.copyWith(enabled: !s.enabled);
      }
      return s;
    }).toList();
    state = state.copyWith(subscriptions: subs);
  }

  /// 更新单个订阅
  Future<RuleSubscription?> updateSubscription(String id) async {
    final sub = state.subscriptions.firstWhere((s) => s.id == id);

    try {
      final response = await _dio.get<String>(sub.url,
          options: Options(responseType: ResponseType.plain));

      if (response.data != null) {
        final rules = _parser.parse(response.data!, sub.id);

        // 更新订阅信息
        final updatedSub = sub.copyWith(
          lastUpdated: DateTime.now().toIso8601String(),
          ruleCount: rules.length,
        );

        final subs = state.subscriptions.map((s) {
          if (s.id == id) return updatedSub;
          return s;
        }).toList();

        state = state.copyWith(subscriptions: subs);

        return updatedSub;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: '更新${sub.name}失败: $e');
    }
    return null;
  }

  /// 更新所有已启用的订阅
  Future<void> updateAllSubscriptions() async {
    state = state.copyWith(isUpdating: true, errorMessage: null);

    try {
      final allRules = <AdBlockRule>[];

      for (final sub in state.subscriptions) {
        if (!sub.enabled) continue;

        try {
          final response = await _dio.get<String>(sub.url,
              options: Options(responseType: ResponseType.plain));

          if (response.data != null) {
            final rules = _parser.parse(response.data!, sub.id);
            allRules.addAll(rules);

            // 更新订阅信息
            final updatedSub = sub.copyWith(
              lastUpdated: DateTime.now().toIso8601String(),
              ruleCount: rules.length,
            );

            final subs = state.subscriptions.map((s) {
              if (s.id == sub.id) return updatedSub;
              return s;
            }).toList();

            state = state.copyWith(subscriptions: subs);
          }
        } catch (_) {
          continue;
        }
      }

      // 加载所有规则到引擎
      await _adBlockEngine.loadRules(allRules);

      state = state.copyWith(
        isUpdating: false,
        lastUpdateTime: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        errorMessage: '更新失败: $e',
      );
    }
  }

  /// 应用所有已启用的订阅规则
  Future<void> applyEnabledRules() async {
    final allRules = <AdBlockRule>[];

    // 先添加内置规则
    allRules.addAll(_adBlockEngine.state.rules.where((r) => r.source == 'builtin'));

    // 加载已启用订阅的规则
    for (final sub in state.subscriptions) {
      if (!sub.enabled) continue;
      // 实际实现中应从缓存读取，这里跳过
    }

    await _adBlockEngine.loadRules(allRules);
  }
}

final subscriptionManagerProvider =
    StateNotifierProvider<SubscriptionManager, SubscriptionManagerState>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 30),
  ));
  final adBlockEngine = ref.read(adBlockEngineProvider.notifier);
  return SubscriptionManager(dio, adBlockEngine);
});