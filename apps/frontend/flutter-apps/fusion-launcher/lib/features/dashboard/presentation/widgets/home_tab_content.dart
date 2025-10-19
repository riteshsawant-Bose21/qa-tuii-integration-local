import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/theme/app_theme.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart' hide FusionUtils;

import '../../../../core/router/routes.dart';
import '../../../../core/service_locator.dart';
import '../../../../core/utils/fusion_utils.dart';

class HomeTabContent extends StatefulWidget {
  const HomeTabContent({super.key});

  @override
  State<HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<HomeTabContent> {
  final SharedPreferencesHandler prefs = serviceLocator<SharedPreferencesHandler>();
  final List<Map<String, String>> cardData = <Map<String, String>>[
    <String, String>{
      'label': 'Getting Started',
      'title': 'How does FUSION work?',
      'button': 'Start',
      'description':
          'FUSION is a comprehensive design tool that allows you to create, manage, and visualize your audio-visual projects with ease. From initial concept to final implementation, FUSION provides the tools you need to bring your vision to life.',
    },
    <String, String>{
      'label': 'Announcement',
      'title': 'Big sound. Small footprint. Incredible power. 🔊',
      'button': 'Learn More',
      'description':
          "Introducing the all-new Forum series loudspeakers from Bose Professional — truly powerful, compact, and purpose-built for permanent installations where clarity, control, and serious output matter most.",
      'imageUrl': 'assets/images/speaker_banner.png',
      "actionUrl": "https://boseprofessional.com/company/newsroom/2025/built-in-honors-bose-professional-with-2025-best-place-to-work-award",
    },
    <String, String>{
      'label': 'Announcement',
      'title': 'Smart. Simple. Seriously powerful.🎛',
      'button': 'Learn More',
      'description':
          "Meet Veritas—a new series of smart mixer amplifiers designed to deliver clarity, control, and clean design in one compact package. With Bluetooth® 5.0, OLED screens, and DSP-optimized presets, these amps are ready to take on restaurants, retail, fitness, and more.",
      'imageUrl': 'assets/images/amplifiers_banner.png',
      "actionUrl": "https://boseprofessional.com/company/newsroom/2025/built-in-honors-bose-professional-with-2025-best-place-to-work-award",
    },
    <String, String>{
      'label': 'Announcement',
      'title': '🎶 Meet Veritas: Smart, Simple, and Powerful. 🔊',
      'button': 'Learn More',
      'description':
          'The Veritas Series Smart Mixer Amplifiers bring seamless sound to small- and medium-sized commercial spaces with Bluetooth® wireless input, intuitive controls, and a quick-start QR code for effortless setup. Whether it’s background music, paging, or multimedia, Veritas makes it easy to deliver superior Bose Professional sound anywhere.',
      'imageUrl': 'assets/images/dsp_banner.png',
      "actionUrl": "https://boseprofessional.com/company/newsroom/2025/built-in-honors-bose-professional-with-2025-best-place-to-work-award",
    },
    <String, String>{
      'label': 'Success Stories',
      'title': 'InfoComm 2025',
      'button': 'Learn More',
      'description':
          'A/V professionals, system integrators, and people from around the world will converge in Orlando to discover the newest innovations in pro audio and share their passion for sound. Visit us this year at Booth 6361 and Demo Room W224D. We can’t wait to see you there!',
      'imageUrl': 'assets/images/infocomm_banner.png',
      "actionUrl": "https://boseprofessional.com/company/newsroom/2025/infocomm-2025-press-release",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Optionally, you can use _currentTab to change the content based on the active tab.
                if (cardData.isNotEmpty) _buildTopCardsSlider(),
                if (cardData.isEmpty) const SizedBox(height: 0) else const SizedBox(height: 32),
                _buildSectionTitle('Recently viewed'),
                const SizedBox(height: 20),
                _buildRecentProjects(),
                const SizedBox(height: 32),
                _buildSectionTitle('Start from Template'),
                const SizedBox(height: 20),
                _buildTemplates(),
                const SizedBox(height: 32), // Add bottom padding
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build sidebar widget
  Widget _buildTopCardsSlider() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Make height responsive to available space
        final double cardHeight = constraints.maxHeight > 400 ? 384 : constraints.maxHeight * 0.8;

        return SizedBox(
          height: cardHeight.clamp(300, 384), // Ensure minimum and maximum heights
          child: ListView.separated(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 16),
            itemCount: cardData.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (BuildContext context, int index) {
              return SizedBox(
                width: 559,
                child: _buildInfoCard(
                  cardData[index]['label']!,
                  cardData[index]['title']!,
                  cardData[index]['button']!,
                  cardData[index]['description'] ?? 'No description available',
                  cardData[index]['imageUrl'] ?? '',
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// information card widget
  Widget _buildInfoCard(String label, String title, String buttonText, String description, String imageUrl) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      elevation: 0,
      color: Colors.white,
      child: Container(
        width: 559,
        constraints: const BoxConstraints(minHeight: 300, maxHeight: 384), // Add constraints
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF000000).withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            /// Header with label, title, and close button
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
                borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: <Widget>[
                  Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 2, // Prevent title overflow
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        cardData.removeWhere((Map<String, String> element) => element['label'] == label);
                      });
                    },
                    child: const Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),

            /// network image or placeholder
            Expanded(
              child: Image.asset(
                imageUrl.isNotEmpty ? imageUrl : 'assets/images/fusion_default_icon.png',
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            // Bottom section with text and button
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(6)),
              ),
              padding: const EdgeInsets.all(16),
              child: IntrinsicHeight(
                // Ensure proper height distribution
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        "$description ",
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                      child: Text(
                        buttonText,
                        style: const TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build section title with chevron icon
  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),

            Row(
              children: <Widget>[
                if (title == "Recently viewed")
                  if (prefs.getBool(SharedPreferenceKeys.adminLogin) != true)
                    TextButton.icon(
                      onPressed: () async {
                        // FusionUtils.showLoader(context);
                        // final (bool success, String message) = await projectListManager.syncProjectsFromCloud();
                        // if (context.mounted) {
                        //   FusionUtils.hideLoader(context);
                        //   ScaffoldMessenger.of(context).showSnackBar(
                        //     SnackBar(
                        //       content: Text(message),
                        //       backgroundColor: success ? Colors.green : Colors.red,
                        //       duration: const Duration(seconds: 2),
                        //     ),
                        //   );
                        // }
                      },
                      icon: const Icon(Icons.cloud_sync),
                      label: const Text(
                        'Sync Projects',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
              ],
            ),
          ],
        ),
        const SizedBox(height: 17),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
      ],
    );
  }

  /// Build recent projects section with cards
  Widget _buildRecentProjects() {
    return BlocConsumer<ProjectViewModel, ProjectViewModelState>(
      listener: (BuildContext context, ProjectViewModelState state) {
        if (state is ProjectLoaded && context.mounted) {
          if (state.currentProject != null) {
            FusionUiUtils.hideLoader(context);
            Navigator.pushNamed(
              context,
              Routes.projectPage,
            );
          }
        }
        if (state is OpenProjectError && context.mounted) {
          FusionUiUtils.hideLoader(context);
          FusionToast.show(context, message: state.message);
        }
      },
      builder: (BuildContext context, ProjectViewModelState state) {
        if (state is! ProjectLoading && !serviceLocator<ProjectViewModel>().hasProjects) {
          return const Center(
            child: SizedBox(
              width: 262,
              height: 166,
              child: Center(
                child: Text(
                  "No Projects Available",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          );
        }

        return Wrap(
          spacing: 32,
          runSpacing: 32,
          children: List<Widget>.generate(
            serviceLocator<ProjectViewModel>().allProjects.length,
            (int i) {
              return GestureDetector(
                onTap: () async {
                  FusionUiUtils.showLoader(context);
                  serviceLocator<ProjectViewModel>().openProject(serviceLocator<ProjectViewModel>().allProjects[i].id);
                },
                child: _buildProjectCard(
                  title: serviceLocator<ProjectViewModel>().allProjects[i].projectName,
                  subtitle: "", //Helper.formatTimeAgoSimple(projects[i].updatedAt),
                  // subtitle: 'Last updated: ${projects[i].updatedAt.toLocal().toIso8601String().substring(0, 10)}',
                  thumbnailUrl: "",
                  onDelete: () {
                    serviceLocator<ProjectViewModel>().deleteProjectFromLocal(serviceLocator<ProjectViewModel>().allProjects[i].id);
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Build templates section with cards
  Widget _buildTemplates() {
    final List<Map<String, String>> projectTemplate = <Map<String, String>>[
      <String, String>{
        'title': 'Gym Template',
        'subtitle':
            "A comprehensive template for gym and fitness center projects. This template includes optimized layouts for workout zones, equipment placement, and member flow patterns. Perfect for designing commercial gyms, personal training studios, or home fitness spaces with professional-grade planning tools.",
        'thumbnailImage': 'assets/images/floor_plans/gym_floor_template.png',
      },
      <String, String>{
        'title': 'Restaurant Template',
        'subtitle':
            "A versatile template designed for restaurant and dining establishment projects. Features carefully planned seating arrangements, kitchen workflows, and service areas to maximize efficiency and customer experience. Ideal for cafes, fine dining restaurants, fast-casual establishments, or food courts with customizable layouts.",
        'thumbnailImage': 'assets/images/floor_plans/restaurant_floor_template.png',
      },
      <String, String>{
        'title': 'Retail Store Template',
        'subtitle':
            "A modern template tailored for retail and commercial store projects. Incorporates strategic product placement zones, customer traffic flow optimization, and point-of-sale positioning. Suitable for boutiques, department stores, specialty shops, or pop-up retail spaces with flexible merchandising areas.",
        'thumbnailImage': 'assets/images/floor_plans/retail_floor_template.png',
      },

      <String, String>{
        'title': 'Office Template',
        'subtitle':
            "A professional template for corporate and office workspace projects. Includes collaborative spaces, private offices, meeting rooms, and open work areas designed for productivity and employee comfort. Perfect for startups, established businesses, co-working spaces, or remote work hubs with scalable configurations.",
        'thumbnailImage': 'assets/images/floor_plans/office_floor_template.png',
      },
      <String, String>{
        'title': 'Theater Template',
        'subtitle':
            "An entertainment-focused template for home theater and media room projects. Features optimized seating arrangements, acoustic considerations, and equipment placement for the ultimate viewing experience. Ideal for residential home theaters, media rooms, game rooms, or entertainment spaces with premium audio-visual setups.",
        'thumbnailImage': 'assets/images/floor_plans/theater_template.png',
      },
    ];

    return Wrap(
      spacing: 32,
      runSpacing: 32,
      children:
          projectTemplate
              .map(
                (Map<String, String> template) => _buildTemplateCard(
                  title: template['title']!,
                  subtitle: template['subtitle']!,
                  thumbnailImage: template['thumbnailImage']!,
                ),
              )
              .toList(),
    );
  }

  /// Build template card widget
  Widget _buildTemplateCard({required String title, required String subtitle, required String thumbnailImage}) {
    return SizedBox(
      width: 264,
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        elevation: 0,
        // color: Colors.grey[100],
        color: Colors.white60,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Prevent overflow
            children: <Widget>[
              Container(
                height: 104,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
                child: Center(
                  child: Image.asset(
                    thumbnailImage,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              Flexible(
                /// Make content area flexible
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.blackTransparentL, height: 1.4, letterSpacing: 0.5),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build project card widget
  Widget _buildProjectCard({
    required String title,
    required String subtitle,
    required VoidCallback onDelete,
    required String? thumbnailUrl,
  }) {
    return SizedBox(
      width: 262,
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        elevation: 0,
        color: Colors.white60,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Theme.of(context).colorScheme.borderColorL,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Stack(
                children: <Widget>[
                  /// thumbnail image
                  Container(
                    height: 166,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                    child:
                        thumbnailUrl != null && thumbnailUrl.isNotEmpty
                            ? FutureBuilder<File?>(
                              future: () async {
                                return null;
                                // try {
                                //   return await projectListManager.downloadThumbnailFile(fileId: thumbnailUrl);
                                // } catch (e) {
                                //   return null;
                                // }
                              }(),
                              builder: (BuildContext context, AsyncSnapshot<File?> snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Container(
                                    height: 200,
                                    color: Colors.grey.shade200,
                                    child: const Center(child: CircularProgressIndicator()),
                                  );
                                }
                                if (snapshot.hasError || snapshot.data == null) {
                                  return Image.asset(
                                    "assets/images/floor_plans/default_floor.png",
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  );
                                }
                                return Image.file(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                  height: 200,
                                  width: double.infinity,
                                );
                              },
                            )
                            : Image.asset(
                              "assets/images/floor_plans/default_floor.png",
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                  ),

                  /// Popup menu for delete project
                  Positioned(
                    top: 6,
                    right: 6,
                    child: PopupMenuButton<String>(
                      onSelected: (String value) {
                        if (value == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder:
                          (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: <Widget>[
                                  Icon(Icons.delete_sharp, size: 16, color: Colors.black),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                      icon: const Icon(Icons.more_vert, size: 18, color: Colors.black),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 100),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
}
