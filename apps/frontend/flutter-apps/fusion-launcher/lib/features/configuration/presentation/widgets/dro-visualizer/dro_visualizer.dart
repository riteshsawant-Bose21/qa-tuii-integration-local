import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../../core/utils/dro_json_mapper.dart';
import 'full_screen_image.dart';

class DROVisualizer extends StatelessWidget {
  final bool showJSON;

  const DROVisualizer({
    super.key,
    this.showJSON = true,
  });

  Future<Map<String, dynamic>> getDROResponse(BuildContext context) async {
    final Map<String, dynamic> outputJson = JsonFormatConverter.convertFormat(
      serviceLocator<ProjectViewModel>().getProjectJson(),
      serviceLocator<ProjectViewModel>().fusionDevices,
    );

    //show a loader dialog while processing
    final ResponseCallback<dynamic> responseCallback = await serviceLocator<FusionNetworkClient>().post(api: FusionApiEndpoint.process, data: outputJson);

    if (responseCallback.success) {
      final Map<String, dynamic> data = responseCallback.data as Map<String, dynamic>;

      final Map<String, dynamic> result = Map<String, dynamic>.from(data["result"] ?? <dynamic, dynamic>{});

      return result;
    }
    return <String, dynamic>{};
  }

  @override
  Widget build(BuildContext context) {
    // Future builder with getDROResponse
    return FutureBuilder<Map<String, dynamic>>(
      future: getDROResponse(context),
      builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget(context);
        } else if (snapshot.hasError) {
          return _buildErrorWidget(context, snapshot.error.toString());
        } else if (snapshot.hasData) {
          final Map<String, dynamic> response = snapshot.data!;
          return _buildSuccessWidget(context, response);
        } else {
          return _buildInitialWidget(context);
        }
      },
    );
  }

  Widget _buildInitialWidget(BuildContext context) {
    return const SizedBox(height: 20);
  }

  Widget _buildLoadingWidget(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.width * 0.8,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildSuccessWidget(BuildContext context, Map<String, dynamic> response) {
    final String inputData = response["image_input"];
    final String outputData = response["image_output"];
    final Uint8List inputImageBytes = base64Decode(inputData);
    final Uint8List outputImageBytes = base64Decode(outputData);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          FusionAppText(
            text: "Design Visualizer",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 32),
          FusionAppText(
            text: "Input Design",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          DROResponseImage(
            imageBytes: inputImageBytes,
          ),
          const SizedBox(height: 32),
          FusionAppText(
            text: "Optimized Design",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          DROResponseImage(
            imageBytes: outputImageBytes,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String errorMessage) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: FusionAppText(
        text: 'Error: $errorMessage',
        // overflow: TextOverflow.ellipsis,
        // maxLines: 1,
        softWrap: true,
      ),
    );
  }

  static void openDROVisualizer(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            children: <Widget>[
              Expanded(
                child: Stack(
                  children: <Widget>[
                    SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            child: const DROVisualizer(
                              showJSON: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 24,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DROResponseImage extends StatelessWidget {
  final Uint8List imageBytes;

  const DROResponseImage({
    super.key,
    required this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Image.memory(
        imageBytes,
        fit: BoxFit.contain,
      ),
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder<FullScreenImagePage>(
            opaque: false,
            barrierColor: Colors.black.withValues(alpha: 0.9),
            pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
              return FullScreenImagePage(
                imageBytes: imageBytes,
              );
            },
            transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      },
    );
  }
}
