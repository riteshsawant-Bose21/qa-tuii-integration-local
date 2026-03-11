import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/schematics/state/device_listing_state.dart';
import 'package:fusion_launcher/features/schematics/state/search_state.dart';

abstract class DeviceListingViewModel<T> extends Cubit<DeviceListingState<T>> {
  DeviceListingViewModel() : super(DeviceListingIdleState<T>(devices: <T>[])) {
    refresh();
  }

  ///
  /// Required Functions need to be implemented by the child class
  ///
  List<T> fetchDevices(String query);

  ///

  ///
  /// Base Functions for DeviceListingCubit
  ///
  SearchState? searchState;

  void search(SearchState searchState) {
    this.searchState = searchState;
    refresh();
  }

  void refresh() {
    emit(
      switch (searchState) {
        SearchingState(searchQuery: final String query) => state.search(
          query,
          fetchDevices(query),
        ),
        _ => state.idle(fetchDevices("")),
      },
    );
  }
}
