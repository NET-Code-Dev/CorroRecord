/*
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'package:asset_inspections/Models/camera_model.dart';
import 'package:asset_inspections/Models/project_model.dart';
import 'package:asset_inspections/Pokit_Multimeter/Providers/bluetooth_manager_notifier.dart';
import 'package:asset_inspections/Pokit_Multimeter/Screens/multimeter_ui.dart';
import 'package:asset_inspections/Rectifier/rec_changeNotifier.dart';
import 'package:asset_inspections/Test_Station/ts_notifier.dart';
import 'package:asset_inspections/Util/main_settings.dart';
import 'package:asset_inspections/database_helper.dart';
*/

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'package:asset_inspections/Models/camera_model.dart';
import 'package:asset_inspections/main.dart';

import 'Models/project_model.dart';
import 'Pokit_Multimeter/Providers/bluetooth_manager_notifier.dart';
import 'Pokit_Multimeter/Screens/multimeter_ui.dart';
import 'Rectifier/rec_changeNotifier.dart';
import 'Test_Station/ts_notifier.dart';
import 'Util/main_settings.dart';
import 'database_helper.dart';

class MainPageUI extends State<MainPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ProjectModel projectModel = ProjectModel();

  late Future<bool> projectsExist;
  Project? selectedProjectName;
  List<Project> projectNames = [];
  final bluetoothManager = BluetoothManager.instance;
  String? currentName;
  bool _isInitialLoad = true;

  /// Loads the project names from the database and updates the UI.
  ///
  /// This method checks if there are any projects available by calling the `hasProjects` method.
  /// It then fetches the project names from the database using the [fetchProjectNames] method of the `DatabaseHelper` class.
  /// The fetched project names are assigned to the 'projectNames` variable.
  /// Finally, it triggers a UI update by calling the `setState` method if the widget is still mounted.
  Future<void> loadProjectNames() async {
    await hasProjects();

    final dbHelper = DatabaseHelper.instance;

    projectNames = await dbHelper.fetchProjectNames();

    if (mounted) {
      setState(() {});
    }
  }

  /// Updates the value of [projectsExist] by calling the [hasProjects] method.
  /// After updating the value, it triggers a rebuild of the UI by calling [setState].
  Future<void> updateProjectsExist() async {
    projectsExist = hasProjects();
    setState(() {}); // Trigger a rebuild
    if (kDebugMode) {
      print('updateProjectsExist called');
    }
  }

  /// Checks if there are any projects available.
  /// Returns a [Future] that completes with a [bool] indicating whether there are any projects or not.
  /// The check is performed by fetching all rows from the projectNames table in the database.
  /// Returns `true` if there are projects, `false` otherwise.
  Future<bool> hasProjects() async {
    final dbHelper = DatabaseHelper.instance;
    final projects = await dbHelper.fetchProjectNames();
    return projects.isNotEmpty;
  }

  /// Handles the action based on the selected choice.
  ///
  /// If the choice is 'Multimeter', it navigates to the [MultimeterUIPage].
  /// If the choice is 'Settings', it navigates to the [MainSettings] page.
  ///
  /// Parameters:
  /// - [choice]: The selected choice.
  ///
  /// Returns: void.
  void _choiceAction(String choice) {
    if (choice == 'Multimeter') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MultimeterUIPage()),
      );
    } else if (choice == 'Settings') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainSettings()),
      );
    } else if (choice == 'Copy DB to Downloads') {
      DatabaseHelper.instance.copyDatabaseToDownloads();
    }
  }

  @override
  void initState() {
    super.initState();

    if (mounted) {
      projectsExist = hasProjects();
      loadProjectNames();
    }
  }

  /// Loads project data from the database.
  ///
  /// This method is responsible for loading rectifiers and test stations
  /// associated with a specific project from the database. It takes a [projectID]
  /// as a parameter and uses it to fetch the corresponding data from the database.
  /// The loaded rectifiers are stored in the [RectifierNotifier] and the loaded
  /// test stations are stored in the [TSNotifier].
  Future<void> _loadProjectData(int projectID) async {
    var tsNotifier = Provider.of<TSNotifier>(context, listen: false);
    var rectifierNotifier = Provider.of<RectifierNotifier>(context, listen: false);

    rectifierNotifier.loadRectifiersFromDatabase(projectID, 'serviceTag');
    tsNotifier.loadTestStationsFromDatabase(projectID);
    if (kDebugMode) {
      print('_loadProjectData called');
    }
  }

  /// Handles the selection of a project.
  ///
  /// Updates the current project name, sets the selected project,
  /// and ensures that the initial load flag is set to false.
  /// Finally, it loads the data for the selected project.
  ///
  /// Parameters:
  /// - [selectedProject]: The project that was selected.
  void onProjectSelected(Project selectedProject) {
    if (mounted) {
      setState(() {
        currentName = selectedProject.projectName;
        selectedProjectName = selectedProject;
        _isInitialLoad = false; // Ensure _isInitialLoad is set to false
      });
      if (kDebugMode) {
        print('onProjectSelected called');
      }
      _loadProjectData(selectedProject.id); // Uncommented causes Test Stations to load twice
    }
  }

  /// Selects a project and updates the state with the selected project name.
  /// If the [latestProject] is not null, the [selectedProjectName] is updated with the details of the latest project.
  /// Then, it calls the [_loadProjectData] method to load the project data.
  /// If the [latestProject] is null and the app is running in debug mode, it prints a debug message indicating that the latest project is null.
  ///
  /// Parameters:
  /// - [latestProject]: The latest project to be selected.
  ///
  /// Returns: A [Future] that completes when the project selection and data loading is done.
  // ignore: unused_element
  Future<void> _selectProject(Project? latestProject) async {
    if (latestProject != null) {
      setState(() {
        selectedProjectName = Project(
          id: latestProject.id,
          client: latestProject.client,
          projectName: latestProject.projectName,
          tech: latestProject.tech,
          createDate: latestProject.createDate,
        );
      });

      await _loadProjectData(latestProject.id);
    } else {
      if (kDebugMode) {
        print('Latest project is null');
      }
    }
  }

  /// Saves the selected project ID to shared preferences.
  ///
  /// This method takes an [int] projectID as a parameter and saves it to the shared preferences.
  /// It uses the [SharedPreferences.getInstance] method to get an instance of shared preferences,
  /// and then calls the [setInt] method to save the project ID with the key 'selectedProjectID'.
  Future<void> _saveSelectedProjectToPrefs(int projectID) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedProjectID', projectID);
  }

  /// Shows a dialog to add a new project.
  ///
  /// This method displays an [AlertDialog] with text fields for the client, project name, and technician.
  /// The user can enter the details and click the "OK" button to create a new project.
  /// The method performs validation on the input fields and shows error dialogs if any field is empty or if the project name is invalid.
  /// If the input is valid, the method creates a new project, inserts it into the database, and updates the UI accordingly.
  /// If any error occurs during the project creation process, an error message is displayed.
  void showAddProjectDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          final TextEditingController clientController = TextEditingController();
          final TextEditingController projectNameController = TextEditingController();
          final TextEditingController techController = TextEditingController();
          TextEditingController();

          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              bool isValidClient = true;
              bool isValidProjectName = true;
              bool isValidTech = true;

              return StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  // Function to check the validation state
                  void checkValidationState() {
                    setState(() {
                      isValidClient = clientController.text.isNotEmpty;
                      isValidProjectName = projectNameController.text.isNotEmpty;
                      isValidTech = techController.text.isNotEmpty;
                    });
                  }

                  return AlertDialog(
                    title: const Center(child: Text('Enter New Project Details')),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
// Client TextField
                        TextField(
                          controller: clientController,
                          decoration: InputDecoration(
                            hintText: "Client",
                            errorText: isValidClient ? null : 'Client cannot be empty',
                          ),
                          onChanged: (value) => checkValidationState(),
                        ),
                        SizedBox(height: 20.h),

// ProjectName TextField
                        TextField(
                          controller: projectNameController,
                          decoration: InputDecoration(
                            hintText: "Project Name",
                            errorText: isValidProjectName ? null : 'Project name cannot be empty',
                          ),
                          onChanged: (value) => checkValidationState(),
                        ),
                        SizedBox(height: 20.h),

// Tech TextField
                        TextField(
                          controller: techController,
                          decoration: InputDecoration(
                            hintText: "Technician",
                            errorText: isValidTech ? null : 'Technician cannot be empty',
                          ),
                          onChanged: (value) => checkValidationState(),
                        ),
                      ],
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('OK'),
                        onPressed: () async {
                          final client = clientController.text.trim();
                          final projectName = projectNameController.text.trim();
                          final tech = techController.text.trim();
                          final createDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

// First, check if any of the fields are empty
                          if (client.isEmpty || projectName.isEmpty || tech.isEmpty) {
                            if (kDebugMode) {
                              print('One or more fields are empty, showing error dialog');
                            }
// Show the error dialog if any field is empty
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Error'),
                                content: const Text('All fields are required. Please fill in all the information.'),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('OK'),
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop(); // Close the error dialog
                                    },
                                  ),
                                ],
                              ),
                            );
                            return; // Stop further execution
                          }

// Now that we know fields are not empty, we can validate the project name
                          final isValidName = RegExp(r'^[a-zA-Z0-9_ ]+$').hasMatch(projectName);
                          if (!isValidName) {
// Show an error dialog for invalid project name
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Invalid Project Name'),
                                content: const Text('The project name is not valid. It should only contain alphanumeric characters and underscores.'),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('OK'),
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop(); // Close the error dialog
                                    },
                                  ),
                                ],
                              ),
                            );
                            return;

// Stop further execution
                          } else {
// If the project name is valid, create a new project
                            final projectModel = Provider.of<ProjectModel>(context, listen: false);
                            projectModel.projectID = 0;
                            projectModel.client = client;
                            projectModel.projectName = projectName;
                            projectModel.tech = tech;
                            projectModel.createDate = createDate;

                            final dbHelper = DatabaseHelper.instance;

                            try {
// Create the tables for the new project
                              await dbHelper.createTablesForProject();
                              await dbHelper.createTableForCameraSettings();
                              await dbHelper.insertCameraSettings(CameraSettings(
                                isMapOverlayVisible: false,
                                mapPosition: MapPosition.bottomLeft,
                                dataPosition: MapPosition.bottomLeft,
                                mapType: 'normal',
                                mapOpacity: 1.0,
                                mapSize: 150,
                                mapScale: 16.0,
                                isDataOverlayVisible: false,
                                selectedFontStyle: 'normal',
                                selectedFontColor: 'black',
                                selectedFontSize: 12.0,
                                selectedDateFormat: 'yyyy-MM-dd HH:mm:ss',
                                selectedLocationFormat: 'Street Address, City, State, Zip',
                              ));

                              // Create a map with all the required fields
                              final projectData = {
                                'fullName': projectModel.fullProjectName,
                                'client': projectModel.client,
                                'projectName': projectModel.projectName,
                                'createDate': projectModel.createDate,
                                'tech': projectModel.tech,
                              };

                              // Insert the new project data into the database
                              final projectID = await dbHelper.insertProjectName(projectData);
                              // ignore: unnecessary_null_comparison
                              if (projectID != null) {
// Create a new Project object
                                Project newProject = Project(
                                  id: projectID,
                                  client: projectModel.client,
                                  projectName: projectModel.projectName,
                                  createDate: projectModel.createDate,
                                  tech: projectModel.tech,
                                );
// Update the ProjectModel with user input
                                projectModel.projectID = newProject.id;
                                projectModel.client = newProject.client;
                                projectModel.projectName = newProject.projectName;
                                projectModel.tech = newProject.tech;
                                projectModel.createDate = newProject.createDate;
// Load rectifiers and test stations from the database

                                Provider.of<RectifierNotifier>(context, listen: false).loadRectifiersFromDatabase(newProject.id, 'serviceTag');
                                Provider.of<TSNotifier>(context, listen: false).loadTestStationsFromDatabase(newProject.id);
// Save the selected project to shared preferences
                                _saveSelectedProjectToPrefs(newProject.id);
// Update the projectsExist future
                                await updateProjectsExist();
                                //  await loadProjectNames();
                              }
// Close the dialog and show a Snackbar to notify the user that the project was created successfully
                              if (mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Created database for $projectName')));
                              }
                            } catch (e) {
                              // Handle any errors that might have occurred during the project creation
                              if (mounted) {
                                //
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(content: Text('Failed to create database for $projectName! Error: $e')));
                              }
                            }
                          }
                        },
                      ),
                    ],
                  );
                },
              );
            },
          );
        });
  }

  /// Shows a dialog to select a project.
  /// If there are no projects available, a Snackbar is shown to notify the user.
  /// When a project is selected, the selected project's information is updated in the project model.
  /// The last loaded project is updated in the database.
  /// Rectifiers and test stations associated with the selected project are loaded from the database.
  /// The selected project is saved to preferences.
  /// Finally, the dialog is closed.
  Future<void> showSelectProjectDialog() async {
    // var tsNotifier = Provider.of<TSNotifier>(context, listen: false);
    // var rectifierNotifier = Provider.of<RectifierNotifier>(context, listen: false);

    if (!mounted) {
      return;
    }
    loadProjectNames();

    if (!projectNames.contains(selectedProjectName)) {
      selectedProjectName = null;
    }

    if (kDebugMode) {
      print('projectNames: $projectNames');
    }
    if (projectNames.isEmpty) {
      if (kDebugMode) {
        print("Current projectNames1: $projectNames");
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext outerContext) {
          return StatefulBuilder(
            builder: (BuildContext innerContext, StateSetter setState) {
              return AlertDialog(
                title: const Center(child: Text('Select a Project')),
                content: DropdownButton<Project>(
                  isExpanded: true,
                  value: selectedProjectName,
                  onChanged: (Project? newValue) {
                    if (newValue != null) {
                      onProjectSelected(newValue);
                      final projectModel = Provider.of<ProjectModel>(innerContext, listen: false);
                      projectModel.projectID = newValue.id;
                      projectModel.client = newValue.client;
                      projectModel.projectName = newValue.projectName;
                      projectModel.tech = newValue.tech;
                      projectModel.createDate = newValue.createDate;
                      DatabaseHelper.instance.updateLastLoaded(newValue.id, DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()));
                      Navigator.of(innerContext).pop();
                    }
                  },
                  items: projectNames.map<DropdownMenuItem<Project>>((Project project) {
                    return DropdownMenuItem<Project>(
                      value: project,
                      child: Text(project.fullProjectName), // Display the full project name
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      );
    }
  }

  /// Checks if navigation is allowed based on the current project ID.
  /// Returns a [Future] that resolves to a [bool] indicating whether navigation is allowed.
  /// The [currentProjectId] parameter represents the ID of the current project.
  /// The method checks if the [currentProjectId] is equal to 0. If it is, navigation is not allowed and the method returns false.
  /// Otherwise, the method retrieves the path to the project database file and checks if the file exists.
  ///
  /// Returns true if the database file exists, indicating that navigation is allowed.
  /// Returns false if the database file does not exist.
  Future<bool> _canNavigate(int currentProjectId) async {
    if (currentProjectId == 0) {
      return false;
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'project_database1.db');

    // Check if database file exists
    final dbExists = await databaseExists(path);
    return dbExists;
  }

  /// Shows an error dialog when no project is selected, when trying to navigate to Test Stations, Rectifiers, Tanks, or ISO/OVP.
  ///
  /// This method displays an [AlertDialog] with a title "Action Required" and a content
  /// "Please create or select a project first." It also includes an "OK" button to dismiss
  /// the dialog. The [BuildContext] is required to show the dialog.
  void _showNoProjectSelectedErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Action Required'),
        content: const Text('Please create or select a project first.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Builds the main UI of the application.
  ///
  /// This method returns a [Widget] that represents the main UI of the application.
  /// It uses a [FutureBuilder] to handle the asynchronous loading of data.
  /// If the data loading is complete and successful, it displays the main content of the application.
  /// If there is an error during data loading, it displays an error message.
  /// If no projects exist, it shows a dialog prompting the user to create a project.
  /// The main UI consists of a background image, a top app bar, a bottom app bar, and the main content area.
  /// The main content area contains several buttons that navigate to different screens of the application.
  /// The top app bar displays the current project name and client.
  /// The bottom app bar contains two icons for adding a project and selecting a project.
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: projectsExist,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return const Center(child: Text('An error occurred!'));
          }

          if (snapshot.data == false) {
            // No projects exist
            Future.microtask(() {
              if (ModalRoute.of(context)?.isCurrent ?? false) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Notification'),
                    content: const Text('Please create a project first.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          showAddProjectDialog(context);
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            });
          }

          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: const Color.fromARGB(255, 159, 160, 161),

// Main body
            body: Stack(
              children: [
// Background image
                Positioned.fill(
                  //    top: 10,
                  bottom: 260,
                  child: Image.asset(
                    'assets/images/corrorecord_no_background.png',
                    fit: BoxFit.contain,
                  ),
                ),

                // Content
                Column(
                  children: [
                    // AppBar space (if needed)
                    SizedBox(
                      height: kToolbarHeight + MediaQuery.of(context).padding.top,
                    ),

// Main content
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: 280.h),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: SizedBox(
                                width: 220.w,
                                height: 50.h,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final int currentProjectId = Provider.of<ProjectModel>(context, listen: false).id;
                                    final canNavigate = await _canNavigate(currentProjectId);
                                    if (!mounted) return;
                                    if (canNavigate) {
                                      Navigator.pushNamed(context, '/test_stations');
                                    } else {
                                      _showNoProjectSelectedErrorDialog(context);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 0, 43, 92),
                                  ),
                                  child: Text('Test Stations',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24.sp,
                                        fontWeight: FontWeight.bold,
                                      )),
                                ),
                              ),
                            ),
                            SizedBox(height: 20.h),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: SizedBox(
                                width: 220.w,
                                height: 50.h,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final int currentProjectId = Provider.of<ProjectModel>(context, listen: false).id;
                                    final canNavigate = await _canNavigate(currentProjectId);
                                    if (!mounted) return;
                                    if (canNavigate) {
                                      Navigator.pushNamed(context, '/rectifiers');
                                    } else {
                                      _showNoProjectSelectedErrorDialog(context);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 0, 43, 92),
                                  ),
                                  child: Text(
                                    'Rectifiers',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 20.h),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: SizedBox(
                                width: 220.w,
                                height: 50.h,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final int currentProjectId = Provider.of<ProjectModel>(context, listen: false).id;
                                    final canNavigate = await _canNavigate(currentProjectId);
                                    if (!mounted) return;
                                    if (canNavigate) {
                                      Navigator.pushNamed(context, '/tanks');
                                    } else {
                                      _showNoProjectSelectedErrorDialog(context);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 0, 43, 92),
                                  ),
                                  child: Text(
                                    'Tanks',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 20.h),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: SizedBox(
                                width: 220.w,
                                height: 50.h,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final int currentProjectId = Provider.of<ProjectModel>(context, listen: false).id;
                                    final canNavigate = await _canNavigate(currentProjectId);
                                    if (!mounted) return;
                                    if (canNavigate) {
                                      Navigator.pushNamed(context, '/iso');
                                    } else {
                                      _showNoProjectSelectedErrorDialog(context);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 0, 43, 92),
                                  ),
                                  child: Text(
                                    'ISO/OVP',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

// Top App Bar
            appBar: AppBar(
              backgroundColor: const Color.fromARGB(255, 0, 43, 92),
              elevation: 0, // Remove shadow
              iconTheme: const IconThemeData(color: Colors.white),
              title: Consumer<ProjectModel>(
                builder: (context, projectModel, child) {
                  return Text(
                    '${projectModel.client}: ${projectModel.projectName}',
                    style: TextStyle(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 247, 143, 30),
                    ),
                  );
                },
              ),
              centerTitle: true,
              actions: <Widget>[
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: _choiceAction,
                  itemBuilder: (BuildContext context) {
                    return ['Multimeter', 'Settings', 'Copy DB to Downloads'].map((String choice) {
                      return PopupMenuItem<String>(
                        value: choice,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            choice,
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 0, 43, 92),
                            ),
                          ),
                        ),
                      );
                    }).toList();
                  },
                ),
              ],
            ),

// Bottom App Bar
            bottomNavigationBar: BottomAppBar(
              height: 60.0.h,
              color: const Color.fromARGB(255, 0, 43, 92),
              //   shape: const CircularNotchedRectangle(),
              //  notchMargin: 10.0,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                //   mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.add, color: const Color.fromARGB(255, 247, 143, 30), size: 40.sp),
                    onPressed: () => showAddProjectDialog(context),
                  ),
                  IconButton(
                      icon: Icon(Icons.folder_open, color: const Color.fromARGB(255, 247, 143, 30), size: 40.sp),
                      onPressed: () => showSelectProjectDialog()),
                ],
              ),
            ),
          );
        } else {
          // Show a loading indicator or some placeholder while waiting
          return Center(
            child: SizedBox(
              width: 50.0.w,
              height: 50.0.h,
              child: const CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}



/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
/*
class MainPageUI extends State<MainPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<bool> projectsExist;
  Project? selectedProjectName;
  List<Project> projectNames = [];
  final bluetoothManager = BluetoothManager.instance;
  String? currentName;
  // ignore: unused_field
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    projectsExist = hasProjects();
    loadProjectNames();
    DatabaseHelper.instance.requestStoragePermission();
  }

  Future<void> loadProjectNames() async {
    await hasProjects();
    final dbHelper = DatabaseHelper.instance;
    projectNames = await dbHelper.fetchProjectNames();
    if (mounted) setState(() {});
  }

  Future<void> updateProjectsExist() async {
    projectsExist = hasProjects();
    if (mounted) setState(() {});
  }

  Future<bool> hasProjects() async {
    final dbHelper = DatabaseHelper.instance;
    final projects = await dbHelper.fetchProjectNames();
    return projects.isNotEmpty;
  }

  void _choiceAction(String choice) {
    if (choice == 'Multimeter') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MultimeterUIPage()),
      );
    } else if (choice == 'Settings') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainSettings()),
      );
    } else if (choice == 'Copy DB to Downloads') {
      //  await DatabaseHelper.instance.requestStoragePermission();
      DatabaseHelper.instance.copyDatabaseToDownloads();
    }
  }

  Future<void> _loadProjectData(int projectID) async {
    if (!mounted) return;
    var tsNotifier = Provider.of<TSNotifier>(context, listen: false);
    var rectifierNotifier = Provider.of<RectifierNotifier>(context, listen: false);

    await rectifierNotifier.loadRectifiersFromDatabase(projectID, 'serviceTag');
    await tsNotifier.loadTestStationsFromDatabase(projectID);
    if (kDebugMode) {
      print('_loadProjectData called');
    }
  }

  void onProjectSelected(Project selectedProject) {
    if (!mounted) return;
    setState(() {
      currentName = selectedProject.projectName;
      selectedProjectName = selectedProject;
      _isInitialLoad = false;
    });
    if (kDebugMode) {
      print('onProjectSelected called');
    }
    _loadProjectData(selectedProject.id);
  }

  // ignore: unused_element
  Future<void> _selectProject(Project? latestProject) async {
    if (!mounted) return;
    if (latestProject != null) {
      setState(() {
        selectedProjectName = Project(
          id: latestProject.id,
          client: latestProject.client,
          projectName: latestProject.projectName,
          tech: latestProject.tech,
          createDate: latestProject.createDate,
        );
      });

      await _loadProjectData(latestProject.id);
    }
  }

  Future<void> _saveSelectedProjectToPrefs(int projectID) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedProjectID', projectID);
  }

  void showAddProjectDialog(BuildContext context) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AddProjectDialog(
        onProjectAdded: (Project newProject) async {
          if (!mounted) return;
          final rectifierNotifier = Provider.of<RectifierNotifier>(context, listen: false);
          final tsNotifier = Provider.of<TSNotifier>(context, listen: false);

          try {
            await rectifierNotifier.loadRectifiersFromDatabase(newProject.id, 'serviceTag');
            await tsNotifier.loadTestStationsFromDatabase(newProject.id);
            await _saveSelectedProjectToPrefs(newProject.id);
            await updateProjectsExist();

            if (context.mounted) {
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Created database for ${newProject.projectName}')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error creating database for ${newProject.projectName}: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _prepareProjectData() async {
    if (!mounted) return;
    await loadProjectNames();
    if (!projectNames.contains(selectedProjectName)) {
      selectedProjectName = null;
    }
  }

  void showSelectProjectDialog() {
    if (!mounted) return;

    _prepareProjectData().then((_) {
      if (!mounted) return;
      if (projectNames.isEmpty) return;

      showDialog(
        context: context,
        builder: (BuildContext dialogContext) => SelectProjectDialog(
          projects: projectNames,
          selectedProject: selectedProjectName,
          onProjectSelected: (Project newValue) {
            if (!mounted) return;
            onProjectSelected(newValue);
            final projectModel = Provider.of<ProjectModel>(context, listen: false);
            projectModel.projectID = newValue.id;
            projectModel.client = newValue.client;
            projectModel.projectName = newValue.projectName;
            projectModel.tech = newValue.tech;
            projectModel.createDate = newValue.createDate;
            DatabaseHelper.instance.updateLastLoaded(newValue.id, DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()));
            Navigator.of(dialogContext).pop();
          },
        ),
      );
    });
  }

  Future<bool> _canNavigate(int currentProjectId) async {
    if (currentProjectId == 0) return false;
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'project_database1.db');
    return await databaseExists(path);
  }

  void _showNoProjectSelectedErrorDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Action Required'),
        content: const Text('Please create or select a project first.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: projectsExist,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return const Center(child: Text('An error occurred!'));
          }

          if (snapshot.data == false) {
            Future.microtask(() => _showCreateProjectDialog(context));
          }

          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: const Color.fromARGB(255, 159, 160, 161),
            body: MainPageBody(
              onNavigate: _navigateToPage,
            ),
            appBar: MainAppBar(
              onMoreSelected: _choiceAction,
            ),
            bottomNavigationBar: MainBottomAppBar(
              onAddProject: () => showAddProjectDialog(context),
              onSelectProject: showSelectProjectDialog,
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  void _showCreateProjectDialog(BuildContext context) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Notification'),
        content: const Text('Please create a project first.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              showAddProjectDialog(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToPage(String route) async {
    if (!mounted) return;
    final int currentProjectId = Provider.of<ProjectModel>(context, listen: false).id;
    final canNavigate = await _canNavigate(currentProjectId);
    if (!mounted) return;
    if (canNavigate) {
      Navigator.pushNamed(context, route);
    } else {
      _showNoProjectSelectedErrorDialog();
    }
  }
}

class MainPageBody extends StatelessWidget {
  final Function(String) onNavigate;

  const MainPageBody({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          bottom: 260,
          child: Image.asset(
            'assets/images/corrorecord_no_background.png',
            fit: BoxFit.contain,
          ),
        ),
        Column(
          children: [
            SizedBox(
              height: kToolbarHeight + MediaQuery.of(context).padding.top,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 280.h),
                    NavigationButton(
                      title: 'Test Stations',
                      onPressed: () => onNavigate('/test_stations'),
                    ),
                    SizedBox(height: 20.h),
                    NavigationButton(
                      title: 'Rectifiers',
                      onPressed: () => onNavigate('/rectifiers'),
                    ),
                    SizedBox(height: 20.h),
                    NavigationButton(
                      title: 'Tanks',
                      onPressed: () => onNavigate('/tanks'),
                    ),
                    SizedBox(height: 20.h),
                    NavigationButton(
                      title: 'ISO/OVP',
                      onPressed: () => onNavigate('/iso'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class NavigationButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;

  const NavigationButton({
    super.key,
    required this.title,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: 220.w,
        height: 50.h,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 0, 43, 92),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Function(String) onMoreSelected;

  const MainAppBar({super.key, required this.onMoreSelected});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 0, 43, 92),
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Consumer<ProjectModel>(
        builder: (context, projectModel, child) {
          return Text(
            '${projectModel.client}: ${projectModel.projectName}',
            style: TextStyle(
              fontSize: 26.sp,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 247, 143, 30),
            ),
          );
        },
      ),
      centerTitle: true,
      actions: <Widget>[
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: onMoreSelected,
          itemBuilder: (BuildContext context) {
            return ['Multimeter', 'Settings', 'Copy DB to Downloads'].map((String choice) {
              return PopupMenuItem<String>(
                value: choice,
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    choice,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 0, 43, 92),
                    ),
                  ),
                ),
              );
            }).toList();
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class MainBottomAppBar extends StatelessWidget {
  final VoidCallback onAddProject;
  final VoidCallback onSelectProject;

  const MainBottomAppBar({
    super.key,
    required this.onAddProject,
    required this.onSelectProject,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 60.0.h,
      color: const Color.fromARGB(255, 0, 43, 92),
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.add, color: const Color.fromARGB(255, 247, 143, 30), size: 40.sp),
            onPressed: onAddProject,
          ),
          IconButton(
            icon: Icon(Icons.folder_open, color: const Color.fromARGB(255, 247, 143, 30), size: 40.sp),
            onPressed: onSelectProject,
          ),
        ],
      ),
    );
  }
}

class AddProjectDialog extends StatefulWidget {
  final Function(Project) onProjectAdded;

  const AddProjectDialog({super.key, required this.onProjectAdded});

  @override
  createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends State<AddProjectDialog> {
  final TextEditingController clientController = TextEditingController();
  final TextEditingController projectNameController = TextEditingController();
  final TextEditingController techController = TextEditingController();

  bool isValidClient = true;
  bool isValidProjectName = true;
  bool isValidTech = true;

  void checkValidationState() {
    setState(() {
      isValidClient = clientController.text.isNotEmpty;
      isValidProjectName = projectNameController.text.isNotEmpty;
      isValidTech = techController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Center(child: Text('New Project Details')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: clientController,
              decoration: InputDecoration(
                hintText: "Client",
                errorText: isValidClient ? null : 'Client cannot be empty',
              ),
              onChanged: (_) => checkValidationState(),
            ),
            SizedBox(height: 10.h),
            TextField(
              controller: projectNameController,
              decoration: InputDecoration(
                hintText: "Project Name",
                errorText: isValidProjectName ? null : 'Project name cannot be empty',
              ),
              onChanged: (_) => checkValidationState(),
            ),
            SizedBox(height: 10.h),
            TextField(
              controller: techController,
              decoration: InputDecoration(
                hintText: "Technician",
                errorText: isValidTech ? null : 'Technician cannot be empty',
              ),
              onChanged: (_) => checkValidationState(),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        SizedBox(
          width: 50.w,
          height: 50.h,
          child: FloatingActionButton(
            backgroundColor: const Color.fromARGB(255, 210, 235, 247),
            child: const Icon(Icons.cancel, color: Colors.red),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        SizedBox(width: 20.w),
        SizedBox(
          width: 50.w,
          height: 50.h,
          child: FloatingActionButton(
            backgroundColor: const Color.fromARGB(255, 210, 235, 247),
            onPressed: () async {
              final client = clientController.text.trim();
              final projectName = projectNameController.text.trim();
              final tech = techController.text.trim();
              final createDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

              if (client.isEmpty || projectName.isEmpty || tech.isEmpty) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Error'),
                    content: const Text('All fields are required. Please fill in all the information.'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('OK'),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                    ],
                  ),
                );
                return;
              }

              final isValidName = RegExp(r'^[a-zA-Z0-9_ ]+$').hasMatch(projectName);
              if (!isValidName) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Invalid Project Name'),
                    content: const Text('The project name is not valid. It should only contain alphanumeric characters and underscores.'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('OK'),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                    ],
                  ),
                );
                return;
                //     }  Uncomment this line if 'ELSE' isn't needed
              } else {
                final projectModel = Provider.of<ProjectModel>(context, listen: false);
                projectModel.projectID = 0;
                projectModel.client = client;
                projectModel.projectName = projectName;
                projectModel.tech = tech;
                projectModel.createDate = createDate;

                final dbHelper = DatabaseHelper.instance;

                try {
                  await dbHelper.createTablesForProject();
                  await dbHelper.createTableForCameraSettings();
                  await dbHelper.insertCameraSettings(CameraSettings(
                    isMapOverlayVisible: false,
                    mapPosition: MapPosition.bottomLeft,
                    dataPosition: MapPosition.bottomLeft,
                    mapType: 'normal',
                    mapOpacity: 1.0,
                    mapSize: 150,
                    mapScale: 16.0,
                    isDataOverlayVisible: false,
                    selectedFontStyle: 'normal',
                    selectedFontColor: 'black',
                    selectedFontSize: 12.0,
                    selectedDateFormat: 'yyyy-MM-dd HH:mm:ss',
                    selectedLocationFormat: 'Street Address, City, State, Zip',
                  ));

                  final projectData = {
                    'fullName': projectModel.fullProjectName,
                    'client': projectModel.client,
                    'projectName': projectModel.projectName,
                    'createDate': projectModel.createDate,
                    'tech': projectModel.tech,
                  };

                  final projectID = await dbHelper.insertProjectName(projectData);
                  Project newProject = Project(
                    id: projectID,
                    client: projectModel.client,
                    projectName: projectModel.projectName,
                    createDate: projectModel.createDate,
                    tech: projectModel.tech,
                  );
                  projectModel.projectID = newProject.id;
                  projectModel.client = newProject.client;
                  projectModel.projectName = newProject.projectName;
                  projectModel.tech = newProject.tech;
                  projectModel.createDate = newProject.createDate;
                  widget.onProjectAdded(newProject);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create database for $projectName! Error: $e')));
                  }
                } // <<<Remove this line if 'ELSE' isn't needed
              }
            },
            child: const Icon(Icons.check_circle, color: Colors.green),
          ),
        ),
      ],
    );
  }
}

class SelectProjectDialog extends StatelessWidget {
  final List<Project> projects;
  final Project? selectedProject;
  final Function(Project) onProjectSelected;

  const SelectProjectDialog({
    super.key,
    required this.projects,
    required this.selectedProject,
    required this.onProjectSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Center(child: Text('Select a Project')),
      content: DropdownButton<Project>(
        isExpanded: true,
        value: selectedProject,
        onChanged: (Project? newValue) {
          if (newValue != null) {
            onProjectSelected(newValue);
          }
        },
        items: projects.map<DropdownMenuItem<Project>>((Project project) {
          return DropdownMenuItem<Project>(
            value: project,
            child: Text(project.fullProjectName),
          );
        }).toList(),
      ),
    );
  }
}
*/