package dev.ninefyu.browser.download

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import java.io.File
import java.util.concurrent.TimeUnit

/**
 * 下载后台保活 Worker
 * 使用 WorkManager 定期恢复未完成的下载任务
 */
class DownloadWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    companion object {
        private const val CHANNEL_ID = "download_bg"
        private const val NOTIFICATION_ID = 1001
        private const val WORK_NAME = "bg_download"

        /**
         * 调度后台下载任务
         */
        fun schedule(context: Context) {
            val constraints = androidx.work.Constraints.Builder()
                .setRequiredNetworkType(androidx.work.NetworkType.CONNECTED)
                .build()

            val request = PeriodicWorkRequestBuilder<DownloadWorker>(
                15, TimeUnit.MINUTES
            )
                .setConstraints(constraints)
                .build()

            WorkManager.getInstance(context)
                .enqueueUniquePeriodicWork(
                    WORK_NAME,
                    ExistingPeriodicWorkPolicy.KEEP,
                    request
                )
        }

        /**
         * 取消后台下载任务
         */
        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
        }
    }

    override suspend fun doWork(): Result {
        createNotificationChannel()

        return try {
            val downloadDir = File(
                applicationContext.getExternalFilesDir(null),
                "downloads"
            )
            downloadDir.mkdirs()

            val orchestrator = DownloadOrchestrator(applicationContext, downloadDir)
            orchestrator.resumeIncomplete()
            orchestrator.destroy()

            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "后台下载",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "后台下载任务通知"
                enableVibration(false)
                setShowBadge(false)
            }

            val notificationManager =
                applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}