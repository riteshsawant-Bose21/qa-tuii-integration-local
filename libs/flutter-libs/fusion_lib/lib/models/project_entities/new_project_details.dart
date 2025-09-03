class NewProjectDetails {
  final String name;

  NewProjectDetails({required this.name});

  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}
