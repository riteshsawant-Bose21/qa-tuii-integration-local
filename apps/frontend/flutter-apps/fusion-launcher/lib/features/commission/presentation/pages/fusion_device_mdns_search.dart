import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/core/theme/app_theme.dart';
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
                  color: context.colorScheme.primaryBlack.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                // width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onWirelessConfigPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: context.colorScheme.primaryWhite,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    side: BorderSide(
                      color: context.colorScheme.greyLight.withOpacity(0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: FusionAppText(
                    text: 'Configure Wireless Devices',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.primaryBlack,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStateView() {
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
          backgroundColor: context.colorScheme.primaryBlack,
          animationDuration: const Duration(seconds: 4),
          ripplesCount: 4,
          minRadius: 25,
          maxRadius: 200,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: context.colorScheme.primaryWhite,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: context.colorScheme.primaryWhite.withAlpha((0.8 * 255).toInt()),
                  offset: const Offset(-4, -4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(
              Icons.cell_tower_rounded, // Or auto_awesome for "Fusion" feel
              size: 24,
              color: context.colorScheme.primaryBlack,
            ),
          ),
        ),
        const SizedBox(height: 100),
        Text(
          'Hold on, searching network for Fusion devices...',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: context.colorScheme.primaryBlack,
            height: 1.2,
          ),
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
        Image.asset(
          Assets.errorFace,
          height: 80,
          color: context.colorScheme.greyLight,
        ),
        const SizedBox(height: 32),
        Text(
          'Sorry, We could not detect any hardwares on\nthe network',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: context.colorScheme.primaryBlack,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),

        // Retry Button
        SizedBox(
          width: 200,
          child: ElevatedButton(
            onPressed: _handleRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C2C2C), // Dark grey
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Retry'),
          ),
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
          child: Text(
            'You are not initiating the connection with\nthe network. Please set a VIP address for\ncommunicating with fusion hardwares',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: context.colorScheme.primaryBlack,
              height: 1.5,
            ),
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
                    hintStyle: TextStyle(color: context.colorScheme.greyLight),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      //validate VIP is not empty
                      if (_vipController.text.isNotEmpty) {
                        _handleVipVerification();
                      } else {
                        FusionToast.error(context, message: "Please enter a valid VIP address");
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C2C2C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Verify and Proceed'),
                  ),
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
        SizedBox(
          width: 300,
          child: ElevatedButton(
            onPressed: widget.onFinish,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C2C2C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Finish'),
          ),
        ),
      ],
    );
  }

  // Helper for the Info Chip used in multiple screens
  Widget _buildInfoChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: context.colorScheme.greyLight.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(10), // Rounded pill shape
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.info_outline,
            color: context.colorScheme.greyLight,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Make sure you are connected to right network',
            style: TextStyle(
              fontSize: 12,
              color: context.colorScheme.greyLight,
            ),
          ),
        ],
      ),
    );
  }
}
