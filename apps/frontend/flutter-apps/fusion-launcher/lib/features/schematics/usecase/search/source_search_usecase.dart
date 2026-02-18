import 'package:fusion_lib/fusion_lib.dart';

class SourceSearchUseCase {
  List<Source> call(String query, List<Source> sources) {
    final String lowerCaseQuery = query.toLowerCase();
    return sources.where((Source source) => source.name.toLowerCase().contains(lowerCaseQuery)).toList();
  }
}
