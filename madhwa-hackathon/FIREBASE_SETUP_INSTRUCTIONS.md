# Firebase Firestore Security Rules Setup

## Error You're Seeing:
```
FirebaseError: Missing or insufficient permissions
```

## Solution: Update Firestore Security Rules

### Option 1: Using Firebase Console (Recommended)

1. **Go to Firebase Console:**
   - Visit: https://console.firebase.google.com/
   - Select your project: `madhwa-hackathon`

2. **Navigate to Firestore Database:**
   - Click on "Firestore Database" in the left sidebar
   - Click on the "Rules" tab at the top

3. **Copy and Paste These Rules:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user is admin
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated() && request.auth.uid == userId;
      allow read: if isAdmin();
      allow write: if isAdmin();
    }
    
    // Menus collection
    match /menus/{menuId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
    
    // Meal Selections collection
    match /mealSelections/{date}/users/{userId} {
      allow read: if isAuthenticated() && request.auth.uid == userId;
      allow write: if isAuthenticated() && request.auth.uid == userId;
      allow read: if isAdmin();
    }
    
    // Working Modes collection
    match /workingModes/{date}/users/{userId} {
      allow read: if isAuthenticated() && request.auth.uid == userId;
      allow write: if isAuthenticated() && request.auth.uid == userId;
      allow read: if isAdmin();
    }
    
    // Settings collection
    match /settings/{settingId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
  }
}
```

4. **Click "Publish"** button to save the rules

5. **Refresh your web app** - The errors should be gone!

---

### Option 2: Quick Fix (Development Only - NOT SECURE)

If you just want to test quickly (NOT for production):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

⚠️ **WARNING:** This allows any authenticated user to read/write everything. Use only for testing!

---

### Option 3: Using Firebase CLI

If you have Firebase CLI installed:

```bash
# Navigate to your project
cd c:\Users\haash\OneDrive\Desktop\karmic-canteen\madhwa-hackathon

# Deploy the rules
firebase deploy --only firestore:rules
```

---

## What These Rules Do:

### ✅ Users Collection
- Users can read their own profile
- Admins can read all profiles
- Only admins can create/update users

### ✅ Menus Collection
- All authenticated users can read menus
- Only admins can create/edit/delete menus

### ✅ Meal Selections
- Users can only read/write their own selections
- Admins can read all selections

### ✅ Working Modes
- Users can only read/write their own working mode
- Admins can read all working modes

### ✅ Settings
- All authenticated users can read settings
- Only admins can update settings

---

## After Updating Rules:

1. ✅ Refresh your web application
2. ✅ Try logging in again
3. ✅ The permission errors should be gone
4. ✅ You should be able to:
   - Select working mode
   - Choose meals
   - Save selections
   - View menus

---

## Troubleshooting:

If errors persist:

1. **Check Authentication:**
   - Make sure you're logged in
   - Check Firebase Console > Authentication > Users

2. **Check User Role:**
   - Go to Firestore Database
   - Check `users` collection
   - Verify your user has `role: "employee"` or `role: "admin"`

3. **Clear Browser Cache:**
   - Hard refresh: `Ctrl + Shift + R` (Windows)
   - Or clear browser cache completely

4. **Check Console:**
   - Open browser DevTools (F12)
   - Check for any other errors

---

## Need Help?

If you still see errors, check:
- Firebase Console > Firestore > Rules tab
- Make sure rules are published
- Wait 1-2 minutes for rules to propagate
