/**
 * LanguageSelector Component
 * Provides UI for users to switch between supported languages
 * Persists selection in localStorage via i18next
 * Supports English, Spanish, and Hindi with proper RTL handling
 */

import React from 'react';
import { useTranslation } from 'react-i18next';
import './LanguageSelector.css';

const LanguageSelector = () => {
  const { i18n } = useTranslation();

  const languages = [
    { code: 'en', name: '🇺🇸 English', label: 'English' },
    { code: 'es', name: '🇪🇸 Español', label: 'Spanish' },
    { code: 'hi', name: '🇮🇳 हिन्दी', label: 'Hindi' }
  ];

  const handleLanguageChange = (langCode) => {
    i18n.changeLanguage(langCode);
    // Apply RTL/LTR based on language
    if (langCode === 'hi' || langCode === 'ar') {
      document.documentElement.dir = 'rtl';
      document.documentElement.lang = langCode;
    } else {
      document.documentElement.dir = 'ltr';
      document.documentElement.lang = langCode;
    }
  };

  return (
    <div className="language-selector">
      <div className="language-dropdown">
        <select
          value={i18n.language}
          onChange={(e) => handleLanguageChange(e.target.value)}
          className="language-select"
          aria-label="Select Language"
        >
          {languages.map((lang) => (
            <option key={lang.code} value={lang.code}>
              {lang.label}
            </option>
          ))}
        </select>
      </div>
    </div>
  );
};

export default LanguageSelector;
