import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class FeedbackWebView extends StatefulWidget {
  const FeedbackWebView({super.key});

  @override
  State<FeedbackWebView> createState() => _FeedbackWebViewState();
}

class _FeedbackWebViewState extends State<FeedbackWebView> {
  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        javaScriptCanOpenWindowsAutomatically: true,
      ),
      onReceivedError: (InAppWebViewController controller, WebResourceRequest request, WebResourceError error) {
        log("Error loading feedback form: ${error.description}");
      },
      initialData: InAppWebViewInitialData(
        data: '''
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>Jira Issue Collector Demo</title>

        <!-- Jira Issue Collector Script -->
        <script type="text/javascript" src="https://boseprofessional.atlassian.net/s/d41d8cd98f00b204e9800998ecf8427e-T/ribuf7/b/0/c95134bc67d3a521bb3f4331beb9b804/_/download/batch/com.atlassian.jira.collector.plugin.jira-issue-collector-plugin:issuecollector/com.atlassian.jira.collector.plugin.jira-issue-collector-plugin:issuecollector.js?locale=en-US&collectorId=9740b101"></script>
      </head>
      <body>
      	<iframe
          style="display:none;"
          id="jiraIssueCollector"
          name="jiraIssueCollector"
          src='https://inappwebview.dev/docs/webview/in-app-webview'
        ></iframe>
        <script type="text/javascript">
          // Initialize the Jira Issue Collector
          JIRA.IssueCollector.showIssueCollectorDialog({
            triggerFunction: function() {
              // This function is called when the dialog is shown
              console.log("Jira Issue Collector dialog opened.");
            }
          });
        </script>
      </body>
      ''',
      ),
      // initialUrlRequest: URLRequest(
      //   url: WebUri(
      //     'https://inappwebview.dev/docs/webview/in-app-webview',
      //   ),
      // ),
    );
  }
}
