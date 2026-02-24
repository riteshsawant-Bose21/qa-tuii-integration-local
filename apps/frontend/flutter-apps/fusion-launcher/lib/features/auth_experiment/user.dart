import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/material.dart';

class UserWidget extends StatelessWidget {
  final UserProfile? user;

  const UserWidget({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    final Uri? pictureUrl = user?.pictureUrl;
    // id, name, email, email verified, updated_at
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (pictureUrl != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: CircleAvatar(
              radius: 56,
              child: ClipOval(child: Image.network(pictureUrl.toString())),
            ),
          ),
        Card(
          child: Column(
            children: <Widget>[
              UserEntryWidget(propertyName: 'Id', propertyValue: user?.sub),
              UserEntryWidget(propertyName: 'Name', propertyValue: user?.name),
              UserEntryWidget(
                propertyName: 'Email',
                propertyValue: user?.email,
              ),
              UserEntryWidget(
                propertyName: 'Email Verified?',
                propertyValue: user?.isEmailVerified.toString(),
              ),
              UserEntryWidget(
                propertyName: 'Updated at',
                propertyValue: user?.updatedAt?.toIso8601String(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class UserEntryWidget extends StatelessWidget {
  final String propertyName;
  final String? propertyValue;

  const UserEntryWidget({
    required this.propertyName,
    required this.propertyValue,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[Text(propertyName), Text(propertyValue ?? '')],
      ),
    );
  }
}
