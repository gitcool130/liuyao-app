/// 全局自动保存工具
/// 页面注册保存回调，在分享跳转前自动调用

typedef AutoSaveCallback = Future<void> Function();

class AutoSave {
  static final List<AutoSaveCallback> _callbacks = [];

  /// 注册保存回调
  static void register(AutoSaveCallback callback) {
    _callbacks.add(callback);
  }

  /// 注销保存回调
  static void unregister(AutoSaveCallback callback) {
    _callbacks.remove(callback);
  }

  /// 执行所有已注册的保存回调
  static Future<void> flushAll() async {
    for (final cb in _callbacks) {
      await cb();
    }
  }
}
