class UserProfile {
  final PersonalInfo personalInfo;
  final Security security;
  final Address address;
  final String measurementUnit;
  final String currency;
  final String language;
  final String location;
  final Notifications notifications;

  UserProfile({
    required this.personalInfo,
    required this.security,
    required this.address,
    required this.measurementUnit,
    required this.currency,
    required this.language,
    required this.location,
    required this.notifications,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      personalInfo: PersonalInfo.fromJson(json['personalInfo']),
      security: Security.fromJson(json['security']),
      address: Address.fromJson(json['address']),
      measurementUnit: json['measurementUnit'],
      currency: json['currency'],
      language: json['language'],
      location: json['location'],
      notifications: Notifications.fromJson(json['notifications']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'personalInfo': personalInfo.toJson(),
      'security': security.toJson(),
      'address': address.toJson(),
      'measurementUnit': measurementUnit,
      'currency': currency,
      'language': language,
      'location': location,
      'notifications': notifications.toJson(),
    };
  }

  UserProfile copyWith({
    PersonalInfo? personalInfo,
    Security? security,
    Address? address,
    String? measurementUnit,
    String? currency,
    String? language,
    String? location,
    Notifications? notifications,
  }) {
    return UserProfile(
      personalInfo: personalInfo ?? this.personalInfo,
      security: security ?? this.security,
      address: address ?? this.address,
      measurementUnit: measurementUnit ?? this.measurementUnit,
      currency: currency ?? this.currency,
      language: language ?? this.language,
      location: location ?? this.location,
      notifications: notifications ?? this.notifications,
    );
  }
}

class PersonalInfo {
  final String name;
  final String organization;
  final String jobTitle;
  final String phone;

  PersonalInfo({
    required this.name,
    required this.organization,
    required this.jobTitle,
    required this.phone,
  });

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return PersonalInfo(
      name: json['name'],
      organization: json['organization'],
      jobTitle: json['jobTitle'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'organization': organization,
      'jobTitle': jobTitle,
      'phone': phone,
    };
  }
}

class Security {
  final String username;
  final String password;
  final bool isTwoFactorEnabled;
  final bool enableEmailNotifications;
  final bool enableSMSNotifications;

  Security({
    required this.username,
    required this.password,
    required this.isTwoFactorEnabled,
    required this.enableEmailNotifications,
    required this.enableSMSNotifications,
  });

  factory Security.fromJson(Map<String, dynamic> json) {
    return Security(
      username: json['username'],
      password: json['password'],
      isTwoFactorEnabled: json['isTwoFactorEnabled'],
      enableEmailNotifications: json['enableEmailNotifications'],
      enableSMSNotifications: json['enableSMSNotifications'],
    );
  }

  Security copyWith({
    String? username,
    String? password,
    bool? isTwoFactorEnabled,
    bool? enableEmailNotifications,
    bool? enableSMSNotifications,
  }) {
    return Security(
      username: username ?? this.username,
      password: password ?? this.password,
      isTwoFactorEnabled: isTwoFactorEnabled ?? this.isTwoFactorEnabled,
      enableEmailNotifications: enableEmailNotifications ?? this.enableEmailNotifications,
      enableSMSNotifications: enableSMSNotifications ?? this.enableSMSNotifications,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'username': username,
      'password': password,
      'isTwoFactorEnabled': isTwoFactorEnabled,
      'enableEmailNotifications': enableEmailNotifications,
      'enableSMSNotifications': enableSMSNotifications,
    };
  }
}

class Address {
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final String timezone;

  Address({
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    required this.timezone,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      addressLine1: json['addressLine1'],
      addressLine2: json['addressLine2'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zipCode'],
      country: json['country'],
      timezone: json['timezone'],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'timezone': timezone,
    };
  }
}

class Notifications {
  final bool productUpdates;
  final bool projectActivity;
  final bool trainingAndResources;

  Notifications({
    required this.productUpdates,
    required this.projectActivity,
    required this.trainingAndResources,
  });

  factory Notifications.fromJson(Map<String, dynamic> json) {
    return Notifications(
      productUpdates: json['productUpdates'],
      projectActivity: json['projectActivity'],
      trainingAndResources: json['trainingAndResources'],
    );
  }

  Notifications copyWith({
    bool? productUpdates,
    bool? projectActivity,
    bool? trainingAndResources,
  }) {
    return Notifications(
      productUpdates: productUpdates ?? this.productUpdates,
      projectActivity: projectActivity ?? this.projectActivity,
      trainingAndResources: trainingAndResources ?? this.trainingAndResources,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'productUpdates': productUpdates,
      'projectActivity': projectActivity,
      'trainingAndResources': trainingAndResources,
    };
  }
}
