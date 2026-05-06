class SelectionToolParams {
  final bool enableSelect;
  final bool enableMultiSelect;
  final bool enableMarqueeSelection;
  final List<String> Function(String layerId)? transformSelectedLayerIds;
  const SelectionToolParams({
    this.enableSelect = true,
    this.enableMultiSelect = true,
    this.enableMarqueeSelection = true,
    this.transformSelectedLayerIds,
  });
}
