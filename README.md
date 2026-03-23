# OLTrap Mapping App

A comprehensive Flutter application for Oriental Leafhopper Trap mapping and management. This app helps researchers and agricultural workers track, monitor, and manage OLTrap locations and data efficiently.

## 🚀 Features

### 🗺️ **Interactive Map**
- Real-time trap location visualization
- Current location centering
- Glowing animations for selected traps
- Pulsing effects for better visibility
- High zoom levels (up to 22.0) for detailed inspection

### 📱 **QR Code Scanner**
- Fast QR code scanning for trap registration
- Automatic location capture
- Status management (Deployed/Harvested)
- Location name assignment

### 📊 **Location History**
- Organized trap data by location
- Pull-to-refresh functionality
- Detailed statistics per location
- Search and filter capabilities

### ⚙️ **Settings & Data Management**
- **Import/Export Database**: Backup and restore data
- **Clear Data**: Safely remove all records with confirmation
- **User-selectable export locations**
- **File validation for imports**

### 🎨 **Enhanced UI/UX**
- Modern neumorphic design
- Location pin icons throughout the app
- Swipe-to-hide gestures for details
- Responsive bottom navigation
- Professional color schemes

## 📸 **Screenshots**

*(Add screenshots of the app in action)*

## 🛠️ **Technical Stack**

- **Framework**: Flutter 3.x
- **Language**: Dart
- **Database**: SQLite (via sqflite)
- **Maps**: flutter_map with OpenStreetMap
- **QR Scanning**: mobile_scanner
- **File Operations**: file_picker
- **Location Services**: geolocator

## 📋 **Requirements**

- **Android**: Android 5.0 (API level 21) or higher
- **iOS**: iOS 11.0 or higher
- **Permissions**: 
  - Camera (for QR scanning)
  - Location (for GPS positioning)
  - Storage (for import/export)

## 🚀 **Installation**

### **From GitHub**
```bash
git clone https://github.com/mx-dln/oltrap_mapping.git
cd oltrap_mapping
flutter pub get
flutter run
```

### **Production Build**
```bash
flutter build apk --release
```

The APK will be generated at:
`build/app/outputs/flutter-apk/app-release.apk`

## 📖 **Usage Guide**

### **1. Map Navigation**
- Tap on any trap marker to view details
- Use the compass button to center on your current location
- Use the explore button to reset map rotation to north
- Pull down to refresh trap data

### **2. Adding New Traps**
- Tap the QR scanner button or navigate through location selection
- Scan the QR code on the OLTrap
- Assign a location name
- Set initial status (Deployed/Harvested)

### **3. Managing Data**
- **Export**: Settings → Export Database → Choose save location
- **Import**: Settings → Import Database → Select .db file
- **Clear**: Settings → Clear All Data → Confirm action

### **4. Viewing History**
- Navigate to Locations tab
- Pull down to refresh data
- Tap on any location to view detailed statistics
- Use the search function to find specific locations

## 🏗️ **Project Structure**

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── oltrap.dart          # OLTrap data model
├── screens/
│   ├── map_screen.dart      # Interactive map view
│   ├── qr_scanner_screen.dart # QR code scanning
│   ├── location_history_screen.dart # Location history
│   ├── settings_screen.dart  # Settings and data management
│   └── location_selection_screen.dart # Location selection
├── services/
│   ├── database_helper.dart # SQLite database operations
│   └── geojson_service.dart  # GeoJSON utilities
└── theme/
    └── neumorphism_theme.dart # App theme and styling
```

## 🗄️ **Database Schema**

The app uses SQLite with the following table structure:

```sql
CREATE TABLE oltraps (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    qr_code_data TEXT NOT NULL UNIQUE,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    timestamp INTEGER NOT NULL,
    notes TEXT,
    location_name TEXT,
    status TEXT NOT NULL DEFAULT 'deployed'
);
```

## 🔧 **Configuration**

### **Map Settings**
- Default center: Current user location (falls back to Manila: 16.932411, 121.767825)
- Zoom range: 3.0 to 22.0
- Tile provider: OpenStreetMap

### **Export/Import**
- Export format: SQLite database (.db)
- Import validation: File extension and format checking
- Backup naming: `oltrap_database_[timestamp].db`

## 🐛 **Troubleshooting**

### **Common Issues**

1. **Location not found**
   - Ensure location permissions are granted
   - Check GPS is enabled on your device
   - Try moving to an area with better GPS reception

2. **QR scanner not working**
   - Verify camera permissions are granted
   - Ensure good lighting conditions
   - Hold the camera steady at appropriate distance

3. **Import/Export errors**
   - Ensure sufficient storage space
   - Check file permissions for selected directory
   - Verify the file is a valid .db file

### **Performance Tips**
- The app automatically optimizes font assets (99.7% reduction)
- Map tiles are cached for better performance
- Database operations are optimized for bulk operations

## 🤝 **Contributing**

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### **Development Guidelines**
- Follow Flutter/Dart coding standards
- Add comments for complex logic
- Test on both Android and iOS if possible
- Update documentation as needed

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 **Support**

For support, questions, or feature requests:

- 📧 Email: [your-email@example.com]
- 🐛 Issues: [GitHub Issues](https://github.com/mx-dln/oltrap_mapping/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/mx-dln/oltrap_mapping/discussions)

## 🙏 **Acknowledgments**

- **Flutter Team** - For the amazing cross-platform framework
- **OpenStreetMap** - For providing map tiles
- **Flutter Community** - For the wonderful packages and support
- **Agricultural Researchers** - For the domain expertise and requirements

## 📈 **Version History**

- **v1.0.0** (Current)
  - Initial release with all core features
  - Interactive map with trap visualization
  - QR code scanning and trap management
  - Location history and statistics
  - Settings with import/export functionality
  - Enhanced UI/UX with animations and gestures

---

**Built with ❤️ using Flutter**
