import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter, TextInputFormatter;
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

class SchematicProperties extends StatefulWidget {
  const SchematicProperties({super.key});

  @override
  SchematicPropertiesState createState() => SchematicPropertiesState();
}

class SchematicPropertiesState extends State<SchematicProperties> {
  final TextEditingController speakerQtyController = TextEditingController(text: "1"); // default value 1

  int get speakerQty => int.tryParse(speakerQtyController.text) ?? 1;
  void speakerQtyModify(int value, bool increment) {
    setState(() {
      int newValue = increment ? speakerQty + 1 : speakerQty - 1;
      if (newValue < 1) newValue = 1; // prevent negative values and zero
      speakerQtyController.text = newValue.toString();
    });
  }

  final ExpansibleController basicsViewMoreExpansibleController = ExpansibleController();

  String impedance = 'Auto';
  String tapSettings = 'Tap 1';

  @override
  void dispose() {
    speakerQtyController.dispose();
    basicsViewMoreExpansibleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 16, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: <Widget>[
          const SectionHeader(title: 'Circuits'),

          Row(
            spacing: 3,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: FusionAppText(
                  text: 'Model',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: Row(
                  children: <Widget>[
                    Image.asset("assets/images/speakers/designmax_dm8se.png", width: 32, height: 32),
                    const SizedBox(width: 8),

                    Expanded(
                      child: FusionAppText(
                        text: 'DBMS16',
                        maxLine: 1,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Row(
            spacing: 3,
            children: <Widget>[
              Expanded(
                child: FusionAppText(
                  text: 'Speaker Qty',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),

              Expanded(
                child: Row(
                  spacing: 3,
                  children: <Widget>[
                    GestureDetector(
                      child: const Icon(
                        Icons.remove,
                        size: 17,
                      ),
                      onTap: () => speakerQtyModify(speakerQty, false),
                    ),
                    Flexible(
                      child: Container(
                        width: 36,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.white,
                        ),
                        child: TextField(
                          controller: speakerQtyController,
                          keyboardType: TextInputType.number,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          onChanged: (String value) {
                            final int modifiedQty = int.tryParse(value) ?? 0;
                            if (modifiedQty == 0) speakerQtyController.text = "1";
                          },
                          style: Theme.of(context).textTheme.bodySmall,
                          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration.collapsed(
                            hintText: '0',
                          ),
                        ),
                      ),
                    ),

                    GestureDetector(
                      child: const Icon(
                        Icons.add,
                        size: 17,
                      ),
                      onTap: () => speakerQtyModify(speakerQty, true),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Row(
            spacing: 3,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: FusionAppText(
                  text: 'Price',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: FusionAppText(
                  text: '\$100',
                  maxLine: 1,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),

          Expansible(
            controller: basicsViewMoreExpansibleController,
            headerBuilder: (BuildContext context, Animation<double> animation) {
              final bool isExpanded = basicsViewMoreExpansibleController.isExpanded;
              return GestureDetector(
                onTap: () {
                  if (basicsViewMoreExpansibleController.isExpanded) {
                    basicsViewMoreExpansibleController.collapse();
                  } else {
                    basicsViewMoreExpansibleController.expand();
                  }
                },
                child: FusionAppText(
                  text: isExpanded ? 'view less' : 'view more',
                  maxLine: 1,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF186E79)),
                ),
              );
            },
            expansibleBuilder: (BuildContext context, Widget header, Widget body, Animation<double> animation) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1.0,
                    child: body,
                  ),
                  header,
                ],
              );
            },
            bodyBuilder: (BuildContext context, Animation<double> animation) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ...List<Widget>.generate(3, (int index) {
                    return Row(
                      spacing: 3,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: FusionAppText(
                            text: 'Model',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: <Widget>[
                              Image.asset("assets/images/speakers/designmax_dm8se.png", width: 32, height: 32),
                              const SizedBox(width: 8),

                              Expanded(
                                child: FusionAppText(
                                  text: 'DBMS16',
                                  maxLine: 1,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              );
            },
          ),

          const SizedBox(height: 5),

          const SectionHeader(title: 'Settings'),

          Row(
            spacing: 3,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: FusionAppText(
                  text: 'Impedance',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: DropdownButton<String>(
                  value: impedance,
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  onChanged: (String? v) => setState(() => impedance = v ?? impedance),
                  isExpanded: true,
                  items:
                      <String>['Auto', 'High', 'Low'].map(
                        (String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: FusionAppText(text: value, style: Theme.of(context).textTheme.bodySmall),
                          );
                        },
                      ).toList(),
                ),
              ),
            ],
          ),

          Row(
            spacing: 3,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: FusionAppText(
                  text: 'Tap Settings',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: DropdownButton<String>(
                  value: tapSettings,
                  underline: const SizedBox.shrink(),
                  padding: const EdgeInsets.only(),
                  isExpanded: true,
                  isDense: true,
                  onChanged: (String? v) => setState(() => tapSettings = v ?? tapSettings),
                  items:
                      <String>['Tap 1', 'Tap 2', 'Tap 3'].map(
                        (String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: FusionAppText(text: value, style: Theme.of(context).textTheme.bodySmall),
                          );
                        },
                      ).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),
          const SectionHeader(title: 'Zones & Listening Areas'),

          Row(
            spacing: 3,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: FusionAppText(
                  text: 'Zone',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: Row(
                  spacing: 8,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF7F6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FusionAppText(
                        text: 'Z1',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Expanded(
                      child: FusionAppText(
                        text: 'Reception',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return FusionAppText(
      text: title,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black38),
    );
  }
}
