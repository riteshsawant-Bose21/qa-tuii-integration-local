import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

// Assuming your Ripple Animation is in this path
import '../../../../core/constants/assets_constants.dart';
import '../widgets/ripple_animation.dart';

enum SearchState {
  searching,
  notFound,
  vipConfiguration,
  success,
}

class FusionMdnsSearchPage extends StatefulWidget {
  final VoidCallback onWirelessConfigPressed;
  final VoidCallback onFinish; // Callback when flow is complete

  const FusionMdnsSearchPage({
    super.key,
    required this.onWirelessConfigPressed,
    required this.onFinish,
  });

  @override
  State<FusionMdnsSearchPage> createState() => _FusionMdnsSearchPageState();
}

class _FusionMdnsSearchPageState extends State<FusionMdnsSearchPage> {
  // Initial state
  SearchState _currentState = SearchState.searching;

  // To track if this is the second time searching (to trigger success)
  bool _isRetryAttempt = false;

  final TextEditingController _vipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startInitialMockSearch();
  }

  @override
  void dispose() {
    _vipController.dispose();
    super.dispose();
  }

  // Logic: First search fails after 3 seconds
  void _startInitialMockSearch() {
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentState = SearchState.notFound;
        });
      }
    });
  }

  // Logic: Retry search succeeds after 2 seconds -> Go to VIP
  void _handleRetry() {
    setState(() {
      _currentState = SearchState.searching;
      _isRetryAttempt = true;
    });

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          // If it's a retry, we find the device and go to VIP setup
          _currentState = SearchState.vipConfiguration;
        });
      }
    });
  }

  // Logic: Proceed to Success screen
  void _handleVipVerification() {
    // Simulate a quick verification delay
    serviceLocator<ProjectViewModel>().setVirtualIP(ip: _vipController.text);
    setState(() {
      _currentState = SearchState.success;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          // ------------------------------------------------
          // DYNAMIC CONTENT AREA
          // ------------------------------------------------
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildCurrentStateView(),
            ),
          ),

          // ------------------------------------------------
          // PERSISTENT FOOTER (Wireless Config)
          // ------------------------------------------------
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Do you have wireless devices to configure?',
                style: TextStyle(
                  fontSize: 14,
                  // Assuming dark background based on screenshots, using white/grey
                  color: context.colorScheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              FusionNeumorphicButton(
                text: 'Configure Wireless Devices',
                onTap: widget.onWirelessConfigPressed,
                textStyle: context.textTheme.bodyMedium,
                width: 0.2 * MediaQuery.of(context).size.width,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStateView() {
    // return _buildVipConfigView();

    switch (_currentState) {
      case SearchState.searching:
        return _buildSearchingView();
      case SearchState.notFound:
        return _buildNotFoundView();
      case SearchState.vipConfiguration:
        return _buildVipConfigView();
      case SearchState.success:
        return _buildSuccessView();
    }
  }

  // ------------------------------------------------
  // VIEW 1: SEARCHING
  // ------------------------------------------------
  Widget _buildSearchingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      key: const ValueKey<String>('searching'),
      children: <Widget>[
        NeumorphicRippleWidget(
          backgroundColor: context.colorScheme.primaryWhite,
          animationDuration: const Duration(seconds: 4),
          ripplesCount: 4,
          minRadius: 25,
          maxRadius: 200,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: context.colorScheme.elevation1,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: context.colorScheme.elevation1.withAlpha((0.8 * 255).toInt()),
                  offset: const Offset(-4, -4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(
              Icons.cell_tower_rounded, // Or auto_awesome for "Fusion" feel
              size: 24,
              color: context.colorScheme.primaryWhite,
            ),
          ),
        ),
        const SizedBox(height: 100),
        FusionAppText(
          text: 'Hold on, searching network for Fusion devices...',
          textAlign: TextAlign.center,
          style: context.textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        _buildInfoChip(),
      ],
    );
  }

  // ------------------------------------------------
  // VIEW 2: NOT FOUND (RETRY)
  // ------------------------------------------------
  Widget _buildNotFoundView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      key: const ValueKey<String>('notFound'),
      children: <Widget>[
        // Placeholder for the "Sad Face" dashed icon
        FusionImage.asset(
          Assets.errorFace,
          height: 80,
          assetColor: context.colorScheme.primaryWhite,
        ),
        const SizedBox(height: 32),
        FusionAppText(
          text: 'Sorry, We could not detect any hardwares on\nthe network',
          textAlign: TextAlign.center,
          style: context.textTheme.bodyLarge,
        ),
        const SizedBox(height: 40),

        // Retry Button
        FusionNeumorphicButton(
          onTap: _handleRetry,
          text: 'Retry',
          width: 200,
        ),
        const SizedBox(height: 24),
        _buildInfoChip(),
      ],
    );
  }

  // ------------------------------------------------
  // VIEW 3: SET VIP (FOUND)
  // ------------------------------------------------
  Widget _buildVipConfigView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      key: const ValueKey<String>('vip'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Center(
          child: FusionAppText(
            text: 'You are not initiating the connection with\nthe network. Please set a VIP address for\ncommunicating with fusion hardwares',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyLarge,
          ),
        ),
        const SizedBox(height: 40),

        Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Virtual IP address',
                  style: TextStyle(fontSize: 12, color: context.colorScheme.greyLight),
                ),
                const SizedBox(height: 8),

                // Input Field
                TextFormField(
                  controller: _vipController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF111111),
                    hintText: '192.168.0.100',
                    hintStyle: TextStyle(color: context.colorScheme.elevation4, fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.colorScheme.greyLight.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.colorScheme.greyLight.withOpacity(0.3)),
                    ),
                  ),
                  //add valid ip address pattern validation
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                ),
                const SizedBox(height: 24),

                // Verify Button
                FusionNeumorphicButton(
                  onTap: () {
                    //validate VIP is not empty
                    if (_vipController.text.isNotEmpty) {
                      _handleVipVerification();
                    } else {
                      FusionToast.error(context, message: "Please enter a valid VIP address");
                    }
                  },
                  text: 'Verify and Proceed',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------
  // VIEW 4: SUCCESS
  // ------------------------------------------------
  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      key: const ValueKey<String>('success'),
      children: <Widget>[
        // Check Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: context.colorScheme.primaryBlack, width: 1.5),
          ),
          child: Icon(Icons.check, color: context.colorScheme.primaryBlack, size: 40),
        ),
        const SizedBox(height: 32),

        Text(
          'Network configuration successful',
          style: TextStyle(
            fontSize: 20,
            color: context.colorScheme.primaryBlack,
          ),
        ),
        const SizedBox(height: 40),

        Text(
          'Next Steps >>',
          style: TextStyle(fontSize: 12, color: context.colorScheme.greyLight),
        ),
        const SizedBox(height: 8),
        Text(
          'Map project devices to physical devices',
          style: TextStyle(fontSize: 14, color: context.colorScheme.primaryBlack, fontWeight: FontWeight.bold),
        ),
        Text(
          'Connect / Assign the devices to each other.',
          style: TextStyle(fontSize: 12, color: context.colorScheme.greyLight),
        ),

        const SizedBox(height: 24),

        // Finish Button
        FusionNeumorphicButton(
          onTap: widget.onFinish,
          borderRadius: 12,
          text: "Finish",
          textStyle: context.textTheme.bodyMedium,
          width: 200,
        ),
      ],
    );
  }

  // Helper for the Info Chip used in multiple screens
  Widget _buildInfoChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: context.colorScheme.elevation5,
        ),
        borderRadius: BorderRadius.circular(10), // Rounded pill shape
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.info_outline,
            color: context.colorScheme.primaryWhite,
            size: 16,
          ),
          const SizedBox(width: 8),
          FusionAppText(
            text: 'Make sure you are connected to right network',
            style: context.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
