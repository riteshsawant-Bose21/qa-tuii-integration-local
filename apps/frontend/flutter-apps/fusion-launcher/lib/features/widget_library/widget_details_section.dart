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
import 'package:provider/provider.dart';

import 'models/widget_category.dart';
import 'viewmodel/widget_library_viewmodel.dart';

class WidgetDetailsSection extends StatelessWidget {
  const WidgetDetailsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WidgetLibraryViewModel>(
      builder: (
        BuildContext context,
        WidgetLibraryViewModel viewModel,
        Widget? child,
      ) {
        return Container(
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
            color: context.colorScheme.textSecondary.withOpacity(0.5),
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
        message = 'This category is not implemented yet';
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
          crossAxisAlignment: CrossAxisAlignment.start,
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

  // ================= PRIMARY BUTTON VARIANTS =================

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
    return Column(
      children: <Widget>[
        // ================= DEFAULT =================

        // ================= DROPDOWN =================
        _buildWithCopy(
          context: context,
          preview: CustomTextField(
            semanticId: "dropdown",
            label: "Dropdown",
            hint: "Select Value",
            controller: TextEditingController(),

            isDropdown: true,
            enabled: true,

            dropdownItems: const <String>[
              "Apple",
              "Banana",
              "Orange",
              "Mango",
            ],

            onItemSelected: (String value) {
              debugPrint("Selected: $value");
            },

            showSuffixIcon: true,
            suffixIcon: Icons.arrow_drop_down,
          ),

          code: '''
CustomTextField(
            semanticId: "dropdown",
            label: "Dropdown",
            hint: "Select Value",
            controller: TextEditingController(),

            isDropdown: true,
            enabled: true,

            dropdownItems: const <String>[
              "Apple",
              "Banana",
              "Orange",
              "Mango",
            ],

            onItemSelected: (){}

            showSuffixIcon: true,
            suffixIcon: Icons.arrow_drop_down,
          ),
''',
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
