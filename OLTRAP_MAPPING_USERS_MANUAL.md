# OLTrap Mapping App - User Manual

**Version 1.1.0**  
*Comprehensive Guide for Oriental Leafhopper Trap Mapping and Management*

---

## 📖 Table of Contents

1. [Overview](#overview)
2. [Getting Started](#getting-started)
3. [Main Features](#main-features)
4. [Detailed Usage Guide](#detailed-usage-guide)
5. [Data Management](#data-management)
6. [Troubleshooting](#troubleshooting)
7. [Tips & Best Practices](#tips--best-practices)
8. [FAQ](#faq)

---

## 🎯 Overview

**OLTrap Mapping** is a professional mobile application designed for agricultural researchers and field workers to efficiently track, monitor, and manage Oriental Leafhopper (OL) trap locations and data. The app combines GPS technology, QR code scanning, and interactive mapping to provide a comprehensive trap management solution.

### Key Benefits:
- 📍 **Accurate GPS Tracking**: Precise location capture for each trap
- 📱 **Mobile-First Design**: Works seamlessly in the field
- 🔄 **Real-time Data Sync**: Instant updates across all devices
- 📊 **Comprehensive Analytics**: Detailed statistics and insights
- 💾 **Data Backup**: Secure export/import functionality

---

## 🚀 Getting Started

### System Requirements

**Android:**
- Android 5.0 (API level 21) or higher
- Camera with QR code scanning capability
- GPS/location services enabled
- Minimum 50MB storage space

**iOS:**
- iOS 11.0 or higher
- Camera with QR code scanning capability
- GPS/location services enabled
- Minimum 50MB storage space

### Installation

1. **Download the App**
   - Install from Google Play Store or sideload the APK
   - Allow installation from unknown sources if sideloading

2. **Grant Permissions**
   - **Camera**: Required for QR code scanning
   - **Location**: Required for GPS positioning
   - **Storage**: Required for data import/export

3. **First Launch**
   - Open the app
   - Allow all requested permissions
   - Wait for initial database setup

---

## 🌟 Main Features

### 🗺️ Interactive Map Screen
- **Real-time GPS Tracking**: Shows your current location
- **Trap Visualization**: Color-coded markers for trap status
- **High Zoom Levels**: Zoom up to 22x for detailed inspection
- **Interactive Markers**: Tap to view trap details
- **Status Filtering**: Filter by deployed/harvested status
- **Search Functionality**: Find specific traps quickly

### 📱 QR Code Scanner
- **Fast Scanning**: Quick QR code recognition
- **Automatic Location Capture**: GPS coordinates saved automatically
- **Batch Processing**: Scan multiple traps in sequence
- **Status Assignment**: Set deployed/harvested status during scanning
- **Location Naming**: Assign custom location names

### 📊 Location History
- **Organized View**: Traps grouped by location
- **Statistics Dashboard**: Deployed vs harvested counts
- **Missing/Damage Tracking**: Monitor trap conditions
- **Pull-to-Refresh**: Update data with gesture
- **Detailed Views**: Comprehensive trap information

### ⚙️ Settings & Data Management
- **Export Database**: Save data to Downloads folder
- **Import Database**: Restore from backup files
- **Clear Data**: Reset app with confirmation
- **Cross-Device Compatibility**: Works across different devices

---

## 📋 Detailed Usage Guide

### 1. Map Navigation

#### Viewing Traps on Map
1. **Launch the app** → Map screen opens automatically
2. **Locate trap markers**: 
   - 🟢 Green pins: Deployed traps
   - 🟠 Orange pins: Harvested traps
3. **Tap any marker** to view detailed information
4. **Use pinch gestures** to zoom in/out
5. **Drag to pan** around the map

#### Map Controls
- **🧭 Compass Button**: Center map on your current location
- **🔍 Explore Button**: Reset map rotation to face north
- **🔄 Pull Down**: Refresh trap data
- **🔍 Search Bar**: Find specific traps by QR code or location

#### Status Filtering
1. **Tap filter icon** (funnel shape)
2. **Select trap status**:
   - All traps
   - Deployed only
   - Harvested only
3. **Apply additional filters**:
   - By location name
   - By notes/keywords
4. **Clear filters** to show all traps

### 2. QR Code Scanning

#### Starting QR Scanner
1. **Tap QR scanner button** on map screen
2. **Or navigate through**: Location Selection → QR Scanner
3. **Allow camera permission** if prompted

#### Scanning Process
1. **Position camera** 6-12 inches from QR code
2. **Ensure good lighting** for best results
3. **Hold steady** until QR code is recognized
4. **Confirm scan** when vibration/buzz occurs
5. **Set trap details**:
   - Location name (auto-filled if selected)
   - Status: Deployed/Harvested
   - Notes (optional)

<!-- #### Batch Scanning
1. **Scan multiple QR codes** in sequence
2. **Review scanned list** before saving
3. **Edit individual entries** if needed
4. **Save all traps** to database -->

### 3. Location Management

#### Creating New Locations
1. **Navigate to Locations tab**
2. **Tap "Add Location"** (if available)
3. **Enter location name**
4. **Set GPS coordinates** (automatic or manual)
5. **Save location**

#### Viewing Location Details
1. **Tap any location** in the list
2. **View statistics**:
   - Total traps deployed
   - Total traps harvested
   - Missing traps count
   - Damaged traps count
3. **Browse trap list** for that location
4. **Tap individual traps** for details

### 4. Data Management

#### Exporting Database
1. **Navigate to Settings**
2. **Tap "Export Database"**
3. **Wait for processing** (shows trap count)
4. **File saves automatically** to Downloads folder
5. **Filename format**: `oltrap_database_v1.1.0_[timestamp].db`

#### Importing Database
1. **Navigate to Settings**
2. **Tap "Import Database"**
3. **Select .db file** from device storage
4. **Confirm import** (shows new trap count)
5. **Data merges** with existing database

#### Clearing Data
1. **Navigate to Settings**
2. **Tap "Clear All Data"**
3. **Confirm action** (irreversible)
4. **All trap data** will be deleted

---

## 💾 Data Management Details

### Export Features
- **Automatic Downloads Folder**: Files save to public Downloads
- **Versioned Filenames**: Includes app version and timestamp
- **Cross-Device Compatible**: Works between different Android devices
- **Complete Data Export**: All trap information included
- **Missing/Damage Data**: Includes condition tracking

### Import Features
- **Smart ID Generation**: Avoids conflicts using QR code hashes
- **Schema Migration**: Handles database version differences
- **Type Conversion**: Automatically converts data types
- **Merge Functionality**: Combines with existing data
- **Validation**: Ensures file integrity

### Data Structure
Each trap record contains:
- **ID**: Unique identifier (QR code-based)
- **QR Code**: Scanned QR code data
- **Location**: GPS coordinates (latitude, longitude)
- **Timestamp**: Date/time of scan
- **Notes**: Optional text notes
- **Location Name**: Custom location identifier
- **Status**: Deployed/Harvested
- **Missing**: Boolean flag for missing traps
- **Damaged**: Boolean flag for damaged traps

---

## 🔧 Troubleshooting

### Common Issues & Solutions

#### Location Problems
**Issue**: GPS not working or inaccurate
**Solutions**:
1. Check if location services are enabled
2. Grant location permissions to the app
3. Move to an area with clear sky view
4. Wait a few moments for GPS lock
5. Restart the app if needed

#### QR Scanner Issues
**Issue**: QR codes not scanning
**Solutions**:
1. Ensure camera permission is granted
2. Clean camera lens
3. Improve lighting conditions
4. Hold camera steady at appropriate distance
5. Ensure QR code is not damaged or faded

#### Import/Export Problems
**Issue**: Cannot export or import data
**Solutions**:
1. Check storage permissions
2. Ensure sufficient storage space
3. Verify file format (.db extension)
4. Try different storage location
5. Restart device and retry

#### Performance Issues
**Issue**: App running slowly
**Solutions**:
1. Close other apps running in background
2. Clear app cache
3. Check available storage space
4. Restart the app
5. Update to latest version

### Error Messages

**"Location permissions denied"**
- Go to Settings → Apps → OLTrap Mapping → Permissions
- Enable Location permission

**"Camera permissions denied"**
- Go to Settings → Apps → OLTrap Mapping → Permissions
- Enable Camera permission

**"Storage permissions required"**
- Grant storage permissions when prompted
- Enable access to Downloads folder

**"Database import failed"**
- Verify file is valid .db format
- Check file size (should not be corrupted)
- Ensure sufficient storage space

---

## 💡 Tips & Best Practices

### Field Work Tips

#### Before Going to Field
1. **Fully charge device** - GPS and camera use battery quickly
2. **Test all functions** - QR scanner, GPS, map
3. **Clear storage space** - Ensure room for new data
4. **Update app** - Use latest version for best performance

#### During Field Work
1. **Scan in good lighting** - Bright, indirect light works best
2. **Keep camera steady** - Use both hands if possible
3. **Take notes immediately** - Add context while fresh
4. **Backup regularly** - Export data after each session
5. **Check GPS accuracy** - Ensure coordinates are precise

#### Data Management
1. **Use consistent naming** - Standardize location names
2. **Add meaningful notes** - Include relevant context
3. **Update status promptly** - Mark harvested traps quickly
4. **Export frequently** - Backup after significant changes
5. **Validate data** - Review imports for accuracy

### Best Practices

#### QR Code Scanning
- **Distance**: 6-12 inches from QR code
- **Angle**: Perpendicular to QR code surface
- **Lighting**: Avoid glare and shadows
- **Speed**: Pause briefly on each QR code
- **Quality**: Ensure QR codes are clean and undamaged

#### GPS Accuracy
- **Wait for lock**: Allow 10-30 seconds for GPS stabilization
- **Open sky view**: Avoid buildings and trees when possible
- **Check accuracy**: Look for GPS accuracy indicators
- **Multiple readings**: Take multiple readings if uncertain
- **Manual override**: Enter coordinates manually if needed

#### Data Organization
- **Location hierarchy**: Use logical location naming
- **Date tracking**: Include dates in notes when relevant
- **Status consistency**: Apply status rules uniformly
- **Regular cleanup**: Remove invalid or duplicate entries
- **Documentation**: Keep field notes separate from app notes

---

## ❓ Frequently Asked Questions

### General Questions

**Q: What is OLTrap Mapping?**
A: A mobile app for tracking Oriental Leafhopper trap locations using GPS and QR codes.

**Q: Is the app free to use?**
A: Yes, the app is completely free with no ads or in-app purchases.

**Q: Does it work offline?**
A: Basic functions work offline, but GPS and map tiles require internet connection.

**Q: Can I use it on multiple devices?**
A: Yes, export/import functionality allows data sharing between devices.

### Technical Questions

**Q: What GPS accuracy can I expect?**
A: Typically 5-10 meters with clear sky view. Accuracy varies by device and conditions.

**Q: How much storage does the app use?**
A: The app uses ~50MB, plus additional space for trap data (usually <10MB for thousands of traps).

**Q: Can I export data to other formats?**
A: Currently exports as SQLite database (.db) for maximum compatibility.

**Q: Is my data secure?**
A: Data is stored locally on your device. Export files are not encrypted.

### Usage Questions

**Q: How do I mark a trap as missing or damaged?**
A: Currently, these fields are set during import or through database editing.

**Q: Can I edit trap locations after scanning?**
A: Yes, tap on any trap marker to view and edit details.

**Q: What happens if I scan the same QR code twice?**
A: The app will update the existing trap record rather than create duplicates.

**Q: Can I delete individual traps?**
A: Currently, individual deletion is not available, but you can clear all data.

### Troubleshooting Questions

**Q: Why won't my GPS work?**
A: Check location permissions, ensure GPS is enabled, and move to an area with better satellite reception.

**Q: Why can't I scan QR codes?**
A: Ensure camera permission is granted, clean the lens, and improve lighting conditions.

**Q: Why did my import fail?**
A: Verify the file is a valid .db format, check storage permissions, and ensure sufficient space.

---

## 📞 Support & Contact

### Getting Help
- **Email Support**: [support@oltrap-mapping.com]
- **GitHub Issues**: [https://github.com/mx-dln/oltrap_mapping/issues]
- **User Community**: [https://github.com/mx-dln/oltrap_mapping/discussions]

### Reporting Issues
When reporting problems, please include:
1. **App version**: Check in Settings → About
2. **Device model**: Android/iOS device information
3. **OS version**: Android or iOS version number
4. **Error message**: Exact text of any error
5. **Steps to reproduce**: Detailed description of what leads to the issue
6. **Expected vs actual**: What you expected vs what actually happened

### Feature Requests
We welcome suggestions for improvements:
1. **Submit via GitHub**: Use the "Discussions" tab
2. **Provide details**: Explain the use case and benefits
3. **Consider feasibility**: Note any technical constraints
4. **Prioritize needs**: Indicate urgency/importance

---

## 📚 Appendix

### Version History

**v1.1.0** (Current)
- ✅ Enhanced export to Downloads folder
- ✅ Added missing/damage statistics
- ✅ Fixed database import/export issues
- ✅ Improved cross-device compatibility
- ✅ Added versioned export filenames
- ✅ Enhanced UI with better animations

**v1.0.0**
- ✅ Initial release with core features
- ✅ Interactive map with trap visualization
- ✅ QR code scanning and trap management
- ✅ Location history and statistics
- ✅ Settings with import/export functionality

### Technical Specifications

**Performance**:
- Startup time: <3 seconds
- QR scan recognition: <1 second
- GPS lock: 10-30 seconds (typical)
- Map rendering: 60 FPS
- Database operations: <100ms for 1000 records

**Compatibility**:
- Android: 5.0+ (API 21+)
- iOS: 11.0+
- RAM: Minimum 2GB recommended
- Storage: Minimum 50MB free space

**Data Limits**:
- Maximum traps: Limited by device storage
- QR code length: Up to 200 characters
- Location name: Up to 100 characters
- Notes: Up to 500 characters
- GPS accuracy: 5-10 meters typical

### Keyboard Shortcuts & Gestures

**Map Screen**:
- **Pinch**: Zoom in/out
- **Drag**: Pan map
- **Tap**: Select trap
- **Pull down**: Refresh data
- **Long press**: (Future feature)

**QR Scanner**:
- **Tap to focus**: Manual camera focus
- **Volume buttons**: (Future feature)
- **Back button**: Exit scanner

**General**:
- **Swipe left/right**: Navigate between tabs
- **Back button**: Navigate back
- **Menu button**: Open app options

---

## 🏷️ Quick Reference

### Emergency Procedures

**Data Loss Prevention**:
1. Export data before major app updates
2. Keep backup copies in multiple locations
3. Test imports before clearing original data
4. Document any custom procedures

**Field Emergency**:
1. Use paper backup if device fails
2. Note GPS coordinates manually
3. Take photos of QR codes
4. Transfer data when device is available

### Quick Commands

**Export Data**: Settings → Export Database  
**Import Data**: Settings → Import Database  
**Clear Data**: Settings → Clear All Data  
**Refresh Map**: Pull down on map screen  
**Search Traps**: Tap search bar on map  
**Filter Status**: Tap filter icon on map  

### Important Numbers

- **GPS Accuracy Target**: <10 meters
- **QR Scan Distance**: 6-12 inches
- **Recommended Battery**: >50% for field work
- **Storage Space**: Minimum 50MB free
- **Data Backup Frequency**: Weekly or after major changes

---

**© 2024 OLTrap Mapping Project**  
*Built with ❤️ using Flutter for Agricultural Research*

---

*This manual is for version 1.1.0. Some features may vary based on device capabilities and app updates.*
