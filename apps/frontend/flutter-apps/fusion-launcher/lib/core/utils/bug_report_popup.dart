import 'dart:io';
import 'dart:ui';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fusion_launcher/core/utils/fusion_utils.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../../features/configuration/presentation/viewmodel/project_view_model.dart';
import '../service_locator.dart';

/// Shows a popup dialog with Share, Download, and Submit Feedback options
/// Returns 'share', 'download', 'feedback', or null if dismissed
Future<String?> showShareDownloadPopup(BuildContext context) async {
  return showDialog<String>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.3),
    builder:
        (BuildContext context) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 340),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    spreadRadius: 0,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Title
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                        child: Text(
                          'Support Options',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withOpacity(0.85),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),

                      // Options
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: <Widget>[
                            _buildGlassOption(
                              context: context,
                              icon: Icons.feedback_rounded,
                              title: 'Submit Feedback',
                              subtitle: 'Submit feedback via Jira',
                              onTap: () => Navigator.pop(context, 'feedback'),
                            ),
                            const SizedBox(height: 8),
                            _buildGlassOption(
                              context: context,
                              icon: Icons.share_rounded,
                              title: 'Share Logs',
                              subtitle: 'Share logs via apps',
                              onTap: () => Navigator.pop(context, 'share'),
                            ),
                            const SizedBox(height: 8),
                            _buildGlassOption(
                              context: context,
                              icon: Icons.download_rounded,
                              title: 'Download Logs',
                              subtitle: 'Download logs locally',
                              onTap: () => Navigator.pop(context, 'download'),
                            ),
                          ],
                        ),
                      ),

                      // Divider
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Container(
                          height: 0.5,
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ),

                      // Cancel Button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.black.withOpacity(0.05),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
  );
}

Widget _buildGlassOption({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 24,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Downloads files locally to user-selected directory
/// Returns true if successful, false otherwise
Future<bool> downloadFilesLocally(
  BuildContext context,
  List<XFile> files, {
  File? projectFile,
}) async {
  try {
    // Let user pick a directory to save files
    final String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Download Location',
    );

    if (selectedDirectory == null) {
      // User cancelled
      return false;
    }

    final Directory downloadDir = Directory(selectedDirectory);

    // Create a timestamped folder for this export
    final String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final String exportFolderName = 'fusion_export_$timestamp';
    final Directory exportDir = Directory(p.join(downloadDir.path, exportFolderName));

    await exportDir.create(recursive: true);

    // Copy all log files
    for (final XFile xFile in files) {
      final File sourceFile = File(xFile.path);
      final String fileName = p.basename(xFile.path);
      final String destPath = p.join(exportDir.path, fileName);

      await sourceFile.copy(destPath);
    }

    // Copy project file if provided
    if (projectFile != null && await projectFile.exists()) {
      final String projectFileName = p.basename(projectFile.path);
      final String destPath = p.join(exportDir.path, projectFileName);
      await projectFile.copy(destPath);
    }

    // Show success message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Files saved to: ${exportDir.path}'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () async {
              // Open the folder (platform-specific)
              await _openFolder(exportDir.path);
            },
          ),
        ),
      );
    }

    return true;
  } catch (e, st) {
    FusionLogger.log(
      tag: LogTag.exceptions,
      message: "Download failed: $e\n$st",
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    return false;
  }
}

/// Opens a folder in the system file manager
Future<void> _openFolder(String path) async {
  try {
    if (Platform.isMacOS) {
      await Process.run('open', <String>[path]);
    } else if (Platform.isWindows) {
      await Process.run('explorer', <String>[path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', <String>[path]);
    }
  } catch (e) {
    // Silently fail - opening folder is a nice-to-have
    debugPrint('Could not open folder: $e');
  }
}

/// Alternative: Download as a single ZIP file
Future<bool> downloadAsZip(
  BuildContext context,
  List<XFile> files, {
  File? projectFile,
}) async {
  try {
    // Import archive package: import 'package:archive/archive.dart';
    final Archive archive = Archive();

    // Add all log files to archive
    for (final XFile xFile in files) {
      final File file = File(xFile.path);
      final List<int> bytes = await file.readAsBytes();
      final String fileName = p.basename(xFile.path);
      archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
    }

    // Add project file if provided
    if (projectFile != null && await projectFile.exists()) {
      final List<int> bytes = await projectFile.readAsBytes();
      final String fileName = p.basename(projectFile.path);
      archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
    }

    // Encode to zip
    final ZipEncoder encoder = ZipEncoder();
    final List<int> zipData = encoder.encode(archive);

    // Let user choose save location
    String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Export Archive',
      fileName: 'fusion_export_${DateTime.now().millisecondsSinceEpoch}.zip',
      type: FileType.custom,
      allowedExtensions: <String>['zip'],
    );

    if (outputPath == null) {
      return false; // User cancelled
    }

    // Ensure .zip extension
    if (!outputPath.endsWith('.zip')) {
      outputPath = '$outputPath.zip';
    }

    // Write zip file
    final File zipFile = File(outputPath);
    await zipFile.writeAsBytes(zipData, flush: true);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to: $outputPath'),
          duration: const Duration(seconds: 4),
        ),
      );
    }

    return true;
  } catch (e, st) {
    FusionLogger.log(
      tag: LogTag.exceptions,
      message: "Download as zip failed: $e\n$st",
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    return false;
  }
}

// Usage example in your code:
Future<void> handleExportLogs(BuildContext context) async {
  final String? choice = await showShareDownloadPopup(context);

  if (choice == null) return; // User cancelled

  if (choice == 'feedback') {
    // Show feedback webview
    await showFeedbackWebView(context);
    return;
  }

  FusionUiUtils.showLoader(context);

  try {
    final List<XFile> logsList = await FusionUtils.generateSharableLogsFiles();
    File? projectFile;

    // Get project file for download option
    projectFile = await serviceLocator<ProjectViewModel>().getCurrentProjectFile();
    if (projectFile != null) {
      logsList.add(FusionUtils.generateXFile(projectFile));
    }

    if (context.mounted) FusionUiUtils.hideLoader(context);

    if (choice == 'share') {
      // Share logs only (Notes will be available on macOS)
      await SharePlus.instance.share(
        ShareParams(
          text: "Fusion Logs ${DateTime.now()}",
          files: logsList,
        ),
      );
    } else if (choice == 'download') {
      // Download locally - choose your preferred method:

      // Option 1: Download as separate files in a folder
      if (context.mounted) await downloadFilesLocally(context, logsList, projectFile: projectFile);

      // Option 2: Download as a single ZIP file
      // await downloadAsZip(context, logsList, projectFile: projectFile);
    }
  } catch (e, st) {
    if (context.mounted) FusionUiUtils.hideLoader(context);
    FusionLogger.log(
      tag: LogTag.exceptions,
      message: "Export failed: $e\n$st",
    );
  }
}

class _FeedbackWebView extends StatefulWidget {
  const _FeedbackWebView();

  @override
  State<_FeedbackWebView> createState() => __FeedbackWebViewState();
}

class __FeedbackWebViewState extends State<_FeedbackWebView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Fullscreen WebView
          InAppWebView(
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              javaScriptCanOpenWindowsAutomatically: true,
            ),
            onReceivedError: (InAppWebViewController controller, WebResourceRequest request, WebResourceError error) {
              FusionLogger.log(
                tag: LogTag.exceptions,
                message: "Error loading feedback form: ${error.description}",
              );
            },
            initialData: InAppWebViewInitialData(
              data: '''
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="UTF-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0" />
            <title>Jira Issue Collector Demo</title>
        
            <script>
              // ----- Flutter bridge -----
              function notifyFlutterToCloseWebView() {
                // flutter_inappwebview
                if (window.flutter_inappwebview?.callHandler) {
                  window.flutter_inappwebview.callHandler("jiraCloseRequested");
                  return;
                }
        
                // optional fallback (if ever used in another webview)
                if (window.ReactNativeWebView?.postMessage) {
                  window.ReactNativeWebView.postMessage("jiraCloseRequested");
                }
              }
        
              // Intercept "Close" clicks if the close link is in the same DOM (sometimes it is).
              // If it's inside a cross-origin iframe, this won't see it — that's why we also
              // detect close via DOM changes below.
              document.addEventListener(
                "click",
                function (e) {
                  const closeLink = e.target?.closest?.("a.cancel");
                  if (closeLink) {
                    e.preventDefault();
                    notifyFlutterToCloseWebView();
                  }
                },
                true
              );
        
              // ----- Jira Issue Collector setup -----
              // Must be defined BEFORE issuecollector.js loads
              window.ATL_JQ_PAGE_PROPS = {
                triggerFunction: function (showCollectorDialog) {
                  // Keep a safe opener (do NOT forward click events into it)
                  window.openJiraCollector = function () {
                    showCollectorDialog(); // IMPORTANT: call with NO args
                  };
                },
              };
        
              // Helper: best-effort check if the collector UI is currently open/visible
              function isCollectorOpen() {
                // Common containers/classes used by the collector
                const container =
                  document.getElementById("atlwdg-container") ||
                  document.querySelector(".atlwdg-popup, .atlwdg-blanket, .atlwdg-trigger");
        
                if (!container) return false;
        
                // Visible in layout?
                return !!(container.offsetWidth || container.offsetHeight || container.getClientRects().length);
              }
        
              function clickWhenTriggerAppears() {
                const tryClick = () => {
                  const el = document.getElementById("atlwdg-trigger");
                  if (el && typeof el.getBoundingClientRect === "function") {
                    el.click();
                    return true;
                  }
                  return false;
                };
        
                if (tryClick()) return;
        
                const obs = new MutationObserver(() => {
                  if (tryClick()) obs.disconnect();
                });
        
                obs.observe(document.documentElement, { childList: true, subtree: true });
        
                setTimeout(() => {
                  obs.disconnect();
                  if (!document.getElementById("atlwdg-trigger") && typeof window.openJiraCollector === "function") {
                    window.openJiraCollector();
                  }
                }, 10000);
              }
        
              // Detect dialog close (covers: Close button inside iframe, ESC, outside click, etc.)
              function watchCollectorClose() {
                let wasOpen = isCollectorOpen();
        
                const closeObs = new MutationObserver(() => {
                  const openNow = isCollectorOpen();
                  if (wasOpen && !openNow) {
                    notifyFlutterToCloseWebView();
                  }
                  wasOpen = openNow;
                });
        
                closeObs.observe(document.documentElement, { childList: true, subtree: true });
              }
        
              // Start once DOM exists
              function init() {
                clickWhenTriggerAppears();
                watchCollectorClose();
              }
        
              if (document.readyState === "loading") {
                document.addEventListener("DOMContentLoaded", init, { once: true });
              } else {
                init();
              }
            </script>
        
            <!-- Jira Issue Collector Script -->
            <script
              src="https://boseprofessional.atlassian.net/s/d41d8cd98f00b204e9800998ecf8427e-T/ribuf7/b/0/c95134bc67d3a521bb3f4331beb9b804/_/download/batch/com.atlassian.jira.collector.plugin.jira-issue-collector-plugin:issuecollector/com.atlassian.jira.collector.plugin.jira-issue-collector-plugin:issuecollector.js?locale=en-US&collectorId=9740b101"
              defer
            ></script>
          </head>
        
          <body></body>
        </html>
        ''',
            ),
            // initialUrlRequest: URLRequest(
            //   url: WebUri(
            //     'https://inappwebview.dev/docs/webview/in-app-webview',
            //   ),
            // ),
            onWebViewCreated: (InAppWebViewController controller) {
              controller.addJavaScriptHandler(
                handlerName: "jiraCloseRequested",
                callback: (List<dynamic> args) {
                  // close the page/webview
                  Navigator.of(context).pop();
                  return null;
                },
              );
            },
          ),

          // Floating close button in top right
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the feedback webview in a modal
Future<void> showFeedbackWebView(BuildContext context) async {
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (BuildContext context) => const _FeedbackWebView(),
      fullscreenDialog: true,
    ),
  );
}
