abstract class SearchState {
  String get searchQuery;
}

class SearchingState extends SearchState {
  SearchingState({required this.searchQuery});
  @override
  final String searchQuery;
}

class IdleSearchState extends SearchState {
  IdleSearchState();
  @override
  String get searchQuery => '';
}

extension SearchStateExtension on SearchState {
  SearchingState search(String query) => SearchingState(searchQuery: query);
  IdleSearchState idle() => IdleSearchState();
}
