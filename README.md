Karmic Canteen App

A comprehensive meal management and event broadcasting system for Karmic employees, built with Flutter for mobile and web frontends. Enables meal selection (daily & weekly), work mode management, festival/event broadcasts with RSVP, reports, analytics, and food donation features.

Table of Contents
About The Project
Key Features
Tech Stack
Getting Started
Configuration
Usage
Folder Structure
Contributing
License

About The Project:
Karmic Canteen App helps employees conveniently plan their meals with options to select daily or weekly meals including breakfast, lunch, snacks, and dinner. It supports tracking work location (office or WFH), sends meal reminders, and provides admins with comprehensive analytics. The app also manages festival/event broadcasts with RSVP support to foster employee engagement.

Key Features:
Daily & Weekly Meal Selection: Employees can choose meals day-by-day or bulk plan weekly.
Work Mode Management: Mark work-from-office or WFH per day to control meal selections.
Meal Reports & Analytics: Admins get detailed participant stats and downloadable CSVs.
Festival & Event Broadcasts: Admins send notifications about celebrations with RSVP tracking.
Food Donation Drive: Manage donations to NGOs directly via the app.
Internationalization: Supports multiple languages including English, हिंदी﻿, and ಕನ್ನಡ﻿.
Responsive Flutter Frontend: Separate mobile (flutter-frontend) and web (web-frontend) codebases.

Tech Stack:
Flutter (Dart) for frontend (mobile and web)
Firebase Firestore for backend data and real-time updates
Firebase Cloud Messaging for notifications
Provider for state management
intl for date/time formatting
fl_chart for analytics visualization

Getting Started:
Prerequisites:
Flutter SDK (latest stable)
Compatible IDE (VS Code, Android Studio)
Firebase account with Firestore and FCM setup
Clone the Repositories:

bash
git clone https://github.com/your-username/flutter-frontend.git
git clone https://github.com/your-username/web-frontend.git

Setup & Run:
For mobile frontend:
bash
cd flutter-frontend
flutter pub get
flutter run

For web frontend:
bash
cd web-frontend
flutter pub get
flutter run -d chrome

Configuration:
Configure Firebase in both projects with your project’s config files (google-services.json for Android, GoogleService-Info.plist for iOS, and Firebase web config).
Set meal deadlines and notification timings in Firestore settings collection.
Adjust admin and employee roles in Firestore users collection.

Usage:
Employees log in with Karmic credentials.
Select daily or weekly meals; toggle work mode.
Admins manage menus, view analytics, generate reports, broadcast festivals, and coordinate food donations.
Notifications remind employees before meal selection deadlines.

Folder Structure:
/flutter-frontend
├── lib
│   ├── models
│   ├── providers
│   ├── screens
│   ├── services
│   └── widgets
└── pubspec.yaml

/web-frontend
├── lib
│   ├── models
│   ├── providers
│   ├── screens
│   ├── services
│   └── widgets
└── pubspec.yaml

Contributing:
Contributions are welcome! Please:
Fork the repository
Create a feature branch (git checkout -b feature/NewFeature)
Commit your changes (git commit -m 'Add new feature')
Push the branch (git push origin feature/NewFeature)
Create a Pull Request
Refer to issues for reporting bugs or new feature requests.
