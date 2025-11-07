/**
 * i18n Configuration
 * 
 * This file configures react-i18next for multilingual support.
 * Supports: English (en), Hindi (hi), Kannada (kn)
 * 
 * Features:
 * - Automatic language detection
 * - Fallback to English if language not supported
 * - Dynamic resource loading
 * - Interpolation and pluralization support
 * - Graceful error handling
 */

import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import LanguageDetector from 'i18next-browser-languagedetector';

// Import translation resources
import translationEN from './locales/en/translation.json';
import translationHI from './locales/hi/translation.json';
import translationKN from './locales/kn/translation.json';

// Translation resources
const resources = {
  en: {
    translation: translationEN
  },
  hi: {
    translation: translationHI
  },
  kn: {
    translation: translationKN
  }
};

// Supported languages configuration
export const SUPPORTED_LANGUAGES = [
  {
    code: 'en',
    name: 'English',
    nativeName: 'English',
    flag: '🇬🇧',
    dir: 'ltr'
  },
  {
    code: 'hi',
    name: 'Hindi',
    nativeName: 'हिंदी',
    flag: '🇮🇳',
    dir: 'ltr'
  },
  {
    code: 'kn',
    name: 'Kannada',
    nativeName: 'ಕನ್ನಡ',
    flag: '🇮🇳',
    dir: 'ltr'
  }
];

// Language detection options
const detectionOptions = {
  // Order of detection methods
  order: ['localStorage', 'navigator', 'htmlTag'],
  
  // Keys to lookup language from
  lookupLocalStorage: 'i18nextLng',
  
  // Cache user language
  caches: ['localStorage'],
  
  // Exclude certain languages from detection
  excludeCacheFor: ['cimode'],
  
  // Check for supported languages only
  checkWhitelist: true
};

// Initialize i18next
i18n
  // Detect user language
  .use(LanguageDetector)
  
  // Pass the i18n instance to react-i18next
  .use(initReactI18next)
  
  // Initialize i18next
  .init({
    resources,
    
    // Fallback language if translation not found
    fallbackLng: 'en',
    
    // Supported languages
    supportedLngs: ['en', 'hi', 'kn'],
    
    // Language to use if no language detected
    lng: undefined, // Let detector decide
    
    // Debug mode (set to false in production)
    debug: process.env.NODE_ENV === 'development',
    
    // Namespace configuration
    ns: ['translation'],
    defaultNS: 'translation',
    
    // Key separator (use . for nested keys)
    keySeparator: '.',
    
    // Interpolation options
    interpolation: {
      escapeValue: false, // React already escapes values
      formatSeparator: ','
    },
    
    // React specific options
    react: {
      useSuspense: true, // Use Suspense for async loading
      bindI18n: 'languageChanged loaded',
      bindI18nStore: 'added removed',
      transEmptyNodeValue: '',
      transSupportBasicHtmlNodes: true,
      transKeepBasicHtmlNodesFor: ['br', 'strong', 'i', 'p']
    },
    
    // Detection options
    detection: detectionOptions,
    
    // Missing key handler (for development)
    saveMissing: process.env.NODE_ENV === 'development',
    missingKeyHandler: (lngs, ns, key, fallbackValue) => {
      if (process.env.NODE_ENV === 'development') {
        console.warn(`Missing translation key: ${key} for language: ${lngs[0]}`);
      }
    },
    
    // Parsing options
    parseMissingKeyHandler: (key) => {
      // Return key as fallback if translation missing
      return key;
    }
  });

// Error handling for missing translations
i18n.on('failedLoading', (lng, ns, msg) => {
  console.error(`Failed to load ${lng} ${ns}: ${msg}`);
});

// Log language changes in development
if (process.env.NODE_ENV === 'development') {
  i18n.on('languageChanged', (lng) => {
    console.log(`Language changed to: ${lng}`);
    
    // Update HTML lang attribute
    document.documentElement.lang = lng;
    
    // Update HTML dir attribute for RTL support
    const language = SUPPORTED_LANGUAGES.find(l => l.code === lng);
    if (language) {
      document.documentElement.dir = language.dir;
    }
  });
}

/**
 * Helper function to get language info
 * @param {string} code - Language code
 * @returns {object} Language information
 */
export const getLanguageInfo = (code) => {
  return SUPPORTED_LANGUAGES.find(lang => lang.code === code) || SUPPORTED_LANGUAGES[0];
};

/**
 * Helper function to change language
 * @param {string} languageCode - Language code to switch to
 */
export const changeLanguage = async (languageCode) => {
  try {
    await i18n.changeLanguage(languageCode);
    
    // Update HTML attributes
    document.documentElement.lang = languageCode;
    const language = getLanguageInfo(languageCode);
    document.documentElement.dir = language.dir;
    
    // Store in localStorage
    localStorage.setItem('i18nextLng', languageCode);
    
    return true;
  } catch (error) {
    console.error('Error changing language:', error);
    return false;
  }
};

/**
 * Helper function to get current language
 * @returns {string} Current language code
 */
export const getCurrentLanguage = () => {
  return i18n.language || 'en';
};

/**
 * Helper function to check if language is supported
 * @param {string} code - Language code
 * @returns {boolean} True if supported
 */
export const isLanguageSupported = (code) => {
  return SUPPORTED_LANGUAGES.some(lang => lang.code === code);
};

export default i18n;
