part of '../equipment_location_dialog.dart';

class _EqlSystemRequirementSection extends StatelessWidget {
  const _EqlSystemRequirementSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: FusionAppText(
            text: "SYSTEM REQUIREMENTS",
            style: context.textTheme.bodyMedium?.copyWith(),
          ),
        ),
        const SizedBox(height: 16),
        const Divider(thickness: 0.5, height: 0),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FusionAppText(
                text: "Audio",
                style: context.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "Inputs",
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        for (final (String, String) input in <(String, String)>[
                          ("Mic/Line", "02"),
                          ("RCA (Stereo)", "0"),
                          ("USB", "0"),
                          ("AES67", "0"),
                          ("HDMI", "0"),
                        ])
                          _SrRow(title: input.$1, value: input.$2, baseValue: input.$2),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "Outputs",
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        for (final (String, String) input in <(String, String)>[
                          ("Analog", "02"),
                          ("AES67", "0"),
                        ])
                          _SrRow(title: input.$1, value: input.$2, baseValue: input.$2),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(thickness: 0.5, height: 0),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FusionAppText(
                text: "Control",
                style: context.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        for (final (String, String) input in <(String, String)>[
                          ("Inputs", "02"),
                          ("Outputs", "0"),
                        ])
                          _SrRow(title: input.$1, value: input.$2, baseValue: input.$2),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(thickness: 0.5, height: 0),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FusionAppText(
                text: "Amplification",
                style: context.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        for (final (String, String) input in <(String, String)>[
                          ("Reception", "200W"),
                          ("Gym Cardio", "50W"),
                          ("Gym Weights", "80W"),
                          ("Studio Gold", "100W"),
                          ("Studio Platinum", "100W"),
                        ])
                          Row(
                            children: <Widget>[
                              Expanded(
                                // flex: 2,
                                child: FusionAppText(
                                  text: input.$1,
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: FusionAppText(
                                  text: "Hi-Z",
                                  textAlign: TextAlign.right,
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: FusionAppText(
                                  text: input.$2,
                                  textAlign: TextAlign.right,
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: FusionAppText(
                                  text: input.$2,
                                  textAlign: TextAlign.right,
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: context.colorScheme.primaryBlack,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SrRow extends StatelessWidget {
  final String title;
  final String value;
  final String baseValue;
  const _SrRow({
    super.key,
    required this.title,
    required this.value,
    required this.baseValue,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 10,
          child: FusionAppText(
            text: title,
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
        ),
        SizedBox(
          width: 20,
          child: FusionAppText(
            text: value,
            textAlign: TextAlign.right,
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
        ),
        SizedBox(
          width: 20,
          child: FusionAppText(
            text: baseValue,
            textAlign: TextAlign.right,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.primaryBlack,

              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
