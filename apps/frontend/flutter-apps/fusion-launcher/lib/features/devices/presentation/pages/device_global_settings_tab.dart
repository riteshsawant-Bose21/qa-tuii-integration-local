import 'package:flutter/material.dart';

class GlobalDeviceSettingsTab extends StatefulWidget {
  const GlobalDeviceSettingsTab({super.key});

  @override
  State<GlobalDeviceSettingsTab> createState() => _GlobalDeviceSettingsTabState();
}

class _GlobalDeviceSettingsTabState extends State<GlobalDeviceSettingsTab> {
  final Map<String, GlobalKey> _sectionKeys = <String, GlobalKey<State<StatefulWidget>>>{
    "Network": GlobalKey(),
    "Timezone": GlobalKey(),
    "Wifi": GlobalKey(),
    "Bluetooth": GlobalKey(),
    "Security": GlobalKey(),
    "AES70": GlobalKey(),
  };

  String _selectedSection = "Network";

  // Mock controllers
  final TextEditingController _ipCtrl = TextEditingController(text: "192.168.0.111");
  final TextEditingController _leaderCtrl = TextEditingController(text: "Fusion mini 6");
  final TextEditingController _ntpCtrl = TextEditingController(text: "com.server.time.org");
  final TextEditingController _syncCtrl = TextEditingController(text: "1 secs");
  final TextEditingController _announceCtrl = TextEditingController(text: "1 secs");
  final TextEditingController _ssidCtrl = TextEditingController(text: "NamithGym");
  final TextEditingController _passCtrl = TextEditingController(text: "123456");

  void _scrollToSection(String key) {
    setState(() => _selectedSection = key);
    final BuildContext? context = _sectionKeys[key]?.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgBlack = Color(0xFF0D0D0D); // Very dark background
    const Color sidebarBorderColor = Color(0xFF1F1F1F);

    return Container(
      color: bgBlack,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // ---------------------------
          // LEFT SIDEBAR
          // ---------------------------
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.only(top: 24, right: 12),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: sidebarBorderColor)),
              ),
              child: ListView(
                children: <Widget>[
                  _buildSidebarItem("Network & IP", Icons.settings_ethernet, "Network"),
                  _buildSidebarItem("Timezone", Icons.access_time, "Timezone"),
                  _buildSidebarItem("Wifi", Icons.wifi, "Wifi"),
                  _buildSidebarItem("Bluetooth", Icons.bluetooth, "Bluetooth"),
                  _buildSidebarItem("Security", Icons.lock_outline, "Security"),
                  _buildSidebarItem("AES 70", Icons.settings_input_component, "AES70"),
                ],
              ),
            ),
          ),

          // ---------------------------
          // RIGHT CONTENT FORM
          // ---------------------------
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // --- SECTION 1: LEADER INFO ---
                  _buildSectionContainer(
                    key: _sectionKeys["Network"]!,
                    title: "LEADER INFO",
                    child: Column(
                      children: <Widget>[
                        _buildRowField("Virtual IP (IPv4)", _buildDeepNeumorphicField(_ipCtrl)),
                        const SizedBox(height: 16),
                        _buildRowField("Current Leader", _buildDeepNeumorphicField(_leaderCtrl)),
                        const SizedBox(height: 16),
                        _buildRowField(
                          "Logging",
                          Row(
                            children: <Widget>[
                              _buildToggleLabel("Error", true),
                              const SizedBox(width: 16),
                              _buildToggleLabel("Warning", true),
                              const SizedBox(width: 16),
                              _buildToggleLabel("Info", true),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // --- SECTION 2: TIMEZONE ---
                  _buildSectionContainer(
                    key: _sectionKeys["Timezone"]!,
                    title: "TIMEZONE & CLOCKS",
                    child: Column(
                      children: <Widget>[
                        _buildRowField(
                          "TimeZone",
                          Row(
                            children: <Widget>[
                              _buildDeepNeumorphicDropdown("UTC+ 5:30 - Chennai, India"),
                              const SizedBox(width: 16),
                              _buildToggleLabel("Daylight saving", true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildRowField(
                          "NTP Server",
                          Row(
                            children: <Widget>[
                              _buildRoundedToggle(true),
                              const SizedBox(width: 10),
                              const Text("NTP", style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(left: 150.0),
                          child: Row(
                            children: <Widget>[
                              _buildDeepNeumorphicField(_ntpCtrl),
                              const SizedBox(width: 12),
                              _buildButton("Test"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildRowField("HeartBeat", _buildDeepNeumorphicDropdown("Every 60 seconds")),

                        const SizedBox(height: 24),
                        // PTP SUB-SECTION
                        _buildSubSectionCard(
                          "PTP",
                          Column(
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  _buildLabeledField("Mode", _buildDeepNeumorphicDropdown("Automatic")),
                                  const SizedBox(width: 20),
                                  _buildLabeledField("Sync Int.", _buildDeepNeumorphicField(_syncCtrl)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: <Widget>[
                                  _buildLabeledField("Priority 1", _buildDeepNeumorphicField(TextEditingController(text: "128"))),
                                  const SizedBox(width: 20),
                                  _buildLabeledField("Announce", _buildDeepNeumorphicField(_announceCtrl)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // --- SECTION 3: WIFI ---
                  _buildSectionContainer(
                    key: _sectionKeys["Wifi"]!,
                    title: "WIFI",
                    child: _buildSubSectionCard(
                      null,
                      Column(
                        children: <Widget>[
                          _buildRowField("SSID", _buildDeepNeumorphicField(_ssidCtrl)),
                          const SizedBox(height: 16),
                          _buildRowField("Security", _buildDeepNeumorphicDropdown("WPA2/WPA3 Personal")),
                          const SizedBox(height: 16),
                          _buildRowField("Password", _buildDeepNeumorphicField(_passCtrl, isObscure: true)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // --- SECTION 4: BLUETOOTH ---
                  _buildSectionContainer(
                    key: _sectionKeys["Bluetooth"]!,
                    title: "BLUETOOTH",
                    child: _buildSubSectionCard(
                      null,
                      Column(
                        children: <Widget>[
                          _buildRowField("", _buildToggleLabel("Numeric Comparison", true)),
                          const SizedBox(height: 16),
                          _buildRowField("PassKey", _buildDeepNeumorphicField(TextEditingController(text: "676767"))),
                          const SizedBox(height: 16),
                          _buildRowField("Confirm", _buildDeepNeumorphicField(TextEditingController(text: "******"), isObscure: true)),
                          const SizedBox(height: 16),
                          Row(
                            children: <Widget>[
                              Checkbox(
                                value: true,
                                onChanged: (bool? v) {},
                                activeColor: const Color(0xFF333333),
                                checkColor: Colors.grey,
                                side: const BorderSide(color: Colors.grey, width: 1),
                              ),
                              const Text("Turn off Bluetooth on connection.", style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  //   CUSTOM NEUMORPHIC WIDGETS (Matching Reference)
  // --------------------------------------------------------------------------

  // 1. DEEP NEUMORPHIC TEXT FIELD
  Widget _buildDeepNeumorphicField(TextEditingController controller, {bool isObscure = false}) {
    return Container(
      height: 35, // Slightly taller to allow rounded corners to look correct (pill shape)
      width: 0.2 * MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: const Color(0xFF121212), // Deep dark base
        borderRadius: BorderRadius.circular(12), // High radius for pill shape
        boxShadow: <BoxShadow>[
          // The "Pressed In" Shadow (Top Left, Dark)
          BoxShadow(
            color: Colors.black.withOpacity(1.0),
            offset: const Offset(4, 4),
            blurRadius: 8,
            spreadRadius: 0,
            blurStyle: BlurStyle.inner, // Inset shadow
          ),
          // The "Highlight" (Bottom Right, Light)
          BoxShadow(
            color: Colors.white.withOpacity(0.06),
            offset: const Offset(-2, -2),
            blurRadius: 4,
            spreadRadius: 0,
            blurStyle: BlurStyle.inner, // Inset highlight
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13, fontWeight: FontWeight.w400),
        cursorColor: Colors.green,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Centered text
          border: InputBorder.none,
        ),
      ),
    );
  }

  // 2. DEEP NEUMORPHIC DROPDOWN
  Widget _buildDeepNeumorphicDropdown(String value) {
    return Container(
      height: 35,
      width: 0.2 * MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12), // Match text field radius
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(1.0),
            offset: const Offset(4, 4),
            blurRadius: 8,
            blurStyle: BlurStyle.inner,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.06),
            offset: const Offset(-2, -2),
            blurRadius: 4,
            blurStyle: BlurStyle.inner,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(value, style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
          // Thin custom chevron
          const Icon(Icons.keyboard_arrow_down, color: Color(0xFF666666), size: 18),
        ],
      ),
    );
  }

  // 3. ROUNDED TOGGLE
  Widget _buildRoundedToggle(bool value) {
    return Container(
      width: 28,
      height: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4), // Rectangular with rounded corners
        color: value ? const Color(0xFF435848) : const Color(0xFF222222),
      ),
      padding: const EdgeInsets.all(2),
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: value ? const Color(0xFFE0E0E0) : const Color(0xFF555555),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  //   LAYOUT HELPERS
  // --------------------------------------------------------------------------

  Widget _buildSidebarItem(String title, IconData icon, String key) {
    final bool isSelected = _selectedSection == key;
    return InkWell(
      onTap: () => _scrollToSection(key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: isSelected ? const Border(left: BorderSide(color: Colors.white, width: 2)) : null,
          color: isSelected ? const Color(0xFF1A1A1A) : Colors.transparent,
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContainer({required GlobalKey key, required String title, required Widget child}) {
    return Container(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(color: Color(0xFF666666), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSubSectionCard(String? title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Text(title, style: const TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildRowField(String label, Widget field) {
    return Row(
      children: <Widget>[
        if (label.isNotEmpty) SizedBox(width: 150, child: Text(label, style: const TextStyle(color: Color(0xFFC0C0C0), fontSize: 12))),
        field,
      ],
    );
  }

  Widget _buildLabeledField(String label, Widget field) {
    return Row(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Text(label, style: const TextStyle(color: Color(0xFFC0C0C0), fontSize: 12)),
        ),
        field,
      ],
    );
  }

  Widget _buildToggleLabel(String label, bool value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildRoundedToggle(value),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildButton(String text) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
    );
  }
}
