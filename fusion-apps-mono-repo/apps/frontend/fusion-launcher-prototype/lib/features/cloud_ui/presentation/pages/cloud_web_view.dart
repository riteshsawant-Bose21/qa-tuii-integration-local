import 'package:flutter/material.dart';
import 'package:fusion_design_tool_prototype/core/utils/broadcast_controllers.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/service_locator.dart';
import '../../../../core/services/app_settings.dart';

class FusionCloudWebView extends StatefulWidget {
  final String? pageToRedirect;
  final String? title;
  final bool showAppBar;
  final bool showProgress;

  const FusionCloudWebView({
    super.key,
    this.pageToRedirect,
    this.title,
    this.showAppBar = true,
    this.showProgress = true,
  });

  @override
  State<FusionCloudWebView> createState() => _FusionCloudWebViewState();
}

class _FusionCloudWebViewState extends State<FusionCloudWebView> {
   String webUiUrl = " ";

  WebViewController? controller;
  bool isLoading = true;
  double loadingProgress = 0.0;
  bool isSubPageRequested = false;

  @override
  void initState() {
    super.initState();
    loadUrl();
  }

  @override
  void didUpdateWidget(covariant FusionCloudWebView oldWidget) {

    super.didUpdateWidget(oldWidget);

    loadUrl();
  }

  void loadUrl() {
    //build initial URL for the web view

    final String redirectLink = cloudRedirectUrl.trim().isNotEmpty  ? cloudRedirectUrl : widget.pageToRedirect ?? "";
    webUiUrl =
        "http://${serviceLocator<AppSettings>().cloudWebUrl}/$redirectLink";
    cloudRedirectUrl = "";

    debugPrint("Web UI URL: $webUiUrl");
    isSubPageRequested =false;
    // Initialize the controller
    controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {
                setState(() {
                  loadingProgress = progress / 100;
                });
              },
              onPageStarted: (String url) {
                setState(() {
                  isLoading = true;
                });
              },
              onPageFinished: (String url) {
                // if (!isSubPageRequested && widget.pageToRedirect != null) {
                //   Future<void>.delayed(const Duration(seconds: 1), () {
                //     final String redirectUrl = "http://${serviceLocator<AppSettings>().cloudWebUrl}${widget.pageToRedirect}";
                //     print("Redirecting to: $redirectUrl");
                //     controller?.loadRequest(Uri.parse(redirectUrl));
                //     isSubPageRequested = true;
                //   });
                // }
                setState(() {
                  isLoading = false;
                });
              },
              onWebResourceError: (WebResourceError error) {
                debugPrint('WebView error: ${error.description}');
              },
            ),
          )
          ..loadRequest(Uri.parse(webUiUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          // Progress indicator
          if (widget.showProgress && isLoading)
            LinearProgressIndicator(
              value: loadingProgress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),

          // WebView
          Expanded(
            child: WebViewWidget(
              controller: controller!,
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      //show a refresh button
      floatingActionButton: Container(
        margin: const EdgeInsets.only(top: 16.0, right: 16.0),
        child: FloatingActionButton(
          shape: const CircleBorder(),
          onPressed: () {
            loadUrl();
          },
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}
