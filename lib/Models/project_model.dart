import 'package:flutter/foundation.dart';
import '../database_helper.dart';

/// Represents a project.
class Project {
  final int id;
  final String client;
  final String projectName;
  final String tech;
  final String createDate;

  /// Constructs a [Project] instance.
  ///
  /// The [id], [client], [projectName], [tech], and [createDate] parameters are required.
  Project({required this.id, required this.client, required this.projectName, required this.tech, required this.createDate});

  /// Converts the [Project] instance to a map.
  ///
  /// Returns a map representation of the [Project] instance.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client': client,
      'projectName': projectName,
      'tech': tech,
      'createDate': createDate,
    };
  }

  /// Constructs a [Project] instance from a map.
  ///
  /// The [map] parameter is a map representation of a [Project] instance.
  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      client: map['client'],
      projectName: map['projectName'],
      tech: map['tech'],
      createDate: map['createDate'],
    );
  }

  /// Gets the full project name.
  ///
  /// Returns a string representing the full project name in the format: "client: projectName".
  String get fullProjectName => '$client: $projectName';

  @override
  String toString() {
    return 'Project{id: $id, client: $client, project: $projectName}';
  }
}

/// A model class representing a project.
///
/// This class contains properties and methods related to a project.
/// It provides getters and setters for accessing and modifying the project's properties.
/// The properties include the project ID, client name, project name, technology used, creation date, and a list of projects.
/// The class also includes a method to load projects from a database and fetch all project names.
class ProjectModel with ChangeNotifier {
  int _projectID = 0;
  String _client = '';
  String _projectName = 'Select A Project';
  String _tech = '';
  String _createDate = '';
  List<Project> _projects = [];
  Set<int> _loadedProjectIDs = {};

  // Getters
  int get id => _projectID;
  String get client => _client;
  String get projectName => _projectName;
  String get tech => _tech;
  String get createDate => _createDate;
  List<Project> get projects => _projects;
  Set<int> get loadedProjectIDs => _loadedProjectIDs;

  String get fullProjectName => '$_client: $_projectName';

  // Setters
  set projectID(int value) {
    _projectID = value;
    notifyListeners();
  }

  set client(String value) {
    _client = value;
    notifyListeners();
  }

  set projectName(String value) {
    _projectName = value;
    notifyListeners();
  }

  set tech(String value) {
    _tech = value;
    notifyListeners();
  }

  set createDate(String value) {
    _createDate = value;
    notifyListeners();
  }

  set projects(List<Project> value) {
    _projects = value;
    notifyListeners();
  }

  Future<void> loadProjects() async {
    try {
      _projects = await fetchAllProjectsSQL();
      loadedProjectIDs.addAll(_projects.map((project) => project.id));
    } catch (e) {
      if (kDebugMode) {
        print("Error loading projects: $e");
      }
      // Handle the error as needed
    }
  }

  Future<List<Project>> fetchAllProjectsSQL() async {
    try {
      List<Project> projects = await DatabaseHelper.instance.fetchProjectNames();
      return projects;
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching all projects: $e");
      }
      // Handle the error as needed
      return [];
    }
  }
}
