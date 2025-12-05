class UserModel {
  final UserData? user;
  final UserAccount? account;
  final UserRole? role;
  final UserPermissions? permissions;

  UserModel({
    this.user,
    this.account,
    this.role,
    this.permissions,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      user: json['user'] != null ? UserData.fromJson(json['user']) : null,
      account: json['account'] != null ? UserAccount.fromJson(json['account']) : null,
      role: json['role'] != null ? UserRole.fromJson(json['role']) : null,
      permissions: json['permissions'] != null ? UserPermissions.fromJson(json['permissions']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user?.toJson(),
      'account': account?.toJson(),
      'role': role?.toJson(),
      'permissions': permissions?.toJson(),
    };
  }
}

class UserData {
  final String? id;
  final String? email;

  UserData({this.id, this.email});

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
    };
  }
}

class UserAccount {
  final String? id;
  final String? name;
  final String? description;
  final String? type;

  UserAccount({
    this.id,
    this.name,
    this.description,
    this.type,
  });

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
    };
  }
}

class UserRole {
  final int? id;
  final String? roleName;

  UserRole({this.id, this.roleName});

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      id: json['id'],
      roleName: json['role_name'], // Note the mapping from snake_case
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role_name': roleName,
    };
  }
}

class UserPermissions {
  final String? buildingCostEstimatorWidget;
  final String? buildingView;
  final String? commissioningView;
  final String? configurationView;
  final String? costEstimatorView;
  final String? projectArchive;
  final String? projectAssignUser;
  final String? projectCreate;
  final String? projectDelete;
  final String? projectGrantAccess;
  final String? projectLock;
  final String? projectRead;
  final String? projectRemoveUser;
  final String? projectStart;
  final String? projectUnarchive;
  final String? projectUnlock;
  final String? projectUnstar;
  final String? projectUpdate;
  final String? schematicView;

  UserPermissions({
    this.buildingCostEstimatorWidget,
    this.buildingView,
    this.commissioningView,
    this.configurationView,
    this.costEstimatorView,
    this.projectArchive,
    this.projectAssignUser,
    this.projectCreate,
    this.projectDelete,
    this.projectGrantAccess,
    this.projectLock,
    this.projectRead,
    this.projectRemoveUser,
    this.projectStart,
    this.projectUnarchive,
    this.projectUnlock,
    this.projectUnstar,
    this.projectUpdate,
    this.schematicView,
  });

  factory UserPermissions.fromJson(Map<String, dynamic> json) {
    return UserPermissions(
      buildingCostEstimatorWidget: json['building.cost_estimator_widget'],
      buildingView: json['building.view'],
      commissioningView: json['commissioning.view'],
      configurationView: json['configuration.view'],
      costEstimatorView: json['cost_estimator.view'],
      projectArchive: json['project.archive'],
      projectAssignUser: json['project.assign_user'],
      projectCreate: json['project.create'],
      projectDelete: json['project.delete'],
      projectGrantAccess: json['project.grant_access'],
      projectLock: json['project.lock'],
      projectRead: json['project.read'],
      projectRemoveUser: json['project.remove_user'],
      projectStart: json['project.start'],
      projectUnarchive: json['project.unarchive'],
      projectUnlock: json['project.unlock'],
      projectUnstar: json['project.unstar'],
      projectUpdate: json['project.update'],
      schematicView: json['schematic.view'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'building.cost_estimator_widget': buildingCostEstimatorWidget,
      'building.view': buildingView,
      'commissioning.view': commissioningView,
      'configuration.view': configurationView,
      'cost_estimator.view': costEstimatorView,
      'project.archive': projectArchive,
      'project.assign_user': projectAssignUser,
      'project.create': projectCreate,
      'project.delete': projectDelete,
      'project.grant_access': projectGrantAccess,
      'project.lock': projectLock,
      'project.read': projectRead,
      'project.remove_user': projectRemoveUser,
      'project.start': projectStart,
      'project.unarchive': projectUnarchive,
      'project.unlock': projectUnlock,
      'project.unstar': projectUnstar,
      'project.update': projectUpdate,
      'schematic.view': schematicView,
    };
  }
}
