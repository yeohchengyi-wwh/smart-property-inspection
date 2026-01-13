# 🏠 Smart Property Inspection

Smart Property Inspection is a mobile application designed to streamline the process of documenting and managing property inspections. This app allows users to capture property details, assess conditions, record GPS locations and attach photographic evidence—all stored locally.

## ✨ Features

* **Dashboard View**: A clean list of all inspections with color-coded rating badges (Excellent, Good, Fair, Poor).
* **Detailed Reports**: View comprehensive details including dates, descriptions and location data.
* **Evidence Capture**: Take photos using the device camera to document issues (supports multiple photos per inspection).
* **Geolocation**: Automatically fetch and save the GPS coordinates of the property.
* **Map Integration**: One-click navigation to the property location using Google Maps.
* **Offline Storage**: All data is persisted locally using SQLite, ensuring access without an internet connection.
* **CRUD Operations**: Full capability to Create, Read, Update and Delete inspection records.

## 🛠 Tech Stack

* **Framework**: [Flutter] (Dart)
* **Local Database**: [sqflite] (SQLite for storage)
* **Key Plugins**:
    * `image_picker`: For capturing photos via camera.
    * `geolocator`: For fetching GPS coordinates.
    * `url_launcher`: For opening external maps.
    * `intl`: For date and time formatting.
    * `shared_preferences`: For simple data storage (e.g., login state).