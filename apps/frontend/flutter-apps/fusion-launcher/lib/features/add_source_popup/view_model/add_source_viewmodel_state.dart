part of 'add_source_viewmodel.dart';

class AddSourceViewModelState extends Equatable {
  final SourceSectionType selectedSourceSectionType;
  final SourceSelectionOption selectedSourceOption;
  final SignalType selectedSignalType;
  final List<SourceData?> selectedSources;
  final ListeningArea? selectedListeningArea;
  final SourceConnectionType? selectedConnectionType;
  final String? selectedSourceName;

  const AddSourceViewModelState({
    this.selectedSourceSectionType = SourceSectionType.microPhone,
    this.selectedSourceOption = SourceSelectionOption.singleSource,
    this.selectedSignalType = SignalType.mono,
    this.selectedSources = const <SourceData?>[],
    this.selectedListeningArea,
    this.selectedConnectionType,
    this.selectedSourceName,
  });

  AddSourceViewModelState copyWith({
    SourceSectionType? selectedSourceSectionType,
    SourceSelectionOption? selectedSourceOption,
    SignalType? selectedSignalType,
    List<SourceData?>? selectedSources,
    ListeningArea? selectedListeningArea,
    SourceConnectionType? selectedConnectionType,
    String? selectedSourceName,
  }) {
    return AddSourceViewModelState(
      selectedSourceSectionType: selectedSourceSectionType ?? this.selectedSourceSectionType,
      selectedSourceOption: selectedSourceOption ?? this.selectedSourceOption,
      selectedSignalType: selectedSignalType ?? this.selectedSignalType,
      selectedSources: selectedSources ?? this.selectedSources,
      selectedConnectionType: selectedConnectionType ?? this.selectedConnectionType,
      selectedSourceName: selectedSourceName ?? this.selectedSourceName,
      selectedListeningArea: selectedListeningArea ?? this.selectedListeningArea,
    );
  }

  AddSourceViewModelState resetConnectionType() {
    // When the source section type changes,
    // we want to reset the connection type to null
    // since different source types may have different connection options.
    return AddSourceViewModelState(
      selectedSourceSectionType: selectedSourceSectionType,
      selectedSourceOption: selectedSourceOption,
      selectedSignalType: selectedSignalType,
      selectedSources: selectedSources,
      selectedConnectionType: null,
      selectedSourceName: selectedSourceName,
      selectedListeningArea: selectedListeningArea,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    selectedSourceSectionType,
    selectedSourceOption,
    selectedSignalType,
    selectedSources,
    selectedListeningArea,
    selectedConnectionType,
    selectedSourceName,
  ];
}

enum SourceSelectionOption {
  singleSource("Single Source"),
  multipleSources("Multiple Sources");

  const SourceSelectionOption(this.displayName);
  final String displayName;
}

enum SourceSectionType {
  microPhone("Microphones"),
  mediaSources("Media Sources"),
  paging("Paging");

  const SourceSectionType(this.displayName);
  final String displayName;

  List<SourceData> get items {
    switch (this) {
      case SourceSectionType.microPhone:
        return SourceData.microphoneItems;
      case SourceSectionType.mediaSources:
        return SourceData.mediaSourceItems;
      case SourceSectionType.paging:
        return SourceData.pagingItems;
    }
  }

  // List<SourceConnectionType> get connectionTypes {
  //   switch (this) {
  //     case SourceSectionType.microPhone:
  //       return <SourceConnectionType>[
  //         SourceConnectionType.analogInput,
  //         SourceConnectionType.endpoint,
  //         SourceConnectionType.aes67input,
  //         // SourceConnectionType.xlr,
  //         // SourceConnectionType.ethernet,
  //       ];
  //     case SourceSectionType.mediaSources:
  //       return <SourceConnectionType>[
  //         SourceConnectionType.usb,
  //         SourceConnectionType.hdmi,
  //         SourceConnectionType.bluetooth,
  //         SourceConnectionType.audioJack,
  //         SourceConnectionType.rca,
  //         // SourceConnectionType.ethernet,
  //         // SourceConnectionType.wired,
  //         // SourceConnectionType.rca,
  //       ];

  //     case SourceSectionType.paging:
  //       return <SourceConnectionType>[];
  //   }
  // }
}

// enum SourceConnectionType {
//   usb("USB"),
//   hdmi("HDMI"),
//   bluetooth("Bluetooth"),
//   ethernet("Ethernet"),
//   wired("Wired"),
//   xlrpal("XLRPAL"),
//   rca("RCA");

//   const AddSourceConnectionType(this.displayName);
//   final String displayName;
// }
