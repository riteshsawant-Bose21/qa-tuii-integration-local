import '../../domain/entities/panel_entity.dart';

abstract class PanelBlocState {}

class PanelInitialState extends PanelBlocState {}

class PanelLoadingState extends PanelBlocState {

  PanelLoadingState();
}

class PanelLoadedState extends PanelBlocState {
  final PanelEntity panel;

  PanelLoadedState(this.panel);
}

class PanelErrorState extends PanelBlocState {
  final String error;

  PanelErrorState(this.error);
}

//TODO: unimplemented
// class PanelSingleWidgetErrorState extends PanelBlocState {
//   final String error;
//   final String id;

//   PanelSingleWidgetErrorState(this.error, this.id);
// }
