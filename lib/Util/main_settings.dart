import 'package:asset_inspections/Pokit_Multimeter/Models/pokitpro_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asset_inspections/Util/connect_bluetooth_ui.dart';
import 'package:asset_inspections/Pokit_Multimeter/Providers/bluetooth_manager_notifier.dart';

class MainSettings extends StatefulWidget {
  const MainSettings({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MainSettingsState createState() => _MainSettingsState();
}

class _MainSettingsState extends State<MainSettings> {
  PokitProModel? pairedDevice;
  late BluetoothManager bluetoothManager;

  /// Builds the settings screen widget.
  ///
  /// This method returns a [Scaffold] widget that displays the settings screen.
  /// The settings screen consists of an [AppBar] with a title, and a [Column]
  /// containing two [ListTile] widgets. Each [ListTile] represents a setting
  /// option and is wrapped in a [Card] widget for styling. The first [ListTile]
  /// represents the "Reference Cells" setting and the second [ListTile] represents
  /// the "Digital Multimeter" setting. Tapping on the "Reference Cells" setting
  /// opens a dialog to add a reference cell, while tapping on the "Digital Multimeter"
  /// setting navigates to the [BluetoothConnectionPage].
  ///
  /// The [AppBar] has a preferred height of 50.0 and a background color of
  /// Color.fromARGB(255, 0, 43, 92). The title of the [AppBar] is set to "Settings"
  /// with a font size of 26.0 and a bold font weight. The title is centered.
  ///
  /// The [Column] widget contains two [ListTile] widgets. Each [ListTile] has a
  /// title and a subtitle. The title and subtitle of the "Reference Cells" [ListTile]
  /// are styled with white color, a font size of 26.sp for the title and 14.0 for the
  /// subtitle, and a bold font weight. The "Reference Cells" [ListTile] has a tile color
  /// of Color.fromARGB(255, 0, 43, 92) and white text color. Tapping on the "Reference Cells"
  /// [ListTile] calls the [_showAddRefCellDialog] method.
  ///
  /// The title and subtitle of the "Digital Multimeter" [ListTile] are styled similarly
  /// to the "Reference Cells" [ListTile]. Tapping on the "Digital Multimeter" [ListTile]
  /// navigates to the [BluetoothConnectionPage] using the [Navigator.push] method.
  ///
  /// The [Column] widget is wrapped in a [Padding] widget with 8.0 padding on all sides.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0), // Set height of the AppBar
        child: AppBar(
          backgroundColor: const Color.fromARGB(255, 0, 43, 92),
          title: const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ListTile(
              title: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Text('Reference Cells',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26.sp,
                      fontWeight: FontWeight.bold,
                    )),
                SizedBox(height: 10.h),
                const Text('Set Default Reference Cells',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                    )),
              ]),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
              dense: false,
              tileColor: const Color.fromARGB(255, 0, 43, 92),
              textColor: Colors.white,
              minVerticalPadding: 10.0,
              onTap: () => _showAddRefCellDialog(context),
            ),
            SizedBox(height: 10.sp),
            ListTile(
              title: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                const Text('Digital Multimeter',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26.0,
                      fontWeight: FontWeight.bold,
                    )),
                SizedBox(height: 10.h),
                const Text('Connect Bluetooth Multimeter',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                    )),
              ]),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
              dense: false,
              tileColor: const Color.fromARGB(255, 0, 43, 92),
              textColor: Colors.white,
              minVerticalPadding: 10.0,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BluetoothConnectionPage()),
              ),

              //BluetoothConnectionPage(context),
            ),
            // ... other settings
          ],
        ),
      ),
    );
  }

  //TODO: Create variables for the name and selected cell type (by projectID)
  //TODO: Add Reference Cell table to the database (by projectID)
  //TODO: Create method to add reference cell to the database (by projectID)
  //TODO: Create method to delete reference cell from the database (by projectID)
  //TODO: Create method to initialize the reference cell table for (by projectID)

  /// Shows a dialog to add a reference cell.
  ///
  /// This method displays an [AlertDialog] with input fields for the name and reference cell type.
  /// The user can enter a name using a [TextFormField] and select a reference cell type from a dropdown menu.
  /// After entering the required information, the user can either cancel or add the reference cell.
  /// The add logic can be implemented in the `onPressed` callback of the 'Add' button.
  void _showAddRefCellDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController nameController = TextEditingController();
        String? selectedCellType;
        return AlertDialog(
          title: const Text('Add Reference Cell'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Name'),
                TextFormField(controller: nameController),
                SizedBox(height: 20.h),
                const Text('Reference Cell Type'),
                DropdownButtonFormField<String>(
                  value: selectedCellType,
                  items: <String>['Copper-Sulfate', 'Zinc', 'Silver-Chloride', 'Saturated Calomel', 'Normal Hydrogen']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCellType = newValue;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                // Add your add logic here
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
