import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../state/search_state.dart';

class SearchControlViewModel extends Cubit<SearchState> {
  SearchControlViewModel() : super(IdleSearchState()) {
    controller.addListener(() {
      emit(state.search(controller.text));
    });
  }

  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();

  void search(String query) => controller.text = query;
  void clear() {
    controller.clear();
    focusNode.unfocus();
  }

  void initiateSearch() {
    search("");
    emit(state.search(""));
    focusNode.requestFocus();
  }

  void cancel() => emit(state.idle());
}

class SearchResultState {
  SearchResultState({required this.query, required this.results});

  final String query;
  final List<dynamic> results;
}

class SearchResultsViewModel extends Cubit<SearchResultState> {
  SearchResultsViewModel() : super(SearchResultState(query: "", results: <dynamic>[]));

  void updateResults(List<dynamic> results) => emit(SearchResultState(query: state.query, results: <dynamic>[...state.results, ...results]));

  void onSearch(SearchState query) => emit(SearchResultState(query: query.searchQuery, results: <dynamic>[]));

  void refresh() => emit(SearchResultState(query: state.query, results: <dynamic>[]));
}
