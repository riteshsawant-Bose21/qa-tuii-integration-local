// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:fusion_web/features/projects/domain/entities/project_entity.dart';

// class ProjectDialog extends StatefulWidget {
//   final ProjectEntity? project;

//   const ProjectDialog({
//     super.key,
//     this.project,
//   });

//   @override
//   State<ProjectDialog> createState() => _ProjectDialogState();
// }

// class _ProjectDialogState extends State<ProjectDialog> {
//   final _formKey = GlobalKey<FormState>();

//   @override
//   void initState() {
//     super.initState();

//     if (widget.project != null) {
//       final p = widget.project!;

//       name.text = p.title;
//       organization.text = p.clientName;
//       country.text = p.region;
//       notes.text = p.description;
//     }
//   }

//   bool showMoreDetails = false;
//   bool get isEditMode => widget.project != null;

//   final TextEditingController name = TextEditingController();
//   final TextEditingController version = TextEditingController();
//   final TextEditingController tags = TextEditingController();
//   final TextEditingController author = TextEditingController();
//   final TextEditingController organization = TextEditingController();
//   final TextEditingController stateCtrl = TextEditingController();
//   final TextEditingController country = TextEditingController();
//   final TextEditingController timeZone = TextEditingController();
//   final TextEditingController building = TextEditingController();
//   final TextEditingController budget = TextEditingController();
//   final TextEditingController goals = TextEditingController();
//   final TextEditingController regional = TextEditingController();
//   final TextEditingController notes = TextEditingController();

//   void _handleSubmit() {
//     if (!_formKey.currentState!.validate()) return;

//     if (isEditMode) {
//       _updateProject();
//     } else {
//       _createProject();
//     }
//   }

//   void _createProject() {
//     final newProject = ProjectEntity(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       title: name.text,
//       description: notes.text,
//       clientName: organization.text,
//       region: country.text,
//       status: "active",
//       healthyDevices: 0,
//       warningDevices: 0,
//       criticalDevices: 0,
//       incidents: 0,
//       lastUpdated: DateTime.now(),
//     );

//     Navigator.pop(context, newProject);
//   }

//   void _updateProject() {
//     final updatedProject = widget.project!.copyWith(
//       title: name.text,
//       description: notes.text,
//       clientName: organization.text,
//       region: country.text,
//       lastUpdated: DateTime.now(),
//     );

//     Navigator.pop(context, updatedProject);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.transparent,
//       child: Center(
//         child: Container(
//           width: 1000,
//           height: 820,
//           padding: const EdgeInsets.all(40),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(28),
//             boxShadow: [
//               BoxShadow(
//                 blurRadius: 40,
//                 color: Colors.black.withOpacity(0.15),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "Create New Project",
//                 style: GoogleFonts.montserrat(
//                   fontSize: 24,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),

//               const SizedBox(height: 32),

//               Expanded(
//                 child: Container(
//                   padding: const EdgeInsets.all(32),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(color: Colors.grey.shade300),
//                   ),
//                   child: Form(
//                     key: _formKey,
//                     child: SingleChildScrollView(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // =============================
//                           // BASIC INFORMATION
//                           // =============================
//                           _sectionTitle("BASIC INFORMATION"),
//                           const SizedBox(height: 24),

//                           Row(
//                             children: [
//                               Expanded(
//                                 child: _input("Project File Name", name),
//                               ),
//                               const SizedBox(width: 20),
//                               Expanded(child: _input("File Version", version)),
//                             ],
//                           ),

//                           const SizedBox(height: 20),
//                           _input(
//                             "Project Tags or Categories",
//                             tags,
//                             hint:
//                                 "Add tags or categories (separated by commas)",
//                           ),

//                           const SizedBox(height: 20),

//                           Row(
//                             children: [
//                               Expanded(child: _input("Author Name", author)),
//                               const SizedBox(width: 20),
//                               Expanded(
//                                 child: _input("Organization", organization),
//                               ),
//                             ],
//                           ),

//                           const SizedBox(height: 28),

//                           // =============================
//                           // ADD MORE DETAILS (Toggle)
//                           // =============================
//                           InkWell(
//                             onTap: () {
//                               setState(() {
//                                 showMoreDetails = !showMoreDetails;
//                               });
//                             },
//                             child: Text(
//                               showMoreDetails
//                                   ? "Show Less Details"
//                                   : "Add More Details",
//                               style: GoogleFonts.montserrat(
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.black87,
//                               ),
//                             ),
//                           ),

//                           const SizedBox(height: 20),

//                           // =============================
//                           // EXPANDED SECTIONS
//                           // =============================
//                           AnimatedCrossFade(
//                             duration: const Duration(milliseconds: 300),
//                             crossFadeState: showMoreDetails
//                                 ? CrossFadeState.showSecond
//                                 : CrossFadeState.showFirst,
//                             firstChild: const SizedBox(),
//                             secondChild: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 // ORGANIZATION DETAILS
//                                 const SizedBox(height: 10),
//                                 _sectionTitle("ORGANIZATION DETAILS"),
//                                 const SizedBox(height: 24),

//                                 _input("Organization Name", organization),
//                                 const SizedBox(height: 20),

//                                 Row(
//                                   children: [
//                                     Expanded(
//                                       child: _input("Project State", stateCtrl),
//                                     ),
//                                     const SizedBox(width: 20),
//                                     Expanded(
//                                       child: _input("Project Country", country),
//                                     ),
//                                   ],
//                                 ),

//                                 const SizedBox(height: 20),
//                                 _input("Project Time Zone", timeZone),
//                                 const SizedBox(height: 20),
//                                 _input("Primary Building Name", building),

//                                 const SizedBox(height: 40),

//                                 // BUDGET
//                                 _sectionTitle("BUDGET & OBJECTIVES"),
//                                 const SizedBox(height: 24),

//                                 Row(
//                                   children: [
//                                     Expanded(
//                                       child: _input("Target Budget", budget),
//                                     ),
//                                     const SizedBox(width: 20),
//                                     Expanded(
//                                       child: _input(
//                                         "Currency",
//                                         TextEditingController(),
//                                       ),
//                                     ),
//                                   ],
//                                 ),

//                                 const SizedBox(height: 20),
//                                 _input("Project Goals", goals),

//                                 const SizedBox(height: 40),

//                                 // UNITS
//                                 _sectionTitle("UNITS & GLOBAL SETTINGS"),
//                                 const SizedBox(height: 24),

//                                 Row(
//                                   children: [
//                                     Expanded(
//                                       child: _input(
//                                         "Measurement Units",
//                                         TextEditingController(),
//                                       ),
//                                     ),
//                                     const SizedBox(width: 20),
//                                     Expanded(
//                                       child: _input(
//                                         "Temperature",
//                                         TextEditingController(),
//                                       ),
//                                     ),
//                                   ],
//                                 ),

//                                 const SizedBox(height: 20),
//                                 _input("Regional Based Defaults", regional),

//                                 const SizedBox(height: 30),
//                               ],
//                             ),
//                           ),

//                           // =============================
//                           // NOTES (Always visible)
//                           // =============================
//                           _input(
//                             "Notes",
//                             notes,
//                             maxLines: 4,
//                             hint: "Add notes or comments",
//                           ),

//                           const SizedBox(height: 40),

//                           Align(
//                             alignment: Alignment.centerRight,
//                             child: ElevatedButton(
//                               onPressed: () {
//                                 if (_formKey.currentState!.validate()) {
//                                   Navigator.pop(context);
//                                 }
//                               },
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.black87,
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 32,
//                                   vertical: 16,
//                                 ),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(14),
//                                 ),
//                               ),
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: const [
//                                   Text("Continue"),
//                                   SizedBox(width: 8),
//                                   Icon(Icons.arrow_forward),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _sectionTitle(String text) {
//     return Text(
//       text,
//       style: GoogleFonts.montserrat(
//         fontSize: 12,
//         fontWeight: FontWeight.w700,
//         color: Colors.grey[600],
//       ),
//     );
//   }

//   Widget _input(
//     String label,
//     TextEditingController controller, {
//     int maxLines = 1,
//     String? hint,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: GoogleFonts.montserrat(
//             fontSize: 13,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         const SizedBox(height: 8),
//         TextFormField(
//           controller: controller,
//           maxLines: maxLines,
//           decoration: InputDecoration(
//             hintText: hint,
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 14,
//             ),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: Colors.grey.shade300),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(color: Colors.black87, width: 1.5),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NewProjectFormData {
  final String name;
  final String version;
  final String tags;
  final String author;
  final String organization;
  final String state;
  final String country;
  final String timeZone;
  final String building;
  final String notes;

  NewProjectFormData({
    required this.name,
    required this.version,
    required this.tags,
    required this.author,
    required this.organization,
    required this.state,
    required this.country,
    required this.timeZone,
    required this.building,
    required this.notes,
  });
}

class ProjectDialog extends StatefulWidget {
  final void Function(NewProjectFormData data) onSubmit;
  final NewProjectFormData? initialData;

  const ProjectDialog({
    super.key,
    required this.onSubmit,
    this.initialData,
  });

  bool get isEdit => initialData != null;

  @override
  State<ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<ProjectDialog> {
  final _formKey = GlobalKey<FormState>();

  bool showMoreDetails = false;

  final TextEditingController name = TextEditingController();
  final TextEditingController version = TextEditingController();
  final TextEditingController tags = TextEditingController();
  final TextEditingController author = TextEditingController();
  final TextEditingController organization = TextEditingController();
  final TextEditingController stateCtrl = TextEditingController();
  final TextEditingController country = TextEditingController();
  final TextEditingController timeZone = TextEditingController();
  final TextEditingController building = TextEditingController();
  final TextEditingController budget = TextEditingController();
  final TextEditingController goals = TextEditingController();
  final TextEditingController regional = TextEditingController();
  final TextEditingController notes = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.initialData != null) {
      name.text = widget.initialData!.name;
      version.text = widget.initialData!.version;
      tags.text = widget.initialData!.tags;
      author.text = widget.initialData!.author;
      organization.text = widget.initialData!.organization;
      stateCtrl.text = widget.initialData!.state;
      country.text = widget.initialData!.country;
      timeZone.text = widget.initialData!.timeZone;
      building.text = widget.initialData!.building;
      notes.text = widget.initialData!.notes;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: 1000,
          height: 820,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                blurRadius: 40,
                color: Colors.black.withOpacity(0.15),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isEdit ? "Edit Project" : "Create New Project",
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle("BASIC INFORMATION"),
                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(
                                child: _input("Project File Name", name),
                              ),
                              const SizedBox(width: 20),
                              Expanded(child: _input("File Version", version)),
                            ],
                          ),

                          const SizedBox(height: 20),
                          _input(
                            "Project Tags or Categories",
                            tags,
                            hint: "Add tags (comma separated)",
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(child: _input("Author Name", author)),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _input("Organization", organization),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          InkWell(
                            onTap: () {
                              setState(() {
                                showMoreDetails = !showMoreDetails;
                              });
                            },
                            child: Text(
                              showMoreDetails
                                  ? "Show Less Details"
                                  : "Add More Details",
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 300),
                            crossFadeState: showMoreDetails
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            firstChild: const SizedBox(),
                            secondChild: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionTitle("ORGANIZATION DETAILS"),
                                const SizedBox(height: 24),

                                Row(
                                  children: [
                                    Expanded(
                                      child: _input("Project State", stateCtrl),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: _input("Project Country", country),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),
                                _input("Project Time Zone", timeZone),
                                const SizedBox(height: 20),
                                _input("Primary Building Name", building),

                                const SizedBox(height: 30),
                              ],
                            ),
                          ),

                          _input(
                            "Notes",
                            notes,
                            maxLines: 4,
                            hint: "Add notes or comments",
                          ),

                          const SizedBox(height: 40),

                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  final formData = NewProjectFormData(
                                    name: name.text.trim(),
                                    version: version.text.trim(),
                                    tags: tags.text.trim(),
                                    author: author.text.trim(),
                                    organization: organization.text.trim(),
                                    state: stateCtrl.text.trim(),
                                    country: country.text.trim(),
                                    timeZone: timeZone.text.trim(),
                                    building: building.text.trim(),
                                    notes: notes.text.trim(),
                                  );

                                  widget.onSubmit(formData);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text("Continue"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _input(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
