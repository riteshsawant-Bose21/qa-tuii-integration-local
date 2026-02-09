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
          const Row(
            children: <Widget>[
              FusionAppText(
                text: 'Types',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
      return const FusionAppText(text: 'No widget selected');
    }

    switch (widget.name) {
      case "FusionAppButton":
        return _buildFusionAppButtonVariants(context);
      case "SecondaryButton":
        return _buildSecondaryButtonVariants(context);
      case "TertiaryLinkButton":
        return _buildTertiaryLinkButtonVariants(context);
      case "FusionTextButton":
        return _buildFusionTextButtonVariants(context);
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
            width: 200,
            label: "Primary",
            onTap: () {},
            style: FusionAppButtonStyle.primary,
          ),
          code: '''
FusionAppButton(
  label: "Primary",
  onTap: () {},
  style: FusionAppButtonStyle.primary,
)
''',
        ),

        const SizedBox(height: 12),

        /// ================= PRIMARY + ICONS =================
        _buildWithCopy(
          context: context,
          preview: FusionAppButton(
            width: 200,
            label: "With Icons",
            onTap: () {},
            style: FusionAppButtonStyle.primary,
            showPrefixIcon: true,
            prefixIcon: Icons.login,
            showSuffixIcon: true,
            suffixIcon: Icons.check,
          ),
          code: '''
FusionAppButton(
  label: "With Icons",
  onTap: () {},
  showPrefixIcon: true,
  prefixIcon: Icons.login,
  showSuffixIcon: true,
  suffixIcon: Icons.check,
)
''',
        ),

        const SizedBox(height: 12),

        /// ================= GRADIENT =================
        _buildWithCopy(
          context: context,
          preview: FusionAppButton(
            label: "Gradient",
            onTap: () {},
            width: 200,
            style: FusionAppButtonStyle.primary,
            gradient: const LinearGradient(
              colors: <Color>[Colors.blue, Colors.purple],
            ),
          ),
          code: '''
FusionAppButton(
  label: "Gradient",
  onTap: () {},
  gradient: LinearGradient(
    colors: [Colors.blue, Colors.purple],
  ),
)
''',
        ),

        const SizedBox(height: 12),

        /// ================= DISABLED =================
        _buildWithCopy(
          context: context,
          preview: FusionAppButton(
            label: "Disabled",
            onTap: () {},
            width: 200,
            isActive: false,
          ),
          code: '''
FusionAppButton(
  label: "Disabled",
  onTap: () {},
  isActive: false,
)
''',
        ),

        const SizedBox(height: 12),

        /// ================= BORDERED =================
        _buildWithCopy(
          context: context,
          preview: FusionAppButton(
            label: "Bordered",
            onTap: () {},
            width: 200,
            borderColor: Colors.blue,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.blue,
          ),
          code: '''
FusionAppButton(
  label: "Bordered",
  onTap: () {},
  borderColor: Colors.blue,
  backgroundColor: Colors.transparent,
)
''',
        ),

        const SizedBox(height: 12),

        /// ================= NEUMORPHIC =================
        _buildWithCopy(
          context: context,
          preview: FusionAppButton(
            label: "Neumorphic",
            width: 200,
            onTap: () {},
            style: FusionAppButtonStyle.primary,
            backgroundColor: context.colorScheme.elevation2,
          ),
          code: '''
FusionAppButton(
  label: "Neumorphic",
  onTap: () {},
  style: FusionAppButtonStyle.neumorphic,
)
''',
        ),

        const SizedBox(height: 12),

        /// ================= NEUMORPHIC + ICON =================
        _buildWithCopy(
          context: context,
          preview: FusionAppButton(
            label: "Soft UI",
            width: 200,
            onTap: () {},
            style: FusionAppButtonStyle.primary,
            backgroundColor: context.colorScheme.elevation2,
            showPrefixIcon: true,
            prefixIcon: Icons.touch_app,
          ),
          code: '''
FusionAppButton(
  label: "Soft UI",
  onTap: () {},
  style: FusionAppButtonStyle.neumorphic,
  showPrefixIcon: true,
  prefixIcon: Icons.touch_app,
)
''',
        ),

        const SizedBox(height: 12),
        _buildWithCopy(
          context: context,
          preview: FusionAppButton(
            width: 200,
            label: "Primary",
            onTap: () {},
            style: FusionAppButtonStyle.neumorphic,
          ),
          code: '''
FusionAppButton(
  label: "Primary",
  onTap: () {},
  style: FusionAppButtonStyle.primary,
)
''',
        ),

        const SizedBox(height: 12),

        /// ================= PRIMARY + ICONS =================
        _buildWithCopy(
          context: context,
          preview: FusionAppButton(
            width: 200,
            label: "With Icons",
            onTap: () {},
            style: FusionAppButtonStyle.neumorphic,
            showPrefixIcon: true,
            prefixIcon: Icons.login,
            showSuffixIcon: true,
            suffixIcon: Icons.check,
          ),
          code: '''
FusionAppButton(
  label: "With Icons",
  onTap: () {},
  showPrefixIcon: true,
  prefixIcon: Icons.login,
  showSuffixIcon: true,
  suffixIcon: Icons.check,
)
''',
        ),

        const SizedBox(height: 12),

        /// ================= DISABLED =================
        _buildWithCopy(
          context: context,
          preview: FusionAppButton(
            label: "Disabled",
            onTap: () {},
            width: 200,
            style: FusionAppButtonStyle.neumorphic,
            isActive: false,
          ),
          code: '''
FusionAppButton(
  label: "Disabled",
  onTap: () {},
  isActive: false,
)
''',
        ),

        const SizedBox(height: 12),

        /// ================= BORDERED =================
        _buildWithCopy(
          context: context,
          preview: FusionAppButton(
            label: "Bordered",
            onTap: () {},
            style: FusionAppButtonStyle.neumorphic,
            width: 200,
            borderColor: Colors.blue,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.blue,
          ),
          code: '''
FusionAppButton(
  label: "Bordered",
  onTap: () {},
  borderColor: Colors.blue,
  backgroundColor: Colors.transparent,
)
''',
        ),

        const SizedBox(height: 12),

        /// ================= NEUMORPHIC =================
        _buildWithCopy(
          context: context,
          preview: FusionAppButton(
            label: "Neumorphic",
            width: 200,
            onTap: () {},
            style: FusionAppButtonStyle.neumorphic,
            backgroundColor: context.colorScheme.elevation2,
          ),
          code: '''
FusionAppButton(
  label: "Neumorphic",
  onTap: () {},
  style: FusionAppButtonStyle.neumorphic,
)
''',
        ),

        const SizedBox(height: 12),

        /// ================= NEUMORPHIC + ICON =================
        _buildWithCopy(
          context: context,
          preview: FusionAppButton(
            label: "Soft UI",
            width: 200,
            onTap: () {},
            style: FusionAppButtonStyle.neumorphic,
            backgroundColor: context.colorScheme.elevation2,
            showPrefixIcon: true,
            prefixIcon: Icons.touch_app,
          ),
          code: '''
FusionAppButton(
  label: "Soft UI",
  onTap: () {},
  style: FusionAppButtonStyle.neumorphic,
  showPrefixIcon: true,
  prefixIcon: Icons.touch_app,
)
''',
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSecondaryButtonVariants(BuildContext context) {
    return Column(
      children: <Widget>[
        // ================= DEFAULT =================
        _buildWithCopy(
          context: context,
          preview: SecondaryButton(
            label: "Default",
            onTap: () {},
          ),
          code: '''
SecondaryButton(
  label: "Default",
  onTap: () {},
)
''',
        ),

        const SizedBox(height: 20),

        // ================= DISABLED =================
        _buildWithCopy(
          context: context,
          preview: SecondaryButton(
            label: "Disabled",
            isActive: false,
            onTap: () {},
          ),
          code: '''
SecondaryButton(
  label: "Disabled",
  isActive: false,
  onTap: () {},
)
''',
        ),

        const SizedBox(height: 20),

        // ================= BOLD TEXT =================
        _buildWithCopy(
          context: context,
          preview: SecondaryButton(
            label: "Bold",
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            onTap: () {},
          ),
          code: '''
SecondaryButton(
  label: "Bold",
  textStyle: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  ),
  onTap: () {},
)
''',
        ),

        const SizedBox(height: 20),

        // ================= PREFIX ICON =================
        _buildWithCopy(
          context: context,
          preview: SecondaryButton(
            label: "Upload",
            showPrefixIcon: true,
            prefixIcon: Icons.upload,
            onTap: () {},
          ),
          code: '''
SecondaryButton(
  label: "Upload",
  showPrefixIcon: true,
  prefixIcon: Icons.upload,
  onTap: () {},
)
''',
        ),

        const SizedBox(height: 20),

        // ================= SUFFIX ICON =================
        _buildWithCopy(
          context: context,
          preview: SecondaryButton(
            label: "Send",
            showSuffixIcon: true,
            suffixIcon: Icons.send,
            onTap: () {},
          ),
          code: '''
SecondaryButton(
  label: "Send",
  showSuffixIcon: true,
  suffixIcon: Icons.send,
  onTap: () {},
)
''',
        ),

        const SizedBox(height: 20),
        _buildWithCopy(
          context: context,
          preview: SecondaryButton(
            label: "Send",
            gradient: const LinearGradient(
              colors: <Color>[Colors.purple, Colors.pink],
            ),
            onTap: () {},
          ),
          code: '''
SecondaryButton(
  label: "Send",
  showSuffixIcon: true,
  suffixIcon: Icons.send,
  gradient: const LinearGradient(
              colors: <Color>[Colors.purple, Colors.pink],
            ),
  onTap: () {},
)
''',
        ),
      ],
    );
  }

  Widget _buildFusionTextButtonVariants(BuildContext context) {
    return Column(
      children: <Widget>[
        // ================= DEFAULT =================
        _buildWithCopy(
          context: context,
          preview: FusionTextButton(
            label: "Default",
            onTap: () {},
          ),
          code: '''
FusionTextButton(
  label: "Default",
  onTap: () {},
)
''',
        ),

        const SizedBox(height: 20),

        // ================= CUSTOM TEXT STYLE =================
        _buildWithCopy(
          context: context,
          preview: FusionTextButton(
            label: "Bold Text",
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
            onTap: () {},
          ),
          code: '''
FusionTextButton(
  label: "Bold Text",
  textStyle: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.blue,
  ),
  onTap: () {},
)
''',
        ),

        const SizedBox(height: 20),

        // ================= PREFIX ICON =================
        _buildWithCopy(
          context: context,
          preview: FusionTextButton(
            label: "Close",
            showPrefixIcon: true,
            prefixIcon: Icons.close,
            onTap: () {},
          ),
          code: '''
FusionTextButton(
  label: "Close",
  showPrefixIcon: true,
  prefixIcon: Icons.close,
  onTap: () {},
)
''',
        ),

        const SizedBox(height: 20),

        // ================= SUFFIX ICON =================
        _buildWithCopy(
          context: context,
          preview: FusionTextButton(
            label: "Next",
            showSuffixIcon: true,
            suffixIcon: Icons.arrow_forward,
            onTap: () {},
          ),
          code: '''
FusionTextButton(
  label: "Next",
  showSuffixIcon: true,
  suffixIcon: Icons.arrow_forward,
  onTap: () {},
)
''',
        ),

        const SizedBox(height: 20),

        // ================= BOTH ICONS =================
        _buildWithCopy(
          context: context,
          preview: FusionTextButton(
            label: "Share",
            showPrefixIcon: true,
            prefixIcon: Icons.share,
            showSuffixIcon: true,
            suffixIcon: Icons.arrow_forward,
            onTap: () {},
          ),
          code: '''
FusionTextButton(
  label: "Share",
  showPrefixIcon: true,
  prefixIcon: Icons.share,
  showSuffixIcon: true,
  suffixIcon: Icons.arrow_forward,
  onTap: () {},
)
''',
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTertiaryLinkButtonVariants(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 20),
        _buildWithCopy(
          context: context,
          preview: FusionTextButton(
            label: "Default",
            textStyle: const TextStyle(
              decoration: TextDecoration.underline,
              fontSize: 16,
              decorationThickness: 2,
              color: Colors.white,
            ),
            onTap: () {},
          ),
          code: '''
FusionTextButton(
  label: "Bold Text",
  textStyle: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.blue,
  ),
  onTap: () {},
)
''',
        ),
        // ================= CUSTOM TEXT STYLE =================
        _buildWithCopy(
          context: context,
          preview: FusionTextButton(
            label: "Bold Text",
            textStyle: const TextStyle(
              fontSize: 16,
              decoration: TextDecoration.underline,
              decorationThickness: 2,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
            onTap: () {},
          ),
          code: '''
FusionTextButton(
  label: "Bold Text",
  textStyle: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.blue,
  ),
  onTap: () {},
)
''',
        ),

        const SizedBox(height: 20),

        // ================= PREFIX ICON =================
        _buildWithCopy(
          context: context,
          preview: FusionTextButton(
            label: "Close",
            showPrefixIcon: true,
            textStyle: const TextStyle(
              decoration: TextDecoration.underline,
              decorationThickness: 2,
            ),
            prefixIcon: Icons.close,
            onTap: () {},
          ),
          code: '''
FusionTextButton(
  label: "Close",
  showPrefixIcon: true,
  prefixIcon: Icons.close,
  onTap: () {},
)
''',
        ),

        const SizedBox(height: 20),

        // ================= SUFFIX ICON =================
        _buildWithCopy(
          context: context,
          preview: FusionTextButton(
            label: "Next",
            showSuffixIcon: true,
            suffixIcon: Icons.arrow_forward,
            textStyle: const TextStyle(
              decoration: TextDecoration.underline,
              decorationThickness: 2,
            ),
            onTap: () {},
          ),
          code: '''
FusionTextButton(
  label: "Next",
  showSuffixIcon: true,
  suffixIcon: Icons.arrow_forward,
  onTap: () {},
)
''',
        ),

        const SizedBox(height: 20),

        // ================= BOTH ICONS =================
        _buildWithCopy(
          context: context,
          preview: FusionTextButton(
            label: "Share",
            showPrefixIcon: true,
            textStyle: const TextStyle(
              decoration: TextDecoration.underline,
              decorationThickness: 2,
            ),
            prefixIcon: Icons.share,
            showSuffixIcon: true,
            suffixIcon: Icons.arrow_forward,
            onTap: () {},
          ),
          code: '''
FusionTextButton(
  label: "Share",
  showPrefixIcon: true,
  prefixIcon: Icons.share,
  showSuffixIcon: true,
  suffixIcon: Icons.arrow_forward,
  onTap: () {},
)
''',
        ),

        const SizedBox(height: 20),
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
            label: "Default",
            hint: "Value",
            controller: TextEditingController(),
            variant: FusionFieldVariant.outline,
          ),
          code: '''
CustomTextField(
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
            label: "Neumorphic",
            hint: "Value",
            controller: TextEditingController(),
            variant: FusionFieldVariant.neumorphic,
          ),
          code: '''
CustomTextField(
            label: "Neumorphic",
            hint: "Value",
            controller: TextEditingController(),
            variant: FusionFieldVariant.neumorphic,
          ),
''',
        ),

        // ================= FOCUSED =================
        _buildWithCopy(
          context: context,
          preview: CustomTextField(
            label: "Focused",
            hint: "Value",
            controller: TextEditingController(text: ""),
            fieldState: FusionFieldState.focused,
          ),
          code: '''
CustomTextField(
            label: "Focused",
            hint: "Value",
            controller: TextEditingController(text: ""),
            fieldState: FusionFieldState.focused,
          ),
''',
        ),

        // ================= FILLED =================
        _buildWithCopy(
          context: context,
          preview: CustomTextField(
            label: "Filled",
            hint: "Value",
            controller: TextEditingController(text: "Hello"),
          ),
          code: '''
CustomTextField(
            label: "Filled",
            hint: "Value",
            controller: TextEditingController(text: "Hello"),
          ),
''',
        ),

        // ================= ERROR =================
        _buildWithCopy(
          context: context,
          preview: CustomTextField(
            label: "Error",
            hint: "Value",
            controller: TextEditingController(text: "123"),
            hasErrorText: true,
            errorText: "Invalid value",
          ),
          code: '''
CustomTextField(
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
            hint: "Value",
            controller: TextEditingController(),
            enabled: false,
          ),
          code: '''
CustomTextField(
            label: "Blocked",
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
            hint: "Value",
            controller: TextEditingController(text: "Readonly"),
            enabled: false,
          ),
          code: '''
CustomTextField(
            label: "Blocked Filled",
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
            label: "Phone",
            hint: "Mobile Number",
            controller: TextEditingController(),
            showCountryCode: true,
            inputType: TextInputType.phone,
          ),
          code: '''
CustomTextField(
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
            label: "Info + Helper",
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
            label: "Info + Helper",
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
            hint: "Value",
            controller: TextEditingController(text: "Done"),
            hasSuccessText: true,
            successText: "Looks good",
          ),
          code: '''
CustomTextField(
            label: "Success",
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
            label: "Default",
            showRupee: true,
            hint: "Value",
            controller: TextEditingController(),
            variant: FusionFieldVariant.outline,
          ),
          code: '''
CustomTextField(
            label: "Default",
            showRupee: true,
            hint: "Value",
            controller: TextEditingController(),
            variant: FusionFieldVariant.outline,
          ),
''',
        ),
        _buildWithCopy(
          context: context,
          preview: CustomTextField(
            label: "Disabled",
            hint: "Value",
            controller: TextEditingController(),
            variant: FusionFieldVariant.outline,
            fieldState: FusionFieldState.blocked,
          ),
          code: '''
CustomTextField(
            label: "Default",
            showRupee: true,
            hint: "Value",
            controller: TextEditingController(),
            variant: FusionFieldVariant.outline,
          ),
''',
        ),
        _buildWithCopy(
          context: context,
          preview: CustomTextField(
            showLabel: true,
            label: "Label",
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
            info: true,
            showPrefixIcon: true,
            prefixIcon: Icons.arrow_drop_down_outlined,
            showSuffixIcon: true,
            button: true,
            buttonText: "Button",
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
            onTap: () {},
          ),

          code: '''
          RadioButton(
            shape: BoxShape.rectangle,
            state: FusionSelectionState.partial,
            variant: FusionSelectionVariant.checkbox,
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
          ),

          code: '''
RadioButton(
            shape: BoxShape.circle,
            variant: FusionSelectionVariant.radio,
            onTap: () {},
          ),
''',
        ),

        _buildWithCopy(
          context: context,
          preview: RadioButton(
            shape: BoxShape.circle,
            variant: FusionSelectionVariant.radio,
            state: FusionSelectionState.checked,
            disabled: true,
            onTap: () {},
          ),

          code: '''
RadioButton(
            shape: BoxShape.circle,
            variant: FusionSelectionVariant.radio,
            state: FusionSelectionState.checked,
            disabled: true,
            onTap: () {},
          ),
''',
        ),
        _buildWithCopy(
          context: context,
          preview: RadioButton(
            shape: BoxShape.circle,
            variant: FusionSelectionVariant.radio,
            state: FusionSelectionState.partial,
            disabled: true,
            onTap: () {},
          ),

          code: '''
RadioButton(
            shape: BoxShape.circle,
            variant: FusionSelectionVariant.radio,
            state: FusionSelectionState.partial,
            disabled: true,
            onTap: () {},
          ),
''',
        ),

        _buildWithCopy(
          context: context,
          preview: RadioButton(
            shape: BoxShape.circle,
            variant: FusionSelectionVariant.radioBox,
            label: "Option 1",
            onTap: () {},
          ),

          code: '''
RadioButton(
            shape: BoxShape.circle,
            variant: FusionSelectionVariant.radioBox,
            label: "Option 1",
            onTap: () {},
          ),
''',
        ),

        _buildWithCopy(
          context: context,
          preview: RadioButton(
            shape: BoxShape.circle,
            variant: FusionSelectionVariant.radioBox,
            label: "Disabled",
            disabled: true,
          ),

          code: '''
RadioButton(
            shape: BoxShape.circle,
            variant: FusionSelectionVariant.radioBox,
            label: "Disabled",
            disabled: true,
          ),
''',
        ),
        _buildWithCopy(
          context: context,
          preview: RadioButton(
            shape: BoxShape.circle,
            variant: FusionSelectionVariant.radioBox,
            state: FusionSelectionState.checked,
            label: "Disabled",
            disabled: true,
          ),

          code: '''
RadioButton(
            shape: BoxShape.circle,
            variant: FusionSelectionVariant.radioBox,
            label: "Disabled",
            disabled: true,
          ),
''',
        ),
        const SizedBox(
          height: 4,
        ),
        _buildWithCopy(
          context: context,
          preview: RadioButton(
            variant: FusionSelectionVariant.radioOption,
            iconPrifix: true,
            label: "Hello",
          ),

          code: '''
RadioButton(
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
            variant: FusionSelectionVariant.radioOption,
            iconPrifix: false,
            label: "Hello",
          ),

          code: '''
RadioButton(
            variant: FusionSelectionVariant.radioOption,
            iconPrifix: false,
            label: "Hello",
          )
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
            label: "Dropdown",
            hint: "Select Value",
            controller: TextEditingController(),
            isDropdown: true,
            showSuffixIcon: true,
            suffixIcon: Icons.arrow_drop_down,
            onTap: () {
              debugPrint("Open dropdown");
            },
          ),
''',
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
