import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'download_engine.dart';

/// 下载任务数据库（基于 SharedPreferences 简化实现）
class DownloadDatabase {
  static const String _keyTasks = 'download_tasks';

  /// 保存所有任务
  Future<void> saveTasks(List<DownloadTask> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final list = tasks.map((t) => _taskToJson(t)).toList();
    await prefs.setString(_keyTasks, jsonEncode(list));
  }

  /// 加载所有任务
  Future<List<DownloadTask>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyTasks);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      final list = jsonDecode(jsonStr) as List;
      return list.map((json) => _taskFromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  /// 插入任务
  Future<void> insertTask(DownloadTask task) async {
    final tasks = await loadTasks();
    tasks.removeWhere((t) => t.id == task.id);
    tasks.add(task);
    await saveTasks(tasks);
  }

  /// 更新任务
  Future<void> updateTask(DownloadTask task) async {
    await insertTask(task);
  }

  /// 更新进度
  Future<void> updateProgress(String taskId, int downloadedBytes) async {
    final tasks = await loadTasks();
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index >= 0) {
      tasks[index] = tasks[index].copyWith(downloadedBytes: downloadedBytes);
      await saveTasks(tasks);
    }
  }

  /// 删除任务
  Future<void> deleteTask(String taskId) async {
    final tasks = await loadTasks();
    tasks.removeWhere((t) => t.id == taskId);
    await saveTasks(tasks);
  }

  /// 获取未完成任务
  Future<List<DownloadTask>> getIncompleteTasks() async {
    final tasks = await loadTasks();
    return tasks
        .where((t) =>
            t.status == DownloadStatus.running ||
            t.status == DownloadStatus.paused ||
            t.status == DownloadStatus.pending)
        .toList();
  }

  Map<String, dynamic> _taskToJson(DownloadTask task) {
    return {
      'id': task.id,
      'url': task.url,
      'fileName': task.fileName,
      'filePath': task.filePath,
      'tempDir': task.tempDir,
      'headers': task.headers,
      'totalBytes': task.totalBytes,
      'downloadedBytes': task.downloadedBytes,
      'status': task.status.index,
      'threadCount': task.threadCount,
      'maxSpeedBytesPerSec': task.maxSpeedBytesPerSec,
      'chunks': task.chunks
          .map((c) => {
                'index': c.index,
                'startByte': c.startByte,
                'endByte': c.endByte,
                'downloadedBytes': c.downloadedBytes,
                'status': c.status.index,
                'tempPath': c.tempPath,
              })
          .toList(),
      'etag': task.etag,
      'lastModified': task.lastModified,
      'hashExpected': task.hashExpected,
      'hashActual': task.hashActual,
      'errorMessage': task.errorMessage,
      'retryCount': task.retryCount,
      'createdAt': task.createdAt?.toIso8601String(),
      'completedAt': task.completedAt?.toIso8601String(),
    };
  }

  DownloadTask _taskFromJson(Map<String, dynamic> json) {
    final chunksJson = (json['chunks'] as List?) ?? [];
    final chunks = chunksJson.map((c) {
      return DownloadChunk(
        index: c['index'] as int,
        startByte: c['startByte'] as int,
        endByte: c['endByte'] as int,
        downloadedBytes: c['downloadedBytes'] as int? ?? 0,
        status: DownloadStatus.values[c['status'] as int? ?? 0],
        tempPath: c['tempPath'] as String?,
      );
    }).toList();

    return DownloadTask(
      id: json['id'] as String,
      url: json['url'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      tempDir: json['tempDir'] as String,
      headers: Map<String, String>.from(json['headers'] as Map? ?? {}),
      totalBytes: json['totalBytes'] as int? ?? -1,
      downloadedBytes: json['downloadedBytes'] as int? ?? 0,
      status: DownloadStatus.values[json['status'] as int? ?? 0],
      threadCount: json['threadCount'] as int? ?? 4,
      maxSpeedBytesPerSec: json['maxSpeedBytesPerSec'] as int? ?? 0,
      chunks: chunks,
      etag: json['etag'] as String?,
      lastModified: json['lastModified'] as String?,
      hashExpected: json['hashExpected'] as String?,
      hashActual: json['hashActual'] as String?,
      errorMessage: json['errorMessage'] as String?,
      retryCount: json['retryCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }
}

final downloadDatabaseProvider = Provider<DownloadDatabase>((ref) {
  return DownloadDatabase();
});