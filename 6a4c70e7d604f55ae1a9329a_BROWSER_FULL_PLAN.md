# 五平台 AI 原生浏览器完整开发方案

> 本方案涵盖：项目定位、技术选型、五平台架构、浏览器引擎、高效下载器、AI 原生功能、GitHub Actions CI/CD 全流程。

---

# 第一部分：项目规划

## 1 项目定位与核心原则

一款**功能丰富的跨平台 AI 原生浏览器**，覆盖 Android / iOS / Windows / macOS / Linux 五大平台，支持集成独立渲染引擎（Android 端），内置高效下载器（支持大文件分块续传与 m3u8 视频下载），集成 AI 对话、智能标签管理、写作助理、自定义技能、AI Agent、订阅管理等功能。

**核心原则：**

| 原则 | 说明 |
|------|------|
| 五平台统一 | UI 与功能逻辑共享，渲染层按平台最优选择 |
| 功能优先 | 不追求极致体积，以功能丰富度和可靠性为第一目标 |
| 引擎可替换 | Android 端可切换系统 WebView / GeckoView，其余平台使用最优系统组件 |
| 下载可靠 | 不相信网络、不相信服务器，只相信本地校验 |
| AI 原生 | 端侧/云端混合推理，所有网页数据不出本地 |
| 扩展友好 | 预留脚本引擎、插件接口、规则订阅等扩展能力 |

---

## 2 技术选型

| 层级 | 技术 | 用途 |
|------|------|------|
| UI 层 | **Flutter** | 五平台统一界面 |
| 业务逻辑 | **Kotlin Multiplatform (KMP)** | 共享核心逻辑 |
| 平台原生 | Kotlin (Android)、Swift (iOS)、C++ (桌面) | 平台特定引擎桥接 |
| 数据层 | **drift (SQLite)** / **ObjectBox** | 跨平台数据库 + 向量存储 |
| 网络层 | **dio** / **OkHttp** | 下载管理、规则同步、API 请求 |
| 状态管理 | **Riverpod** | 跨平台响应式状态 |
| 脚本引擎 | **QuickJS (C 库，FFI 接入)** | 五平台共享 JS 执行环境 |
| AI 推理 | MediaPipe LLM / llama.cpp / 云端 API | 端侧 + 云端混合 |

**五平台渲染引擎配置：**

| 平台 | 默认引擎 | 可选独立引擎 | 说明 |
|------|----------|-------------|------|
| Android | 系统 WebView (Chromium) | **GeckoView** | 用户可在设置中切换 |
| iOS | WKWebView | 无 | App Store 强制要求使用 WebKit |
| Windows | WebView2 (Edge Chromium) | CEF | WebView2 已预装于 Win10+ |
| macOS | WKWebView | CEF | WKWebView 性能优异 |
| Linux | WebKitGTK | CEF | WebKitGTK 更轻量 |

**关键依赖版本：**

```yaml
# pubspec.yaml (Flutter)
dependencies:
  flutter:
    sdk: flutter
  riverpod: ^2.5.0
  dio: ^5.4.0
  path_provider: ^2.1.0
  permission_handler: ^11.3.0
  flutter_local_notifications: ^17.0.0
  crypto: ^3.0.3
  ffi: ^2.1.0
  langchain: ^0.7.0
  objectbox: ^4.0.0
  google_ml_kit: ^0.18.0
  enough_mail: ^2.1.0
  hive: ^2.2.3
  flutter_secure_storage: ^9.2.0
```

```groovy
// build.gradle (Android)
dependencies {
    implementation 'androidx.webkit:webkit:1.11.0'
    implementation 'org.mozilla.geckoview:geckoview-nightly:128.0'
    implementation 'androidx.room:room-ktx:2.6.1'
    implementation 'com.squareup.okhttp3:okhttp:4.12.0'
    implementation 'androidx.work:work-runtime-ktx:2.9.1'
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.0'
}
```

---

## 3 系统架构设计

### 3.1 整体分层架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter UI Layer (Dart)                    │
│  ┌───────────┐ ┌───────────┐ ┌──────────┐ ┌──────────────┐  │
│  │  Browser   │ │ Download  │ │ Settings │ │ Script/Plugin │  │
│  │  Screen   │ │  Screen   │ │  Screen  │ │   Screen     │  │
│  └─────┬─────┘ └─────┬─────┘ └────┬─────┘ └──────┬───────┘  │
│        └──────────────┴───────────┴───────────────┘           │
│                    Riverpod State Layer                       │
├─────────────────────────────────────────────────────────────┤
│                  Platform Bridge Layer                        │
│              MethodChannel / EventChannel                     │
├─────────────────────────────────────────────────────────────┤
│              Platform Native Layer (Kotlin/Swift/C++)       │
│  ┌────────────────┐ ┌────────────────┐ ┌────────────────┐   │
│  │  Android       │ │  iOS            │ │  Desktop        │   │
│  │  WebView/GV   │ │  WKWebView     │ │  WebView2/CEF  │   │
│  │  OkHttp DL    │ │  URLSession DL │ │  libcurl DL    │   │
│  │  QuickJS FFI  │ │  QuickJS FFI   │ │  QuickJS FFI   │   │
│  └────────────────┘ └────────────────┘ └────────────────┘   │
├─────────────────────────────────────────────────────────────┤
│                    Shared Core (KMP)                         │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌────────────┐   │
│  │ Bookmark  │ │ Download  │ │  AdBlock  │ │  AI Engine │   │
│  │  Service  │ │ Orchestr. │ │  Engine   │ │  Router    │   │
│  └───────────┘ └───────────┘ └───────────┘ └────────────┘   │
├─────────────────────────────────────────────────────────────┤
│                    Data Layer                                 │
│            SQLite (drift) + Hive + ObjectBox                  │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Flutter 工程结构

```
project/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── browser_api.dart          # 浏览器引擎抽象接口
│   │   ├── tab_manager.dart          # 标签页管理
│   │   ├── bookmark_service.dart     # 书签/历史
│   │   ├── download_service.dart     # 下载调度
│   │   ├── settings_service.dart     # 设置
│   │   ├── env.dart                  # 多环境配置
│   │   └── ai/
│   │       ├── ai_engine_router.dart    # AI 引擎路由
│   │       ├── cloud_llm_engine.dart    # 云端 LLM
│   │       ├── local_llm_engine.dart    # 端侧 LLM
│   │       └── page_chat_service.dart   # RAG Pipeline
│   ├── platforms/
│   │   ├── android_engine.dart      # Android WebView / GeckoView
│   │   ├── ios_engine.dart           # iOS WKWebView
│   │   ├── desktop_engine.dart       # 桌面 WebView2 / WebKitGTK
│   │   └── engine_factory.dart        # 平台路由
│   ├── features/
│   │   ├── adblock/                  # 广告过滤
│   │   ├── script/                   # 用户脚本系统
│   │   ├── download/                 # 下载管理 UI
│   │   ├── reader/                   # 阅读模式
│   │   ├── sync/                     # 跨端同步
│   │   ├── ai_chat/                  # AI 网页对话
│   │   ├── ai_tab/                   # 智能标签管理
│   │   ├── ai_writer/                # 写作助理
│   │   ├── ai_agent/                 # AI Agent
│   │   ├── skills/                   # 技能系统
│   │   └── subscription/             # 订阅管理
│   └── ui/
│       ├── theme/
│       ├── widgets/
│       └── screens/
├── android/                           # Android 原生层 (Kotlin)
│   └── app/src/main/kotlin/
│       ├── engine/
│       ├── download/
│       └── script/
├── ios/                               # iOS 原生层 (Swift)
├── windows/                           # Windows 原生层 (C++)
├── macos/
├── linux/
├── shared/                            # KMP 共享模块
└── .github/workflows/                 # CI/CD 工作流
```

---

# 第二部分：浏览器引擎

## 4 浏览器引擎抽象层

### 4.1 Dart 端统一接口

```dart
abstract class BrowserEngine {
  Future<void> initialize();
  Future<void> dispose();
  Future<void> loadUrl(String url, {Map<String, String>? headers});
  Future<void> goBack();
  Future<void> goForward();
  Future<void> reload();
  Future<void> stopLoading();
  Future<String> evaluateJavaScript(String script);

  // 事件流
  Stream<LoadStartEvent> get onLoadStart;
  Stream<LoadFinishEvent> get onLoadFinish;
  Stream<LoadErrorEvent> get onLoadError;
  Stream<ProgressEvent> get onProgress;
  Stream<TitleChangeEvent> get onTitleChange;
  Stream<UrlChangeEvent> get onUrlChange;
  Stream<VideoSourceEvent> get onVideoSourceDetected;

  void setDownloadHandler(DownloadHandler handler);
  void setRequestInterceptor(RequestInterceptor interceptor);
  Future<Uint8List> takeScreenshot();
  void setJavaScriptEnabled(bool enabled);
  void setUserAgent(String ua);
  void setNightMode(bool enabled);
}
```

### 4.2 平台路由工厂

```dart
class EngineFactory {
  static BrowserEngine create({EngineType? preferred}) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return preferred == EngineType.gecko
            ? AndroidGeckoEngine()
            : AndroidWebViewEngine();
      case TargetPlatform.iOS:
        return IosWebViewEngine();
      case TargetPlatform.windows:
        return WindowsWebView2Engine();
      case TargetPlatform.macOS:
        return MacOSWebViewEngine();
      case TargetPlatform.linux:
        return LinuxWebKitGtkEngine();
      default:
        throw UnsupportedError('Platform not supported');
    }
  }
}

enum EngineType { system, gecko, cef }
```

### 4.3 Android GeckoView 桥接示例

```dart
class AndroidGeckoEngine implements BrowserEngine {
  static const _channel = MethodChannel('browser/gecko');

  @override
  Future<void> loadUrl(String url, {Map<String, String>? headers}) async {
    await _channel.invokeMethod('loadUrl', {'url': url, 'headers': headers ?? {}});
  }

  @override
  Future<String> evaluateJavaScript(String script) async {
    return await _channel.invokeMethod('evaluateJS', {'script': script});
  }
}
```

对应 Android 原生层：

```kotlin
class GeckoViewPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var geckoSession: GeckoSession
    private lateinit var runtime: GeckoRuntime

    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        runtime = GeckoRuntime.getDefault(binding.applicationContext)
        geckoSession = GeckoSession()
        geckoSession.open(runtime)
    }

    override fun onMethodCall(call: MethodCall, result: Method) {
        when (call.method) {
            "loadUrl" -> geckoSession.loadUri(
                GeckoSession.Loader().uri(call.argument<String>("url")!!)
            )
            "evaluateJS" -> geckoSession.evaluateJS(call.argument<String>("script")!!) {
                result.success(it?.toString())
            }
        }
    }
}
```

---

# 第三部分：下载器

## 5 下载器完整设计

### 5.1 数据模型

```kotlin
@Entity(tableName = "downloads")
data class DownloadTask(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val url: String,
    val fileName: String,
    val mimeType: String?,
    val totalBytes: Long = -1L,
    val downloadedBytes: Long = 0L,
    val status: DownloadStatus = DownloadStatus.PENDING,
    val filePath: String,
    val tempPath: String,
    val etag: String? = null,
    val lastModified: String? = null,
    val hashExpected: String? = null,
    val hashActual: String? = null,
    val threadCount: Int = 4,
    val maxSpeedBytesPerSec: Long = 0L,
    val createdAt: Long = System.currentTimeMillis(),
    val completedAt: Long? = null,
    val errorMessage: String? = null,
    val retryCount: Int = 0
)

enum class DownloadStatus {
    PENDING, RUNNING, PAUSED, COMPLETED, FAILED, VERIFYING, MERGING
}

@Entity(tableName = "download_blocks", indices = [Index("taskId")])
data class DownloadBlock(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val taskId: String,
    val blockIndex: Int,
    val startByte: Long,
    val endByte: Long,
    val downloadedBytes: Long = 0L,
    val status: BlockStatus = BlockStatus.PENDING
)

enum class BlockStatus { PENDING, RUNNING, COMPLETED, FAILED }

@Entity(tableName = "hls_segments", indices = [Index("taskId")])
data class HlsSegment(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val taskId: String,
    val segmentIndex: Int,
    val url: String,
    val status: SegmentStatus = SegmentStatus.PENDING,
    val tempPath: String? = null,
    val retryCount: Int = 0
)

enum class SegmentStatus { PENDING, DOWNLOADING, COMPLETED, FAILED, DECRYPTING }
```

### 5.2 通用块下载器（流式写入 + 大文件适配）

```kotlin
class StreamBlockDownloader(
    private val okHttpClient: OkHttpClient,
    private val blockDao: BlockDao,
    private val taskDao: TaskDao,
    private val storageMonitor: StorageMonitor,
    private val speedLimiter: SpeedLimiter?,
    private val dispatcher: CoroutineDispatcher = Dispatchers.IO
) {
    companion object {
        const val BUFFER_SIZE = 16384        // 16KB buffer
        const val MAX_RETRY = 5
        const val PROGRESS_FLUSH_INTERVAL = 65536L  // 每 64KB 持久化
    }

    suspend fun downloadBlock(
        block: DownloadBlock, task: DownloadTask,
        onProgress: (Long) -> Unit
    ): Result<Unit> = withContext(dispatcher) {
        val start = block.startByte + block.downloadedBytes
        if (start >= block.endByte) {
            blockDao.update(block.copy(status = BlockStatus.COMPLETED))
            return@withContext Result.success(Unit)
        }

        val request = Request.Builder()
            .url(task.url)
            .header("Range", "bytes=$start-${block.endByte}")
            .header("Accept-Encoding", "identity")
            .apply { task.etag?.let { header("If-Match", it) } }
            .build()

        var retry = 0
        while (retry <= MAX_RETRY) {
            try {
                okHttpClient.newCall(request).execute().use { response ->
                    if (response.code != 206 && response.code != 200)
                        throw IOException("HTTP ${response.code}")
                    val body = response.body ?: throw IOException("Empty body")

                    // 降级：服务器不支持 Range
                    if (block.downloadedBytes == 0L && task.totalBytes == -1L
                        && response.header("Content-Range") == null && response.code == 200) {
                        return@withContext handleFullDownload(body, block, task, onProgress)
                    }

                    RandomAccessFile(task.tempPath, "rwd").use { raf ->
                        raf.seek(start)
                        body.byteStream().use { input ->
                            val buffer = ByteArray(BUFFER_SIZE)
                            var offset = block.downloadedBytes
                            var lastFlushAt = 0L
                            var read: Int
                            while (input.read(buffer).also { read = it } != -1) {
                                raf.write(buffer, 0, read)
                                offset += read
                                speedLimiter?.throttle(read.toLong())
                                storageMonitor.guard(task, offset)
                                if (offset - lastFlushAt >= PROGRESS_FLUSH_INTERVAL) {
                                    raf.fd.sync()
                                    blockDao.updateProgress(block.id, offset)
                                    lastFlushAt = offset
                                    onProgress(offset)
                                }
                            }
                            raf.fd.sync()
                            blockDao.update(block.copy(
                                downloadedBytes = offset, status = BlockStatus.COMPLETED
                            ))
                            onProgress(offset)
                        }
                    }
                    return@withContext Result.success(Unit)
                }
            } catch (e: IOException) {
                retry++
                if (retry > MAX_RETRY) {
                    blockDao.update(block.copy(status = BlockStatus.FAILED))
                    return@withContext Result.failure(e)
                }
                delay((1L shl minOf(retry - 1, 4)) * 1000)  // 1s, 2s, 4s, 8s, 16s
            }
        }
        Result.failure(IOException("Max retry exceeded"))
    }

    private suspend fun handleFullDownload(
        body: ResponseBody, block: DownloadBlock,
        task: DownloadTask, onProgress: (Long) -> Unit
    ): Result<Unit> {
        blockDao.deleteByTaskId(task.id)
        val fullBlock = block.copy(startByte = 0, endByte = Long.MAX_VALUE, downloadedBytes = 0)
        blockDao.insert(fullBlock)
        RandomAccessFile(task.tempPath, "rwd").use { raf ->
            raf.setLength(0)
            body.byteStream().use { input ->
                val buffer = ByteArray(BUFFER_SIZE)
                var offset = 0L
                var read: Int
                while (input.read(buffer).also { read = it } != -1) {
                    raf.write(buffer, 0, read)
                    offset += read
                    if (offset % PROGRESS_FLUSH_INTERVAL == 0L) {
                        raf.fd.sync()
                        blockDao.updateProgress(fullBlock.id, offset)
                        onProgress(offset)
                    }
                }
                raf.fd.sync()
                blockDao.update(fullBlock.copy(downloadedBytes = offset, status = BlockStatus.COMPLETED))
                taskDao.updateTotalBytes(task.id, offset)
            }
        }
        return Result.success(Unit)
    }
}
```

### 5.3 下载调度器

```kotlin
class DownloadOrchestrator(
    private val blockDownloader: StreamBlockDownloader,
    private val taskDao: TaskDao,
    private val blockDao: BlockDao,
    private val hlsDao: HlsSegmentDao,
    private val downloadDir: File,
    private val storageMonitor: StorageMonitor,
    private val maxConcurrent: Int = 3
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val semaphore = Semaphore(maxConcurrent)
    private val activeJobs = ConcurrentHashMap<String, Job>()
    private val _progressFlows = ConcurrentHashMap<String, MutableStateFlow<DownloadProgress>>()

    fun getProgressFlow(taskId: String): StateFlow<DownloadProgress> =
        _progressFlows.getOrPut(taskId) { MutableStateFlow(DownloadProgress()) }

    data class DownloadProgress(
        val downloadedBytes: Long = 0, val totalBytes: Long = -1,
        val speed: Long = 0, val status: DownloadStatus = DownloadStatus.PENDING
    )

    suspend fun enqueue(url: String, headers: Map<String, String> = emptyMap()): String {
        val probe = probeUrl(url, headers)
        val fileName = probe.suggestedFileName ?: url.substringAfterLast("/").substringBefore("?")
        val taskId = UUID.randomUUID().toString()

        if (FileSystemCompat.shouldSplitVolumes(probe.contentLength, downloadDir))
            return enqueueSplitVolumes(url, headers, fileName, probe.contentLength)

        val finalFile = File(downloadDir, sanitizeFileName(fileName))
        val tempFile = File(downloadDir, "${finalFile.name}.part")
        storageMonitor.assertEnoughSpace(probe.contentLength)

        val task = DownloadTask(
            id = taskId, url = url, fileName = finalFile.name,
            mimeType = probe.mimeType, totalBytes = probe.contentLength,
            filePath = finalFile.absolutePath, tempPath = tempFile.absolutePath,
            etag = probe.etag, lastModified = probe.lastModified,
            threadCount = if (probe.acceptsRange) 4 else 1
        )
        taskDao.insert(task)
        createBlocks(task, probe)
        startTask(taskId)
        return taskId
    }

    suspend fun enqueueM3u8(m3u8Url: String, outputName: String, headers: Map<String, String>): String {
        val taskId = UUID.randomUUID().toString()
        val tempDir = File(downloadDir, "hls_$taskId").apply { mkdirs() }
        val task = DownloadTask(
            id = taskId, url = m3u8Url, fileName = "$outputName.mp4",
            mimeType = "video/mp4", totalBytes = -1,
            filePath = File(downloadDir, "$outputName.mp4").absolutePath,
            tempPath = tempDir.absolutePath, threadCount = 8
        )
        taskDao.insert(task)
        startHlsTask(taskId, m3u8Url, headers, tempDir)
        return taskId
    }

    fun pause(taskId: String) { activeJobs[taskId]?.cancel(); activeJobs.remove(taskId) }

    fun cancel(taskId: String) {
        activeJobs[taskId]?.cancel(); activeJobs.remove(taskId)
        scope.launch {
            val task = taskDao.getById(taskId) ?: return@launch
            File(task.tempPath).delete(); blockDao.deleteByTaskId(taskId); taskDao.delete(task)
        }
    }

    suspend fun resumeIncomplete() {
        taskDao.getByStatuses(listOf(DownloadStatus.PENDING, DownloadStatus.RUNNING, DownloadStatus.PAUSED))
            .forEach { startTask(it.id) }
    }
}
```

### 5.4 m3u8 视频下载器

```kotlin
class HlsDownloader(private val okHttpClient: OkHttpClient) {
    suspend fun parseM3u8(m3u8Url: String, headers: Map<String, String>): M3u8Info {
        val content = okHttpClient.newCall(
            Request.Builder().url(m3u8Url).apply { headers.forEach { (k, v) -> addHeader(k, v) } }.build()
        ).execute().use { it.body?.string() ?: throw IOException("Empty m3u8") }

        val baseUri = m3u8Url.substringBeforeLast("/") + "/"
        val segments = mutableListOf<String>()
        var isEncrypted = false; var keyUri: String? = null; var isMaster = false

        content.lines().forEach { line ->
            val trimmed = line.trim()
            when {
                trimmed.startsWith("#EXT-X-STREAM") -> isMaster = true
                trimmed.startsWith("#EXT-X-KEY") -> {
                    isEncrypted = true
                    Regex("URI=\"([^\"]+)\"").find(trimmed)?.groupValues?.get(1)?.let {
                        keyUri = if (it.startsWith("http")) it else baseUri + it
                    }
                }
                trimmed.startsWith("#") -> {}
                trimmed.isNotBlank() -> segments.add(
                    if (trimmed.startsWith("http")) trimmed else baseUri + trimmed
                )
            }
        }
        return M3u8Info(segments, isEncrypted, keyUri, baseUri, isMaster)
    }

    private fun decryptAes128(data: ByteArray, key: ByteArray): ByteArray {
        val cipher = Cipher.getInstance("AES/CBC/PKCS5Padding")
        cipher.init(Cipher.DECRYPT_MODE, SecretKeySpec(key, "AES"), IvParameterSpec(ByteArray(16)))
        return cipher.doFinal(data)
    }

    fun mergeSegments(segments: List<HlsSegment>, tempDir: File, outputFile: File) {
        FileOutputStream(outputFile).use { out ->
            segments.sortedBy { it.segmentIndex }.forEach { seg ->
                File(tempDir, "${seg.segmentIndex}.ts").takeIf { it.exists() }
                    ?.inputStream?.use { it.copyTo(out) }
            }
        }
    }

    data class M3u8Info(
        val segments: List<String>, val isEncrypted: Boolean,
        val keyUri: String?, val baseUri: String, val isMaster: Boolean
    )
}
```

### 5.5 磁盘监控与限速

```kotlin
class StorageMonitor(private val targetDir: File, private val reservePercent: Float = 0.1f) {
    fun safeAvailableBytes(): Long {
        val stat = StatFs(targetDir.absolutePath)
        val available = stat.availableBlocksLong * stat.blockSizeLong
        val reserved = (stat.totalBytesLong * reservePercent).toLong()
        return maxOf(available - reserved, 0L)
    }
    fun assertEnoughSpace(fileSize: Long) {
        if (fileSize > 0 && safeAvailableBytes() < fileSize)
            throw IOException("磁盘空间不足：需要 ${fileSize/1024/1024}MB，可用 ${safeAvailableBytes()/1024/1024}MB")
    }
    fun guard(task: DownloadTask, bytesWritten: Long) {
        val checkInterval = 50L * 1024 * 1024
        if (bytesWritten > 0 && bytesWritten % checkInterval < 16384) {
            val remaining = (task.totalBytes - bytesWritten).coerceAtLeast(0)
            if (task.totalBytes > 0 && safeAvailableBytes() < remaining)
                throw IOException("磁盘空间即将耗尽")
        }
    }
}

class SpeedLimiter(private val maxBytesPerSec: Long) {
    private var available = maxBytesPerSec
    private var lastRefillNanos = System.nanoTime()

    @Synchronized
    suspend fun throttle(bytes: Long) {
        if (maxBytesPerSec <= 0) return
        refill()
        if (available < bytes) {
            val deficit = bytes - available
            val waitNanos = (deficit * 1_000_000_000 / maxBytesPerSec)
            delay(waitNanos / 1_000_000 + 1)
            refill()
        }
        available -= bytes
    }

    private fun refill() {
        val now = System.nanoTime()
        val elapsed = now - lastRefillNanos
        available = minOf(available + elapsed * maxBytesPerSec / 1_000_000_000, maxBytesPerSec)
        lastRefillNanos = now
    }
}

object FileSystemCompat {
    fun getMaxFileSize(dir: File): Long = minOf(
        StatFs(dir.absolutePath).availableBlocksLong * StatFs(dir.absolutePath).blockSizeLong,
        4L * 1024 * 1024 * 1024 - 1
    )
    fun shouldSplitVolumes(fileSize: Long, dir: File) = fileSize >= getMaxFileSize(dir)
}
```

### 5.6 WebView 下载拦截

```kotlin
class BrowserDownloadInterceptor(
    private val orchestrator: DownloadOrchestrator,
    private val cookieManager: CookieManager
) {
    fun attachToWebView(webView: WebView) {
        webView.setDownloadListener { url, _, _, _, _ ->
            val headers = extractHeaders(webView, url)
            GlobalScope.launch {
                try { orchestrator.enqueue(url, headers) }
                catch (e: Exception) { fallbackToSystemDownload(webView.context, url, headers) }
            }
        }
    }

    fun createWebViewClient(): WebViewClient = object : WebViewClient() {
        override fun shouldInterceptRequest(view: WebView, request: WebResourceRequest): WebResourceResponse? {
            val url = request.url.toString()
            return null  // 视频嗅探事件通过 EventChannel 发送到 Flutter 层
        }
    }

    private fun extractHeaders(wv: WebView, url: String) = mutableMapOf<String, String>().apply {
        cookieManager.getCookie(url)?.let { put("Cookie", it) }
        put("User-Agent", wv.settings.userAgentString)
        put("Referer", wv.url ?: url)
    }
}
```

### 5.7 后台保活

```kotlin
class DownloadWorker(context: Context, params: WorkerParameters,
    private val orchestrator: DownloadOrchestrator
) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        setForeground(createForegroundInfo())
        orchestrator.resumeIncomplete()
        return Result.success()
    }
    private fun createForegroundInfo(): ForegroundInfo {
        val channel = NotificationChannel("download_bg", "后台下载", NotificationManager.IMPORTANCE_LOW)
        (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).createNotificationChannel(channel)
        return ForegroundInfo(1001, NotificationCompat.Builder(applicationContext, "download_bg")
            .setContentTitle("下载服务运行中").setSmallIcon(android.R.drawable.stat_sys_download)
            .setOngoing(true).setSilent(true).build())
    }
    companion object {
        fun schedule(context: Context) {
            val request = PeriodicWorkRequestBuilder<DownloadWorker>(15, TimeUnit.MINUTES)
                .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build()).build()
            WorkManager.getInstance(context)
                .enqueueUniquePeriodicWork("bg_download", ExistingPeriodicWorkPolicy.KEEP, request)
        }
    }
}
```

### 5.8 VPN 韧性下载模块

VPN 自动切换服务器（IP 变更）时，TCP 连接会断开，且服务端 session 通常绑定 IP，导致正在进行的下载直接失败（EOF、连接重置、403 Forbidden）。本模块专门解决这一问题。

**核心防御链：**

```
VPN 切换 → TCP 断开 → OkHttp 捕获 IOException
    → 自动重试（携带原 ETag / Range 头续传）
    → 服务器校验 IP 与 session 不匹配 → 403
    → 检测到 403 → 重新发起 HEAD 请求获取新 session
    → 从上次断点继续下载
```

```kotlin
class VpnResilientDownloader(
    private val okHttpClient: OkHttpClient,
    private val blockDownloader: StreamBlockDownloader,
    private val taskDao: TaskDao,
    private val blockDao: BlockDao,
    private val dispatcher: CoroutineDispatcher = Dispatchers.IO
) {
    companion object {
        const val VPN_RECOVERY_RETRY = 8       // VPN 场景多给几次重试
        const val VPN_COOLDOWN_INITIAL = 2_000L // 首次 2 秒冷却
        const val VPN_COOLDOWN_MAX = 30_000L     // 最大 30 秒
        const val IP_CHANGE_COOLDOWN = 5_000L    // 检测到 IP 变化时额外冷却
    }

    /**
     * 带 VPN 韧性的块下载
     */
    suspend fun downloadBlockWithVpnResilience(
        block: DownloadBlock,
        task: DownloadTask,
        onProgress: (Long) -> Unit
    ): Result<Unit> = withContext(dispatcher) {
        var lastKnownIp = detectCurrentIp()
        var retry = 0

        while (retry <= VPN_RECOVERY_RETRY) {
            val result = blockDownloader.downloadBlock(block, task, onProgress)

            if (result.isSuccess) return@withContext result

            val exception = result.exceptionOrNull() ?: continue

            when {
                // TCP 连接被 VPN 切换断开
                isTcpReset(exception) || isConnectionReset(exception) -> {
                    val newIp = detectCurrentIp()
                    if (newIp != lastKnownIp) {
                        // IP 确实变了 — 等待 VPN 稳定后重试
                        lastKnownIp = newIp
                        retry++
                        delay(IP_CHANGE_COOLDOWN)
                        continue
                    }
                    // IP 没变但连接断了 — 短暂冷却后重试
                    retry++
                    delay(VPN_COOLDOWN_INITIAL shl minOf(retry - 1, 4))
                    continue
                }

                // 服务器因 IP 变更返回 403
                isForbiddenByIpChange(exception) -> {
                    // session 失效，需要重新获取连接上下文
                    val recovered = recoverSession(block, task)
                    if (recovered) {
                        lastKnownIp = detectCurrentIp()
                        retry = 0  // 重置重试计数
                        continue
                    }
                    retry++
                    delay(VPN_COOLDOWN_MAX)
                    continue
                }

                // SSL 握手失败（VPN 切换瞬间可能出现）
                isSslException(exception) -> {
                    retry++
                    delay(IP_CHANGE_COOLDOWN)
                    continue
                }

                // 其他 IO 异常 — 走标准重试
                else -> {
                    retry++
                    delay(VPN_COOLDOWN_INITIAL shl minOf(retry - 1, 4))
                    continue
                }
            }
        }

        // 超过重试次数，标记失败并记录原因
        blockDao.update(block.copy(status = BlockStatus.FAILED))
        Result.failure(IOException("VPN resilience: max retry ($VPN_RECOVERY_RETRY) exceeded"))
    }

    /**
     * session 恢复：重新 HEAD 请求获取新 ETag / Accept-Ranges
     */
    private suspend fun recoverSession(block: DownloadBlock, task: DownloadTask): Boolean {
        return try {
            val headRequest = Request.Builder()
                .url(task.url)
                .head()
                .header("User-Agent", task.userAgent ?: DEFAULT_UA)
                .header("Cookie", task.cookie ?: "")
                .header("Referer", task.referer ?: task.url)
                .build()

            okHttpClient.newCall(headRequest).execute().use { response ->
                when (response.code) {
                    200, 206 -> {
                        // 服务器正常响应，更新 ETag
                        val newEtag = response.header("ETag")
                        val newLastModified = response.header("Last-Modified")
                        if (newEtag != null || newLastModified != null) {
                            taskDao.updateEtag(task.id, newEtag, newLastModified)
                        }
                        // 更新块的起始位置为已下载位置
                        blockDao.update(block.copy(
                            downloadedBytes = block.downloadedBytes
                            // 不改变 startByte，Range 续传仍基于原始偏移
                        ))
                        true
                    }
                    else -> false
                }
            }
        } catch (e: Exception) {
            false
        }
    }

    /**
     * 检测当前出口 IP（通过公共服务，快速判断 VPN 是否切换）
     */
    private suspend fun detectCurrentIp(): String? {
        return try {
            val request = Request.Builder()
                .url("https://api.ipify.org?format=text")
                .tag(VpnCheck::class.java)  // 标记为辅助请求，不计入统计
                .build()

            okHttpClient.newCall(request).execute().use { response ->
                if (response.isSuccessful) response.body?.string()?.trim() else null
            }
        } catch (_: Exception) {
            null
        }
    }

    // ---- 异常分类 ----

    private fun isTcpReset(e: Throwable): Boolean {
        var cause = e
        while (cause != null) {
            val msg = cause.message?.lowercase() ?: ""
            if (msg.contains("connection reset") ||
                msg.contains("stream was reset") ||
                msg.contains("eof") ||
                cause is java.net.SocketException) return true
            cause = cause.cause
        }
        return false
    }

    private fun isConnectionReset(e: Throwable): Boolean {
        return e is java.net.ConnectException ||
            e is java.net.SocketTimeoutException ||
            e.message?.lowercase()?.contains("broken pipe") == true
    }

    private fun isForbiddenByIpChange(e: Throwable): Boolean {
        var cause = e
        while (cause != null) {
            if (cause is HttpException && cause.code == 403) return true
            val msg = cause.message?.lowercase() ?: ""
            if (msg.contains("403") || msg.contains("forbidden")) return true
            cause = cause.cause
        }
        return false
    }

    private fun isSslException(e: Throwable): Boolean {
        var cause = e
        while (cause != null) {
            if (cause is javax.net.ssl.SSLException ||
                cause is javax.net.ssl.SSLHandshakeException) return true
            cause = cause.cause
        }
        return false
    }
}
```

**OkHttp 拦截器层面的 VPN 防御：**

```kotlin
/**
 * VPN 切换时，服务器可能返回 403 + 自定义错误页。
 * 此拦截器在 403 时尝试从 Location 头获取重定向 URL（部分 CDN 支持）。
 */
class VpnRetryInterceptor : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        val response = chain.proceed(request)

        if (response.code == 403 && request.tag() != VpnCheck::class.java) {
            // 检查是否有重定向提示
            val location = response.header("Location")
            if (!location.isNullOrBlank()) {
                response.close()
                val newRequest = request.newBuilder().url(location).build()
                return chain.proceed(newRequest)
            }

            // 无重定向 — 返回 403 让上层 VpnResilientDownloader 处理
        }

        return response
    }
}
```

**集成到 OkHttp 配置：**

```kotlin
val okHttpClient = OkHttpClient.Builder()
    .addInterceptor(VpnRetryInterceptor())
    .connectTimeout(30, TimeUnit.SECONDS)
    .readTimeout(60, TimeUnit.SECONDS)       // VPN 环境下适当放长读取超时
    .writeTimeout(60, TimeUnit.SECONDS)
    .retryOnConnectionFailure(true)           // 自动重试连接失败
    .build()
```

**集成到 DownloadOrchestrator：**

在 `startTask()` 中，将普通 `blockDownloader.downloadBlock()` 替换为 `vpnResilientDownloader.downloadBlockWithVpnResilience()`：

```kotlin
// 下载器初始化时
val vpnResilientDownloader = VpnResilientDownloader(
    okHttpClient, blockDownloader, taskDao, blockDao
)

// startTask 中使用
val result = vpnResilientDownloader.downloadBlockWithVpnResilience(
    block, task, onProgress = { ... }
)
```

**VPN 韧性模块的关键参数：**

| 参数 | 值 | 理由 |
|------|-----|------|
| VPN 最大重试次数 | 8 | 比普通重试多，因为 VPN 恢复需要等待 |
| IP 变化检测冷却 | 5 秒 | 等 VPN 完成切换、DNS 缓存刷新 |
| 读取超时 | 60 秒 | VPN 高延迟环境需要更长超时 |
| session 恢复冷却 | 最大 30 秒 | 部分服务器限流，不宜立即重连 |
| IP 检测方式 | api.ipify.org | 免费、快速、无需认证 |
| 连接级别重试 | 开启 | OkHttp 自动重试 TCP 连接失败 |

### 5.9 下载器关键参数

| 参数 | 小文件 | 大文件 (>=1GB) | 理由 |
|------|--------|--------------|------|
| 块大小 | 2MB | 4-8MB | 减少块记录数量 |
| 写入 buffer | 8KB | 16KB | 减少 I/O 系统调用 |
| 进度持久化频率 | 每 256KB | 每 64KB | 崩溃代价高 |
| 磁盘空间检查 | 仅开始时 | 每 50MB 一次 | 防止被占满 |
| 并发线程数 | 4 | 4-8（可配置） | 充分利用带宽 |
| 重试次数 | 3 | 5 | 大文件投入高，多试 |
| 退避上限 | 4s | 16s | 可能是限流，等久点 |
| FAT32 分卷阈值 | 无 | >=4GB 自动分卷 | 兼容老设备 |

---

# 第四部分：AI 原生功能

## 6 AI 功能架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter UI Layer                           │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌─────────────┐  │
│  │ AI Chat   │ │ Tab Smart │ │ Screenshot│ │ Skill Market│  │
│  │ Overlay   │ │ Organizer │ │ + AI Ask  │ │ & Editor    │  │
│  └───────────────────────────┴───────────┴──────────────┘   │
│                    AI Service Layer                           │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────┐   │
│  │              AI Engine Router                         │   │
│  │  Local LLM (on-device) | Cloud LLM (API) | Hybrid     │   │
│  └──────────────────────────────────────────────────────┘   │
│  RAG Pipeline | Vision Model (OCR) | Agent Engine           │
│  Content Extractor | Prompt Template | Email Scanner       │
└─────────────────────────────────────────────────────────────┘
```

## 7 AI 引擎路由

```dart
abstract class AiEngine {
  Future<String> chat(String prompt, {List<ChatMessage> history});
  Future<String> chatWithContext(String prompt, String context, {List<ChatMessage> history});
  Stream<String> chatStream(String prompt);
  Future<bool> isAvailable();
  AiEngineType get type;
}

class AiEngineRouter {
  final LocalLlmEngine _local;
  final CloudLlmEngine _cloud;

  Future<String> chat(String prompt, {bool preferLocal = false}) async {
    if (preferLocal && await _local.isAvailable()) return _local.chat(prompt);
    return _cloud.chat(prompt);
  }

  Future<String> chatWithRag(String prompt, List<String> contextChunks) async {
    final context = contextChunks.join("\n---\n");
    return chat("基于以下网页内容回答问题。如果内容中没有答案，请明确说明。\n\n上下文：\n$context\n\n问题：$prompt");
  }
}
```

**本地模型选项：**

| 模型 | 体积 | 特点 |
|------|------|------|
| Qwen 2.5 0.5B | ~600MB | 中文友好，极小 |
| Gemma 2B | ~2GB | Google 出品 |
| Llama 3.2 1B/3B | ~1-3GB | 端侧最强 |
| Phi-3 Mini | ~2.3GB | 推理能力强 |

**云端模型通过标准 OpenAI 兼容 API 接入，支持流式输出。**

## 8 智能标签管理

```dart
class SmartTabOrganizer {
  final AiEngineRouter _ai;

  /// AI 按意图自动分组
  Future<List<TabGroup>> autoGroup(List<TabInfo> tabs) async {
    final prompt = """
将以下浏览器标签页按主题/意图分组。返回 JSON 数组：
[{"groupName": "组名", "tabIndices": [0,1,2]}]
标签页：
${tabs.asMap().entries.map((e) => "${e.key}: ${e.value.title} (${e.value.url})").join('\n')}""";
    return parseGroupJson(await _ai.chat(prompt));
  }

  /// 纯规则：按域名分组（无需 AI）
  List<TabGroup> groupByDomain(List<TabInfo> tabs) {
    final groups = <String, List<TabInfo>>{};
    for (final tab in tabs) groups.putIfAbsent(extractDomain(tab.url), () => []).add(tab);
    return groups.entries.map((e) => TabGroup(name: e.key, tabs: e.value)).toList();
  }

  /// 检测重复标签
  List<List<TabInfo>> findDuplicates(List<TabInfo> tabs) {
    final urlMap = <String, List<TabInfo>>{};
    for (final tab in tabs) urlMap.putIfAbsent(normalizeUrl(tab.url), () => []).add(tab);
    return urlMap.values.where((list) => list.length > 1).toList();
  }
}
```

## 9 AI 网页对话（RAG Pipeline）

```dart
class PageChatService {
  final AiEngineRouter _ai;
  final ContentExtractor _extractor;
  final VectorStore _vectorStore;

  Future<void> indexPage(String pageId, String html) async {
    final content = _extractor.extractReadableContent(html);
    final chunks = _chunkContent(content, chunkSize: 500, overlap: 50);
    for (int i = 0; i < chunks.length; i++) {
      final embedding = await _ai.embed(chunks[i]);
      await _vectorStore.insert(PageChunk(pageId: pageId, chunkIndex: i,
          content: chunks[i], embedding: embedding));
    }
  }

  Future<String> ask(String pageId, String question) async {
    final questionEmbedding = await _ai.embed(question);
    final chunks = await _vectorStore.search(
        pageId: pageId, queryEmbedding: questionEmbedding, topK: 5);
    return _ai.chatWithRag(question, chunks.map((c) => c.content).toList());
  }

  Stream<String> askStream(String pageId, String question) async* {
    final questionEmbedding = await _ai.embed(question);
    final chunks = await _vectorStore.search(
        pageId: pageId, queryEmbedding: questionEmbedding, topK: 5);
    yield* _ai.chatStreamWithContext(question, chunks.map((c) => c.content).toList());
  }

  List<String> _chunkContent(String content, {int chunkSize = 500, int overlap = 50}) {
    final chunks = <String>[]; int start = 0;
    while (start < content.length) {
      chunks.add(content.substring(start, min(start + chunkSize, content.length)));
      start = min(start + chunkSize, content.length) - overlap;
    }
    return chunks;
  }
}
```

## 10 截图 + AI 问答

```dart
class ScreenshotAskService {
  final AiEngineRouter _ai;
  final VisionModel _vision;

  Future<String> askAboutScreenshot(Uint8List screenshot, String question,
      {String? pageUrl, String? pageTitle}) async {
    final ocrText = await _vision.ocr(screenshot);
    return _ai.chatWithContext(question,
        "当前页面：$pageTitle\nURL：$pageUrl\n截图中的文字：\n$ocrText");
  }
}
```

## 11 写作助理

```dart
class WritingAssistant {
  final AiEngineRouter _ai;
  final ContentExtractor _extractor;

  /// @ 触发引用选择器
  Future<List<Citation>> getCitationCandidates(String query) async {
    final tabs = await tabService.getAllTabs();
    return [for (final tab in tabs)
      if (await _extractor.getCachedContent(tab.id)?.contains(query) == true)
        Citation(tabId: tab.id, title: tab.title, url: tab.url,
            snippet: _extractSnippet(await _extractor.getCachedContent(tab.id)!, query))
    ];
  }

  Future<String> composeWithCitations(String topic, List<Citation> citations, WritingStyle style) async {
    final context = citations.map((c) => "[${c.title}] ${c.url}\n${c.snippet}").join("\n---\n");
    return _ai.chat("""基于以下资料，撰写关于"$topic"的文章。风格：${style.description}。标注信息来源。\n\n资料：\n$context""");
  }
}

enum WritingStyle {
  academic('学术风格，严谨客观'),
  blog('博客风格，轻松活泼'),
  summary('摘要风格，简明扼要'),
  social('社交媒体风格，简短有力');
  final String description;
  const WritingStyle(this.description);
}
```

## 12 自定义技能系统

```dart
class SkillSystem {
  final AiEngineRouter _ai;
  final Box<Skill> _skillStorage;

  static final builtInSkills = [
    SkillTemplate('summarize', '网页摘要', Icons.summarize,
        '请用 3 句话总结：\n\n{content}', ['content']),
    SkillTemplate('translate', '翻译网页', Icons.translate,
        '翻译为 {targetLanguage}：\n\n{content}', ['targetLanguage', 'content']),
    SkillTemplate('extract_key_points', '提取要点', Icons.format_list_bulleted,
        '提取 5 个关键要点：\n\n{content}', ['content']),
    SkillTemplate('explain_like_five', '通俗解释', Icons.child_care,
        '用通俗语言解释：\n\n{content}', ['content']),
    SkillTemplate('fact_check', '事实核查', Icons.fact_check,
        '核查事实性陈述：\n\n{content}', ['content']),
  ];

  Future<String> executeSkill(String skillId, Map<String, String> variables) async {
    final skill = builtInSkills.firstWhere((s) => s.id == skillId);
    var prompt = skill.prompt;
    variables.forEach((key, value) => prompt = prompt.replaceAll('{$key}', value));
    return _ai.chat(prompt);
  }
}
```

## 13 AI Agent

```dart
class BrowserAgent {
  final AiEngineRouter _ai;
  final BrowserEngine _browser;

  Future<AgentResult> executeTask(String taskDescription) async {
    final plan = await _ai.chat("""
将以下任务拆解为 JSON 步骤：
[{"action":"navigate/click/input/extract/scroll","url/selector/value":"..."}]
任务：$taskDescription""");
    final steps = parseSteps(plan);
    for (final step in steps) {
      await _executeStep(step);  // navigate → click → input → extract → scroll
    }
    return AgentResult(steps: steps);
  }
}
```

## 14 订阅管理器

```dart
class SubscriptionManager {
  final EmailScanner _emailScanner;
  final AiEngineRouter _ai;

  Future<List<Subscription>> scanEmailAccount(EmailAccount account) async {
    final emails = await _emailScanner.fetchEmails(account,
        filter: (e) => ['receipt','invoice','billing','subscription'].any(
            (k) => '${e.subject} ${e.from}'.toLowerCase().contains(k)));
    return [for (final email in emails)
      await _extractSubscriptionInfo(email) ?? continue];
  }

  Future<Subscription?> _extractSubscriptionInfo(Email email) async {
    return parseSubscriptionJson(await _ai.chat("""
从邮件中提取订阅信息，非订阅邮件返回 null。
JSON: {"serviceName","amount","currency","billingCycle","nextBillingDate","category"}
发件人：${email.from}\n主题：${email.subject}\n内容：${email.plainText}"""));
  }

  SubscriptionSummary getSummary(List<Subscription> subs) {
    final total = subs.fold(0.0, (sum, s) => sum + s.monthlyEquivalent);
    return SubscriptionSummary(totalMonthly: total, count: subs.length);
  }
}
```

## 15 AI 功能集成点总览

| 功能 | 触发方式 | 数据流 |
|------|----------|--------|
| 智能标签整理 | 右键标签栏 / 自动（>20 标签） | 标题/URL → LLM → 分组 |
| AI 网页对话 | Ctrl+Shift+A / 浮动按钮 | HTML → 提取 → 向量化 → RAG → LLM |
| 截图 + 问答 | 工具栏截图 → 框选 → 提问 | WebView 截图 → OCR → LLM |
| 写作助理 | 笔记页输入 @ → 选择引用 | 标签内容 → LLM → 带引用文章 |
| 技能 | 地址栏旁按钮 / 右键 | 网页内容 → 模板填充 → LLM |
| Agent | 地址栏自然语言指令 | 指令 → LLM 拆解 → API 执行 |
| 订阅管理 | 设置 → 连接邮箱 | IMAP → 筛选 → LLM 抽取 |

**隐私策略：**
- 默认端侧模型，云端需用户主动配置 API Key
- 网页向量数据仅存本地 ObjectBox
- 截图 OCR 使用 Google ML Kit 端侧

---

# 第五部分：扩展功能模块

## 16 广告过滤

```kotlin
class AdBlockEngine @Inject constructor(private val ruleDatabase: RuleDatabase) {
    private val bloomFilter = BloomFilter.create(
        Funnels.stringFunnel(Charsets.UTF_8), 200_000, 0.01)

    fun shouldBlock(url: String, pageDomain: String): Boolean {
        if (!bloomFilter.mightContain(url)) return false
        return ruleDatabase.match(url, pageDomain)
    }

    fun loadRules(rules: List<AdBlockRule>) {
        bloomFilter.clear()
        ruleDatabase.replaceAll(rules)
        rules.filter { it.ruleType == RuleType.URL_BLOCK }.forEach { bloomFilter.put(it.ruleText) }
    }
}
```

## 17 脚本引擎

```kotlin
class ScriptEngine @Inject constructor() {
    private var quickJs: QuickJs? = null

    fun initialize() {
        quickJs = QuickJs.create()
        quickJs?.set("console", ConsoleBridge())
    }

    fun executeScript(script: UserScript, pageUrl: String) {
        val engine = quickJs ?: return
        engine.set("GM", GM_Api(
            getValue = { key, _ -> scriptStorage.get(key, pageUrl) },
            setValue = { key, value -> scriptStorage.set(key, value, pageUrl) },
            xmlHttpRequest = { config -> gmXHR(config) },
            addStyle = { css -> injectCssToPage(css) }
        ))
        engine.evaluate(script.sourceCode)
    }

    fun destroy() { quickJs?.close(); quickJs = null }
}
```

---

# 第六部分：GitHub Actions CI/CD

## 18 CI/CD 整体策略

```
push tag (v*)        → 全平台 Release 构建 + 自动发布
push main            → 全平台 Debug 构建验证
pull_request         → Android + Linux 快速 CI
workflow_dispatch   → 手动触发，可选平台 + Debug/Release
```

**仓库结构：**

```
.github/workflows/
├── release.yml      # 统一 Release 入口，调度五平台
├── android.yml      # Android APK 构建
├── ios.yml          # iOS IPA 构建
├── windows.yml      # Windows MSI 安装包构建
├── macos.yml        # macOS DMG 构建
├── linux.yml        # Linux AppImage 构建
├── web.yml          # Web 版（可选）
└── ci.yml           # PR/push 快速检查
```

## 19 统一 Release 触发

```yaml
# .github/workflows/release.yml
name: Release All Platforms

on:
  push:
    tags: ['v*']

jobs:
  android:
    uses: ./.github/workflows/android.yml
    with:
      build_type: release
      version: ${{ github.ref_name }}
    secrets: inherit

  ios:
    uses: ./.github/workflows/ios.yml
    with:
      build_type: release
      version: ${{ github.ref_name }}
    secrets: inherit

  windows:
    uses: ./.github/workflows/windows.yml
    with:
      build_type: release
      version: ${{ github.ref_name }}
    secrets: inherit

  macos:
    uses: ./.github/workflows/macos.yml
    with:
      build_type: release
      version: ${{ github.ref_name }}
    secrets: inherit

  linux:
    uses: ./.github/workflows/linux.yml
    with:
      build_type: release
      version: ${{ github.ref_name }}
    secrets: inherit

  create-release:
    needs: [android, ios, windows, macos, linux]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/download-artifact@v4
        with:
          path: build
      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: ${{ github.ref_name }}
          name: Browser ${{ github.ref_name }}
          body: |
            ## Downloads
            | Platform | File |
            |----------|------|
            | Android | `.apk` |
            | iOS | `.ipa` |
            | Windows | `.msi` |
            | macOS | `.dmg` |
            | Linux | `.AppImage` |
          files: build/**/*
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## 20 Android 构建

```yaml
# .github/workflows/android.yml
name: Android Build

on:
  workflow_call:
    inputs:
      build_type: { type: string, default: debug }
      version: { type: string, default: '1.0.0' }
  workflow_dispatch:
    inputs:
      build_type: { type: choice, options: [debug, release] }
      version: { type: string }

jobs:
  build-android:
    runs-on: ubuntu-latest
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { distribution: temurin, java-version: '17', cache: gradle }
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.24.0', channel: stable, cache: true }
      - run: flutter pub get

      - name: Decode signing key
        if: inputs.build_type == 'release'
        run: |
          echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android/app/keystore.jks
          echo "storeFile=keystore.jks" >> android/key.properties
          echo "storePassword=${{ secrets.ANDROID_KEYSTORE_PASSWORD }}" >> android/key.properties
          echo "keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}" >> android/key.properties
          echo "keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}" >> android/key.properties

      - name: Build Release
        if: inputs.build_type == 'release'
        run: |
          flutter build apk --release \
            --build-name=${{ inputs.version }} \
            --build-number=${{ github.run_number }} \
            --dart-define=ENV=production \
            --obfuscate --split-debug-info=build/debug-info

      - name: Build Debug
        if: inputs.build_type == 'debug'
        run: flutter build apk --debug

      - uses: actions/upload-artifact@v4
        with:
          name: android-${{ inputs.build_type }}
          path: build/app/outputs/flutter-apk/*.apk
          retention-days: 30
```

## 21 iOS 构建

```yaml
# .github/workflows/ios.yml
name: iOS Build

on:
  workflow_call:
    inputs:
      build_type: { type: string, default: debug }
      version: { type: string, default: '1.0.0' }
  workflow_dispatch:
    inputs:
      build_type: { type: choice, options: [debug, release] }
      version: { type: string }

jobs:
  build-ios:
    runs-on: macos-latest
    timeout-minutes: 60
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.24.0', channel: stable, cache: true }
      - run: flutter pub get
      - run: cd ios && pod install --repo-update

      - name: Import certificates
        if: inputs.build_type == 'release'
        uses: apple-actions/import-codesign-certs@v2
        with:
          p12-file-base64: ${{ secrets.IOS_P12_BASE64 }}
          p12-password: ${{ secrets.IOS_P12_PASSWORD }}

      - name: Install Provisioning Profile
        if: inputs.build_type == 'release'
        run: |
          mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
          echo "${{ secrets.IOS_PROVISION_PROFILE_BASE64 }}" | base64 -d \
            > ~/Library/MobileDevice/Provisioning\ Profiles/profile.mobileprovision

      - name: Build IPA
        if: inputs.build_type == 'release'
        run: |
          flutter build ipa --release \
            --build-name=${{ inputs.version }} \
            --build-number=${{ github.run_number }} \
            --export-options-plist=ios/ExportOptions.plist \
            --dart-define=ENV=production \
            --obfuscate --split-debug-info=build/debug-info

      - name: Build Debug
        if: inputs.build_type == 'debug'
        run: flutter build ios --debug --no-codesign

      - name: Archive IPA
        if: inputs.build_type == 'release'
        run: |
          cd build/ios/ipa && mkdir -p ../../output
          zip -r ../../output/browser-${{ inputs.version }}-ios.ipa Payload

      - uses: actions/upload-artifact@v4
        if: inputs.build_type == 'release'
        with:
          name: ios-release
          path: build/output/*.ipa
          retention-days: 30
```

## 22 Windows 构建（MSI 安装包）

```yaml
# .github/workflows/windows.yml
name: Windows Build

on:
  workflow_call:
    inputs:
      build_type: { type: string, default: debug }
      version: { type: string, default: '1.0.0' }
  workflow_dispatch:
    inputs:
      build_type: { type: choice, options: [debug, release] }
      version: { type: string }

jobs:
  build-windows:
    runs-on: windows-latest
    timeout-minutes: 60
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.24.0', channel: stable, cache: true }
      - run: flutter pub get

      - name: Build Windows
        run: |
          flutter build windows `
            --${{ inputs.build_type == 'release' && 'release' || 'debug' }} `
            --build-name=${{ inputs.version }} `
            --build-number=${{ github.run_number }} `
            --dart-define=ENV=${{ inputs.build_type == 'release' && 'production' || 'staging' }}

      # ---- 使用 WiX Toolset 生成 MSI 安装包 ----
      - name: Install WiX Toolset
        if: inputs.build_type == 'release'
        shell: pwsh
        run: |
          # WiX v4 通过 dotnet tool 安装
          dotnet tool install --global wix --version 4.0.0
          # 确保 WiX 在 PATH 中
          echo "$env:USERPROFILE\.dotnet\tools" | Out-File -FilePath $env:GITHUB_PATH -Append

      - name: Create MSI installer
        if: inputs.build_type == 'release'
        shell: pwsh
        run: |
          $outDir = "build\windows\x64\runner\Release"
          $version = "${{ inputs.version }}"

          # 生成 WiX 源文件 (wxs)
          @"
          <?xml version="1.0" encoding="UTF-8"?>
          <Wix xmlns="http://wixtoolset.org/schemas/v4/wxs">
            <Package Name="Browser" Version="$version" Manufacturer="Browser Team"
                     UpgradeCode="YOUR-GUID-HERE" Scope="perMachine">
              <MajorUpgrade DowngradeErrorMessage="A newer version is already installed." />
              <MediaTemplate EmbedCab="yes" CompressionLevel="high" />

              <FeatureRef Id="MainFeature" />

              <!-- 安装到 Program Files -->
              <StandardDirectory Id="ProgramFilesFolder">
                <Directory Id="INSTALLFOLDER" Name="Browser">
                  <Component Id="MainExe" Guid="YOUR-GUID-HERE">
                    <File Id="BrowserExe" Source="$outDir\browser.exe" KeyPath="yes" />
                  </Component>
                  <ComponentGroupRef Id="RuntimeFiles" />
                </Directory>
              </StandardDirectory>

              <!-- 开始菜单快捷方式 -->
              <ShortcutPropertyRef Id="StartMenuShortcut" />

              <Icon Id="ProductIcon" SourceFile="windows\runner\resources\app_icon.ico" />
              <Property Id="ARPPRODUCTICON" Value="ProductIcon" />
            </Package>
          </Wix>
          "@ | Out-File -FilePath "windows\installer\browser.wxs" -Encoding UTF8

          # 收集所有运行时文件作为 ComponentGroup
          $files = Get-ChildItem -Path $outDir -Recurse -File
          $components = $files | ForEach-Object {
            $compId = [Guid]::NewGuid().ToString("N")
            $relPath = $_.FullName.Substring($outDir.Length + 1)
            $dirId = $relPath -replace '\\[^\\]*$', '' -replace '\\', '_'
            @"
              <Component Id="comp_$($compId)" Directory="dir_$($dirId)" Guid="$($compId)">
                <File Id="file_$($compId)" Source="$($_.FullName)" />
              </Component>
            "@
          }

          # 编译为 MSI
          wix build windows\installer\browser.wxs `
            -arch x64 `
            -out build\browser-${{ inputs.version }}-windows.msi `
            -define Version="$version" `
            -define SourceDir="$outDir"

      # ---- 或者使用 Inno Setup 生成 setup.exe（备选方案）----
      - name: Create Inno Setup installer (alternative)
        if: inputs.build_type == 'release'
        shell: pwsh
        run: |
          choco install innosetup -y
          $outDir = "build\windows\x64\runner\Release"
          $version = "${{ inputs.version }}"

          @"
          [Setup]
          AppName=Browser
          AppVersion=$version
          DefaultDirName={pf}\Browser
          DefaultGroupName=Browser
          OutputDir=build
          OutputBaseFilename=browser-$version-windows-setup
          Compression=lzma2/ultra64
          SolidCompression=yes
          SetupIconFile=windows\runner\resources\app_icon.ico
          ArchitecturesAllowed=x64compatible
          ArchitecturesInstallIn64BitMode=x64compatible
          AllowPathPersistence=yes
          AlwaysShowComponentsList=no
          DisableProgramGroupPage=yes
          PrivilegesRequired=admin
          PrivilegesRequiredOverridesAllowed=dialog

          ; 安装向导页面：允许用户选择安装路径
          DisableDirPage=no

          [Messages]
          ; 自定义安装路径选择页面的提示文字
          SelectDirBrowseLabel=点击下方按钮选择安装 Browser 的文件夹。

          [Files]
          Source: "$outDir\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

          [Icons]
          Name: "{group}\Browser"; Filename: "{app}\browser.exe"
          Name: "{autodesktop}\Browser"; Filename: "{app}\browser.exe"

          [Registry]
          ; 将安装路径写入注册表，便于卸载和升级时定位
          Root: HKLM; Subkey: "Software\Browser"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"; Flags: uninsdeletevalue
          Root: HKLM; Subkey: "Software\Browser"; ValueType: string; ValueName: "Version"; ValueData: "$version"; Flags: uninsdeletevalue

          [Run]
          Filename: "{app}\browser.exe"; Description: "Launch Browser"; Flags: nowait postinstall skipifsilent

          [Uninstall]
          ; 卸载时保留用户数据（书签、下载等）
          ; 如需完全清理，取消下方注释
          ; Delete {app}\*
          ; 只删除安装目录下的可执行文件和资源，保留用户数据
          "@ | Out-File -FilePath "windows\installer\browser.iss" -Encoding UTF8

          & "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" windows\installer\browser.iss

      # ---- 代码签名（如果需要）----
      - name: Code sign
        if: inputs.build_type == 'release'
        shell: pwsh
        run: |
          $cert = "${{ secrets.WINDOWS_CERT_BASE64 }}"
          if ($cert) {
            $certBytes = [Convert]::FromBase64String($cert)
            [IO.File]::WriteAllBytes("build\cert.pfx", $certBytes)
            $exe = "build\browser-${{ inputs.version }}-windows-setup.exe"
            if (Test-Path $exe) { & signtool sign /f build\cert.pfx /p "${{ secrets.WINDOWS_CERT_PASSWORD }}" /tr http://timestamp.digicert.com /td sha256 $exe }
          }
        continue-on-error: true

      - name: Upload installer
        uses: actions/upload-artifact@v4
        with:
          name: windows-${{ inputs.build_type }}
          path: build/*.msi, build/*.exe
          retention-days: 30
```

## 23 macOS 构建

```yaml
# .github/workflows/macos.yml
name: macOS Build

on:
  workflow_call:
    inputs:
      build_type: { type: string, default: debug }
      version: { type: string, default: '1.0.0' }
  workflow_dispatch:
    inputs:
      build_type: { type: choice, options: [debug, release] }
      version: { type: string }

jobs:
  build-macos:
    runs-on: macos-latest
    timeout-minutes: 60
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.24.0', channel: stable, cache: true }
      - run: flutter pub get

      - name: Build macOS
        run: |
          flutter build macos --${{ inputs.build_type == 'release' && 'release' || 'debug' }} \
            --build-name=${{ inputs.version }} \
            --build-number=${{ github.run_number }} \
            --dart-define=ENV=${{ inputs.build_type == 'release' && 'production' || 'staging' }}

      - name: Create DMG
        if: inputs.build_type == 'release'
        run: |
          brew install create-dmg
          create-dmg \
            --volname "Browser" \
            --window-pos 200 120 --window-size 600 400 \
            --icon-size 100 --app-drop-link 460 220 \
            "build/browser-${{ inputs.version }}-macos.dmg" \
            "build/macos/Build/Products/Release/browser.app"

      - name: Code sign
        if: inputs.build_type == 'release'
        uses: apple-actions/import-codesign-certs@v2
        with:
          p12-file-base64: ${{ secrets.MACOS_P12_BASE64 }}
          p12-password: ${{ secrets.MACOS_P12_PASSWORD }}

      - uses: actions/upload-artifact@v4
        with:
          name: macos-${{ inputs.build_type }}
          path: build/*.dmg
          retention-days: 30
```

## 24 Linux 构建

```yaml
# .github/workflows/linux.yml
name: Linux Build

on:
  workflow_call:
    inputs:
      build_type: { type: string, default: debug }
      version: { type: string, default: '1.0.0' }
  workflow_dispatch:
    inputs:
      build_type: { type: choice, options: [debug, release] }
      version: { type: string }

jobs:
  build-linux:
    runs-on: ubuntu-22.04
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@v4
      - name: Install dependencies
        run: |
          sudo apt-get update && sudo apt-get install -y \
            clang cmake ninja-build pkg-config \
            libgtk-3-dev libblkid-dev liblzma-dev \
            libsecret-1-dev libwebkit2gtk-4.1-dev \
            libjson-glib-dev libglib2.0-dev \
            librsvg2-dev libappindicator3-dev

      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.24.0', channel: stable, cache: true }
      - run: flutter config --enable-linux-desktop
      - run: flutter pub get

      - name: Build Linux
        run: |
          flutter build linux --${{ inputs.build_type == 'release' && 'release' || 'debug' }} \
            --dart-define=ENV=${{ inputs.build_type == 'release' && 'production' || 'staging' }}

      - name: Package AppImage
        if: inputs.build_type == 'release'
        run: |
          wget -q https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
          chmod +x linuxdeploy-x86_64.AppImage
          mkdir -p build/AppDir
          cp -r build/linux/x64/release/bundle/* build/AppDir/
          ./linuxdeploy-x86_64.AppImage --appdir build/AppDir --output appimage \
            --desktop-file=linux/packaging/linux/browser.desktop \
            --icon-file=linux/packaging/linux/browser.png
          mv Browser-*.AppImage build/browser-${{ inputs.version }}-linux.AppImage

      - uses: actions/upload-artifact@v4
        with:
          name: linux-${{ inputs.build_type }}
          path: build/*.AppImage
          retention-days: 30
```

## 25 CI 快速检查

```yaml
# .github/workflows/ci.yml
name: CI Check

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.24.0' }
      - run: flutter pub get
      - run: dart format --set-exit-if-changed lib/ test/
      - run: dart analyze lib/ --fatal-infos
      - run: flutter test --coverage

  build-android-ci:
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.24.0' }
      - run: flutter pub get
      - run: flutter build apk --debug --dart-define=ENV=staging

  build-linux-ci:
    runs-on: ubuntu-22.04
    needs: analyze
    steps:
      - uses: actions/checkout@v4
      - name: Install deps
        run: sudo apt-get update && sudo apt-get install -y clang cmake ninja-build pkg-config \
            libgtk-3-dev libblkid-dev liblzma-dev libsecret-1-dev libwebkit2gtk-4.1-dev
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.24.0' }
      - run: flutter config --enable-linux-desktop
      - run: flutter pub get
      - run: flutter build linux --debug
```

## 26 多环境配置

```dart
// lib/core/env.dart
class Env {
  static const String env = String.fromEnvironment('ENV', defaultValue: 'staging');
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const bool isProduction = env == 'production';
  static const bool isStaging = env == 'staging';
  static const String version = String.fromEnvironment('VERSION', defaultValue: '0.0.0');
}
```

## 27 GitHub Secrets 清单

| Secret | 用途 | 获取方式 |
|--------|------|----------|
| `ANDROID_KEYSTORE_BASE64` | Android 签名密钥 | `base64 -i keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | 密钥库密码 | 自定义 |
| `ANDROID_KEY_ALIAS` | 密钥别名 | 自定义 |
| `ANDROID_KEY_PASSWORD` | 密钥密码 | 自定义 |
| `IOS_P12_BASE64` | iOS 证书 | Keychain Access → 导出 .p12 → base64 |
| `IOS_P12_PASSWORD` | p12 密码 | 导出时设置 |
| `IOS_PROVISION_PROFILE_BASE64` | 描述文件 | Developer Portal → 下载 → base64 |
| `MACOS_P12_BASE64` | macOS 证书 | 同 iOS |
| `MACOS_P12_PASSWORD` | p12 密码 | 同 iOS |
| `WINDOWS_CERT_BASE64` | Windows 签名证书（.pfx） | 购买代码签名证书 |
| `WINDOWS_CERT_PASSWORD` | pfx 密码 | 购买时设置 |

**各平台首次/缓存构建时间：**

| 平台 | 首次 | 缓存后 |
|------|------|--------|
| Android | ~8 min | ~3 min |
| iOS | ~12 min | ~5 min |
| Windows | ~10 min | ~4 min |
| macOS | ~10 min | ~4 min |
| Linux | ~9 min | ~3 min |

---

# 第七部分：开发路线图

## 28 18 周路线图

### Phase 1：核心可用（第 1-6 周）

| 周次 | 任务 | 产出 |
|------|------|------|
| 1-2 | Flutter 项目搭建、五平台骨架、引擎抽象层 | 五平台可编译运行 |
| 3 | 地址栏、导航、多标签页、书签历史 | 基础浏览器可用 |
| 4-5 | 下载器核心（分块续传、通知栏进度、WebView 拦截） | 可靠下载可用 |
| 6 | AI 引擎路由（云端 API）+ 技能系统 + 写作助理 | AI 对话可用 |

### Phase 2：功能增强（第 7-12 周）

| 周次 | 任务 | 产出 |
|------|------|------|
| 7 | 广告过滤（EasyList + Bloom Filter） | 广告拦截 |
| 8 | QuickJS 脚本引擎 + 用户脚本管理 | 油猴脚本 |
| 9 | m3u8 视频嗅探 + HLS 下载器 | 视频下载 |
| 10 | 大文件优化（磁盘监控、限速、分卷） | GB 级稳定下载 |
| 11 | 端侧模型 + RAG + 截图问答 + 智能标签 | AI 功能完整 |
| 12 | AI Agent + 订阅管理器 + 阅读模式/手势/夜模式 | 功能完备 |

### Phase 3：五平台适配与发布（第 13-18 周）

| 周次 | 任务 | 产出 |
|------|------|------|
| 13-14 | iOS WKWebView + iOS 签名适配 | iOS 端可用 |
| 15 | Windows MSI 安装包 + WebView2 | Windows 安装包可用 |
| 16 | macOS DMG + 签名 | macOS 端可用 |
| 17 | Linux AppImage + WebKitGTK | Linux 端可用 |
| 18 | GitHub Actions CI/CD 全链路 + 商店素材 | 一键发布五平台 |

## 29 项目规模预估

| 指标 | 数值 |
|------|------|
| Dart 代码量 | ~15,000 行 |
| Android Kotlin | ~8,000 行 |
| iOS Swift | ~3,000 行 |
| 桌面 C++/Dart FFI | ~5,000 行 |
| 首包体积（Android，系统 WebView） | ~15-20MB |
| 首包体积（Android，GeckoView） | ~45-55MB |
| 首包体积（Windows MSI） | ~25-35MB |
| 首包体积（iOS） | ~15-20MB |
| 首包体积（macOS DMG） | ~20-30MB |
| 首包体积（Linux AppImage） | ~20-30MB |

---

> **发布命令：**
> ```bash
> git tag v1.0.0 && git push origin v1.0.0
> ```
> 五平台并行构建 → 自动签名打包 → GitHub Release 自动创建 → 用户下载各平台安装包。
