// import 'package:flutter/material.dart';
// import 'package:fusion_lib/fusion_lib.dart';
//
// class WidgetDetailsSection extends StatelessWidget {
//   const WidgetDetailsSection({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       clipBehavior: Clip.hardEdge,
//       decoration: BoxDecoration(
//         color: context.colorScheme.primaryBlack,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(width: 1, color: context.colorScheme.elevation2),
//       ),
//       child: const Center(
//         child: FusionAppText(text: 'Widget Details Section'),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fusion_launcher/features/widget_library/models/widget_item.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_flat_container.dart';
import 'package:fusion_lib/models/dock_item_config.dart';
import 'package:fusion_lib/models/fusion_dock_item.dart';
import 'package:provider/provider.dart';

import '../../core/assets/asset_svg.dart';
import 'models/widget_category.dart';
import 'viewmodel/widget_library_viewmodel.dart';

class WidgetDetailsSection extends StatefulWidget {
  const WidgetDetailsSection({super.key});

  @override
  State<WidgetDetailsSection> createState() => _WidgetDetailsSectionState();
}

class _WidgetDetailsSectionState extends State<WidgetDetailsSection> {
  List<String> selected = <String>[];
  bool isOn = false;
  String? wraptext;
  bool isOns = false;
  double height1 = 200;
  double height2 = 150;
  String? select;
  String? selecting;
  final List<String> item = <String>["Apple", "Banana", "Orange"];

  String selectedValue = "Male";
  late DockItem myDockItem;
  late DockItemConfig myConfig;
  List<String> selectedGenders = <String>[];
  String selectedAction = "Edit";
  String selectedCode = "M";

  @override
  void initState() {
    super.initState();

    myDockItem = DockItem(
      id: "settings", // example
      title: "Settings",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WidgetLibraryViewModel>(
      builder: (
        BuildContext context,
        WidgetLibraryViewModel viewModel,
        Widget? child,
      ) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: context.colorScheme.primaryBlack,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              width: 1,
              color: context.colorScheme.elevation5,
            ),
          ),
          child: _buildBody(context, viewModel),
        );
      },
    );
  }

  // ================= BODY SWITCH =================
  Widget _buildBody(
    BuildContext context,
    WidgetLibraryViewModel viewModel,
  ) {
    final WidgetItem? selectedWidget = viewModel.selectedWidget;
    final WidgetCategory? selectedCategory = viewModel.selectedCategory;

    if (selectedWidget == null && selectedCategory == null) {
      return _buildEmptyState(context);
    }

    if (selectedWidget == null && selectedCategory != null) {
      return _buildCategoryPlaceholder(context, selectedCategory);
    }

    return _buildWidgetDetails(context, viewModel);
  }

  // ================= EMPTY STATE =================
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.widgets,
            size: 64,
            color: context.colorScheme.textSecondary,
          ),
          const SizedBox(height: 16),
          FusionAppText(
            text: 'Select a widget to view details',
            style: TextStyle(
              color: context.colorScheme.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ================= CATEGORY PLACEHOLDER =================
  Widget _buildCategoryPlaceholder(
    BuildContext context,
    WidgetCategory category,
  ) {
    String message;

    switch (category) {
      case WidgetCategory.textFields:
        message = 'Text field variants not yet implemented';
        break;
      default:
        message = 'Select a widget from widget library';
    }

    return Center(
      child: FusionAppText(
        text: message,
        style: TextStyle(
          fontSize: 16,
          color: context.colorScheme.textSecondary,
        ),
      ),
    );
  }

  // ================= WIDGET DETAILS =================
  Widget _buildWidgetDetails(
    BuildContext context,
    WidgetLibraryViewModel viewModel,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildHeader(context, viewModel),
          const SizedBox(height: 24),
          _buildVariantsPreview(context, viewModel),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(
    BuildContext context,
    WidgetLibraryViewModel viewModel,
  ) {
    final WidgetItem widget = viewModel.selectedWidget!;

    return Row(
      children: <Widget>[
        const SizedBox(width: 16),

        Column(
          children: <Widget>[
            FusionAppText(
              semanticId: widget.name,
              text: widget.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),
          ],
        ),
      ],
    );
  }

  // ================= VARIANTS PANEL =================
  Widget _buildVariantsPreview(
    BuildContext context,
    WidgetLibraryViewModel viewModel,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colorScheme.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.colorScheme.elevation2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const FusionAppText(
            text: 'Types',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          _buildWidgetVariants(context, viewModel),
        ],
      ),
    );
  }

  // ================= VARIANT ROUTER =================
  Widget _buildWidgetVariants(
    BuildContext context,
    WidgetLibraryViewModel viewModel,
  ) {
    final WidgetItem? widget = viewModel.selectedWidget;

    if (widget == null) {
      return const FusionAppText(
        text: 'No widget selected',
      );
    }

    switch (widget.name) {
      case "FusionAppButton":
        return _buildFusionAppButtonVariants(context);
      case "FusionTextField":
        return _buildFusionTextFieldVariants(context);
      case "RadioButton":
        return _buildRadioButtonVariants(context);
      case "DropDown":
        return _buildDropDownVariants(context);
      case "Popup":
        return _buildPopupVariants(context);
      case "CheckboxGroup":
        return _buildCheckboxGroupVariants(context);
      case "FusionContainer":
        return _buildFusionContainerVariants(context);
      case "FusionFlatContainer":
        return _buildFusionFlatContainerVariants(context);
      case "FusionDialog":
        return _buildFusionDialogVariants(context);
      case "FusionExpandableTileWidget":
        return _buildFusionExpandableTileWidgetVariants(context);
      case "FusionHorizontalResizableWidget":
        return _buildFusionHorizontalResizableWidgetVariants(context);
      case "FusionImage":
        return _buildFusionImageWidgetVariants(context);
      case "FusionKeyboardWrapper":
        return _buildFusionKeyboardWrapperVariants(context);
      case "FusionPopupMenu":
        return _buildFusionPopupMenuVariants(context);
      case "FusionProfileImage":
        return _buildFusionProfileImageVariants(context);
      case "FusionShimmer":
        return _buildFusionShimmerVariants(context);
      case "ReorderableRow":
        return _buildReorderableRowVariants(context);
      case "ReorderableColumn":
        return _buildReorderableColumnVariants(context);
      case "ReorderableFlex":
        return _buildReorderableFlexVariants(context);
      case "FusionToast":
        return _buildFusionToastVariants(context);
      case "FusionVerticalResizableWidget":
        return _buildFusionVerticalResizableWidgetVariants(context);
      case "HoverDropdownButtonFormField":
        return _buildHoverDropdownButtonFormFieldVariants(context);
      case "FusionTable":
        return _buildFusionTableVariants(context);
      case "FusionSwitch":
        return _buildFusionSwitchVariants(context);
      case "FusionSvgIcon":
        return _buildFusionSvgIconVariants(context);

      default:
        return const FusionAppText(
          text: 'Variants not yet implemented',
        );
    }
  }

  // ================= COPY HELPER =================
  Widget _buildWithCopy({
    required BuildContext context,
    required Widget preview,
    required String code,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Flexible(
          child: preview,
        ),

        const SizedBox(width: 8),

        IconButton(
          tooltip: "Copy code",
          icon: const Icon(Icons.copy, size: 18),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: code));

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Copied to clipboard"),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
      ],
    );
  }

  // ================= VARIANTS =================
  Widget _buildFusionAppButtonVariants(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// ================= PRIMARY =================
        _buildWithCopy(
          context: context,
          preview: FusionAppButton(
            semanticId: "Primary",
            text: "Primary",
            showPrefixIcon: true,
            prefixIcon: Icons.arrow_back,
            showSuffixIcon: true,
            suffixIcon: Icons.arrow_forward,
            onPressed: () {},
            IconButton: true,
            style: FusionAppButtonStyle.primary,
          ),
          code: '''
FusionAppButton(
            semanticId: "Primary",
            text: "Primary",
            showPrefixIcon: true,
            prefixIcon: Icons.arrow_back,
            showSuffixIcon: true,
            suffixIcon: Icons.arrow_forward,
            onPressed: () {},
            IconButton: true,
            style: FusionAppButtonStyle.primary,
          ),
''',
        ),
        const SizedBox(
          height: 10,
        ),
        _buildWithCopy(
          context: context,
          preview: FusionAppButton(
            semanticId: "Primary_disabled",
            text: "Primary",
            showPrefixIcon: true,
            prefixIcon: Icons.arrow_back,
            showSuffixIcon: true,
            enabled: false,
            suffixIcon: Icons.arrow_forward,
            onPressed: () {},
            IconButton: true,
            style: FusionAppButtonStyle.primary,
          ),
          code: '''
FusionAppButton(
            semanticId: "Primary_disabled",
            text: "Primary",
            showPrefixIcon: true,
            prefixIcon: Icons.arrow_back,
            showSuffixIcon: true,
            enabled: false,
            suffixIcon: Icons.arrow_forward,
            onPressed: () {},
            IconButton: true,
            style: FusionAppButtonStyle.primary,
          ),
''',
        ),
        const SizedBox(
          height: 10,
        ),
        _buildWithCopy(
          context: context,
          preview: FusionAppButton(
            semanticId: "Secondary",
            text: "Secondary",
            showPrefixIcon: true,
            prefixIcon: Icons.arrow_back,
            showSuffixIcon: true,
            suffixIcon: Icons.arrow_forward,
            onPressed: () {},
            IconButton: true,
            style: FusionAppButtonStyle.secondary,
          ),
          code: '''
FusionAppButton(
            semanticId: "Secondary",
            text: "Secondary",
            showPrefixIcon: true,
            prefixIcon: Icons.arrow_back,
            showSuffixIcon: true,
            suffixIcon: Icons.arrow_forward,
            onPressed: () {},
            IconButton: true,
            style: FusionAppButtonStyle.secondary,
          ),
''',
        ),
        const SizedBox(
          height: 10,
        ),
        _buildWithCopy(
          context: context,
          preview: FusionAppButton(
            semanticId: "Secondary_disabled",
            text: "Secondary",
            showPrefixIcon: true,
            prefixIcon: Icons.arrow_back,
            showSuffixIcon: true,
            enabled: false,
            suffixIcon: Icons.arrow_forward,
            onPressed: () {},
            IconButton: true,
            style: FusionAppButtonStyle.secondary,
          ),
          code: '''
FusionAppButton(
            semanticId: "Secondary_disabled",
            text: "Secondary",
            showPrefixIcon: true,
            prefixIcon: Icons.arrow_back,
            showSuffixIcon: true,
            enabled: false,
            suffixIcon: Icons.arrow_forward,
            onPressed: () {},
            IconButton: true,
            style: FusionAppButtonStyle.secondary,
          ),
''',
        ),
        const SizedBox(
          height: 10,
        ),
        _buildWithCopy(
          context: context,
          preview: FusionAppButton(
            semanticId: "Neuomorpic",
            text: "Neuomorpic",
            showPrefixIcon: true,
            prefixIcon: Icons.arrow_back,
            showSuffixIcon: true,
            suffixIcon: Icons.arrow_forward,
            onPressed: () {},
            IconButton: true,
            style: FusionAppButtonStyle.neumorphic,
          ),
          code: '''
FusionAppButton(
            semanticId: "Neuomorpic",
            text: "Neuomorpic",
            showPrefixIcon: true,
            prefixIcon: Icons.arrow_back,
            showSuffixIcon: true,
            suffixIcon: Icons.arrow_forward,
            onPressed: () {},
            IconButton: true,
            style: FusionAppButtonStyle.neumorphic,
          ),
''',
        ),
        const SizedBox(
          height: 10,
        ),
        _buildWithCopy(
          context: context,
          preview: FusionAppButton(
            text: "Neuomorpic",
            semanticId: "Neuomorpic_disabled",
            showPrefixIcon: true,
            prefixIcon: Icons.arrow_back,
            showSuffixIcon: true,
            enabled: false,
            suffixIcon: Icons.arrow_forward,
            onPressed: () {},
            IconButton: true,
            style: FusionAppButtonStyle.neumorphic,
          ),
          code: '''
FusionAppButton(
            text: "Neuomorpic",
            semanticId: "Neuomorpic_disabled",
            showPrefixIcon: true,
            prefixIcon: Icons.arrow_back,
            showSuffixIcon: true,
            enabled: false,
            suffixIcon: Icons.arrow_forward,
            onPressed: () {},
            IconButton: true,
            style: FusionAppButtonStyle.neumorphic,
          ),
''',
        ),

        const SizedBox(
          height: 10,
        ),
        _buildWithCopy(
          context: context,
          preview: FusionAppButton(
            semanticId: "Brand Green",
            text: "Brand Green",
            showPrefixIcon: true,
            prefixIcon: Icons.arrow_back,
            showSuffixIcon: true,
            suffixIcon: Icons.arrow_forward,
            onPressed: () {},
            IconButton: true,
            style: FusionAppButtonStyle.brand,
          ),
          code: '''
FusionAppButton(
            semanticId: "Brand Green",
            text: "Brand Green",
            showPrefixIcon: true,
            prefixIcon: Icons.arrow_back,
            showSuffixIcon: true,
            suffixIcon: Icons.arrow_forward,
            onPressed: () {},
            IconButton: true,
            style: FusionAppButtonStyle.brand,
          ),
''',
        ),
        const SizedBox(
          height: 10,
        ),
        _buildWithCopy(
          context: context,
          preview: FusionAppButton(
            semanticId: "Brand_Green_disabled",
            text: "Brand Green",
            showPrefixIcon: true,
            prefixIcon: Icons.arrow_back,
            showSuffixIcon: true,
            enabled: false,
            suffixIcon: Icons.arrow_forward,
            onPressed: () {},
            IconButton: true,
            style: FusionAppButtonStyle.brand,
          ),
          code: '''
FusionAppButton(
            semanticId: "Brand_Green_disabled",
            text: "Brand Green",
            showPrefixIcon: true,
            prefixIcon: Icons.arrow_back,
            showSuffixIcon: true,
            enabled: false,
            suffixIcon: Icons.arrow_forward,
            onPressed: () {},
            IconButton: true,
            style: FusionAppButtonStyle.brand,
          ),
''',
        ),

        const SizedBox(
          height: 10,
        ),
        _buildWithCopy(
          context: context,
          preview: FusionAppButton(
            semanticId: "Tertiary",
            text: "Tertiary",
            showPrefixIcon: true,
            prefixIcon: Icons.arrow_back,
            showSuffixIcon: true,
            suffixIcon: Icons.arrow_forward,
            onPressed: () {},
            IconButton: true,
            style: FusionAppButtonStyle.tertiary,
          ),
          code: '''
FusionAppButton(
            semanticId: "Tertiary",
            text: "Tertiary",
            showPrefixIcon: true,
            prefixIcon: Icons.arrow_back,
            showSuffixIcon: true,
            suffixIcon: Icons.arrow_forward,
            onPressed: () {},
            IconButton: true,
            style: FusionAppButtonStyle.tertiary,
          ),
''',
        ),
        const SizedBox(
          height: 10,
        ),
        _buildWithCopy(
          context: context,
          preview: FusionAppButton(
            semanticId: "Tertiary_disabled",
            text: "Tertiary",
            showPrefixIcon: true,
            prefixIcon: Icons.arrow_back,
            showSuffixIcon: true,
            enabled: false,
            suffixIcon: Icons.arrow_forward,
            onPressed: () {},
            IconButton: true,
            style: FusionAppButtonStyle.tertiary,
          ),
          code: '''
FusionAppButton(
            semanticId: "Tertiary_disabled",
            text: "Tertiary",
            showPrefixIcon: true,
            prefixIcon: Icons.arrow_back,
            showSuffixIcon: true,
            enabled: false,
            suffixIcon: Icons.arrow_forward,
            onPressed: () {},
            IconButton: true,
            style: FusionAppButtonStyle.tertiary,
          ),
''',
        ),
        const SizedBox(
          height: 10,
        ),
        _buildWithCopy(
          context: context,
          preview: FusionAppButton(
            semanticId: "Link",
            text: "Link",
            showPrefixIcon: true,
            prefixIcon: Icons.arrow_back,
            showSuffixIcon: true,
            suffixIcon: Icons.arrow_forward,
            onPressed: () {},
            IconButton: true,
            style: FusionAppButtonStyle.link,
          ),
          code: '''
FusionAppButton(
            semanticId: "Link",
            text: "Link",
            showPrefixIcon: true,
            prefixIcon: Icons.arrow_back,
            showSuffixIcon: true,
            suffixIcon: Icons.arrow_forward,
            onPressed: () {},
            IconButton: true,
            style: FusionAppButtonStyle.link,
          ),
''',
        ),
        const SizedBox(
          height: 10,
        ),
        _buildWithCopy(
          context: context,
          preview: FusionAppButton(
            semanticId: "Link_disabled",
            text: "Link",
            showPrefixIcon: true,
            prefixIcon: Icons.arrow_back,
            showSuffixIcon: true,
            enabled: false,
            suffixIcon: Icons.arrow_forward,
            onPressed: () {},
            IconButton: true,
            style: FusionAppButtonStyle.link,
          ),
          code: '''
FusionAppButton(
            semanticId: "Link_disabled",
            text: "Link",
            showPrefixIcon: true,
            prefixIcon: Icons.arrow_back,
            showSuffixIcon: true,
            enabled: false,
            suffixIcon: Icons.arrow_forward,
            onPressed: () {},
            IconButton: true,
            style: FusionAppButtonStyle.link,
          ),
''',
        ),
      ],
    );
  }

  Widget _buildFusionTextFieldVariants(BuildContext context) {
    return Column(
      children: <Widget>[
        // ================= DEFAULT (OUTLINE) =================
        _buildWithCopy(
          context: context,
          preview: CustomTextField(
            semanticId: "Default",
            label: "Default",
            hint: "Value",
            controller: TextEditingController(),
            variant: FusionFieldVariant.outline,
          ),
          code: '''
CustomTextField(
            semanticId: "Default",
            label: "Default",
            hint: "Value",
            controller: TextEditingController(),
            variant: FusionFieldVariant.outline,
          ),
''',
        ),

        // ================= DEFAULT (NEUMORPHIC) =================
        _buildWithCopy(
          context: context,
          preview: CustomTextField(
            semanticId: "Neumorphic",
            label: "Neumorphic",
            hint: "Value",
            controller: TextEditingController(),
            variant: FusionFieldVariant.neumorphic,
          ),
          code: '''
CustomTextField(
            semanticId: "Neumorphic",
            label: "Neumorphic",
            hint: "Value",
            controller: TextEditingController(),
            variant: FusionFieldVariant.neumorphic,
          ),''',
        ),

        // ================= ERROR =================
        _buildWithCopy(
          context: context,
          preview: CustomTextField(
            semanticId: "Error",
            label: "Error",
            hint: "Value",
            controller: TextEditingController(text: "123"),
            hasErrorText: true,
            errorText: "Invalid value",
          ),
          code: '''
CustomTextField(
            semanticId: "Error",
            label: "Error",
            hint: "Value",
            controller: TextEditingController(text: "123"),
            hasErrorText: true,
            errorText: "Invalid value",
          ),
''',
        ),

        // ================= BLOCKED =================
        _buildWithCopy(
          context: context,
          preview: CustomTextField(
            label: "Blocked",
            semanticId: "Blocked",
            hint: "Value",
            controller: TextEditingController(),
            enabled: false,
          ),
          code: '''
CustomTextField(
            label: "Blocked",
            semanticId: "Blocked",
            hint: "Value",
            controller: TextEditingController(),
            enabled: false,
          ),
''',
        ),

        // ================= BLOCKED FILLED =================
        _buildWithCopy(
          context: context,
          preview: CustomTextField(
            label: "Blocked Filled",
            semanticId: "Blocked Filled",
            hint: "Value",
            controller: TextEditingController(text: "Readonly"),
            enabled: false,
          ),
          code: '''
CustomTextField(
            label: "Blocked Filled",
            semanticId: "Blocked Filled",
            hint: "Value",
            controller: TextEditingController(text: "Readonly"),
            enabled: false,
          ),
''',
        ),

        // ================= WITH BUTTON =================
        _buildWithCopy(
          context: context,
          preview: CustomTextField(
            semanticId: "With Button",
            label: "With Button",
            hint: "Value",
            controller: TextEditingController(),
            button: true,
            buttonText: "Submit",
            buttonTap: () {
              debugPrint("Submit");
            },
          ),
          code: '''
CustomTextField(
            semanticId: "With Button",
            label: "With Button",
            hint: "Value",
            controller: TextEditingController(),
            button: true,
            buttonText: "Submit",
            buttonTap: () {
              debugPrint("Submit");
            },
          ),
''',
        ),

        // ================= COUNTRY PICKER =================
        _buildWithCopy(
          context: context,
          preview: CustomTextField(
            semanticId: "Phone",
            label: "Phone",
            hint: "Mobile Number",
            controller: TextEditingController(),
            showCountryCode: true,
            inputType: TextInputType.phone,
          ),
          code: '''
CustomTextField(
            semanticId: "Phone",
            label: "Phone",
            hint: "Mobile Number",
            controller: TextEditingController(),
            showCountryCode: true,
            inputType: TextInputType.phone,
          ),
''',
        ),

        // ================= PREFIX + SUFFIX =================
        _buildWithCopy(
          context: context,
          preview: CustomTextField(
            semanticId: "Icons",
            label: "Icons",
            hint: "Value",
            controller: TextEditingController(),
            showPrefixIcon: true,
            showSuffixIcon: true,
            prefixIcon: Icons.search,
            suffixIcon: Icons.clear,
          ),
          code: '''
CustomTextField(
            semanticId: "Icons",
            label: "Icons",
            hint: "Value",
            controller: TextEditingController(),
            showPrefixIcon: true,
            showSuffixIcon: true,
            prefixIcon: Icons.search,
            suffixIcon: Icons.clear,
          ),
''',
        ),

        // ================= INFO + HELPERS =================
        _buildWithCopy(
          context: context,
          preview: CustomTextField(
            label: "Info",
            semanticId: "Info",
            hint: "Value",
            controller: TextEditingController(),
            info: true,
            infoTap: () {
              debugPrint("Info clicked");
            },
            hasHelperText: true,
            helperText: "Enter valid value",
          ),
          code: '''
CustomTextField(
            label: "Info",
            semanticId: "Info",
            hint: "Value",
            controller: TextEditingController(),
            info: true,
            infoTap: () {
              debugPrint("Info clicked");
            },
            hasHelperText: true,
            helperText: "Enter valid value",
          ),
''',
        ),

        // ================= SUCCESS =================
        _buildWithCopy(
          context: context,
          preview: CustomTextField(
            label: "Success",
            semanticId: "Success",
            hint: "Value",
            controller: TextEditingController(text: "Done"),
            hasSuccessText: true,
            successText: "Looks good",
          ),
          code: '''
CustomTextField(
            label: "Success",
            semanticId: "Success",
            hint: "Value",
            controller: TextEditingController(text: "Done"),
            hasSuccessText: true,
            successText: "Looks good",
          ),
''',
        ),

        _buildWithCopy(
          context: context,
          preview: CustomTextField(
            label: "Disabled",
            semanticId: "Disabled",
            hint: "Value",
            controller: TextEditingController(),
            variant: FusionFieldVariant.outline,
            fieldState: FusionFieldState.blocked,
          ),
          code: '''
CustomTextField(
            label: "Disabled",
            semanticId: "Disabled",
            hint: "Value",
            controller: TextEditingController(),
            variant: FusionFieldVariant.outline,
            fieldState: FusionFieldState.blocked,
          ),
''',
        ),
        _buildWithCopy(
          context: context,
          preview: CustomTextField(
            showLabel: true,
            label: "Label",
            semanticId: "Label",
            info: true,
            showPrefixIcon: true,
            prefixIcon: Icons.arrow_drop_down_outlined,
            showSuffixIcon: true,
            button: true,
            buttonText: "Button",
            enabled: false,
            suffixIcon: Icons.arrow_drop_down_outlined,
            showCountryCode: true,
            showRupee: true,
            hasHelperText: true,
            helperText: "Helper Text",
            hasSuccessText: true,
            successText: "Success Message",
            hasErrorText: true,
            errorText: "Error Message",
            hint: "Value",
            controller: TextEditingController(),
            variant: FusionFieldVariant.outline,
            fieldState: FusionFieldState.blocked,
          ),
          code: '''
CustomTextField(
            showLabel: true,
            label: "Label",
            semanticId: "Label",
            info: true,
            showPrefixIcon: true,
            prefixIcon: Icons.arrow_drop_down_outlined,
            showSuffixIcon: true,
            button: true,
            buttonText: "Button",
            enabled: false,
            suffixIcon: Icons.arrow_drop_down_outlined,
            showCountryCode: true,
            showRupee: true,
            hasHelperText: true,
            helperText: "Helper Text",
            hasSuccessText: true,
            successText: "Success Message",
            hasErrorText: true,
            errorText: "Error Message",
            hint: "Value",
            controller: TextEditingController(),
            variant: FusionFieldVariant.outline,
            fieldState: FusionFieldState.blocked,
          ),
''',
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildRadioButtonVariants(BuildContext context) {
    return Column(
      children: <Widget>[
        // ================= DEFAULT =================
        _buildWithCopy(
          context: context,
          preview: RadioButton(
            shape: BoxShape.rectangle,
            state: FusionSelectionState.partial,
            variant: FusionSelectionVariant.checkbox,
            semanticId: "checkbox",
            onTap: () {},
          ),

          code: '''
          RadioButton(
            shape: BoxShape.rectangle,
            state: FusionSelectionState.partial,
            variant: FusionSelectionVariant.checkbox,
            semanticId: "checkbox",
            onTap: () {},
          ),
''',
        ),

        _buildWithCopy(
          context: context,
          preview: RadioButton(
            shape: BoxShape.circle,
            variant: FusionSelectionVariant.radio,
            onTap: () {},
            semanticId: "radiobutton",
          ),

          code: '''
 RadioButton(
            shape: BoxShape.circle,
            variant: FusionSelectionVariant.radio,
            onTap: () {},
            semanticId: "radiobutton",
          ),
''',
        ),

        _buildWithCopy(
          context: context,
          preview: FusionRadio<String>(
            semanticId: "default",
            selected: select,
            options: <String>['Option 1', 'Option 2', 'Option 3'],
            labelBuilder: (String option) => Text(option),
            onChanged: (String value) {
              setState(() {
                select = value;
              });
            },
          ),

          code: '''
FusionRadio<String>(
            semanticId: "default",
            selected: select,
            options: <String>['Option 1', 'Option 2', 'Option 3'],
            labelBuilder: (String option) => Text(option),
            onChanged: (String value) {
              setState(() {
                select = value;
              });
            },
          ),
''',
        ),

        _buildWithCopy(
          context: context,
          preview: RadioButton(
            semanticId: "radiobox",
            shape: BoxShape.circle,
            variant: FusionSelectionVariant.radioBox,
            label: "Option 1",
            onTap: () {},
          ),

          code: '''
RadioButton(
            semanticId: "radiobox",
            shape: BoxShape.circle,
            variant: FusionSelectionVariant.radioBox,
            label: "Option 1",
            onTap: () {},
          ),
''',
        ),

        const SizedBox(
          height: 4,
        ),
        _buildWithCopy(
          context: context,
          preview: RadioButton(
            semanticId: "radiooption_v1",
            variant: FusionSelectionVariant.radioOption,
            iconPrifix: true,
            label: "Hello",
          ),

          code: '''
RadioButton(
            semanticId: "radiooption",
            variant: FusionSelectionVariant.radioOption,
            iconPrifix: true,
            label: "Hello",
          ),
''',
        ),
        const SizedBox(
          height: 10,
        ),
        _buildWithCopy(
          context: context,
          preview: RadioButton(
            semanticId: "radiooption_v2",
            variant: FusionSelectionVariant.radioOption,
            iconPrifix: false,
            label: "Hello",
          ),

          code: '''
RadioButton(
            semanticId: "radiooption_v2",
            variant: FusionSelectionVariant.radioOption,
            iconPrifix: false,
            label: "Hello",
          ),
''',
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDropDownVariants(BuildContext context) {
    int selectedIndex = 0;
    return Column(
      children: <Widget>[
        // ================= DROPDOWN =================
        _buildWithCopy(
          context: context,
          preview: FusionDropDown<String>(
            semanticId: "itembased",
            items: <String>["Small", "Medium", "Large"],
            selectedIndex: selectedIndex,

            itemBuilder: (BuildContext context, String item, bool isSelected) {
              return Text(
                item,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            },

            childBuilder: (BuildContext context, int index, String item) {
              return Text(item);
            },

            onSelected: (int index) {
              setState(() => selectedIndex = index);
            },
          ),

          code: '''
FusionDropDown<String>(
            semanticId: "itembased",
            items: <String>["Small", "Medium", "Large"],
            selectedIndex: selectedIndex,

            itemBuilder: (BuildContext context, String item, bool isSelected) {
              return Text(
                item,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            },

            childBuilder: (BuildContext context, int index, String item) {
              return Text(item);
            },

            onSelected: (int index) {
              setState(() => selectedIndex = index);
            },
          ),
''',
        ),
        _buildWithCopy(
          context: context,
          preview: FusionDropDown<String>(
            semanticId: "iconbased",
            items: <String>["Edit", "Delete", "Share"],
            selectedIndex: 0,

            trigger: const Icon(Icons.more_vert),

            itemBuilder: (BuildContext context, String item, bool isSelected) {
              return Text(item);
            },

            childBuilder: null,

            // Not needed when trigger is used
            onSelected: (int index) {},
          ),

          code: '''
FusionDropDown<String>(
            semanticId: "iconbased",
            items: <String>["Edit", "Delete", "Share"],
            selectedIndex: 0,

            trigger: const Icon(Icons.more_vert),

            itemBuilder: (BuildContext context, String item, bool isSelected) {
              return Text(item);
            },

            childBuilder: null, // Not needed when trigger is used

            onSelected: (int index) {
            },
          ),
''',
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPopupVariants(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildWithCopy(
          context: context,
          preview: FusionArrowPopup(
            semanticId: "tap_popup",
            content: Container(
              padding: const EdgeInsets.all(12),
              child: const Text("Hello Popup"),
            ),
            child: const Icon(Icons.info_outline),
          ),
          code: '''
FusionArrowPopup(
            semanticId: "tap_popup",
            content: Container(
              padding: const EdgeInsets.all(12),
              child: const Text("Hello Popup"),
            ),
            child: const Icon(Icons.info_outline),
          ),
''',
        ),

        _buildWithCopy(
          context: context,
          preview: FusionArrowPopup(
            semanticId: "show_on_load",
            showOnCreate: true,
            content: const Text("Tap here to start"),
            child: ElevatedButton(
              onPressed: () {},
              child: const Text("Start"),
            ),
          ),
          code: '''
FusionArrowPopup(
            semanticId: "show_on_load",
            showOnCreate: true,
            content: const Text("Tap here to start"),
            child: ElevatedButton(
              onPressed: () {},
              child: const Text("Start"),
            ),
          ),
''',
        ),
        _buildWithCopy(
          context: context,
          preview: const FusionArrowPopup(
            semanticId: "disabled",
            enabled: false,
            content: Text("Disabled"),
            child: Icon(Icons.lock),
          ),
          code: '''
FusionArrowPopup(
            semanticId: "disabled",
            enabled: false,
            content: Text("Disabled"),
            child: Icon(Icons.lock),
          ),
''',
        ),
        _buildWithCopy(
          context: context,
          preview: const FusionArrowPopup(
            semanticId: "background_color",
            backgroundColor: Colors.black,
            arrowColor: Colors.black,
            content: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                "Dark Theme",
                style: TextStyle(color: Colors.white),
              ),
            ),
            child: Icon(Icons.dark_mode),
          ),
          code: '''
FusionArrowPopup(
            semanticId: "background_color",
            backgroundColor: Colors.black,
            arrowColor: Colors.black,
            content: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                "Dark Theme",
                style: TextStyle(color: Colors.white),
              ),
            ),
            child: Icon(Icons.dark_mode),
          ),
''',
        ),
        _buildWithCopy(
          context: context,
          preview: FusionArrowPopup(
            semanticId: "menu_popup",
            maxWidth: 180,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  title: const Text("Edit"),
                  onTap: () {},
                ),
                ListTile(
                  title: const Text("Delete"),
                  onTap: () {},
                ),
              ],
            ),
            child: const Icon(Icons.more_vert),
          ),

          code: '''
FusionArrowPopup(
            semanticId: "menu_popup",
            maxWidth: 180,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  title: const Text("Edit"),
                  onTap: () {},
                ),  
                ListTile(
                  title: const Text("Delete"),
                  onTap: () {},
                ),
              ],
            ),
            child: const Icon(Icons.more_vert),
          ),
''',
        ),
        _buildWithCopy(
          context: context,
          preview: const FusionArrowPopup(
            semanticId: "No_Arrow_Popup",
            showArrow: false,
            content: Padding(
              padding: EdgeInsets.all(16),
              child: Text("No Arrow Popup"),
            ),
            child: Icon(Icons.open_in_new),
          ),

          code: '''
FusionArrowPopup(
            semanticId: "No_Arrow_Popup",
            showArrow: false,
            content: Padding(
              padding: EdgeInsets.all(16),
              child: Text("No Arrow Popup"),
            ),
            child: Icon(Icons.open_in_new),
          ),
''',
        ),
        _buildWithCopy(
          context: context,
          preview: FusionArrowPopup(
            semanticId: "background_blur",
            shouldBlur: true,
            blurAmount: 6,
            onDismiss: () {
              debugPrint("Popup Closed");
            },
            content: const Text("Blurred Background"),
            child: const Icon(Icons.visibility),
          ),

          code: '''
FusionArrowPopup(
            semanticId: "background_blur",
            shouldBlur: true,
            blurAmount: 6,
            onDismiss: () {
              debugPrint("Popup Closed");
            },
            content: const Text("Blurred Background"),
            child: const Icon(Icons.visibility),
          ),
''',
        ),
        _buildWithCopy(
          context: context,
          preview: FusionArrowPopup(
            semanticId: "form",
            maxWidth: 300,
            content: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const TextField(
                    decoration: InputDecoration(labelText: "Name"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text("Submit"),
                  ),
                ],
              ),
            ),
            child: const Icon(Icons.edit),
          ),

          code: '''
 FusionArrowPopup(
            semanticId: "form",
            maxWidth: 300,
            content: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const TextField(
                    decoration: InputDecoration(labelText: "Name"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text("Submit"),
                  ),
                ],
              ),
            ),
            child: const Icon(Icons.edit),
          ),
''',
        ),
        _buildWithCopy(
          context: context,
          preview: const FusionArrowPopup(
            semanticId: "card",
            maxWidth: 500,
            maxHeight: 900,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircleAvatar(radius: 24),
                SizedBox(height: 8),
                Text("Developer"),
                Text("Flutter Dev"),
              ],
            ),
            child: CircleAvatar(),
          ),

          code: '''
 FusionArrowPopup(
            semanticId: "card",
            maxWidth: 220,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircleAvatar(radius: 24),
                SizedBox(height: 8),
                Text("Developer"),
                Text("Flutter Dev"),
              ],
            ),
            child: CircleAvatar(),
          ),
''',
        ),
      ],
    );
  }

  Widget _buildFusionPopupMenuVariants(BuildContext context) {
    return Column(
      children: <Widget>[
        /// -------- Multi Select --------
        _buildWithCopy(
          context: context,
          preview: FusionPopupMenu<String>(
            semanticsId: "default",
            matchChildWidth: false,
            items: const <String>["Male", "Female", "Other"],

            onSelected: (String value) {
              setState(() {
                if (selectedGenders.contains(value)) {
                  selectedGenders.remove(value);
                } else {
                  selectedGenders.add(value);
                }
              });
            },

            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  selectedGenders.isEmpty
                      ? "Select"
                      : selectedGenders.join(", "),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),

          code: '''FusionPopupMenu<String>(
          semanticsId: "default",
            matchChildWidth: false,
            items: const <String>["Male", "Female", "Other"],

            onSelected: (String value) {
              setState(() {
                if (selectedGenders.contains(value)) {
                  selectedGenders.remove(value);
                } else {
                  selectedGenders.add(value);
                }
              });
            },

            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  selectedGenders.isEmpty
                      ? "Select"
                      : selectedGenders.join(", "),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),''',
        ),

        /// -------- Code → Label Menu --------
        _buildWithCopy(
          context: context,
          preview: FusionPopupMenu<String>(
            semanticsId: "with_icon",
            items: const <String>["M", "F", "O"],
            matchChildWidth: false,
            itemLabels: const <String, String>{
              "M": "Male",
              "F": "Female",
              "O": "Other",
            },

            onSelected: (String value) {
              setState(() {
                selectedCode = value;
              });
            },

            child: Text(
              const <String, String>{
                "M": "Male",
                "F": "Female",
                "O": "Other",
              }[selectedCode]!,
            ),
          ),

          code: '''FusionPopupMenu<String>(
          semanticsId: "with_icon",
            items: const <String>["M", "F", "O"],
            matchChildWidth: false,
            itemLabels: const <String, String>{
              "M": "Male",
              "F": "Female",
              "O": "Other",
            },

            onSelected: (String value) {
              setState(() {
                selectedCode = value;
              });
            },

            child: Text(
              const <String, String>{
                "M": "Male",
                "F": "Female",
                "O": "Other",
              }[selectedCode]!,
            ),
          ),''',
        ),
      ],
    );
  }

  Widget _buildCheckboxGroupVariants(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildWithCopy(
          context: context,
          preview: FusionCheckboxGroup<String>(
            direction: Axis.vertical,
            semanticId: "vertical",
            spacing: 12,

            options: const <String>["Male", "Female", "Other"],

            selected: selected,

            labelBuilder: (_, String v) => Text(v),

            onChanged: (List<String> v) {
              setState(() {
                selected = <String>[...v];
              });
            },
          ),

          code: '''
FusionCheckboxGroup<String>(
            semanticId: "vertical",
            direction: Axis.vertical,
            spacing: 12,

            options: const <String>["Male", "Female", "Other"],

            selected: selected,

            labelBuilder: (_, String v) => Text(v),

            onChanged: (List<String> v) {
              setState(() {
                selected = <String>[...v];
              });
            },
          ),
''',
        ),

        _buildWithCopy(
          context: context,
          preview: FusionCheckboxGroup<String>(
            semanticId: "vertical",
            options: <String>["Home", "Work", "School"],
            selected: selected,
            labelBuilder: (BuildContext context, String option) {
              return Row(
                children: <Widget>[
                  const Icon(Icons.location_on, size: 14),
                  const SizedBox(width: 4),
                  Text(option),
                ],
              );
            },
            onChanged: (List<String> value) {
              setState(() => selected = value);
            },
          ),

          code: '''
FusionArrowPopup(
            semanticId: "show_on_load",
            showOnCreate: true,
            content: const Text("Tap here to start"),
            child: ElevatedButton(
              onPressed: () {},
              child: const Text("Start"),
            ),
          ),
''',
        ),
      ],
    );
  }

  Widget _buildFusionContainerVariants(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildWithCopy(
          context: context,
          preview: const FusionContainer(
            width: 150,
            height: 40,
            semanticId: "default_Container",
            child: Center(child: Text("Hello Fusion")),
          ),

          code: '''
const FusionContainer(
            semanticId: "default_Container",
            child: Text("Hello Fusion"),
          ),
          ''',
        ),

        _buildWithCopy(
          context: context,
          preview: FusionContainer(
            width: 150,
            semanticId: "coloured",
            height: 40,
            color: context.colorScheme.elevation5,
            child: const Center(
              child: Text("Coloured"),
            ),
          ),
          code: '''
FusionContainer(
            width: 150,
            semanticId: "coloured",
            height: 40,
            color: context.colorScheme.elevation5,
            child: const Center(
              child: Text("Coloured"),
            ),
          ),
          ''',
        ),
        const SizedBox(
          height: 10,
        ),
        _buildWithCopy(
          context: context,
          preview: const FusionContainer(
            semanticId: "raised",
            raised: true,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text("Raised Container"),
            ),
          ),
          code: '''
const FusionContainer(
            semanticId: "raised",
            raised: true,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text("Raised Container"),
            ),
          ),
          ''',
        ),
        const SizedBox(
          height: 10,
        ),
        const SizedBox(
          height: 10,
        ),
        _buildWithCopy(
          context: context,
          preview: const FusionContainer(
            height: 50,
            width: 200,
            semanticId: "aligned",
            alignment: Alignment.centerRight,
            child: Text("Right Aligned"),
          ),
          code: '''
const FusionContainer(
            height: 50,
            width: 200,
            semanticId: "aligned",
            alignment: Alignment.centerRight,
            child: Text("Right Aligned"),
          ),
          ''',
        ),
        const SizedBox(
          height: 10,
        ),
      ],
    );
  }

  Widget _buildFusionHorizontalResizableWidgetVariants(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildWithCopy(
          context: context,
          preview: const FusionHorizontalResizableWidget(
            semanticId: "drag_left",
            child: Text("Drag Left"),
            dragLeft: true,
          ),

          code: '''
const FusionHorizontalResizableWidget(
            semanticId: "drag_left",
            child: Text("Drag Left"),
            dragLeft: true,
          ),
          ''',
        ),

        _buildWithCopy(
          context: context,
          preview: const FusionHorizontalResizableWidget(
            semanticId: "drag_right",
            dragRight: true,
            child: Center(
              child: Text("Drag Right"),
            ),
          ),
          code: '''
FusionContainer(
            width: 150,
            semanticId: "coloured",
            height: 40,
            color: context.colorScheme.elevation5,
            child: const Center(
              child: Text("Coloured"),
            ),
          ),
          ''',
        ),
        const SizedBox(
          height: 10,
        ),
      ],
    );
  }

  Widget _buildFusionVerticalResizableWidgetVariants(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildWithCopy(
          context: context,
          preview: FusionVerticalResizableWidget(
            semanticId: "drag_up",
            initialHeight: height1,
            minHeight: 100,
            maxHeight: 400,
            dragTop: true,
            dragBottom: false,
            onHeightChanged: (double newHeight) {
              setState(() {
                height1 = newHeight;
              });
            },
            child: Container(
              color: Colors.blue.withOpacity(0.2),
              child: const Center(
                child: Text("Drag from Top"),
              ),
            ),
          ),

          code: '''
 FusionVerticalResizableWidget(
            semanticId: "drag_up",
            initialHeight: height1,
            minHeight: 100,
            maxHeight: 400,
            dragTop: true,
            dragBottom: false,
            onHeightChanged: (double newHeight) {
              setState(() {
                height1 = newHeight;
              });
            },
            child: Container(
              color: Colors.blue.withOpacity(0.2),
              child: const Center(
                child: Text("Drag from Top"),
              ),
            ),
          ),
          ''',
        ),
        const SizedBox(
          height: 20,
        ),
        _buildWithCopy(
          context: context,
          preview: FusionVerticalResizableWidget(
            semanticId: "drag_down",
            initialHeight: height2,
            minHeight: 100,
            maxHeight: 400,
            dragTop: false,
            dragBottom: true,
            onHeightChanged: (double newHeight) {
              setState(() {
                height2 = newHeight;
              });
            },
            child: Container(
              color: Colors.green.withOpacity(0.2),
              child: const Center(
                child: Text("Drag from Bottom"),
              ),
            ),
          ),
          code: '''
FusionVerticalResizableWidget(
            semanticId: "drag_down",
            initialHeight: height2,
            minHeight: 100,
            maxHeight: 400,
            dragTop: false,
            dragBottom: true,
            onHeightChanged: (double newHeight) {
              setState(() {
                height2 = newHeight;
              });
            },
            child: Container(
              color: Colors.green.withOpacity(0.2),
              child: const Center(
                child: Text("Drag from Bottom"),
              ),
            ),
          ),
          ''',
        ),
        const SizedBox(
          height: 10,
        ),
      ],
    );
  }

  Widget _buildFusionFlatContainerVariants(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildWithCopy(
          context: context,
          preview: const FusionFlatContainer(
            width: 150,
            height: 50,
            semanticId: "default_Container",
            child: Text("Hello Fusion"),
          ),

          code: '''
const FusionFlatContainer(
            width: 150,
            height: 50,
            semanticId: "default_Container",
            child: Text("Hello Fusion"),
          ),
          ''',
        ),

        _buildWithCopy(
          context: context,
          preview: FusionFlatContainer(
            width: 150,
            height: 50,
            semanticId: "coloured",
            color: context.colorScheme.elevation5,
            child: const Center(
              child: Text("Coloured"),
            ),
          ),
          code: '''
FusionFlatContainer(
            width: 150,
            height: 50,
            semanticId: "coloured",
            color: context.colorScheme.elevation5,
            child: const Center(
              child: Text("Coloured"),
            ),
          ),
          ),
          ''',
        ),
        const SizedBox(
          height: 10,
        ),
        _buildWithCopy(
          context: context,
          preview: FusionFlatContainer(
            width: 150,
            height: 50,
            semanticId: "coloured",
            borderColor: context.colorScheme.elevation6,
            child: const Center(
              child: Text("Border"),
            ),
          ),
          code: '''
FusionFlatContainer(
            width: 150,
            height: 50,
            semanticId: "coloured",
            borderColor: context.colorScheme.elevation6,
            child: const Center(
              child: Text("Border"),
            ),
          ),
          ''',
        ),
        const SizedBox(
          height: 10,
        ),
      ],
    );
  }

  Widget _buildFusionDialogVariants(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildWithCopy(
          context: context,
          preview: ElevatedButton(
            onPressed: () {
              DialogBox.showSuccess(
                context,
                type: DialogType.success,
                title: "Modal Title Text",
                description:
                    "This is a brief overview of the modal, usually consisting of 2 to 3 lines that provide essential information.",
                copyText: "COPY TEXT",
                contactEmail: "info@boseprofessional.com",
                primaryButtonText: "Primary Button",
                secondaryButtonText: "Secondary Button",
                onPrimaryPressed: () {},
                onSecondaryPressed: () {},
                showCopyButton: true,
                horizontal: true,
                vertical: true,
              );
            },
            child: const Text("Hello"),
          ),

          code: '''
        FusionDialog(
                    semanticId: "default",
                    title: "Success",
                    description: "Your data was saved successfully.",

                    primaryButtonLabel: "OK",
                    onPrimaryPressed: () {},
                  ),
                  ''',
        ),
        _buildWithCopy(
          context: context,
          preview: ElevatedButton(
            onPressed: () {
              DialogBox.showSuccess(
                context,
                type: DialogType.success,
                title: "Modal Title Text",
                description:
                    "This is a brief overview of the modal, usually consisting of 2 to 3 lines that provide essential information.",
                copyText: "COPY TEXT",
                contactEmail: "info@boseprofessional.com",
                primaryButtonText: "Primary Button",
                secondaryButtonText: "Secondary Button",
                onPrimaryPressed: () {},
                onSecondaryPressed: () {},
                showCopyButton: true,
                horizontal: true,
                vertical: true,
              );
            },
            child: const Text("Hello"),
          ),

          code: '''
        FusionDialog(
                    semanticId: "default",
                    title: "Success",
                    description: "Your data was saved successfully.",

                    primaryButtonLabel: "OK",
                    onPrimaryPressed: () {},
                  ),
                  ''',
        ),

        _buildWithCopy(
          context: context,
          preview: DialogBox(
            type: DialogType.success,
            title: "Modal Title Text",
            description:
                "This is a brief overview of the modal, usually consisting of 2 to 3 lines that provide essential information.",
            copyText: "COPY TEXT",
            contactEmail: "info@boseprofessional.com",
            primaryButtonText: "Primary Button",
            secondaryButtonText: "Secondary Button",
            onPrimaryPressed: () {},
            onSecondaryPressed: () {},
            showCopyButton: true,
            horizontal: true,
            vertical: true,
          ),

          code: '''
        FusionDialog(
                    title: "Delete Item",
                    description: "Are you sure you want to delete this item?",

                    primaryButtonLabel: "Delete",
                    onPrimaryPressed: () {},
                    semanticId: "confirmation",
                    secondaryButtonLabel: "Cancel",
                    onSecondaryPressed: () {},
                  ),
                  ''',
        ),
        _buildWithCopy(
          context: context,
          preview: DialogBox(
            type: DialogType.success,
            devicetype: DeviceType.mobile,
            title: "Modal Title Text",
            description:
                "This is a brief overview of the modal, usually consisting of 2 to 3 lines that provide essential information.",
            copyText: "COPY TEXT",
            contactEmail: "info@boseprofessional.com",
            primaryButtonText: "Primary Button",
            secondaryButtonText: "Secondary Button",
            onPrimaryPressed: () {},
            onSecondaryPressed: () {},
            showCopyButton: true,
            horizontal: true,
            vertical: true,
          ),

          code: '''
        FusionDialog(
                    title: "Delete Item",
                    description: "Are you sure you want to delete this item?",

                    primaryButtonLabel: "Delete",
                    onPrimaryPressed: () {},
                    semanticId: "confirmation",
                    secondaryButtonLabel: "Cancel",
                    onSecondaryPressed: () {},
                  ),
                  ''',
        ),
        const SizedBox(
          height: 10,
        ),
        _buildWithCopy(
          context: context,
          preview: DialogBox(
            type: DialogType.failure,
            title: "Modal Title Text",
            description:
                "This is a brief overview of the modal, usually consisting of 2 to 3 lines that provide essential information.",
            copyText: "COPY TEXT",
            contactEmail: "info@boseprofessional.com",
            primaryButtonText: "Primary Button",
            secondaryButtonText: "Secondary Button",
            onPrimaryPressed: () {},
            onSecondaryPressed: () {},
            showCopyButton: true,
            horizontal: true,
            vertical: true,
          ),

          code: '''
        FusionDialog(
                    title: "Delete Item",
                    description: "Are you sure you want to delete this item?",

                    primaryButtonLabel: "Delete",
                    onPrimaryPressed: () {},
                    semanticId: "confirmation",
                    secondaryButtonLabel: "Cancel",
                    onSecondaryPressed: () {},
                  ),
                  ''',
        ),
        const SizedBox(
          height: 10,
        ),
        _buildWithCopy(
          context: context,
          preview: DialogBox(
            type: DialogType.confirmation,
            title: "Modal Title Text",
            description:
                "This is a brief overview of the modal, usually consisting of 2 to 3 lines that provide essential information.",
            copyText: "COPY TEXT",
            contactEmail: "info@boseprofessional.com",
            primaryButtonText: "Primary Button",
            secondaryButtonText: "Secondary Button",
            onPrimaryPressed: () {},
            onSecondaryPressed: () {},
            showCopyButton: true,
            horizontal: true,
            vertical: true,
          ),
          code: '''
        FusionDialog(
                    semanticId: "erroDialog",
                    title: "warning",
                    description: "This action may affect your account.",

                    icon: Icons.warning,
                    iconColor: Colors.orange,

                    primaryButtonLabel: "Continue",
                    onPrimaryPressed: () {},

                    secondaryButtonLabel: "Back",
                    onSecondaryPressed: () {},
                  ),
                  ''',
        ),
        const SizedBox(
          height: 10,
        ),
        _buildWithCopy(
          context: context,
          preview: DialogBox(
            type: DialogType.warning,
            title: "Modal Title Text",
            description:
                "This is a brief overview of the modal, usually consisting of 2 to 3 lines that provide essential information.",
            copyText: "COPY TEXT",
            contactEmail: "info@boseprofessional.com",
            primaryButtonText: "Primary Button",
            secondaryButtonText: "Secondary Button",
            onPrimaryPressed: () {},
            onSecondaryPressed: () {},
            showCopyButton: true,
            horizontal: true,
            vertical: true,
          ),
          code: '''
        FusionDialog(
                    semanticId: "errorDialog",
                    title: "Error",
                    description: "Something went wrong. Please try again.",

                    icon: Icons.error,
                    iconColor: Colors.red,

                    primaryButtonLabel: "Retry",
                    onPrimaryPressed: () {},
                  ),
                  ''',
        ),
      ],
    );
  }

  Widget _buildFusionExpandableTileWidgetVariants(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildWithCopy(
          context: context,
          preview: FusionExpandableTileWidget(
            item: myDockItem,

            config: const DockItemConfig(
              title: "Settings",
              initiallyExpanded: false,
              allowUndock: true,
              dockItemWidget: Padding(
                padding: EdgeInsets.all(10.0),
                child: Text("Settings Content"),
              ),
              id: '',
              side: '',
            ),

            controller: ExpansibleController(),

            onUndock: (DockItem item, DraggableDetails details) {},

            onExpansionChanged: (DockItem item, bool expanded) {},
          ),

          code: '''
FusionExpandableTileWidget(
            item: myDockItem,

            config: const DockItemConfig(
              title: "Settings",
              initiallyExpanded: false,
              allowUndock: true,
              dockItemWidget: Text("Settings Content"),
              id: '',
              side: '',
            ),

            controller: ExpansibleController(),

            onUndock: (DockItem item, DraggableDetails details) {},

            onExpansionChanged: (DockItem item, bool expanded) {},
          ),
          ''',
        ),
        _buildWithCopy(
          context: context,
          preview: FusionExpandableTileWidget(
            item: myDockItem,

            config: const DockItemConfig(
              title: "Profile",
              initiallyExpanded: true,
              allowUndock: true,
              dockItemWidget: Padding(
                padding: EdgeInsets.all(10.0),
                child: Text("Opened Content"),
              ),
              id: '',
              side: '',
            ),
            controller: ExpansibleController(),
            onUndock: (DockItem item, DraggableDetails details) {},

            onExpansionChanged: (DockItem item, bool expanded) {
              debugPrint("Profile expanded: $expanded");
            },
          ),

          code: '''
FusionExpandableTileWidget(
            item: myDockItem,

            config: const DockItemConfig(
              title: "Profile",
              initiallyExpanded: true, 
              allowUndock: true,
              dockItemWidget: Text("Opened Content"),
              id: '',
              side: '',
            ),
            controller: ExpansibleController(),
            onUndock: (DockItem item, DraggableDetails details) {},

            onExpansionChanged: (DockItem item, bool expanded) {
            },
          ),
          ''',
        ),
        const SizedBox(
          height: 10,
        ),
      ],
    );
  }

  Widget _buildFusionImageWidgetVariants(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildWithCopy(
          context: context,
          preview: FusionImage.network(
            semanticId: "network_image",
            "https://picsum.photos/200",
            width: 120,
            height: 120,
            borderRadius: BorderRadius.circular(12),
          ),

          code: '''
FusionImage.network(
            semanticId: "network_image",
            "https://picsum.photos/200",
            width: 120,
            height: 120,
            borderRadius: BorderRadius.circular(12),
          ),
          ''',
        ),
        const SizedBox(
          height: 20,
        ),
        _buildWithCopy(
          context: context,
          preview: const FusionImage.circle(
            semanticId: "circle_image",
            asset: "assets/images/launcher_hero.png",
            size: 100,
          ),

          code: '''
const FusionImage.circle(
            semanticId: "circle_image",
            asset: "",
            size: 100,
          ),
          ''',
        ),
        const SizedBox(
          height: 10,
        ),
      ],
    );
  }

  Widget _buildFusionProfileImageVariants(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildWithCopy(
          context: context,
          preview: const FusionProfileImage(
            semanticId: "network",
            imageUrl: 'https://example.com/profile.jpg',
            size: 60,
          ),

          code: '''
FusionProfileImage(
            semanticId: "network",
            imageUrl: 'https://example.com/profile.jpg',
            size: 60,
          ),
          ''',
        ),
        const SizedBox(
          height: 20,
        ),
        _buildWithCopy(
          context: context,
          preview: FusionProfileImage.asset(
            semanticId: "asset",
            'assets/images/launcher_hero.png',
            size: 50,
            border: Border.all(color: Colors.blue, width: 2),
          ),

          code: '''
FusionProfileImage.asset(
            semanticId: "asset",
            'assets/images/launcher_hero.png',
            size: 50,
            border: Border.all(color: Colors.blue, width: 2),
          ),
          ''',
        ),
        const SizedBox(
          height: 10,
        ),
      ],
    );
  }

  Widget _buildFusionKeyboardWrapperVariants(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildWithCopy(
          context: context,
          preview: FusionKeyboardWrapper(
            semanticId: "default",
            onUp: () {
              setState(() {
                select = "UP pressed";
              });
            },
            onDown: () {
              setState(() {
                select = "Down pressed";
              });
            },
            onLeft: () {
              setState(() {
                select = "Left pressed";
              });
            },
            onRight: () {
              setState(() {
                select = "Right pressed";
              });
            },
            onControlDown: () {
              setState(() {
                select = "Down pressed";
              });
            },
            onControlUp: () {
              setState(() {
                select = "Down pressed";
              });
            },
            onDelete: () {
              setState(() {
                select = "Delete pressed";
              });
            },

            onRedo: () {
              setState(() {
                select = "Redo pressed";
              });
            },
            onUndo: () {
              setState(() {
                select = "Undo pressed";
              });
            },
            onShiftDown: () {
              setState(() {
                select = "Shift Down pressed";
              });
            },
            onShiftUp: () {
              setState(() {
                select = "Shift Up pressed";
              });
            },
            child: Container(
              height: 200,
              color: context.colorScheme.elevation4,
              child: Center(child: Text(select!)),
            ),
          ),

          code: '''
FusionKeyboardWrapper(
 FusionKeyboardWrapper(
            semanticId: "default",
            onUp: () {
              setState(() {
                select = "UP pressed";
              });
            },
            onDown: () {
              setState(() {
                select = "Down pressed";
              });
            },
            onLeft: () {
              setState(() {
                select = "Left pressed";
              });
            },
            onRight: () {
              setState(() {
                select = "Right pressed";
              });
            },
            onControlDown: () {
              setState(() {
                select = "Down pressed";
              });
            },
            onControlUp: () {
              setState(() {
                select = "Down pressed";
              });
            },
            onDelete: () {
              setState(() {
                select = "Delete pressed";
              });
            },

            onRedo: () {
              setState(() {
                select = "Redo pressed";
              });
            },
            onUndo: () {
              setState(() {
                select = "Undo pressed";
              });
            },
            onShiftDown: () {
              setState(() {
                select = "Shift Down pressed";
              });
            },
            onShiftUp: () {
              setState(() {
                select = "Shift Up pressed";
              });
            },
            child: Container(
              height: 200,
              color: context.colorScheme.elevation4,
              child: Center(child: Text(select!)),
            ),
          ),
          ''',
        ),
      ],
    );
  }

  Widget _buildFusionShimmerVariants(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildWithCopy(
          context: context,
          preview: FusionShimmer(
            semanticId: "default",
            baseColor: context.colorScheme.elevation5,
            width: 400,
            height: 220,
            radius: 8,
          ),

          code: '''
 const FusionShimmer(
            semanticId: "default",
            width: 120,
            height: 120,
            radius: 8,
          ),
          ''',
        ),
      ],
    );
  }

  Widget _buildFusionToastVariants(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildWithCopy(
          context: context,
          preview: ElevatedButton(
            onPressed: () {
              FusionToast.success(
                context,
                message: "Sucess Toast",
              );
            },
            child: const Text("Success Toast"),
          ),

          code: '''
              FusionToast.success(
                context,
                message: "Sucess Toast",
              );
          
          ''',
        ),
        _buildWithCopy(
          context: context,
          preview: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.error,
            ),
            onPressed: () {
              FusionToast.error(
                context,
                message: "Error Toast",
              );
            },
            child: const Text("Error Toast"),
          ),

          code: '''
FusionToast.error(
                context,
                message: "Error Toast",
              );
          ''',
        ),
        _buildWithCopy(
          context: context,
          preview: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.elevation5,
            ),
            onPressed: () {
              FusionToast.show(
                context,
                message: "Custom Toast",
              );
            },
            child: const Text("Custom Toast"),
          ),

          code: '''
FusionToast.show(
                context,
                message: "Custom Toast",
              );
          ''',
        ),
      ],
    );
  }

  Widget _buildReorderableRowVariants(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          height: 100,
          child: _buildWithCopy(
            context: context,
            preview: ReorderableRow<String>(
              semanticId: "row",
              items: const <String>["Male", "Female", "Other"],

              onReorder: (int oldIndex, int newIndex) {
                setState(() {});
              },

              itemBuilder: (BuildContext context, String item) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(vertical: 4),

                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),

                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.drag_handle),
                      const SizedBox(width: 8),
                      Text(item),
                    ],
                  ),
                );
              },
            ),
            code: '''
  ReorderableRow<String>(
              semanticId: "row",
              items: const <String>["Male", "Female", "Other"],

              onReorder: (int oldIndex, int newIndex) {
                setState(() {});
              },

              itemBuilder: (BuildContext context, String item) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(vertical: 4),

                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),

                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.drag_handle),
                      const SizedBox(width: 8),
                      Text(item),
                    ],
                  ),
                );
              },
            ),
          ''',
          ),
        ),
      ],
    );
  }

  Widget _buildReorderableColumnVariants(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildWithCopy(
          context: context,
          preview: ReorderableColumn<String>(
            semanticId: "column",
            items: const <String>["Male", "Female", "Other"],

            onReorder: (int oldIndex, int newIndex) {
              setState(() {});
            },

            itemBuilder: (BuildContext context, String item) {
              return Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(vertical: 4),

                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),

                child: Row(
                  children: <Widget>[
                    const Icon(Icons.drag_handle),
                    const SizedBox(width: 8),
                    Text(item),
                  ],
                ),
              );
            },
          ),
          code: '''
  ReorderableColumn<String>(
            semanticId: "column",
            items: const <String>["Male", "Female", "Other"],

            onReorder: (int oldIndex, int newIndex) {
              setState(() {});
            },

            itemBuilder: (BuildContext context, String item) {
              return Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(vertical: 4),

                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),

                child: Row(
                  children: <Widget>[
                    const Icon(Icons.drag_handle),
                    const SizedBox(width: 8),
                    Text(item),
                  ],
                ),
              );
            },
          ),
          ''',
        ),
      ],
    );
  }

  Widget _buildReorderableFlexVariants(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildWithCopy(
          context: context,
          preview: ReorderableFlex<String>(
            direction: Axis.vertical,
            semanticId: "flex_vertical",
            items: const <String>["Male", "Female", "Other"],

            onReorder: (int oldIndex, int newIndex) {
              setState(() {});
            },

            itemBuilder: (BuildContext context, String item) {
              return Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(vertical: 4),

                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),

                child: Row(
                  children: <Widget>[
                    const Icon(Icons.drag_handle),
                    const SizedBox(width: 8),
                    Text(item),
                  ],
                ),
              );
            },
          ),
          code: '''
  ReorderableFlex<String>(
            direction: Axis.vertical,
            semanticId: "flex_vertical",
            items: const <String>["Male", "Female", "Other"],

            onReorder: (int oldIndex, int newIndex) {
              setState(() {});
            },

            itemBuilder: (BuildContext context, String item) {
              return Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(vertical: 4),

                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),

                child: Row(
                  children: <Widget>[
                    const Icon(Icons.drag_handle),
                    const SizedBox(width: 8),
                    Text(item),
                  ],
                ),
              );
            },
          ),
          ''',
        ),
        SizedBox(
          height: 100,
          child: _buildWithCopy(
            context: context,
            preview: ReorderableFlex<String>(
              direction: Axis.horizontal,
              semanticId: "flex_horizontal",
              items: const <String>["Male", "Female", "Other"],

              onReorder: (int oldIndex, int newIndex) {
                setState(() {});
              },

              itemBuilder: (BuildContext context, String item) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(vertical: 4),

                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),

                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.drag_handle),
                      const SizedBox(width: 8),
                      Text(item),
                    ],
                  ),
                );
              },
            ),
            code: '''
  ReorderableFlex(
              direction: Axis.horizontal,
              semanticId: "flex_horizontal",
              items: const <String>["Male", "Female", "Other"],

              onReorder: (int oldIndex, int newIndex) {
                setState(() {});
              },

              itemBuilder: (BuildContext context, String item) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(vertical: 4),

                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),

                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.drag_handle),
                      const SizedBox(width: 8),
                      Text(item),
                    ],
                  ),
                );
              },
            ),
          ''',
          ),
        ),
      ],
    );
  }

  Widget _buildHoverDropdownButtonFormFieldVariants(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildWithCopy(
          context: context,
          preview: HoverDropdownButtonFormField<String>(
            semanticId: "default",
            // Selected value
            value: selecting,

            // Dropdown items
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(
                value: "Low",
                child: Text("Low"),
              ),
              DropdownMenuItem<String>(
                value: "Medium",
                child: Text("Medium"),
              ),
              DropdownMenuItem<String>(
                value: "High",
                child: Text("High"),
              ),
            ],

            // On select
            onChanged: (String? value) {
              setState(() {
                selecting = value;
              });
            },

            // On hover (IMPORTANT: typed params)
            onHover: (String? value, int? index) {
              if (value == null) return;
              setState(() => selecting = value);
              print(selecting);
            },

            decoration: InputDecoration(
              labelText: "Select Level",
              fillColor: context.colorScheme.elevation1,
            ),
          ),

          code: '''
HoverDropdownButtonFormField<String>(
            // Selected value
            value: select,

            // Dropdown items
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(
                value: "Low",
                child: Text("Low"),
              ),
              DropdownMenuItem<String>(
                value: "Medium",
                child: Text("Medium"),
              ),
              DropdownMenuItem<String>(
                value: "High",
                child: Text("High"),
              ),
            ],

            // On select
            onChanged: (String? value) {
              setState(() {
                select = value;
              });
            },

            // On hover (IMPORTANT: typed params)
            onHover: (String? value, int? index) {
              if (value == null) return;
              setState(() => select = value);
              print(select);
            },

            decoration: InputDecoration(
              labelText: "Select Level",
              fillColor: context.colorScheme.elevation1,
            ),
          ),
''',
        ),
      ],
    );
  }

  Widget _buildFusionTableVariants(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          height: 150,
          child: _buildWithCopy(
            context: context,
            preview: const FusionTable(
              semanticId: "content_table",
              columns: <FusionTableColumn>[
                FusionTableColumn(
                  key: "name",
                  header: "Name",
                  flex: 2,
                ),
                FusionTableColumn(
                  key: "role",
                  header: "Role",
                  flex: 2,
                ),
                FusionTableColumn(
                  key: "status",
                  header: "Status",
                  flex: 1,
                  alignment: Alignment.center,
                ),
              ],

              // 2️⃣ Define Rows
              rows: <FusionTableRow>[
                FusionTableRow(
                  key: "1",
                  cells: <String, FusionTableCell>{
                    "name": FusionTableCell(
                      value: "John",
                      child: FusionAppText(text: "John"),
                    ),
                    "role": FusionTableCell(
                      value: "Developer",
                      child: FusionAppText(text: "Developer"),
                    ),
                    "status": FusionTableCell(
                      value: "Active",
                      child: FusionAppText(
                        text: "Active",
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  },
                ),

                FusionTableRow(
                  key: "2",
                  cells: <String, FusionTableCell>{
                    "name": FusionTableCell(
                      value: "Sarah",
                      child: FusionAppText(text: "Sarah"),
                    ),
                    "role": FusionTableCell(
                      value: "Designer",
                      child: FusionAppText(text: "Designer"),
                    ),
                    "status": FusionTableCell(
                      value: "Inactive",
                      child: FusionAppText(
                        text: "Inactive",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  },
                ),
              ],
            ),

            code: '''
const FusionTable(
              columns: <FusionTableColumn>[
                FusionTableColumn(
                  key: "name",
                  header: "Name",
                  flex: 2,
                ),
                FusionTableColumn(
                  key: "role",
                  header: "Role",
                  flex: 2,
                ),
                FusionTableColumn(
                  key: "status",
                  header: "Status",
                  flex: 1,
                  alignment: Alignment.center,
                ),
              ],

              // 2️⃣ Define Rows
              rows: <FusionTableRow>[
                FusionTableRow(
                  key: "1",
                  cells: <String, FusionTableCell>{
                    "name": FusionTableCell(
                      value: "John",
                      child: FusionAppText(text: "John"),
                    ),
                    "role": FusionTableCell(
                      value: "Developer",
                      child: FusionAppText(text: "Developer"),
                    ),
                    "status": FusionTableCell(
                      value: "Active",
                      child: FusionAppText(
                        text: "Active",
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  },
                ),

                FusionTableRow(
                  key: "2",
                  cells: <String, FusionTableCell>{
                    "name": FusionTableCell(
                      value: "Sarah",
                      child: FusionAppText(text: "Sarah"),
                    ),
                    "role": FusionTableCell(
                      value: "Designer",
                      child: FusionAppText(text: "Designer"),
                    ),
                    "status": FusionTableCell(
                      value: "Inactive",
                      child: FusionAppText(
                        text: "Inactive",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  },
                ),
              ],
            ),
''',
          ),
        ),
      ],
    );
  }

  Widget _buildFusionSwitchVariants(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildWithCopy(
          context: context,
          preview: FusionSwitch(
            semanticId: "default",
            value: isOn,
            onChanged: (bool newValue) {
              setState(() {
                isOn = newValue;
              });
            },
          ),

          code: '''
FusionSwitch(
            semanticId: "default",
            value: isOn,
            onChanged: (bool newValue) {
              setState(() {
                isOn = newValue;
              });
            },
          ),
''',
        ),
        const SizedBox(
          height: 10,
        ),
        _buildWithCopy(
          context: context,
          preview: FusionSwitch(
            semanticId: "with_style",
            value: isOns,
            onChanged: (bool newValue) {
              setState(() {
                isOns = newValue;
              });
            },
            height: 40,
            width: 70,
            radiusFactor: 0.5, // More rounded corners
            activeTrackColor: Colors.green,
            inactiveTrackColor: Colors.grey,
            activeThumbColor: Colors.white,
            inactiveThumbColor: Colors.grey.shade300,
          ),

          code: '''
FusionSwitch(
            semanticId: "with_style",
            value: isOns,
            onChanged: (bool newValue) {
              setState(() {
                isOns = newValue;
              });
            },
            height: 40,
            width: 70,
            radiusFactor: 0.5, // More rounded corners
            activeTrackColor: Colors.green,
            inactiveTrackColor: Colors.grey,
            activeThumbColor: Colors.white,
            inactiveThumbColor: Colors.grey.shade300,
          ),
''',
        ),
      ],
    );
  }

  Widget _buildFusionSvgIconVariants(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildWithCopy(
          context: context,
          preview: const FusionSvgIcon(
            semanticId: "default_without_icon",
            icon: AssetSvg.expandUp,
            size: 40,
          ),

          code: '''
const FusionSvgIcon(
            semanticId: "default",
            icon: AssetSvg.expandUp,
            size: 40,
          ),
''',
        ),
        _buildWithCopy(
          context: context,
          preview: FusionSvgIcon(
            semanticId: "with_icon",
            icon: AssetSvg.broadcast,
            color: context.colorScheme.green,
            size: 40,
          ),

          code: '''
 FusionSvgIcon(
            semanticId: "with_icon",
            icon: AssetSvg.broadcast,
            color: context.colorScheme.green,
            size: 40,
          ),
''',
        ),
      ],
    );
  }
}
