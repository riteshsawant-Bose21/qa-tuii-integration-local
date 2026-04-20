import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'source_select_view_model_state.dart';

class SourceSelectViewModel extends Cubit<SourceSelectViewModelState> {
  SourceSelectViewModel() : super(SourceSelectViewModelInitial());
}
