part of 'viewmodel.dart';

class AddSourceViewModelState extends Equatable {
  final SourceSectionType selectedSourceSectionType;
  final SourceSelectionOption selectedSourceOption;
  final SignalType selectedSignalType;
  final List<SourceData?> selectedSources;
  final Zone? selectedZone;
  final SubZone? selectedSubZone;
  final SourceConnectionLocation? selectedConnectionLocation;
  final String? selectedSourceName;

  const AddSourceViewModelState({
    this.selectedSourceSectionType = SourceSectionType.microPhone,
    this.selectedSourceOption = SourceSelectionOption.singleSource,
    this.selectedSignalType = SignalType.mono,
    this.selectedSources = const <SourceData>[],
    this.selectedZone,
    this.selectedSubZone,
    this.selectedConnectionLocation,
    this.selectedSourceName,
  });

  AddSourceViewModelState copyWith({
    SourceSectionType? selectedSourceSectionType,
    SourceSelectionOption? selectedSourceOption,
    SignalType? selectedSignalType,
    List<SourceData?>? selectedSources,
    Zone? selectedZone,
    SubZone? selectedSubZone,
    SourceConnectionLocation? selectedConnectionLocation,
    String? selectedSourceName,
  }) {
    return AddSourceViewModelState(
      selectedSourceSectionType: selectedSourceSectionType ?? this.selectedSourceSectionType,
      selectedSourceOption: selectedSourceOption ?? this.selectedSourceOption,
      selectedSignalType: selectedSignalType ?? this.selectedSignalType,
      selectedSources: selectedSources ?? this.selectedSources,
      selectedZone: selectedZone ?? this.selectedZone,
      selectedSubZone: selectedSubZone ?? this.selectedSubZone,
      selectedConnectionLocation: selectedConnectionLocation ?? this.selectedConnectionLocation,
      selectedSourceName: selectedSourceName ?? this.selectedSourceName,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    selectedSourceSectionType,
    selectedSourceOption,
    selectedSignalType,
    selectedSources,
    selectedZone,
    selectedSubZone,
    selectedConnectionLocation,
    selectedSourceName,
  ];
}

extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final T element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}

enum SourceSelectionOption {
  singleSource("Single Source"),
  multipleSources("Multiple Sources");

  const SourceSelectionOption(this.displayName);
  final String displayName;
}

enum SourceSectionType {
  microPhone("Microphones"),
  mediaSources("Media Sources");

  const SourceSectionType(this.displayName);
  final String displayName;

  List<SourceData> get items {
    switch (this) {
      case SourceSectionType.microPhone:
        return SourceData.microphoneItems;
      case SourceSectionType.mediaSources:
        return SourceData.mediaSourceItems;
    }
  }
}

enum SourceConnectionLocation {
  internal("Internal"),
  external("External");

  const SourceConnectionLocation(this.displayName);
  final String displayName;
}
