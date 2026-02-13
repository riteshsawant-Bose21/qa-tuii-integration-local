import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NewProjectDialog extends StatefulWidget {
  const NewProjectDialog({super.key});

  @override
  State<NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<NewProjectDialog> {
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
                "Create New Project",
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

                          // =============================
                          // BASIC INFORMATION
                          // =============================

                          _sectionTitle("BASIC INFORMATION"),
                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(child: _input("Project File Name", name)),
                              const SizedBox(width: 20),
                              Expanded(child: _input("File Version", version)),
                            ],
                          ),

                          const SizedBox(height: 20),
                          _input(
                            "Project Tags or Categories",
                            tags,
                            hint: "Add tags or categories (separated by commas)",
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(child: _input("Author Name", author)),
                              const SizedBox(width: 20),
                              Expanded(child: _input("Organization", organization)),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // =============================
                          // ADD MORE DETAILS (Toggle)
                          // =============================

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

                          // =============================
                          // EXPANDED SECTIONS
                          // =============================

                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 300),
                            crossFadeState: showMoreDetails
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            firstChild: const SizedBox(),
                            secondChild: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                // ORGANIZATION DETAILS
                                const SizedBox(height: 10),
                                _sectionTitle("ORGANIZATION DETAILS"),
                                const SizedBox(height: 24),

                                _input("Organization Name", organization),
                                const SizedBox(height: 20),

                                Row(
                                  children: [
                                    Expanded(child: _input("Project State", stateCtrl)),
                                    const SizedBox(width: 20),
                                    Expanded(child: _input("Project Country", country)),
                                  ],
                                ),

                                const SizedBox(height: 20),
                                _input("Project Time Zone", timeZone),
                                const SizedBox(height: 20),
                                _input("Primary Building Name", building),

                                const SizedBox(height: 40),

                                // BUDGET
                                _sectionTitle("BUDGET & OBJECTIVES"),
                                const SizedBox(height: 24),

                                Row(
                                  children: [
                                    Expanded(child: _input("Target Budget", budget)),
                                    const SizedBox(width: 20),
                                    Expanded(child: _input("Currency", TextEditingController())),
                                  ],
                                ),

                                const SizedBox(height: 20),
                                _input("Project Goals", goals),

                                const SizedBox(height: 40),

                                // UNITS
                                _sectionTitle("UNITS & GLOBAL SETTINGS"),
                                const SizedBox(height: 24),

                                Row(
                                  children: [
                                    Expanded(child: _input("Measurement Units", TextEditingController())),
                                    const SizedBox(width: 20),
                                    Expanded(child: _input("Temperature", TextEditingController())),
                                  ],
                                ),

                                const SizedBox(height: 20),
                                _input("Regional Based Defaults", regional),

                                const SizedBox(height: 30),
                              ],
                            ),
                          ),

                          // =============================
                          // NOTES (Always visible)
                          // =============================

                          _input("Notes", notes,
                              maxLines: 4,
                              hint: "Add notes or comments"),

                          const SizedBox(height: 40),

                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text("Continue"),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward),
                                ],
                              ),
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
        Text(label,
            style: GoogleFonts.montserrat(
                fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Colors.black87, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
