import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'configure_device_page.dart';
import 'fusion_device_mdns_search.dart';
import 'wireless_device_setup_page.dart';
// Import your other pages here

class DeviceSetupWizard extends StatefulWidget {
  final VoidCallback onFinish;

  const DeviceSetupWizard({
    super.key,
    required this.onFinish,
  });

  @override
  State<DeviceSetupWizard> createState() => _DeviceSetupWizardState();
}

class _DeviceSetupWizardState extends State<DeviceSetupWizard> {
  // Controller to handle page switching
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _goToNextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleBack() {
    // If we are on a step > 0, go back one step
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // If on the first step, actually close the wizard
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // canPop is TRUE only if we are on the first page.
    // Otherwise, we block the pop to handle it manually (go to prev page).
    final bool canPop = _currentPage == 0;
    print("DeviceSetupWizard: canPop = $canPop, currentPage = $_currentPage");

    return Scaffold(
      backgroundColor: context.colorScheme.elevation1,
      // ---------------------------------------------------------
      // DYNAMIC BODY: Swaps content without losing the header
      // ---------------------------------------------------------
      // appBar:
      //     (_currentPage != 0)
      //         ? AppBar(
      //           backgroundColor: context.colorScheme.primaryWhite,
      //           leading: IconButton(
      //             icon: Icon(
      //               Icons.arrow_back,
      //               color: context.colorScheme.primaryBlack,
      //             ),
      //             onPressed: _handleBack,
      //           ),
      //           elevation: 0,
      //         )
      //         : null,
      body: PopScope(
        canPop: canPop,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (didPop) {
            return;
          }
          // Logic for when back is pressed but 'canPop' was false
          _handleBack();
        },
        child: PageView(
          controller: _pageController,
          onPageChanged: (int page) {
            setState(() {
              _currentPage = page;
            });
          },
          physics: const NeverScrollableScrollPhysics(), // Prevents user swiping manually
          children: <Widget>[
            // Step 1: The Configure Page (Pass the callback to navigate)
            ConfigureDevicePage(onStartPressed: _goToNextPage),

            // Step 2: The Searching Network Page
            FusionMdnsSearchPage(
              onWirelessConfigPressed: () {
                _goToNextPage();
              },
              onFinish: widget.onFinish,
            ),

            BluetoothSetupPage(
              onFinish: () {
                _goToPage(1); // Go back to the MDNS search page after finishing
              },
              onBack: () {
                _handleBack();
              },
            ),
          ],
        ),
      ),
    );
  }
}
