import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/create_new_project/viewmodel/create_new_project_vm.dart';
import 'package:fusion_launcher/features/home/presentation/widgets/project_card.dart';
import 'package:fusion_lib/fusion_building_view/floor_plan_calibrator.dart';
import 'package:fusion_lib/fusion_lib.dart' hide FusionUtils;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../home/presentation/widgets/saved_projects_tab.dart';

class CreateNewProjectDialog extends StatefulWidget {
  final bool isEditMode;
  const CreateNewProjectDialog({super.key, this.isEditMode = false});

  static void show(BuildContext context, {bool isEditMode = false}) {
    Navigator.of(context).push(
      AnimatedBlurDialogRoute<void>(
        isDismissible: false,
        builder: (BuildContext context) {
          return Material(
            color: Colors.transparent,
            child: CreateNewProjectDialog(
              isEditMode: isEditMode,
            ),
          );
        },
      ),
    );
  }

  @override
  State<CreateNewProjectDialog> createState() => _CreateNewProjectDialogState();
}

class _CreateNewProjectDialogState extends State<CreateNewProjectDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  ValueNotifier<bool> shouldShowMoreDetailsNotifier = ValueNotifier<bool>(
    false,
  );

  @override
  void dispose() {
    shouldShowMoreDetailsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double borderRadius = 14;
    final int maxCharLength = 25;

    return BlocProvider<CreateNewProjectViewmodel>(
      create: (_) => CreateNewProjectViewmodel(isEditMode: widget.isEditMode),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double cardWidth = constraints.maxWidth * 0.5 > 660 ? 660 : constraints.maxWidth * 0.5;

          return BlocBuilder<CreateNewProjectViewmodel, NewProjectDetails>(
            builder: (BuildContext context, NewProjectDetails state) {
              final CreateNewProjectViewmodel createNewProjectViewmodel = context.read<CreateNewProjectViewmodel>();

              final bool isEditMode = createNewProjectViewmodel.isEditMode;

              return Container(
                constraints: BoxConstraints(maxWidth: cardWidth),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  color: context.colorScheme.elevation1,
                  border: Border.all(color: context.colorScheme.elevation2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: FusionAppText(
                              text: isEditMode ? "Edit Project" : "Create New Project",
                              style: context.textTheme.titleMedium?.copyWith(
                                color: context.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(LucideIcons.x200),
                            color: context.colorScheme.iconDefault,
                          ),
                        ],
                      ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(borderRadius),
                              color: context.colorScheme.elevation1,
                              border: Border.all(
                                color: context.colorScheme.elevation2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(borderRadius),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                physics: const ClampingScrollPhysics(),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    spacing: 10,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      FusionAppText(
                                        text: "BASIC INFORMATION",
                                        maxLine: 2,
                                        style: context.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: context.colorScheme.onSurface,
                                        ),
                                      ),

                                      Row(
                                        spacing: 10,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Expanded(
                                            child: BorderedTextfield(
                                              controllerValue: state.name,
                                              autofocus: true,
                                              label: "Project file name *",
                                              hintText: "Project Name",
                                              maxLength: maxCharLength,
                                              validator: (String? value) {
                                                if (value?.isEmpty ?? true) return "Project name cannot be empty";
                                                return null;
                                              },
                                              onChanged: (String value) {
                                                createNewProjectViewmodel.update(
                                                  state.copyWith(
                                                    name: value,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          Expanded(
                                            child: BorderedTextfield(
                                              controllerValue: state.metadata.fileVersion,
                                              label: "File version",
                                              hintText: "Version Number",
                                              maxLength: maxCharLength,
                                              onChanged: (String value) {
                                                createNewProjectViewmodel.updateMetaData(
                                                  state.metadata.copyWith(
                                                    fileVersion: value,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      FusionCommaSeperatedTagTextfield(
                                        values: state.metadata.tags ?? <String>[],
                                        label: "Project tags or categories",
                                        hintText: "Add tags or categories (separated by commas)",
                                        onChanged: (List<String> values) {
                                          createNewProjectViewmodel.updateMetaData(
                                            state.metadata.copyWith(
                                              tags: values,
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        spacing: 10,
                                        children: <Widget>[
                                          Expanded(
                                            child: BorderedTextfield(
                                              controllerValue: state.metadata.authorName,
                                              label: "Author name",
                                              hintText: "Full Name",
                                              maxLength: maxCharLength,
                                              onChanged: (String value) {
                                                createNewProjectViewmodel.updateMetaData(
                                                  state.metadata.copyWith(
                                                    authorName: value,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          Expanded(
                                            child: BorderedTextfield(
                                              controllerValue: state.metadata.organisationName,
                                              label: "Organisation *",
                                              hintText: "Organisation name",
                                              maxLength: maxCharLength,
                                              validator: (String? value) {
                                                if (value?.isEmpty ?? true) return "Organisation cannot be empty";
                                                return null;
                                              },
                                              onChanged: (String value) {
                                                createNewProjectViewmodel.updateMetaData(
                                                  state.metadata.copyWith(
                                                    organisationName: value,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),

                                      // =============================================
                                      //  Add More Details Section
                                      // =============================================
                                      ValueListenableBuilder<bool>(
                                        valueListenable: shouldShowMoreDetailsNotifier,

                                        builder: (
                                          BuildContext context,
                                          bool value,
                                          Widget? child,
                                        ) {
                                          return AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            switchInCurve: Curves.easeOut,
                                            switchOutCurve: Curves.easeIn,
                                            transitionBuilder: (
                                              Widget child,
                                              Animation<double> animation,
                                            ) {
                                              return SizeTransition(
                                                sizeFactor: animation,
                                                child: child,
                                              );
                                            },
                                            child: Builder(
                                              key: ValueKey<bool>(value),
                                              builder: (BuildContext context) {
                                                if (!value) return const SizedBox.shrink();
                                                return Padding(
                                                  padding: const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ).copyWith(bottom: 0),
                                                  child: Column(
                                                    spacing: 10,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: <Widget>[
                                                      // ===============================
                                                      //  Organisation DETAILS SECTION
                                                      // ===============================
                                                      FusionAppText(
                                                        text: "ORGANISATION DETAILS",
                                                        maxLine: 2,
                                                        style: context.textTheme.bodySmall?.copyWith(
                                                          fontWeight: FontWeight.bold,
                                                          color: context.colorScheme.onSurface,
                                                        ),
                                                      ),

                                                      const SizedBox(height: 5),
                                                      Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        spacing: 10,
                                                        children: <Widget>[
                                                          Expanded(
                                                            child: FusionDropdown2<FusionCountries>(
                                                              selectedValue: state.metadata.country,
                                                              title: "Project country",
                                                              placeholder: "Select country",
                                                              items: FusionCountries.values,
                                                              labelBuilder: (FusionCountries value) => value.name.toUpperCase(),
                                                              onChanged: (FusionCountries value) {
                                                                createNewProjectViewmodel.updateMetaData(
                                                                  state.metadata.copyWith(
                                                                    country: value,
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: BorderedTextfield(
                                                              controllerValue: state.metadata.state,
                                                              label: "Project state",
                                                              hintText: "State",
                                                              maxLength: maxCharLength,
                                                              onChanged: (
                                                                String value,
                                                              ) {
                                                                createNewProjectViewmodel.updateMetaData(
                                                                  state.metadata.copyWith(
                                                                    state: value,
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      ),

                                                      const SizedBox(height: 5),

                                                      Row(
                                                        spacing: 10,
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: <Widget>[
                                                          Expanded(
                                                            child: FusionDropdown2<FusionTimeZones>(
                                                              selectedValue: state.metadata.timeZone,
                                                              title: "Project time zone",
                                                              placeholder: "Select time zone",
                                                              items: FusionTimeZones.values,
                                                              labelBuilder: (FusionTimeZones value) => value.name.toUpperCase(),
                                                              onChanged: (FusionTimeZones value) {
                                                                createNewProjectViewmodel.updateMetaData(
                                                                  state.metadata.copyWith(
                                                                    timeZone: value,
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: BorderedTextfield(
                                                              controllerValue: state.metadata.primaryBuildingName,
                                                              label: "Primary Building Name",
                                                              hintText: "Primary Building Name",
                                                              maxLength: maxCharLength,
                                                              onChanged: (
                                                                String value,
                                                              ) {
                                                                createNewProjectViewmodel.updateMetaData(
                                                                  state.metadata.copyWith(
                                                                    primaryBuildingName: value,
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      ),

                                                      const SizedBox(height: 5),
                                                      // ===============================
                                                      //  BUDGET & OBJECTIVES SECTION
                                                      // ===============================
                                                      FusionAppText(
                                                        text: "BUDGET & OBJECTIVES",
                                                        maxLine: 2,
                                                        style: context.textTheme.bodySmall?.copyWith(
                                                          fontWeight: FontWeight.bold,
                                                          color: context.colorScheme.onSurface,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 5),
                                                      Row(
                                                        spacing: 10,
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: <Widget>[
                                                          Expanded(
                                                            child: FusionDropdown2<CurrencyType>(
                                                              selectedValue: state.metadata.currency,
                                                              title: "Currency",
                                                              placeholder: "Select currency",
                                                              items: CurrencyType.values,
                                                              labelBuilder:
                                                                  (
                                                                    CurrencyType value,
                                                                  ) => value.name.toUpperCase(),
                                                              onChanged: (
                                                                CurrencyType value,
                                                              ) {
                                                                createNewProjectViewmodel.updateMetaData(
                                                                  state.metadata.copyWith(
                                                                    currency: value,
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: BorderedTextfield(
                                                              controllerValue: state.metadata.budget,
                                                              label: "Target Budget",
                                                              hintText: "Budget",
                                                              maxLength: maxCharLength,
                                                              inputFormatters: <TextInputFormatter>[
                                                                FilteringTextInputFormatter.allow(
                                                                  RegExp(
                                                                    r'^\d*\.?\d{0,2}',
                                                                  ),
                                                                ),
                                                              ],
                                                              onChanged: (
                                                                String value,
                                                              ) {
                                                                createNewProjectViewmodel.updateMetaData(
                                                                  state.metadata.copyWith(
                                                                    budget: value,
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      ),

                                                      // Project Time Zone
                                                      const SizedBox(height: 5),
                                                      BorderedTextfield(
                                                        controllerValue: state.metadata.projectGoals,
                                                        label: "Project Goals",
                                                        hintText: "Add project goals or objectives",
                                                        minLines: 1,
                                                        maxLines: 10,
                                                        onChanged: (
                                                          String value,
                                                        ) {
                                                          createNewProjectViewmodel.updateMetaData(
                                                            state.metadata.copyWith(
                                                              projectGoals: value,
                                                            ),
                                                          );
                                                        },
                                                      ),

                                                      const SizedBox(height: 5),

                                                      // ===============================
                                                      //  UNITS & GLOBAL SETTINGS SECTION
                                                      // ===============================
                                                      FusionAppText(
                                                        text: "UNITS & GLOBAL SETTINGS",
                                                        maxLine: 2,
                                                        style: context.textTheme.bodySmall?.copyWith(
                                                          fontWeight: FontWeight.bold,
                                                          color: context.colorScheme.onSurface,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 5),
                                                      Row(
                                                        spacing: 10,
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: <Widget>[
                                                          Expanded(
                                                            child: FusionDropdown2<MeasurementUnit>(
                                                              selectedValue: state.metadata.measurementUnit,
                                                              title: "Measurement Units",
                                                              placeholder: "Select",
                                                              items: MeasurementUnit.values,
                                                              labelBuilder: (MeasurementUnit value) => "${value.displayName} (${value.symbol})",
                                                              onChanged: (MeasurementUnit value) {
                                                                createNewProjectViewmodel.updateMetaData(
                                                                  state.metadata.copyWith(
                                                                    measurementUnit: value,
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: FusionDropdown2<String>(
                                                              selectedValue: state.metadata.temperature,
                                                              title: "Temperature",
                                                              placeholder: "Select",
                                                              items: <String>['Celsius', 'Fahrenheit'],
                                                              labelBuilder: (String value) => value,
                                                              onChanged: (String value) {
                                                                createNewProjectViewmodel.updateMetaData(
                                                                  state.metadata.copyWith(
                                                                    temperature: value,
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),

                                      const SizedBox(height: 5),
                                      BorderedTextfield(
                                        controllerValue: state.metadata.notes,
                                        label: "Notes",
                                        hintText: "Add notes or comments",
                                        minLines: 5,
                                        maxLines: 10,
                                        onChanged: (String value) {
                                          createNewProjectViewmodel.updateMetaData(
                                            state.metadata.copyWith(
                                              notes: value,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      Row(
                        children: <Widget>[
                          //  ================================
                          //  Show Less Details Section
                          // ===============================
                          const SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: InkWell(
                              onTap: () => shouldShowMoreDetailsNotifier.value = !shouldShowMoreDetailsNotifier.value,
                              splashColor: Colors.transparent,
                              child: ValueListenableBuilder<bool>(
                                valueListenable: shouldShowMoreDetailsNotifier,
                                builder: (
                                  BuildContext context,
                                  bool value,
                                  Widget? child,
                                ) {
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Flexible(
                                        child: FusionAppText(
                                          text: value ? "Show Less Details" : "Show More Details",
                                          style: context.textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        value ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                                        size: FusionSizes.iconSize16,
                                        color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                          const Spacer(),
                          SemanticHelper.button(
                            testId: SemanticHelper.createTestId(
                              SemanticTypes.button,
                              "create_new_project_button",
                            ),
                            child: FusionNeumorphicButton(
                              semanticId: 'create_new_project_button',
                              onTap: () async {
                                final bool isFormFilled = _formKey.currentState?.validate() ?? false;
                                if (!isFormFilled) return;
                                createNewProjectViewmodel.onSubmit(context);
                              },
                              width: 160,
                              height: 40,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: FusionAppText(
                                        text: isEditMode ? 'Save' : 'Continue',
                                        textAlign: TextAlign.center,
                                        style: context.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: Container(
                                        height: 28,
                                        width: 47,
                                        decoration: BoxDecoration(
                                          color: FusionDarkColorPallette.green20,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Icon(
                                          LucideIcons.arrowRight,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
