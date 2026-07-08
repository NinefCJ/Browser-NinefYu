package dev.ninefyu.browser.download

import android.content.Context
import java.io.File
import java.io.RandomAccessFile
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Semaphore
import kotlin.concurrent.thread
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

/**
 * 下载分块
 */
data class DownloadBlock(
    val index: Int,
    val startByte: Long,
    val endByte: Long,
    var downloadedBytes: Long = 0,
    var status: BlockStatus = BlockStatus.PENDING,
    var tempPath: String? = null
)

enum class BlockStatus {
    PENDING,
    RUNNING,
    COMPLETED,
    FAILED,
    PAUSED
}

/**
 * 下载任务
 */
data class DownloadTask(
    val id: String,
    val url: String,
    val fileName: String,
    var filePath: String,
    var tempDir: String,
    var totalBytes: Long = -1,
    var downloadedBytes: Long = 0,
    var status: DownloadStatus = DownloadStatus.PENDING,
    val threadCount: Int = 4,
    var maxSpeedBytesPerSec: Long = 0,
    val blocks: MutableList<DownloadBlock> = mutableListOf(),
    var etag: String? = null,
    var lastModified: String? = null,
    var errorMessage: String? = null,
    var retryCount: Int = 0,
    var createdAt: Long = System.currentTimeMillis(),
    var completedAt: Long? = null
)

enum class DownloadStatus {
    PENDING,
    RUNNING,
    PAUSED,
    COMPLETED,
    FAILED,
    CANCELLED,
    MERGING,
    VERIFYING
}

/**
 * 下载监听器
 */
interface DownloadListener {
    fun onProgress(taskId: String, downloadedBytes: Long, totalBytes: Long)
    fun onStatusChanged(taskId: String, status: DownloadStatus)
    fun onCompleted(taskId: String)
    fun onError(taskId: String, error: String)
}

/**
 * 流式分块下载器
 */
class StreamBlockDownloader(
    private val storageMonitor: StorageMonitor,
    private val speedLimiter: SpeedLimiter? = null
) {
    suspend fun downloadBlock(
        block: DownloadBlock,
        task: DownloadTask,
        onProgress: (Long) -> Unit
    ): Boolean = suspendCoroutine { cont ->
        thread {
            try {
                val file = File(block.tempPath!!)
                file.parentFile?.mkdirs()

                val startPos = block.startByte + block.downloadedBytes
                val raf = RandomAccessFile(file, "rw")
                raf.seek(block.downloadedBytes)

                val url = URL(task.url)
                val conn = url.openConnection() as HttpURLConnection
                conn.requestMethod = "GET"
                conn.setRequestProperty("Range", "bytes=$startPos-${block.endByte}")
                conn.connectTimeout = 30000
                conn.readTimeout = 60000

                val inputStream = conn.inputStream
                val buffer = ByteArray(8192)
                var bytesRead: Int
                var totalRead = block.downloadedBytes

                while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                    if (block.status == BlockStatus.PAUSED || block.status == BlockStatus.FAILED) {
                        break
                    }

                    raf.write(buffer, 0, bytesRead)
                    totalRead += bytesRead
                    block.downloadedBytes = totalRead

                    // 速度限制
                    speedLimiter?.throttle(bytesRead)

                    // 磁盘监控
                    storageMonitor.guard(task.totalBytes, task.downloadedBytes)

                    onProgress(totalRead)
                }

                raf.close()
                inputStream.close()
                conn.disconnect()

                if (totalRead >= (block.endByte - block.startByte + 1)) {
                    block.status = BlockStatus.COMPLETED
                    cont.resume(true)
                } else {
                    block.status = BlockStatus.FAILED
                    cont.resume(false)
                }
            } catch (e: Exception) {
                block.status = BlockStatus.FAILED
                cont.resumeWithException(e)
            }
        }
    }
}

/**
 * 磁盘监控
 */
class StorageMonitor(private val targetDir: File) {
    fun safeAvailableBytes(): Long {
        return try {
            val stat = targetDir.totalSpace
            val available = targetDir.freeSpace
            val reserved = (available * 0.1).toLong()
            (available - reserved).coerceAtLeast(0L)
        } catch (e: Exception) {
            -1L
        }
    }

    fun guard(totalBytes: Long, bytesWritten: Long) {
        val checkInterval = 50 * 1024 * 1024L
        if (bytesWritten > 0 && bytesWritten % checkInterval < 16384) {
            val remaining = (totalBytes - bytesWritten).coerceAtLeast(0L)
            val available = safeAvailableBytes()
            if (totalBytes > 0 && available in 1 until remaining) {
                throw StorageException("磁盘空间不足")
            }
        }
    }
}

class StorageException(message: String) : Exception(message)

/**
 * 速度限制器
 */
class SpeedLimiter(private val maxBytesPerSec: Long) {
    private var available: Long = 0
    private var lastRefill = System.currentTimeMillis()

    fun throttle(bytes: Int) {
        if (maxBytesPerSec <= 0) return

        refill()
        while (available < bytes) {
            val deficit = bytes - available
            val waitMs = (deficit * 1000 / maxBytesPerSec).coerceAtLeast(1L)
            Thread.sleep(waitMs)
            refill()
        }
        available -= bytes
    }

    private fun refill() {
        val now = System.currentTimeMillis()
        val elapsedMs = now - lastRefill
        if (elapsedMs > 0) {
            available += (maxBytesPerSec * elapsedMs / 1000)
            available = available.coerceIn(0, maxBytesPerSec * 2)
            lastRefill = now
        }
    }
}

/**
 * 下载编排器
 */
class DownloadOrchestrator(
    private val context: Context,
    private val downloadDir: File,
    private val maxConcurrent: Int = 3
) {
    private val semaphore = Semaphore(maxConcurrent)
    private val activeJobs = ConcurrentHashMap<String, Thread>()
    private val tasks = ConcurrentHashMap<String, DownloadTask>()
    private val blocks = ConcurrentHashMap<String, MutableList<DownloadBlock>>()
    private val listeners = mutableListOf<DownloadListener>()
    private val storageMonitor = StorageMonitor(downloadDir)

    init {
        downloadDir.mkdirs()
    }

    fun addListener(listener: DownloadListener) {
        listeners.add(listener)
    }

    fun removeListener(listener: DownloadListener) {
        listeners.remove(listener)
    }

    fun createTask(url: String, fileName: String? = null, threadCount: Int = 4): DownloadTask {
        val id = "dl_${System.currentTimeMillis()}_${(Math.random() * 10000).toInt()}"
        val fname = fileName ?: url.substringAfterLast('/').ifEmpty { "download_$id" }
        val tempDir = File(context.cacheDir, "downloads/$id")
        tempDir.mkdirs()

        val task = DownloadTask(
            id = id,
            url = url,
            fileName = fname,
            filePath = File(downloadDir, fname).absolutePath,
            tempDir = tempDir.absolutePath,
            threadCount = threadCount
        )

        tasks[id] = task
        blocks[id] = mutableListOf()

        return task
    }

    fun startTask(taskId: String) {
        val task = tasks[taskId] ?: return
        if (task.status == DownloadStatus.RUNNING) return

        task.status = DownloadStatus.RUNNING
        task.createdAt = System.currentTimeMillis()
        listeners.forEach { it.onStatusChanged(taskId, DownloadStatus.RUNNING) }

        val job = thread {
            try {
                semaphore.acquire()
                // 探测文件大小
                probeFileSize(task)

                // 创建分块
                createBlocks(task)

                // 下载各分块
                val blockDownloader = StreamBlockDownloader(
                    storageMonitor,
                    if (task.maxSpeedBytesPerSec > 0) SpeedLimiter(task.maxSpeedBytesPerSec) else null
                )

                val blockList = blocks[taskId] ?: return@thread
                val threads = mutableListOf<Thread>()

                for (block in blockList) {
                    if (block.status == BlockStatus.COMPLETED) continue

                    val t = thread {
                        try {
                            block.status = BlockStatus.RUNNING
                            val success = blockDownloader.downloadBlock(block, task) { offset ->
                                task.downloadedBytes = blockList.sumOf { it.downloadedBytes }
                                listeners.forEach {
                                    it.onProgress(taskId, task.downloadedBytes, task.totalBytes)
                                }
                            }
                            if (!success) {
                                task.retryCount++
                            }
                        } catch (e: Exception) {
                            block.status = BlockStatus.FAILED
                            task.errorMessage = e.message
                        }
                    }
                    threads.add(t)
                }

                threads.forEach { it.join() }

                // 检查全部完成
                val allComplete = blockList.all { it.status == BlockStatus.COMPLETED }
                if (allComplete) {
                    task.status = DownloadStatus.MERGING
                    listeners.forEach { it.onStatusChanged(taskId, DownloadStatus.MERGING) }

                    mergeBlocks(task)

                    task.status = DownloadStatus.COMPLETED
                    task.completedAt = System.currentTimeMillis()
                    listeners.forEach { it.onCompleted(taskId) }
                    listeners.forEach { it.onStatusChanged(taskId, DownloadStatus.COMPLETED) }

                    // 清理临时文件
                    try {
                        File(task.tempDir).deleteRecursively()
                    } catch (_) {}
                } else {
                    task.status = DownloadStatus.FAILED
                    listeners.forEach { it.onError(taskId, task.errorMessage ?: "下载失败") }
                    listeners.forEach { it.onStatusChanged(taskId, DownloadStatus.FAILED) }
                }
            } catch (e: Exception) {
                task.status = DownloadStatus.FAILED
                task.errorMessage = e.message
                listeners.forEach { it.onError(taskId, e.message ?: "未知错误") }
                listeners.forEach { it.onStatusChanged(taskId, DownloadStatus.FAILED) }
            } finally {
                semaphore.release()
                activeJobs.remove(taskId)
            }
        }

        activeJobs[taskId] = job
    }

    private fun probeFileSize(task: DownloadTask) {
        try {
            val url = URL(task.url)
            val conn = url.openConnection() as HttpURLConnection
            conn.requestMethod = "HEAD"
            conn.connectTimeout = 10000
            conn.connect()

            val contentLength = conn.getHeaderField("Content-Length")
            if (contentLength != null) {
                task.totalBytes = contentLength.toLong()
            }

            task.etag = conn.getHeaderField("ETag")
            task.lastModified = conn.getHeaderField("Last-Modified")

            conn.disconnect()
        } catch (_: Exception) {}
    }

    private fun createBlocks(task: DownloadTask) {
        if (task.totalBytes <= 0) {
            // 单块下载
            val block = DownloadBlock(
                index = 0,
                startByte = 0,
                endByte = Long.MAX_VALUE,
                tempPath = "${task.tempDir}/block_0"
            )
            blocks[task.id]?.add(block)
            return
        }

        val blockSize = task.totalBytes / task.threadCount
        val blockList = blocks[task.id] ?: mutableListOf()

        for (i in 0 until task.threadCount) {
            val start = i * blockSize
            val end = if (i == task.threadCount - 1) task.totalBytes - 1 else (start + blockSize - 1)

            val block = DownloadBlock(
                index = i,
                startByte = start,
                endByte = end,
                tempPath = "${task.tempDir}/block_$i"
            )

            // 检查断点续传
            val file = File(block.tempPath!!)
            if (file.exists()) {
                block.downloadedBytes = file.length()
                if (block.downloadedBytes >= (end - start + 1)) {
                    block.status = BlockStatus.COMPLETED
                }
            }

            blockList.add(block)
        }

        blocks[task.id] = blockList
    }

    private fun mergeBlocks(task: DownloadTask) {
        val outputFile = File(task.filePath)
        outputFile.parentFile?.mkdirs()
        val output = outputFile.outputStream()

        try {
            val blockList = blocks[task.id] ?: return
            for (block in blockList.sortedBy { it.index }) {
                val file = File(block.tempPath!!)
                if (file.exists()) {
                    file.inputStream().use { input ->
                        input.copyTo(output)
                    }
                }
            }
            output.flush()
        } finally {
            output.close()
        }
    }

    fun pauseTask(taskId: String) {
        val task = tasks[taskId] ?: return
        task.status = DownloadStatus.PAUSED
        blocks[taskId]?.forEach { it.status = BlockStatus.PAUSED }
        listeners.forEach { it.onStatusChanged(taskId, DownloadStatus.PAUSED) }
    }

    fun resumeTask(taskId: String) {
        val task = tasks[taskId] ?: return
        if (task.status != DownloadStatus.PAUSED) return
        startTask(taskId)
    }

    fun cancelTask(taskId: String) {
        val task = tasks[taskId] ?: return
        task.status = DownloadStatus.CANCELLED
        blocks[taskId]?.forEach { it.status = BlockStatus.FAILED }
        activeJobs[taskId]?.interrupt()
        activeJobs.remove(taskId)
        listeners.forEach { it.onStatusChanged(taskId, DownloadStatus.CANCELLED) }

        try {
            File(task.tempDir).deleteRecursively()
        } catch (_) {}
    }

    fun getTask(taskId: String): DownloadTask? = tasks[taskId]

    fun getAllTasks(): List<DownloadTask> = tasks.values.toList()

    fun resumeIncomplete() {
        tasks.values.forEach { task ->
            if (task.status == DownloadStatus.RUNNING ||
                task.status == DownloadStatus.PENDING) {
                startTask(task.id)
            }
        }
    }

    fun destroy() {
        activeJobs.values.forEach { it.interrupt() }
        activeJobs.clear()
    }
}