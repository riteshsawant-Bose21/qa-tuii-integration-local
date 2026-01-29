import 'package:flutter_bloc/flutter_bloc.dart';

class EquipmentLocationSelectionViewmodel extends Cubit<String?> {
  EquipmentLocationSelectionViewmodel(super.initialState);

  void selectEquipmentLocation(String? locationId) {
    emit(locationId);
  }
}
