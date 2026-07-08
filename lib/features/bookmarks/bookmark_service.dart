import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 书签项
class Bookmark {
  final String id;
  final String title;
  final String url;
  final String? parentId;
  final bool isFolder;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int order;

  Bookmark({
    required this.id,
    required this.title,
    required this.url,
    this.parentId,
    this.isFolder = false,
    DateTime? createdAt,
    this.updatedAt,
    this.order = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Bookmark copyWith({
    String? id,
    String? title,
    String? url,
    String? parentId,
    bool? isFolder,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? order,
  }) {
    return Bookmark(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      parentId: parentId ?? this.parentId,
      isFolder: isFolder ?? this.isFolder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      order: order ?? this.order,
    );
  }
}

class BookmarkService extends StateNotifier<List<Bookmark>> {
  int _counter = 0;

  BookmarkService() : super([]) {
    _loadDefaults();
  }

  void _loadDefaults() {
    final defaults = [
      Bookmark(id: 'folder_${_counter++}', title: '常用网站', url: '', isFolder: true, order: 0),
      Bookmark(id: 'bookmark_${_counter++}', title: 'Google', url: 'https://www.google.com', parentId: 'folder_0', order: 0),
      Bookmark(id: 'bookmark_${_counter++}', title: 'GitHub', url: 'https://github.com', parentId: 'folder_0', order: 1),
      Bookmark(id: 'bookmark_${_counter++}', title: '百度', url: 'https://www.baidu.com', parentId: 'folder_0', order: 2),
      Bookmark(id: 'bookmark_${_counter++}', title: 'B站', url: 'https://www.bilibili.com', order: 1),
      Bookmark(id: 'bookmark_${_counter++}', title: '知乎', url: 'https://www.zhihu.com', order: 2),
    ];
    state = defaults;
  }

  void addBookmark(String title, String url, {String? parentId}) {
    final bookmark = Bookmark(
      id: 'bookmark_${_counter++}',
      title: title,
      url: url,
      parentId: parentId,
      order: state.where((b) => b.parentId == parentId).length,
    );
    state = [...state, bookmark];
  }

  void addFolder(String title, {String? parentId}) {
    final folder = Bookmark(
      id: 'folder_${_counter++}',
      title: title,
      url: '',
      parentId: parentId,
      isFolder: true,
      order: state.where((b) => b.parentId == parentId).length,
    );
    state = [...state, folder];
  }

  void removeBookmark(String id) {
    state = state.where((b) => b.id != id).toList();
  }

  void updateBookmark(String id, {String? title, String? url}) {
    state = state.map((b) {
      if (b.id == id) {
        return b.copyWith(title: title, url: url);
      }
      return b;
    }).toList();
  }

  bool isBookmarked(String url) {
    return state.any((b) => !b.isFolder && b.url == url);
  }

  List<Bookmark> getChildren(String? parentId) {
    return state.where((b) => b.parentId == parentId).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  List<Bookmark> getAllBookmarks() {
    return state.where((b) => !b.isFolder).toList();
  }
}

final bookmarkServiceProvider =
    StateNotifierProvider<BookmarkService, List<Bookmark>>((ref) {
  return BookmarkService();
});