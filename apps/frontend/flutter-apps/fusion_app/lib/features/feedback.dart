// import 'package:flutter/material.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// class FeedbackWebView extends StatefulWidget {
//   const FeedbackWebView();
//
//   @override
//   State<FeedbackWebView> createState() => _FeedbackWebViewState();
// }
//
// class _FeedbackWebViewState extends State<FeedbackWebView> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: <Widget>[
//           // Fullscreen WebView
//           InAppWebView(
//             initialSettings: InAppWebViewSettings(
//               javaScriptEnabled: true,
//               javaScriptCanOpenWindowsAutomatically: true,
//             ),
//             onReceivedError: (
//                 InAppWebViewController controller,
//                 WebResourceRequest request,
//                 WebResourceError error,
//                 ) {
//               print("Error loading feedback form: ${error.description}");
//               // FusionLogger.log(
//               //   tag: LogTag.exceptions,
//               //   message: "Error loading feedback form: ${error.description}",
//               // );
//             },
//             initialData: InAppWebViewInitialData(
//               data: '''
//         <!DOCTYPE html>
//         <html lang="en">
//           <head>
//             <meta charset="UTF-8" />
//             <meta name="viewport" content="width=device-width, initial-scale=1.0" />
//             <title>Jira Issue Collector Demo</title>
//
//             <script>
//               // ----- Flutter bridge -----
//               function notifyFlutterToCloseWebView() {
//                 // flutter_inappwebview
//                 if (window.flutter_inappwebview?.callHandler) {
//                   window.flutter_inappwebview.callHandler("jiraCloseRequested");
//                   return;
//                 }
//
//                 // optional fallback (if ever used in another webview)
//                 if (window.ReactNativeWebView?.postMessage) {
//                   window.ReactNativeWebView.postMessage("jiraCloseRequested");
//                 }
//               }
//
//               // Intercept "Close" clicks if the close link is in the same DOM (sometimes it is).
//               // If it's inside a cross-origin iframe, this won't see it — that's why we also
//               // detect close via DOM changes below.
//               document.addEventListener(
//                 "click",
//                 function (e) {
//                   const closeLink = e.target?.closest?.("a.cancel");
//                   if (closeLink) {
//                     e.preventDefault();
//                     notifyFlutterToCloseWebView();
//                   }
//                 },
//                 true
//               );
//
//               // ----- Jira Issue Collector setup -----
//               // Must be defined BEFORE issuecollector.js loads
//               window.ATL_JQ_PAGE_PROPS = {
//                 triggerFunction: function (showCollectorDialog) {
//                   // Keep a safe opener (do NOT forward click events into it)
//                   window.openJiraCollector = function () {
//                     showCollectorDialog(); // IMPORTANT: call with NO args
//                   };
//                 },
//               };
//
//               // Helper: best-effort check if the collector UI is currently open/visible
//               function isCollectorOpen() {
//                 // Common containers/classes used by the collector
//                 const container =
//                   document.getElementById("atlwdg-container") ||
//                   document.querySelector(".atlwdg-popup, .atlwdg-blanket, .atlwdg-trigger");
//
//                 if (!container) return false;
//
//                 // Visible in layout?
//                 return !!(container.offsetWidth || container.offsetHeight || container.getClientRects().length);
//               }
//
//               function clickWhenTriggerAppears() {
//                 const tryClick = () => {
//                   const el = document.getElementById("atlwdg-trigger");
//                   if (el && typeof el.getBoundingClientRect === "function") {
//                     el.click();
//                     return true;
//                   }
//                   return false;
//                 };
//
//                 if (tryClick()) return;
//
//                 const obs = new MutationObserver(() => {
//                   if (tryClick()) obs.disconnect();
//                 });
//
//                 obs.observe(document.documentElement, { childList: true, subtree: true });
//
//                 setTimeout(() => {
//                   obs.disconnect();
//                   if (!document.getElementById("atlwdg-trigger") && typeof window.openJiraCollector === "function") {
//                     window.openJiraCollector();
//                   }
//                 }, 10000);
//               }
//
//               // Detect dialog close (covers: Close button inside iframe, ESC, outside click, etc.)
//               function watchCollectorClose() {
//                 let wasOpen = isCollectorOpen();
//
//                 const closeObs = new MutationObserver(() => {
//                   const openNow = isCollectorOpen();
//                   if (wasOpen && !openNow) {
//                     notifyFlutterToCloseWebView();
//                   }
//                   wasOpen = openNow;
//                 });
//
//                 closeObs.observe(document.documentElement, { childList: true, subtree: true });
//               }
//
//               // Start once DOM exists
//               function init() {
//                 clickWhenTriggerAppears();
//                 watchCollectorClose();
//               }
//
//               if (document.readyState === "loading") {
//                 document.addEventListener("DOMContentLoaded", init, { once: true });
//               } else {
//                 init();
//               }
//             </script>
//
//             <!-- Jira Issue Collector Script -->
//             <script type="text/javascript" src="https://boseprofessional.atlassian.net/s/d41d8cd98f00b204e9800998ecf8427e-T/150dpd/b/0/c95134bc67d3a521bb3f4331beb9b804/_/download/batch/com.atlassian.jira.collector.plugin.jira-issue-collector-plugin:issuecollector/com.atlassian.jira.collector.plugin.jira-issue-collector-plugin:issuecollector.js?locale=en-US&collectorId=f4d9fdc5"></script>
//
//           </head>
//
//           <body></body>
//         </html>
//         ''',
//             ),
//             // initialUrlRequest: URLRequest(
//             //   url: WebUri(
//             //     'https://inappwebview.dev/docs/webview/in-app-webview',
//             //   ),
//             // ),
//             onWebViewCreated: (InAppWebViewController controller) {
//               controller.addJavaScriptHandler(
//                 handlerName: "jiraCloseRequested",
//                 callback: (List<dynamic> args) {
//                   // close the page/webview
//                   Navigator.of(context).pop();
//                   return null;
//                 },
//               );
//             },
//           ),
//
//           // Floating close button in top right
//           Positioned(
//             top: MediaQuery.of(context).padding.top + 16,
//             right: 16,
//             child: Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 color: Colors.black.withValues(alpha: 0.6),
//                 shape: BoxShape.circle,
//                 boxShadow: <BoxShadow>[
//                   BoxShadow(
//                     color: Colors.black.withValues(alpha: 0.3),
//                     blurRadius: 8,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: IconButton(
//                 icon: const Icon(
//                   Icons.close,
//                   color: Colors.white,
//                   size: 20,
//                 ),
//                 onPressed: () => Navigator.pop(context),
//                 padding: EdgeInsets.zero,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }