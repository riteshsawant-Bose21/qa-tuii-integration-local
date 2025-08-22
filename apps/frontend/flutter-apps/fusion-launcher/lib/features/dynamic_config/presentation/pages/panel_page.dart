import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/models/fusion_models.dart';

import '../../../../core/service_locator.dart';
import '../bloc/panel_bloc.dart';
import '../bloc/panel_bloc_event.dart';
import '../bloc/panel_bloc_state.dart';
import 'audio_panel_view.dart';

class PanelPage extends StatefulWidget {
  final ProcessingBlockEntity processingBlockEntity;

  const PanelPage({super.key, required this.processingBlockEntity});

  @override
  State<PanelPage> createState() => _PanelPageState();
}

class _PanelPageState extends State<PanelPage> {
  @override
  void initState() {
    super.initState();
    serviceLocator<PanelBloc>().add(
      InitializePanel(
        widget.processingBlockEntity,
      ),
    );
  }

  @override
  void dispose() {
    serviceLocator<PanelBloc>().add(
      DisposePanel(),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<PanelBloc, PanelBlocState>(
        builder: (BuildContext context, PanelBlocState state) {
          if (state is PanelInitialState) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is PanelLoadingState) {
            return const Center(
              child: Text('Loading...'),
            );
          } else if (state is PanelLoadedState) {
            return AudioPanelView(
              panel: state.panel,
            );
          } else if (state is PanelErrorState) {
            return Center(child: Text('Something went wrong. ${state.error}'));
          } else {
            return const Center(child: Text('Something went wrong'));
          }
        },
      ),
    );
  }
}
