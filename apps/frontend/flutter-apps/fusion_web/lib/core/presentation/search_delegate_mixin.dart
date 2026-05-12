import 'dart:async';
import 'package:fusion_web/core/presentation/base_viewmodel.dart';

mixin SearchDelegateMixin<T> on BaseViewModel<List<T>> {
  String? searchQuery;
  Timer? debouncer;
  void onSearchChanged(String query) {
    debouncer?.cancel();
    debouncer = Timer(Duration(milliseconds: 100), () => getData());
  }

  Future<void> getData() async {
    try {
      setLoading();
      final data = await search(searchQuery);
      setLoaded(data);
    } catch (e) {
      setError(e.toString());
    }
  }

  Future<List<T>> search(String? query);
}
