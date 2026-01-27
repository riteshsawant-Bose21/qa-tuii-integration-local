import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class VIPConfigurationScreen extends StatefulWidget {
  final Function(String) onVerify;

  const VIPConfigurationScreen({
    super.key,
    required this.onVerify,
  });

  @override
  State<VIPConfigurationScreen> createState() => _VIPConfigurationScreenState();
}

class _VIPConfigurationScreenState extends State<VIPConfigurationScreen> {
  final TextEditingController _vipController = TextEditingController();
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _vipController.text = '192.168.0.100'; // Default value
  }

  @override
  void dispose() {
    _vipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Set a VIP address for Fusion hardware.',
              style: TextStyle(
                color: context.colorScheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Virtual IP address',
              style: TextStyle(
                color: context.colorScheme.textLabel,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _vipController,
              style: TextStyle(
                color: context.colorScheme.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: '192.168.0.100',
                hintStyle: TextStyle(
                  color: context.colorScheme.textPlaceholder,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: context.colorScheme.elevation2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: context.colorScheme.strokeLight,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: context.colorScheme.strokeLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: context.colorScheme.primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FusionNeumorphicButton(
                text: 'Verify and proceed',
                onTap: _verify,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _verify() {
    if (_vipController.text.isEmpty) {
      FusionToast.error(context, message: "Please enter a VIP address.");
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    widget.onVerify(_vipController.text);
  }
}
