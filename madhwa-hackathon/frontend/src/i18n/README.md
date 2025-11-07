# 🌍 Internationalization (i18n) System

## Overview

This directory contains the complete internationalization setup for the Karmic Canteen application using `react-i18next`.

## Directory Structure

```
i18n/
├── config.js                 # Main i18n configuration
├── locales/                  # Translation files
│   ├── en/
│   │   └── translation.json  # English translations
│   ├── hi/
│   │   └── translation.json  # Hindi translations
│   └── kn/
│       └── translation.json  # Kannada translations
└── README.md                 # This file
```

## Supported Languages

| Code | Language | Native Name | Flag |
|------|----------|-------------|------|
| en   | English  | English     | 🇬🇧   |
| hi   | Hindi    | हिंदी       | 🇮🇳   |
| kn   | Kannada  | ಕನ್ನಡ       | 🇮🇳   |

## Features

### ✅ Automatic Language Detection
- Detects browser language on first visit
- Falls back to English if unsupported
- Remembers user's choice in localStorage

### ✅ Dynamic Language Switching
- Instant language switching without page reload
- Smooth transitions
- Updates HTML lang and dir attributes

### ✅ Robust Error Handling
- Graceful fallback for missing keys
- Returns key name if translation not found
- Logs warnings in development mode
- Never crashes the application

### ✅ Interpolation Support
```javascript
// translation.json
"greeting": "Hello, {{name}}!"

// Component
t('greeting', { name: 'John' })  // "Hello, John!"
```

### ✅ Pluralization Support
```javascript
// translation.json
"items": "{{count}} item",
"items_plural": "{{count}} items"

// Component
t('items', { count: 1 })  // "1 item"
t('items', { count: 5 })  // "5 items"
```

### ✅ Context-Based Translations
```javascript
// translation.json
"friend": "A friend",
"friend_male": "A boyfriend",
"friend_female": "A girlfriend"

// Component
t('friend', { context: 'male' })  // "A boyfriend"
```

### ✅ RTL Support
Automatically handles right-to-left languages by updating `dir` attribute.

## Usage

### In Components

```jsx
import { useTranslation } from 'react-i18next';

function MyComponent() {
  const { t, i18n } = useTranslation();
  
  return (
    <div>
      <h1>{t('common.appName')}</h1>
      <p>{t('employee.dashboard.subtitle')}</p>
      <button onClick={() => i18n.changeLanguage('hi')}>
        Switch to Hindi
      </button>
    </div>
  );
}
```

### With Helper Functions

```javascript
import { changeLanguage, getCurrentLanguage, getLanguageInfo } from './i18n/config';

// Change language
await changeLanguage('hi');

// Get current language
const currentLang = getCurrentLanguage();  // 'en'

// Get language info
const langInfo = getLanguageInfo('hi');
// { code: 'hi', name: 'Hindi', nativeName: 'हिंदी', flag: '🇮🇳', dir: 'ltr' }
```

## Translation Key Structure

### Naming Convention
Use dot notation for nested keys:
```
section.subsection.key
```

### Current Structure

```
common.*              # Common UI elements
├── appName
├── loading
├── error
├── success
├── save
└── cancel

auth.*                # Authentication
├── login
├── logout
├── email
├── password
└── errors.*

navbar.*              # Navigation
├── dashboard
├── menu
├── reports
└── settings

employee.*            # Employee features
└── dashboard.*
    ├── title
    ├── subtitle
    └── meals.*

admin.*               # Admin features
├── dashboard.*
├── menuManager.*
├── reports.*
└── settings.*

errors.*              # Error messages
validation.*          # Form validation
time.*                # Time-related
language.*            # Language switcher
```

## Adding New Translations

### Step 1: Add to English (Base Language)

Edit `locales/en/translation.json`:
```json
{
  "myFeature": {
    "title": "My Feature",
    "description": "This is my feature",
    "action": "Click Here"
  }
}
```

### Step 2: Add to Other Languages

Edit `locales/hi/translation.json`:
```json
{
  "myFeature": {
    "title": "मेरी सुविधा",
    "description": "यह मेरी सुविधा है",
    "action": "यहाँ क्लिक करें"
  }
}
```

Edit `locales/kn/translation.json`:
```json
{
  "myFeature": {
    "title": "ನನ್ನ ವೈಶಿಷ್ಟ್ಯ",
    "description": "ಇದು ನನ್ನ ವೈಶಿಷ್ಟ್ಯ",
    "action": "ಇಲ್ಲಿ ಕ್ಲಿಕ್ ಮಾಡಿ"
  }
}
```

### Step 3: Use in Component

```jsx
<div>
  <h1>{t('myFeature.title')}</h1>
  <p>{t('myFeature.description')}</p>
  <button>{t('myFeature.action')}</button>
</div>
```

## Adding a New Language

### 1. Create Translation File

Create `locales/[code]/translation.json` with all required keys.

### 2. Update config.js

```javascript
// Import
import translationNEW from './locales/new/translation.json';

// Add to resources
const resources = {
  // ... existing
  new: { translation: translationNEW }
};

// Add to SUPPORTED_LANGUAGES
export const SUPPORTED_LANGUAGES = [
  // ... existing
  {
    code: 'new',
    name: 'New Language',
    nativeName: 'Native Name',
    flag: '🏳️',
    dir: 'ltr'  // or 'rtl'
  }
];

// Add to supportedLngs
supportedLngs: ['en', 'hi', 'kn', 'new']
```

## Best Practices

### 1. Always Use Translation Keys
```jsx
// ❌ Bad
<button>Save</button>

// ✅ Good
<button>{t('common.save')}</button>
```

### 2. Use Descriptive Keys
```jsx
// ❌ Bad
{t('btn1')}

// ✅ Good
{t('employee.dashboard.saveButton')}
```

### 3. Provide Fallback Text
```jsx
{t('key', 'Default text if key missing')}
```

### 4. Group Related Keys
```json
{
  "employee": {
    "dashboard": {
      "title": "...",
      "subtitle": "...",
      "actions": {
        "save": "...",
        "cancel": "..."
      }
    }
  }
}
```

### 5. Use Interpolation for Dynamic Content
```jsx
// ❌ Bad
{`Welcome, ${userName}!`}

// ✅ Good
{t('welcome', { name: userName })}
```

## Configuration Options

### Language Detection Order
```javascript
order: ['localStorage', 'navigator', 'htmlTag']
```
1. Check localStorage first
2. Then browser language
3. Finally HTML lang attribute

### Fallback Language
```javascript
fallbackLng: 'en'
```
Always falls back to English if translation missing.

### Debug Mode
```javascript
debug: process.env.NODE_ENV === 'development'
```
Logs translation issues in development only.

### Caching
```javascript
caches: ['localStorage']
```
Saves language preference in localStorage.

## Error Handling

### Missing Translation Key
```jsx
{t('nonexistent.key')}
// Returns: "nonexistent.key"
// Logs warning in dev mode
```

### Failed Resource Loading
```javascript
i18n.on('failedLoading', (lng, ns, msg) => {
  console.error(`Failed to load ${lng} ${ns}: ${msg}`);
});
```

### Language Change Error
```javascript
try {
  await changeLanguage('invalid');
} catch (error) {
  console.error('Language change failed:', error);
  // App continues with current language
}
```

## Performance

### Lazy Loading
Translations are loaded asynchronously with Suspense:
```jsx
<Suspense fallback={<Loading />}>
  <App />
</Suspense>
```

### Caching
- Language preference cached in localStorage
- Translation resources cached in memory
- No network requests after initial load

### Bundle Size
- react-i18next: ~10KB gzipped
- i18next: ~15KB gzipped
- Translation files: ~5-10KB each

## Testing

### Test Language Detection
```javascript
// Clear cache
localStorage.clear();

// Set browser language
Object.defineProperty(navigator, 'language', {
  value: 'hi',
  writable: true
});

// Reload and check
console.log(i18n.language);  // Should be 'hi'
```

### Test Missing Keys
```javascript
// Use non-existent key
const result = t('fake.key');
console.log(result);  // "fake.key"

// Check console for warning
```

### Test Language Switching
```javascript
// Change language
await changeLanguage('kn');

// Verify
console.log(i18n.language);  // 'kn'
console.log(document.documentElement.lang);  // 'kn'
console.log(localStorage.getItem('i18nextLng'));  // 'kn'
```

## Troubleshooting

### Issue: Translations not showing

**Check:**
1. Is i18n initialized? `console.log(i18n.isInitialized)`
2. Is component using hook? `const { t } = useTranslation()`
3. Are keys correct? Check translation files

### Issue: Language not persisting

**Check:**
1. localStorage: `localStorage.getItem('i18nextLng')`
2. Browser not blocking localStorage
3. No errors in console

### Issue: Component not re-rendering

**Solution:**
```jsx
// Make sure you're destructuring t from the hook
const { t } = useTranslation();  // ✅ Correct

// Not this
const t = i18n.t;  // ❌ Won't trigger re-render
```

## Resources

- [react-i18next Documentation](https://react.i18next.com/)
- [i18next Documentation](https://www.i18next.com/)
- [Translation Best Practices](https://www.i18next.com/principles/fallback)

## Support

For issues or questions:
1. Check this README
2. Check main implementation guide: `I18N_IMPLEMENTATION_GUIDE.md`
3. Review example components
4. Check browser console for errors

---

**Version**: 1.0.0  
**Last Updated**: November 3, 2024  
**Maintainer**: Development Team
