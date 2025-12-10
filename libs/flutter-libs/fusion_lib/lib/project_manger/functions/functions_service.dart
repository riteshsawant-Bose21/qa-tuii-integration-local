import 'package:fusion_lib/fusion_lib.dart';

extension ZoneFunctionService on ProjectService {
  void addFunctionToZone({required ZoneFunctions function, required String zoneId}) {
    zoneFunctions.add(function.id, function);

    //unlink previous function
    final currentZoneFunctions = relationships.getChildren(RelationshipType.zoneFunctions, zoneId);
    if (currentZoneFunctions.isNotEmpty) {
      //remove old function
      removeFunction(functionId: currentZoneFunctions.first);
    }

    relationships.link(RelationshipType.zoneFunctions, zoneId, function.id);

    addMissingSourceSettingsToFunction(function.id);
  }

  void removeFunction({required String functionId}) {
    zoneFunctions.remove(functionId);
    relationships.removeAllRelationships(functionId);
  }

  ZoneFunctions? getZoneFunction({required String zoneOrSubZoneId}) {
    // final zoneId = zones.exists(zoneOrSubZoneId)
    //     ? zoneOrSubZoneId
    //     : relationships.getParent(RelationshipType.zoneSubZones, zoneOrSubZoneId)!;

    final zoneFunctions = relationships.getChildren(RelationshipType.zoneFunctions, zoneOrSubZoneId);
    if (zoneFunctions.isEmpty) {
      return null;
    }
    return getZoneFunctionById(functionId: zoneFunctions.first);
  }

  ZoneFunctions? getZoneFunctionById({required String functionId}) {
    return zoneFunctions.get(functionId);
  }

  void updateZoneGain({required String zoneId, required double gain}) {
    if (zones.exists(zoneId)) {
      final zone = zones.get(zoneId)!;
      final updatedZone = zone.copyWith(gain: gain);
      zones.add(zoneId, updatedZone);
    } else if (subZones.exists(zoneId)) {
      final subZone = subZones.get(zoneId)!;
      final updatedSubZone = subZone.copyWith(gain: gain);
      subZones.add(zoneId, updatedSubZone);
    }
  }

  void muteZone({required String zoneId, required bool isMuted}) {
    if (zones.exists(zoneId)) {
      final zone = zones.get(zoneId)!;
      final updatedZone = zone.copyWith(muted: isMuted);
      zones.add(zoneId, updatedZone);
    } else if (subZones.exists(zoneId)) {
      final subZone = subZones.get(zoneId)!;
      final updatedSubZone = subZone.copyWith(muted: isMuted);
      subZones.add(zoneId, updatedSubZone);
    }
  }

  //return selected Source for given function
  String? getSelectedSourceForFunction({required String functionId}) {
    final ZoneFunctions? function = getZoneFunctionById(functionId: functionId);
    if (function == null) {
      return null;
    }
    return function.selectedSourceId;
  }

  void selectSourceForFunction({required String functionId, required String sourceId}) {
    final ZoneFunctions? function = getZoneFunctionById(functionId: functionId);
    if (function == null) {
      return;
    }
    final updatedFunction = function.copyWith(selectedSourceId: sourceId);
    zoneFunctions.add(functionId, updatedFunction);
  }
}
