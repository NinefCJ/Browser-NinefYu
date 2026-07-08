import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'download_engine.dart';
import 'storage_monitor.dart';

/// 下载管理页面
class DownloadManagerPage extends ConsumerStatefulWidget {
  const DownloadManagerPage({super.key});

  @override
  ConsumerState<DownloadManagerPage> createState() => _DownloadManagerPageState();
}

class _DownloadManagerPageState extends ConsumerState<DownloadManagerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final downloadState = ref.watch(downloadEngineProvider);
    final downloadEngine = ref.read(downloadEngineProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('下载管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '下载中 (${downloadState.where((t) => t.status == DownloadStatus.running || t.status == DownloadStatus.pending).length})'),
            Tab(text: '已完成 (${downloadState.where((t) => t.status == DownloadStatus.completed).length})'),
            Tab(text: '已失败 (${downloadState.where((t) => t.status == DownloadStatus.failed || t.status == DownloadStatus.cancelled).length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDownloadDialog(context, downloadEngine),
            tooltip: '新建下载',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDownloadingTab(downloadState, downloadEngine),
          _buildCompletedTab(downloadState, downloadEngine),
          _buildFailedTab(downloadState, downloadEngine),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDownloadDialog(context, downloadEngine),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDownloadingTab(List<DownloadTask> tasks, DownloadEngine engine) {
    final downloading = tasks.where((t) =>
        t.status == DownloadStatus.running ||
        t.status == DownloadStatus.pending ||
        t.status == DownloadStatus.paused).toList();

    if (downloading.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.downloading, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无下载任务'),
            SizedBox(height: 8),
            Text('点击右下角 + 开始新下载', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: downloading.length,
      itemBuilder: (context, index) {
        final task = downloading[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.fileName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusChip(task.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  StorageMonitor.formatBytes(task.downloadedBytes) +
                      ' / ' +
                      (task.totalBytes > 0 ? StorageMonitor.formatBytes(task.totalBytes) : '未知'),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: task.totalBytes > 0 ? task.progress : 0,
                  backgroundColor: Colors.grey[200],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      task.totalBytes > 0
                          ? '${(task.progress * 100).toStringAsFixed(1)}%'
                          : '连接中...',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Row(
                      children: [
                        if (task.status == DownloadStatus.running)
                          IconButton(
                            icon: const Icon(Icons.pause, size: 20),
                            onPressed: () => engine.pauseTask(task.id),
                            tooltip: '暂停',
                          ),
                        if (task.status == DownloadStatus.paused)
                          IconButton(
                            icon: const Icon(Icons.play_arrow, size: 20),
                            onPressed: () => engine.resumeTask(task.id),
                            tooltip: '继续',
                          ),
                        IconButton(
                          icon: const Icon(Icons.cancel, size: 20, color: Colors.red),
                          onPressed: () => engine.cancelTask(task.id),
                          tooltip: '取消',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletedTab(List<DownloadTask> tasks, DownloadEngine engine) {
    final completed = tasks.where((t) => t.status == DownloadStatus.completed).toList();

    if (completed.isEmpty) {
      return const Center(child: Text('暂无已完成的下载'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: completed.length,
      itemBuilder: (context, index) {
        final task = completed[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.done, color: Colors.green),
            title: Text(task.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(StorageMonitor.formatBytes(task.totalBytes), style: const TextStyle(fontSize: 12)),
                if (task.completedAt != null)
                  Text(
                    _formatDateTime(task.completedAt!),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.share, size: 20),
                  onPressed: () {},
                  tooltip: '分享',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () {},
                  tooltip: '删除',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFailedTab(List<DownloadTask> tasks, DownloadEngine engine) {
    final failed = tasks.where((t) =>
        t.status == DownloadStatus.failed ||
        t.status == DownloadStatus.cancelled).toList();

    if (failed.isEmpty) {
      return const Center(child: Text('暂无失败的下载'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: failed.length,
      itemBuilder: (context, index) {
        final task = failed[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Icon(
              task.status == DownloadStatus.cancelled ? Icons.cancel : Icons.error,
              color: task.status == DownloadStatus.cancelled ? Colors.grey : Colors.red,
            ),
            title: Text(task.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.errorMessage ?? (task.status == DownloadStatus.cancelled ? '已取消' : '下载失败'),
                  style: TextStyle(fontSize: 12, color: Colors.red[400]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '重试次数: ${task.retryCount}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
            trailing: TextButton.icon(
              onPressed: () => engine.retryTask(task.id),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重试'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(DownloadStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case DownloadStatus.running:
        color = Colors.blue;
        text = '下载中';
        icon = Icons.downloading;
        break;
      case DownloadStatus.paused:
        color = Colors.orange;
        text = '已暂停';
        icon = Icons.pause;
        break;
      case DownloadStatus.pending:
        color = Colors.grey;
        text = '等待中';
        icon = Icons.schedule;
        break;
      case DownloadStatus.completed:
        color = Colors.green;
        text = '已完成';
        icon = Icons.check_circle;
        break;
      case DownloadStatus.failed:
        color = Colors.red;
        text = '失败';
        icon = Icons.error;
        break;
      case DownloadStatus.cancelled:
        color = Colors.grey;
        text = '已取消';
        icon = Icons.cancel;
        break;
      case DownloadStatus.merging:
        color = Colors.purple;
        text = '合并中';
        icon = Icons.merge_type;
        break;
      case DownloadStatus.verifying:
        color = Colors.teal;
        text = '校验中';
        icon = Icons.verified;
        break;
    }

    return Chip(
      avatar: Icon(icon, size: 14, color: color),
      label: Text(text, style: TextStyle(fontSize: 11, color: color)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _showAddDownloadDialog(BuildContext context, DownloadEngine engine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建下载'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: '下载链接',
                hintText: '输入 URL 地址',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('线程数: '),
                DropdownButton<int>(
                  value: 4,
                  items: const [1, 2, 4, 8, 16].map((n) {
                    return DropdownMenuItem(value: n, child: Text('$n 线程'));
                  }).toList(),
                  onChanged: (_) {},
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (_urlController.text.trim().isNotEmpty) {
                await engine.createTask(_urlController.text.trim());
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('开始下载'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}