import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 脚本注入时机
enum ScriptRunAt {
  documentStart,  // 文档开始加载时（head解析前）
  documentEnd,    // 文档加载完成时（DOMContentLoaded）
  documentIdle,   // 文档空闲时（load事件后）
}

/// 用户脚本元数据
class UserScriptMetadata {
  final String name;
  final String? namespace;
  final String? version;
  final String? description;
  final String? author;
  final List<String> matches;       // 匹配的URL模式
  final List<String> excludes;      // 排除的URL模式
  final List<String> includes;      // 包含的URL模式
  final ScriptRunAt runAt;
  final bool noFrames;
  final List<String> grant;         // 需要的GM API权限
  final String? homepageUrl;
  final String? downloadUrl;
  final String? updateUrl;
  final List<String> requireJs;     // 依赖的JS文件URL
  final List<String> resources;     // 资源文件

  UserScriptMetadata({
    required this.name,
    this.namespace,
    this.version,
    this.description,
    this.author,
    this.matches = const [],
    this.excludes = const [],
    this.includes = const [],
    this.runAt = ScriptRunAt.documentEnd,
    this.noFrames = false,
    this.grant = const [],
    this.homepageUrl,
    this.downloadUrl,
    this.updateUrl,
    this.requireJs = const [],
    this.resources = const [],
  });
}

/// 用户脚本
class UserScript {
  final String id;
  final UserScriptMetadata metadata;
  final String sourceCode;
  final bool enabled;
  final DateTime? createdAt;
  final DateTime? lastModified;
  final int runCount;
  final String? iconUrl;

  UserScript({
    required this.id,
    required this.metadata,
    required this.sourceCode,
    this.enabled = true,
    this.createdAt,
    this.lastModified,
    this.runCount = 0,
    this.iconUrl,
  });

  UserScript copyWith({
    String? id,
    UserScriptMetadata? metadata,
    String? sourceCode,
    bool? enabled,
    DateTime? createdAt,
    DateTime? lastModified,
    int? runCount,
    String? iconUrl,
  }) {
    return UserScript(
      id: id ?? this.id,
      metadata: metadata ?? this.metadata,
      sourceCode: sourceCode ?? this.sourceCode,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      runCount: runCount ?? this.runCount,
      iconUrl: iconUrl ?? this.iconUrl,
    );
  }
}

/// GM_API 桥接接口
/// 在实际使用中，这些API通过JavaScript注入到页面中执行
class GM_Api {
  final Map<String, dynamic> _storage = {};
  final String _pageUrl;
  final String _scriptId;

  GM_Api(this._pageUrl, this._scriptId);

  // ---- 存储相关 ----

  /// 获取存储值
  dynamic getValue(String key, [dynamic defaultValue]) {
    return _storage['$_scriptId:$key'] ?? defaultValue;
  }

  /// 设置存储值
  void setValue(String key, dynamic value) {
    _storage['$_scriptId:$key'] = value;
  }

  /// 删除存储值
  void deleteValue(String key) {
    _storage.remove('$_scriptId:$key');
  }

  /// 列出所有存储键
  List<String> listValues() {
    return _storage.keys
        .where((k) => k.startsWith('$_scriptId:'))
        .map((k) => k.substring('$_scriptId:'.length))
        .toList();
  }

  // ---- 资源相关 ----

  /// 获取资源文本
  String? getResourceText(String resourceName) {
    // 实际实现中从缓存的资源文件读取
    return null;
  }

  /// 获取资源URL
  String? getResourceUrl(String resourceName) {
    return null;
  }

  // ---- 网络请求 ----

  /// XMLHttpRequest
  /// 在实际实现中通过Dio代理请求
  Future<Map<String, dynamic>> xmlHttpRequest(Map<String, dynamic> details) async {
    // 实际实现中通过 MethodChannel 或 Dart 端代理请求
    return {
      'responseText': '',
      'response': null,
      'status': 0,
      'statusText': '',
      'readyState': 0,
      'finalUrl': details['url'] ?? '',
    };
  }

  // ---- 标签相关 ----

  /// 打开新标签页
  void openInTab(String url, {bool active = true}) {
    // 通知浏览器打开新标签
  }

  /// 关闭当前标签
  void closeTab() {
    // 通知浏览器关闭标签
  }

  // ---- 通知相关 ----

  /// 显示通知
  void notification(String title, {String? text, String? image}) {
    // 调用系统通知
  }

  // ---- 剪贴板 ----

  /// 复制到剪贴板
  void setClipboard(String text) {
    // 复制到剪贴板
  }

  // ---- UI相关 ----

  /// 添加样式
  String addStyle(String css) {
    final styleId = 'gm-style-$_scriptId-${DateTime.now().millisecondsSinceEpoch}';
    // 注入CSS到页面
    return styleId;
  }

  /// 添加菜单项
  void registerMenuCommand(String caption, Function() commandFunc, {String? accessKey}) {
    // 注册脚本菜单命令
  }

  /// 取消注册菜单
  void unregisterMenuCommand(String menuCmdId) {
    // 取消注册
  }

  // ---- 工具方法 ----

  /// 获取脚本信息
  Map<String, dynamic> get scriptInfo {
    return {
      'script': {
        'name': '',
        'version': '',
        'description': '',
      },
      'scriptMetaStr': '',
      'scriptHandler': 'Browser-NinefYu',
      'version': '1.0',
    };
  }

  /// 日志
  void log(dynamic message) {
    // print('[UserScript] $message');
  }

  /// 日志 - 错误
  void error(dynamic message) {
    // print('[UserScript][ERROR] $message');
  }

  /// 日志 - 警告
  void warn(dynamic message) {
    // print('[UserScript][WARN] $message');
  }
}

/// 脚本元数据解析器
class UserScriptParser {
  /// 从脚本源代码解析元数据
  UserScriptMetadata parse(String sourceCode) {
    final header = _extractHeader(sourceCode);
    if (header == null) {
      return UserScriptMetadata(name: 'Unnamed Script');
    }

    String name = 'Unnamed Script';
    String? namespace;
    String? version;
    String? description;
    String? author;
    final matches = <String>[];
    final excludes = <String>[];
    final includes = <String>[];
    var runAt = ScriptRunAt.documentEnd;
    var noFrames = false;
    final grant = <String>[];
    String? homepageUrl;
    String? downloadUrl;
    String? updateUrl;
    final requireJs = <String>[];
    final resources = <String>[];

    final lines = header.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('@')) continue;

      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.isEmpty) continue;

      final key = parts.first.toLowerCase();
      final value = parts.length > 1
          ? parts.sublist(1).join(' ')
          : '';

      switch (key) {
        case '@name':
          name = value;
          break;
        case '@namespace':
          namespace = value;
          break;
        case '@version':
          version = value;
          break;
        case '@description':
          description = value;
          break;
        case '@author':
          author = value;
          break;
        case '@match':
          if (value.isNotEmpty) matches.add(value);
          break;
        case '@exclude':
          if (value.isNotEmpty) excludes.add(value);
          break;
        case '@include':
          if (value.isNotEmpty) includes.add(value);
          break;
        case '@run-at':
          switch (value.toLowerCase()) {
            case 'document-start':
              runAt = ScriptRunAt.documentStart;
              break;
            case 'document-end':
              runAt = ScriptRunAt.documentEnd;
              break;
            case 'document-idle':
              runAt = ScriptRunAt.documentIdle;
              break;
          }
          break;
        case '@noframes':
          noFrames = true;
          break;
        case '@grant':
          if (value.isNotEmpty) grant.add(value);
          break;
        case '@homepageurl':
        case '@homepage':
          homepageUrl = value;
          break;
        case '@downloadurl':
          downloadUrl = value;
          break;
        case '@updateurl':
          updateUrl = value;
          break;
        case '@require':
          if (value.isNotEmpty) requireJs.add(value);
          break;
        case '@resource':
          if (value.isNotEmpty) resources.add(value);
          break;
      }
    }

    return UserScriptMetadata(
      name: name,
      namespace: namespace,
      version: version,
      description: description,
      author: author,
      matches: matches,
      excludes: excludes,
      includes: includes,
      runAt: runAt,
      noFrames: noFrames,
      grant: grant,
      homepageUrl: homepageUrl,
      downloadUrl: downloadUrl,
      updateUrl: updateUrl,
      requireJs: requireJs,
      resources: resources,
    );
  }

  /// 提取脚本头部注释块
  String? _extractHeader(String sourceCode) {
    final startMatch = RegExp(r'//\s*==UserScript==').firstMatch(sourceCode);
    if (startMatch == null) return null;

    final endMatch = RegExp(r'//\s*==/UserScript==').firstMatch(sourceCode);
    if (endMatch == null) return null;

    return sourceCode.substring(
      startMatch.start,
      endMatch.end,
    );
  }
}

/// URL匹配工具
class ScriptUrlMatcher {
  /// 检查URL是否匹配脚本的include/exclude规则
  static bool shouldRun(UserScript script, String url, {bool isTopFrame = true}) {
    final meta = script.metadata;

    // 检查是否在iframe中运行
    if (meta.noFrames && !isTopFrame) return false;

    // 检查排除规则（优先级最高）
    for (final exclude in meta.excludes) {
      if (matchPattern(exclude, url)) return false;
    }

    // 检查include规则
    if (meta.includes.isNotEmpty) {
      for (final include in meta.includes) {
        if (matchPattern(include, url)) return true;
      }
      return false;
    }

    // 检查match规则
    if (meta.matches.isNotEmpty) {
      for (final match in meta.matches) {
        if (matchPattern(match, url)) return true;
      }
      return false;
    }

    return true;
  }

  /// 匹配URL模式
  static bool matchPattern(String pattern, String url) {
    if (pattern == '*') return true;

    if (pattern.contains('/')) {
      // 完整URL模式
      return _matchGlob(pattern, url);
    } else {
      // 域名模式
      return url.contains(pattern);
    }
  }

  /// Glob模式匹配
  static bool _matchGlob(String pattern, String text) {
    final regex = _globToRegex(pattern);
    return RegExp(regex, caseSensitive: false).hasMatch(text);
  }

  static String _globToRegex(String glob) {
    final buffer = StringBuffer();
    buffer.write('^');

    for (var i = 0; i < glob.length; i++) {
      final char = glob[i];
      switch (char) {
        case '*':
          if (i + 1 < glob.length && glob[i + 1] == '*') {
            buffer.write('.*');
            i++;
          } else {
            buffer.write('[^/]*');
          }
          break;
        case '?':
          buffer.write('.');
          break;
        case '.':
        case '+':
        case '^':
        case '\$':
        case '{':
        case '}':
        case '[':
        case ']':
        case '\\':
        case '|':
        case '(':
        case ')':
          buffer.write('\\');
          buffer.write(char);
          break;
        default:
          buffer.write(char);
      }
    }

    buffer.write(r'$');
    return buffer.toString();
  }
}

/// 用户脚本引擎状态
class UserScriptState {
  final List<UserScript> scripts;
  final bool enabled;
  final int totalRuns;
  final String? lastError;

  UserScriptState({
    this.scripts = const [],
    this.enabled = true,
    this.totalRuns = 0,
    this.lastError,
  });

  UserScriptState copyWith({
    List<UserScript>? scripts,
    bool? enabled,
    int? totalRuns,
    String? lastError,
  }) {
    return UserScriptState(
      scripts: scripts ?? this.scripts,
      enabled: enabled ?? this.enabled,
      totalRuns: totalRuns ?? this.totalRuns,
      lastError: lastError ?? this.lastError,
    );
  }
}

/// 用户脚本引擎
class UserScriptEngine extends StateNotifier<UserScriptState> {
  final UserScriptParser _parser = UserScriptParser();
  final Map<String, GM_Api> _apiInstances = {};

  UserScriptEngine() : super(UserScriptState()) {
    _loadBuiltInScripts();
  }

  /// 加载内置示例脚本
  void _loadBuiltInScripts() {
    final demoScripts = <UserScript>[];

    // 示例：自动展开全文
    demoScripts.add(UserScript(
      id: 'demo_expand',
      metadata: UserScriptMetadata(
        name: '自动展开全文',
        description: '自动点击"展开全文"按钮',
        matches: ['*://*.baidu.com/*', '*://*.weibo.com/*'],
        runAt: ScriptRunAt.documentEnd,
      ),
      sourceCode: '''
// ==UserScript==
// @name         自动展开全文
// @description  自动点击"展开全文"按钮
// @match        *://*.baidu.com/*
// @match        *://*.weibo.com/*
// @run-at       document-end
// @grant        none
// ==/UserScript==

(function() {
  'use strict';
  
  function expandAll() {
    const buttons = document.querySelectorAll(
      'button:contains("展开"), .expand-btn, .show-more'
    );
    buttons.forEach(btn => btn.click());
  }
  
  expandAll();
  
  const observer = new MutationObserver(expandAll);
  observer.observe(document.body, { childList: true, subtree: true });
})();
''',
    ));

    // 示例：夜间模式增强
    demoScripts.add(UserScript(
      id: 'demo_darkmode',
      metadata: UserScriptMetadata(
        name: '夜间模式增强',
        description: '为所有网站添加更舒适的夜间模式',
        matches: ['*://*/*'],
        excludes: [],
        runAt: ScriptRunAt.documentStart,
      ),
      sourceCode: '''
// ==UserScript==
// @name         夜间模式增强
// @description  为所有网站添加更舒适的夜间模式
// @match        *://*/*
// @run-at       document-start
// @grant        GM_addStyle
// ==/UserScript==

(function() {
  'use strict';
  
  GM_addStyle(`
    html, body {
      background-color: #1a1a1a !important;
      color: #e0e0e0 !important;
    }
    a { color: #80a0ff !important; }
    img { opacity: 0.85; }
  `);
})();
''',
      enabled: false,
    ));

    // 示例：广告拦截增强
    demoScripts.add(UserScript(
      id: 'demo_adblock_plus',
      metadata: UserScriptMetadata(
        name: '广告拦截增强',
        description: '补充过滤一些难以通过规则拦截的广告',
        matches: ['*://*/*'],
        runAt: ScriptRunAt.documentIdle,
      ),
      sourceCode: '''
// ==UserScript==
// @name         广告拦截增强
// @description  补充过滤一些难以通过规则拦截的广告
// @match        *://*/*
// @run-at       document-idle
// @grant        none
// ==/UserScript==

(function() {
  'use strict';
  
  const adTexts = ['广告', '推广', '赞助', 'Advertisement', 'Sponsored'];
  
  function hideTextAds() {
    const elements = document.querySelectorAll('div, span, p');
    elements.forEach(el => {
      const text = el.textContent.trim();
      if (adTexts.some(ad => text === ad || text.startsWith(ad))) {
        el.style.display = 'none';
      }
    });
  }
  
  hideTextAds();
  
  const observer = new MutationObserver(() => {
    setTimeout(hideTextAds, 1000);
  });
  observer.observe(document.body, { childList: true, subtree: true });
})();
''',
      enabled: false,
    ));

    state = state.copyWith(scripts: demoScripts);
  }

  /// 获取指定注入时机的脚本
  List<UserScript> getScriptsForRunAt(ScriptRunAt runAt, String url, {bool isTopFrame = true}) {
    if (!state.enabled) return [];

    return state.scripts.where((script) {
      if (!script.enabled) return false;
      if (script.metadata.runAt != runAt) return false;
      return ScriptUrlMatcher.shouldRun(script, url, isTopFrame: isTopFrame);
    }).toList();
  }

  /// 生成要注入的JS代码
  String generateInjection(ScriptRunAt runAt, String url, {bool isTopFrame = true}) {
    final scripts = getScriptsForRunAt(runAt, url, isTopFrame: isTopFrame);
    if (scripts.isEmpty) return '';

    final buffer = StringBuffer();

    // 注入GM_API基础
    buffer.writeln(_generateGM_APIBridge());

    // 注入每个脚本
    for (final script in scripts) {
      buffer.writeln('/* Script: ${script.metadata.name} */');
      buffer.writeln('(function() {');
      buffer.writeln('  try {');
      buffer.writeln('    var GM = (function() {');
      buffer.writeln('      return {');
      buffer.writeln('        getValue: function(k, d) { return window.__GM__.getValue("$scriptId", k, d); },');
      buffer.writeln('        setValue: function(k, v) { return window.__GM__.setValue("$scriptId", k, v); },');
      buffer.writeln('        deleteValue: function(k) { return window.__GM__.deleteValue("$scriptId", k); },');
      buffer.writeln('        xmlHttpRequest: function(d) { return window.__GM__.xmlHttpRequest("$scriptId", d); },');
      buffer.writeln('        addStyle: function(c) { return window.__GM__.addStyle("$scriptId", c); },');
      buffer.writeln('        openInTab: function(u, a) { return window.__GM__.openInTab("$scriptId", u, a); },');
      buffer.writeln('        setClipboard: function(t) { return window.__GM__.setClipboard("$scriptId", t); },');
      buffer.writeln('        notification: function(t, o) { return window.__GM__.notification("$scriptId", t, o); },');
      buffer.writeln('        info: window.__GM__.getInfo("$scriptId"),');
      buffer.writeln('        log: function(m) { console.log("[${script.metadata.name}]", m); },');
      buffer.writeln('        error: function(m) { console.error("[${script.metadata.name}]", m); },');
      buffer.writeln('      };');
      buffer.writeln('    })();');
      buffer.writeln('    var GM_info = GM.info;');
      buffer.writeln('    var unsafeWindow = window;');
      buffer.writeln('    var GM_addStyle = GM.addStyle;');
      buffer.writeln('    var GM_xmlhttpRequest = GM.xmlHttpRequest;');
      buffer.writeln('    var GM_setValue = GM.setValue;');
      buffer.writeln('    var GM_getValue = GM.getValue;');
      buffer.writeln('    var GM_deleteValue = GM.deleteValue;');
      buffer.writeln('    ');
      buffer.writeln(script.sourceCode);
      buffer.writeln('  } catch(e) {');
      buffer.writeln('    console.error("Script ${script.metadata.name} error:", e);');
      buffer.writeln('  }');
      buffer.writeln('})();');
      buffer.writeln('');
    }

    // 增加运行计数
    state = state.copyWith(totalRuns: state.totalRuns + scripts.length);

    return buffer.toString();
  }

  /// 生成GM API桥接代码（Dart端与JS端通信的中间层）
  String _generateGM_APIBridge() {
    return '''
if (!window.__GM__) {
  window.__GM__ = {
    _storage: {},
    getValue: function(sid, key, def) {
      var k = sid + ":" + key;
      return this._storage[k] !== undefined ? this._storage[k] : def;
    },
    setValue: function(sid, key, val) {
      this._storage[sid + ":" + key] = val;
    },
    deleteValue: function(sid, key) {
      delete this._storage[sid + ":" + key];
    },
    xmlHttpRequest: function(sid, details) {
      return new Promise(function(resolve, reject) {
        var xhr = new XMLHttpRequest();
        xhr.open(details.method || "GET", details.url);
        if (details.headers) {
          for (var h in details.headers) {
            xhr.setRequestHeader(h, details.headers[h]);
          }
        }
        xhr.onload = function() {
          resolve({
            responseText: xhr.responseText,
            status: xhr.status,
            statusText: xhr.statusText,
            finalUrl: xhr.responseURL
          });
        };
        xhr.onerror = function() { reject(xhr.statusText); };
        xhr.ontimeout = function() { reject("timeout"); };
        if (details.timeout) xhr.timeout = details.timeout;
        if (details.data) {
          xhr.send(details.data);
        } else {
          xhr.send();
        }
      });
    },
    addStyle: function(sid, css) {
      var style = document.createElement("style");
      style.textContent = css;
      style.id = "gm-style-" + sid + "-" + Date.now();
      document.head.appendChild(style);
      return style.id;
    },
    openInTab: function(sid, url, active) {
      window.open(url, "_blank");
    },
    setClipboard: function(sid, text) {
      navigator.clipboard.writeText(text);
    },
    notification: function(sid, title, opts) {
      if ("Notification" in window) {
        if (Notification.permission === "granted") {
          new Notification(title, opts || {});
        } else if (Notification.permission !== "denied") {
          Notification.requestPermission().then(function(p) {
            if (p === "granted") new Notification(title, opts || {});
          });
        }
      }
    },
    getInfo: function(sid) {
      return {
        scriptHandler: "Browser-NinefYu",
        version: "1.0.0"
      };
    }
  };
}
''';
  }

  /// 添加脚本
  void addScript(UserScript script) {
    final scripts = List<UserScript>.from(state.scripts);
    scripts.add(script);
    state = state.copyWith(scripts: scripts);
  }

  /// 从源代码安装脚本
  UserScript installFromSource(String sourceCode) {
    final metadata = _parser.parse(sourceCode);
    final id = 'script_${DateTime.now().millisecondsSinceEpoch}';

    final script = UserScript(
      id: id,
      metadata: metadata,
      sourceCode: sourceCode,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );

    addScript(script);
    return script;
  }

  /// 移除脚本
  void removeScript(String scriptId) {
    final scripts = state.scripts.where((s) => s.id != scriptId).toList();
    state = state.copyWith(scripts: scripts);
    _apiInstances.remove(scriptId);
  }

  /// 切换脚本启用状态
  void toggleScript(String scriptId) {
    final scripts = state.scripts.map((s) {
      if (s.id == scriptId) {
        return s.copyWith(enabled: !s.enabled);
      }
      return s;
    }).toList();
    state = state.copyWith(scripts: scripts);
  }

  /// 启用/禁用所有脚本
  void setEnabled(bool enabled) {
    state = state.copyWith(enabled: enabled);
  }

  /// 更新脚本代码
  void updateScript(String scriptId, String sourceCode) {
    final metadata = _parser.parse(sourceCode);
    final scripts = state.scripts.map((s) {
      if (s.id == scriptId) {
        return s.copyWith(
          metadata: metadata,
          sourceCode: sourceCode,
          lastModified: DateTime.now(),
        );
      }
      return s;
    }).toList();
    state = state.copyWith(scripts: scripts);
  }

  /// 解析脚本
  UserScriptMetadata parseScript(String sourceCode) {
    return _parser.parse(sourceCode);
  }
}

final userScriptEngineProvider =
    StateNotifierProvider<UserScriptEngine, UserScriptState>((ref) {
  return UserScriptEngine();
});