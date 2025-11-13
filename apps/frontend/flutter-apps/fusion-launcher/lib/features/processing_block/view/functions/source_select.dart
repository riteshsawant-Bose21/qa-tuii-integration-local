import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../widgets/pb_radio.dart';
import '../widgets/pb_textfield.dart';
import 'widgets.dart';

class SourceSelectZoneControlPanel extends StatefulWidget {
  const SourceSelectZoneControlPanel({super.key});

  @override
  State<SourceSelectZoneControlPanel> createState() => _SourceSelectZoneControlPanelState();
}

class _SourceSelectZoneControlPanelState extends State<SourceSelectZoneControlPanel> {
  late List<String> musicList;

  @override
  void initState() {
    super.initState();
    // Dummy data
    musicList = List<String>.generate(20, (int index) => "Music_0$index");
  }

  void onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final String item = musicList.removeAt(oldIndex);
      musicList.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double controlScreenWidth = MediaQuery.sizeOf(context).width * 0.5;

    return Dialog(
      constraints: BoxConstraints(
        maxWidth: controlScreenWidth < 500 ? controlScreenWidth : 500,
        maxHeight: MediaQuery.sizeOf(context).height * 0.45,
      ),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        child: Stack(
          children: <Widget>[
            Container(
              color: Colors.black,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(height: 35),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Container(
                      color: Colors.white,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // LEFT COLUMN (Reorderable List)
                          Expanded(
                            child: Column(
                              children: <Widget>[
                                Container(
                                  height: 32,
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  color: const Color(0xFFF5F5F5),
                                  child: FusionAppText(
                                    text: "SOURCE SELECT",
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    spacing: 10,
                                    children: <Widget>[
                                      Expanded(
                                        flex: 2,
                                        child: Center(
                                          child: FusionAppText(
                                            text: "Channels",
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context).textTheme.labelSmall,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: FusionAppText(
                                            text: "Out",
                                            style: Theme.of(context).textTheme.labelSmall,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 🔥 DRAG-AND-DROP LIST
                                Expanded(
                                  child: ReorderableListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    physics: const ClampingScrollPhysics(),
                                    itemCount: musicList.length,
                                    onReorder: onReorder,
                                    proxyDecorator: (Widget child, int index, Animation<double> animation) {
                                      return Material(
                                        color: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        child: child,
                                      );
                                    },
                                    buildDefaultDragHandles: false,
                                    itemBuilder: (BuildContext context, int index) {
                                      final String musicName = musicList[index];
                                      return Container(
                                        key: ValueKey<String>(musicName),
                                        margin: const EdgeInsets.symmetric(vertical: 2),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: const Color(0xFFE5E5E5)),
                                          borderRadius: BorderRadius.circular(4),
                                          color: Colors.white,
                                        ),
                                        child: Row(
                                          spacing: 5,
                                          children: <Widget>[
                                            Flexible(
                                              child: Container(
                                                height: 24,
                                                margin: const EdgeInsets.all(4),
                                                alignment: Alignment.center,
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF5F5F5),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: FusionAppText(
                                                  text: musicName,
                                                  maxLine: 1,
                                                  style: Theme.of(context).textTheme.labelSmall,
                                                ),
                                              ),
                                            ),
                                            PBRadio(
                                              value: index % 2 == 0,
                                              size: const Size(24, 24),
                                              padding: const EdgeInsets.all(2),
                                              onChanged: (bool value) {},
                                            ),
                                            // 👇 Drag handle
                                            MouseRegion(
                                              cursor: SystemMouseCursors.grabbing,
                                              child: ReorderableDragStartListener(
                                                index: index,
                                                child: const Icon(
                                                  Icons.drag_indicator,
                                                  color: Colors.grey,
                                                  size: 14,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const VerticalDivider(width: 1, color: Colors.black12),

                          // RIGHT COLUMN (Static)
                          Expanded(
                            child: Column(
                              children: <Widget>[
                                Container(
                                  height: 32,
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  color: const Color(0xFFF5F5F5),
                                  child: FusionAppText(
                                    text: "ZONE VOLUME",
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                PBTextField(
                                  width: 72,
                                  height: 32,
                                  hintText: "0db ",
                                  borderRadius: 8,
                                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                                ),
                                const Expanded(
                                  child: SizedBox(
                                    width: 150,
                                    child: SliderAndMeterWidget(),
                                  ),
                                ),
                                const NeumorphicAudioToggleButton(
                                  isActive: false,
                                  width: 100,
                                  height: 35,
                                  borderRadius: 8,
                                  iconSize: 18,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // HEADER TITLE
            Positioned(
              left: 0,
              child: Container(
                height: 35,
                color: Colors.black,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  "ZONE CONTROL PANEL - SOURCE SELECT",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ),
            ),

            // CLOSE BUTTON
            Positioned(
              right: 0,
              child: Container(
                height: 35,
                color: Colors.black,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: Navigator.of(context).pop,
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
