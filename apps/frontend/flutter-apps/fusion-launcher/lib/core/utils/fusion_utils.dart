import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../router/navigation_observer.dart';

bool isLoaderVisible = false;

class FusionUiUtils {
  static void showLoader(BuildContext context) {
    if (routeObserver.getRouteNames().last != "FusionLoader") {
      showDialog(
        context: context,
        barrierDismissible: false,
        routeSettings: const RouteSettings(name: "FusionLoader"),
        builder: (BuildContext context) {
          return PopScope(
            canPop: false,
            child: Stack(
              children: <Widget>[
                const Opacity(
                  opacity: 0.3,
                  child: ModalBarrier(dismissible: false, color: Colors.white),
                ),
                Center(
                  child: Semantics(
                    identifier: "loader",
                    label: "loader",
                    container: true,
                    child: const CupertinoActivityIndicator(
                      radius: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  static void hideLoader(BuildContext context) {
    if (routeObserver.getRouteNames().last == "FusionLoader") {
      Navigator.of(context).pop();
    }
  }

  static Color hexToColor(String hexString) {
    final StringBuffer buffer = StringBuffer();
    if (hexString.startsWith('#')) hexString = hexString.substring(1);
    if (hexString.length == 6) buffer.write('FF');
    buffer.write(hexString);
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static String colorToHex(Color color, {bool includeAlpha = false}) {
    String twoHex(int v) => v.toRadixString(16).padLeft(2, '0');

    final int a = (color.a * 255.0).round() & 0xff;
    final int r = (color.r * 255.0).round() & 0xff;
    final int g = (color.g * 255.0).round() & 0xff;
    final int b = (color.b * 255.0).round() & 0xff;

    final StringBuffer buffer = StringBuffer();
    if (includeAlpha) buffer.write(twoHex(a));
    buffer
      ..write(twoHex(r))
      ..write(twoHex(g))
      ..write(twoHex(b));

    return '#${buffer.toString().toUpperCase()}';
  }

  static void showErrorDialog(DioException err, {bool fromError = false}) {
    final BuildContext? context = globalNavigatorKey.currentContext;
    if (context == null) return;
    final String url = err.requestOptions.uri.toString();

    if (!fromError) {
      //if fromError (i.e. internal server error etc... show dialog , else check if url is backend server) endpoint)
      if (url.isBackendServerEndpoint()) {
        return;
      }
    }

    FusionUiUtils.hideLoader(context);

    final String method = err.requestOptions.method;
    final Map<String, dynamic> headers = err.requestOptions.headers;
    final dynamic requestData = err.requestOptions.data;
    final int? statusCode = err.response?.statusCode;
    final dynamic responseData = err.response?.data;
    final String? errorMessage = err.message;

    String formattedRequestData = 'None';
    if (requestData != null) {
      try {
        if (requestData is FormData) {
          formattedRequestData = 'FormData with ${requestData.fields.length} fields';
        } else if (requestData is Map) {
          formattedRequestData = const JsonEncoder.withIndent('  ').convert(requestData);
        } else {
          formattedRequestData = requestData.toString();
        }
      } catch (e) {
        formattedRequestData = requestData.toString();
      }
    }

    String formattedResponseData = 'None';
    if (responseData != null) {
      try {
        if (responseData is Map || responseData is List) {
          formattedResponseData = const JsonEncoder.withIndent('  ').convert(responseData);
        } else {
          formattedResponseData = responseData.toString();
        }
      } catch (e) {
        formattedResponseData = responseData.toString();
      }
    }

    showDialog(
      context: context,
      routeSettings: const RouteSettings(name: "ApiErrorDialog"),
      barrierDismissible: false,
      builder: (BuildContext context) {
        bool showDetails = false;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final List<Widget> contentChildren = <Widget>[
              _buildErrorSection(context, 'Request URL', '$method $url'),
            ];

            if (showDetails) {
              contentChildren.addAll(<Widget>[
                const SizedBox(height: 16),
                _buildErrorSection(context, 'Request Headers', const JsonEncoder.withIndent('  ').convert(headers)),
                const SizedBox(height: 16),
                _buildErrorSection(context, 'Request Payload', formattedRequestData),
                const SizedBox(height: 16),
                _buildErrorSection(context, 'Response Data', formattedResponseData),
              ]);
              if (errorMessage != null) {
                contentChildren.addAll(<Widget>[
                  const SizedBox(height: 16),
                  _buildErrorSection(context, 'Error Message', errorMessage),
                ]);
              }
            } else {
              if (errorMessage != null) {
                contentChildren.addAll(<Widget>[
                  const SizedBox(height: 16),
                  _buildErrorSection(context, 'Error Message', errorMessage),
                ]);
              }
            }

            return AlertDialog(
              title: FusionAppText(
                text: '⚠️ API Error ${statusCode != null ? '($statusCode)' : ''}',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: min(700, MediaQuery.of(context).size.width * 0.9),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: contentChildren,
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const FusionAppText(text: 'Close', style: TextStyle(color: Colors.blueAccent)),
                ),
                TextButton(
                  onPressed: () => setState(() => showDetails = !showDetails),
                  child: FusionAppText(
                    text: showDetails ? 'Hide Details' : 'Show Details',
                    style: const TextStyle(color: Colors.blueAccent),
                  ),
                ),
                if (showDetails) ...<Widget>[
                  TextButton(
                    onPressed: () => _copyRequestData(context, requestData),
                    child: const FusionAppText(text: 'Copy Request', style: TextStyle(color: Colors.blueAccent)),
                  ),
                  TextButton(
                    onPressed: () {
                      final String errorDetails = '''
API Error Details:
Request URL: $method $url
Request Headers: ${const JsonEncoder.withIndent('  ').convert(headers)}
Request Payload: $formattedRequestData
Response Data: $formattedResponseData
Error Message: ${errorMessage ?? 'None'}
Status Code: ${statusCode ?? 'None'}
''';
                      _copyToClipboard(context, errorDetails);
                    },
                    child: const FusionAppText(text: 'Copy All', style: TextStyle(color: Colors.blueAccent)),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  static void _copyRequestData(BuildContext context, dynamic requestData) {
    String dataToCopy = 'None';

    if (requestData != null) {
      try {
        if (requestData is FormData) {
          // For FormData, create a readable format
          final Map<String, dynamic> formFields = <String, dynamic>{};
          for (MapEntry<String, String> field in requestData.fields) {
            formFields[field.key] = field.value;
          }
          dataToCopy = const JsonEncoder.withIndent('  ').convert(formFields);
        } else if (requestData is Map) {
          dataToCopy = const JsonEncoder.withIndent('  ').convert(requestData);
        } else {
          dataToCopy = requestData.toString();
        }
      } catch (e) {
        dataToCopy = requestData.toString();
      }
    }

    _copyToClipboard(context, dataToCopy);
  }

  static void _copyToClipboard(BuildContext context, String text) {
    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: text));

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: FusionAppText(text: 'Data copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );

    // Navigator.of(context).pop();
  }

  static Widget _buildErrorSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FusionAppText(
          text: title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.colorScheme.elevation1,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: context.colorScheme.textPrimary),
          ),
          child: SelectableText(
            content,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
