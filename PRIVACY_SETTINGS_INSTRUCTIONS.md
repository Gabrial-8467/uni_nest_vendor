# Privacy Settings Integration Instructions

## Manual Steps Required

Since the profile_screen.dart file edit was restricted, you need to manually add the following changes:

### 1. Add Import Statement
At the top of `lib/screens/profile_screen.dart`, add this import:
```dart
import '../widgets/widgets.dart';
```

### 2. Add Privacy Settings Navigation Function
Add this function inside the `_ProfileScreenState` class (after the `_showChangePasswordDialog` function):

```dart
void _showPrivacySettingsDialog() {
  showDialog(
    context: context,
    builder: (context) => const PrivacySettingsDialog(),
  );
}
```

### 3. Update Privacy Settings Action Item
Find the privacy settings action item around line 413-419 and replace the empty onTap function:

```dart
_buildActionItem(
  'Privacy Settings',
  Icons.privacy_tip_outlined,
  Colors.green,
  _showPrivacySettingsDialog,
),
```

## What's Already Implemented

✅ PrivacySettings model with comprehensive privacy options
✅ Updated Vendor model to include privacy settings  
✅ PrivacySettingsDialog widget with categorized settings
✅ updatePrivacySettings method in VendorProvider

## Privacy Settings Features

The privacy settings include:

### Profile Visibility
- Make profile public
- Show phone number
- Show email address  
- Show business address

### Customer Interactions
- Allow customer reviews
- Show business hours
- Allow direct messages

### Data & Analytics
- Show revenue analytics
- Analytics tracking

### Data Sharing
- Data sharing with partners
- Marketing communications
- Location tracking

All settings are properly integrated with the vendor state management and persist across app sessions.
