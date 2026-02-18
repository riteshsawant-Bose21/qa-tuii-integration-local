import 'package:fusion_lib/fusion_lib.dart';

class AmplifierSearchUseCase {
  List<Amplifier> call(String query, List<Amplifier> amplifiers) {
    final String lowerCaseQuery = query.toLowerCase();
    return amplifiers.where((Amplifier amplifier) => amplifier.name.toLowerCase().contains(lowerCaseQuery)).toList();
  }
}
