import 'package:flutter/material.dart';
import 'package:fusion_app/features/passcode/widgets/number_button.dart';

class NumberPad extends StatelessWidget {
  final Function(String) onNumber;
  final VoidCallback onDelete;
  final VoidCallback onSubmit;

  const NumberPad({
    required this.onNumber,
    required this.onDelete,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final numbers = [
      "1","2","3",
      "4","5","6",
      "7","8","9",
    ];

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          /// Numbers
          for (int i = 0; i < numbers.length; i += 3)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: numbers
                  .sublist(i, i + 3)
                  .map((n) => NumberButton(
                label: n,
                onTap: () => onNumber(n),
              ))
                  .toList(),
            ),


          /// Bottom row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              NumberButton(
                icon: Icons.backspace_outlined,
                onTap: onDelete,
              ),

              NumberButton(
                label: "0",
                onTap: () => onNumber("0"),
              ),

              NumberButton(
                icon: Icons.keyboard_return,
                onTap: onSubmit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}