import 'package:fusion_lib/models/project_entities/floor_text_model.dart';

import '../project/project_relationship_manager.dart';
import '../project/project_service.dart';

extension TextService on ProjectService {
  void addText(FloorText floorText, String floorId, {bool overwriteIfLinked = false}) {
    if (!floors.exists(floorId)) {
      throw Exception('Floor $floorId not found');
    }

    if (texts.exists(floorText.id)) {
      throw Exception('Text ${floorText.id} already exists in repository');
    }

    final String? existingFloor = relationships.getParent(RelationshipType.floorTexts, floorText.id);
    if (existingFloor != null) {
      if (!overwriteIfLinked) {
        throw Exception('Text ${floorText.id} is already linked to floor $existingFloor');
      }
      relationships.unlink(RelationshipType.floorTexts, existingFloor, floorText.id);
    }

    texts.add(floorText.id, floorText);
    relationships.link(RelationshipType.floorTexts, floorId, floorText.id);
  }

  void updateText(FloorText floorText) {
    if (!texts.exists(floorText.id)) {
      throw Exception('Text ${floorText.id} not found');
    }
    texts.add(floorText.id, floorText);
  }

  void removeText(String textId) {
    if (!texts.exists(textId)) {
      throw Exception('Text $textId not found');
    }

    relationships.removeAllRelationships(textId);
    texts.remove(textId);
  }

  FloorText getTextById(String textId) {
    final FloorText? text = texts.get(textId);
    if (text == null) {
      throw Exception('Text $textId not found');
    }
    return text;
  }

  List<FloorText> getTextsForFloor(String floorId) {
    final Set<String> textIds = relationships.getChildren(RelationshipType.floorTexts, floorId);
    return textIds.map((String id) => texts.get(id)).whereType<FloorText>().toList();
  }

  List<FloorText> getAllTexts() {
    return texts.getAll();
  }
}
