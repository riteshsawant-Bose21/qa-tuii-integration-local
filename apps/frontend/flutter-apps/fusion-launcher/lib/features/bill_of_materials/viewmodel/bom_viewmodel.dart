import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/speaker_selection_popup/viewmodel/product_query_view_model.dart';

import '../state/bom_state.dart';

class BomViewModel extends Cubit<BomState> {
  StreamSubscription<ProductQueryViewModelState>? _pricesSub;

  BomViewModel()
    : super(
        BomIdleState(
          allItems: <BomItem>[],
          filteredItems: <BomItem>[],
          selectedCategory: BomCategory.all,
          searchQuery: '',
        ),
      ) {
    refresh();

    // Re-refresh whenever prices finish loading so speaker prices appear.
    _pricesSub = serviceLocator<ProductQueryViewModel>().stream.listen((ProductQueryViewModelState s) {
      if (!s.isLoading && !s.isRefreshing) {
        refresh();
      }
    });
  }

  @override
  Future<void> close() {
    _pricesSub?.cancel();
    return super.close();
  }

  /// Reload all data from [ProjectViewModel] and reapply current filter/search.
  void refresh() {
    emit(state.refresh());
  }

  /// Switch the active sidebar category.
  void changeCategory(BomCategory category) {
    emit(state.changeCategory(category));
  }

  /// Filter items by search query.
  void search(String query) {
    emit(state.search(query));
  }
}
