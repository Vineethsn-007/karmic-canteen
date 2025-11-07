/**
 * Language Switcher Component
 * 
 * A dropdown component that allows users to switch between supported languages.
 * Features:
 * - Displays current language with flag
 * - Shows all supported languages
 * - Smooth transitions
 * - Error handling
 * - Accessible keyboard navigation
 */

import React, { useState, useRef, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { SUPPORTED_LANGUAGES, changeLanguage, getCurrentLanguage } from '../../i18n/i18n';
import './LanguageSwitcher.css';

const LanguageSwitcher = () => {
  const { t, i18n } = useTranslation();
  const [isOpen, setIsOpen] = useState(false);
  const [isChanging, setIsChanging] = useState(false);
  const dropdownRef = useRef(null);

  // Get current language info
  const currentLang = SUPPORTED_LANGUAGES.find(
    lang => lang.code === i18n.language
  ) || SUPPORTED_LANGUAGES[0];

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Handle language change
  const handleLanguageChange = async (languageCode) => {
    if (languageCode === i18n.language || isChanging) {
      setIsOpen(false);
      return;
    }

    try {
      setIsChanging(true);
      const success = await changeLanguage(languageCode);
      
      if (success) {
        // Close dropdown after successful change
        setTimeout(() => {
          setIsOpen(false);
          setIsChanging(false);
        }, 300);
      } else {
        console.error('Failed to change language');
        setIsChanging(false);
      }
    } catch (error) {
      console.error('Error changing language:', error);
      setIsChanging(false);
    }
  };

  // Handle keyboard navigation
  const handleKeyDown = (event, languageCode) => {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      handleLanguageChange(languageCode);
    } else if (event.key === 'Escape') {
      setIsOpen(false);
    }
  };

  return (
    <div className="language-switcher" ref={dropdownRef}>
      <button
        className="language-switcher-button"
        onClick={() => setIsOpen(!isOpen)}
        aria-label={t('language.select')}
        aria-expanded={isOpen}
        aria-haspopup="true"
        disabled={isChanging}
      >
        <span className="language-flag" role="img" aria-label={currentLang.name}>
          {currentLang.flag}
        </span>
        <span className="language-name">{currentLang.nativeName}</span>
        <span className={`language-arrow ${isOpen ? 'open' : ''}`}>▼</span>
      </button>

      {isOpen && (
        <div className="language-dropdown" role="menu">
          {SUPPORTED_LANGUAGES.map((language) => {
            const isActive = language.code === i18n.language;
            
            return (
              <button
                key={language.code}
                className={`language-option ${isActive ? 'active' : ''}`}
                onClick={() => handleLanguageChange(language.code)}
                onKeyDown={(e) => handleKeyDown(e, language.code)}
                role="menuitem"
                aria-current={isActive ? 'true' : 'false'}
                disabled={isChanging}
              >
                <span className="language-flag" role="img" aria-label={language.name}>
                  {language.flag}
                </span>
                <div className="language-info">
                  <span className="language-native-name">{language.nativeName}</span>
                  <span className="language-english-name">{language.name}</span>
                </div>
                {isActive && (
                  <span className="language-check" aria-label="Selected">✓</span>
                )}
              </button>
            );
          })}
        </div>
      )}

      {isChanging && (
        <div className="language-loading" aria-live="polite">
          <span className="loading-spinner"></span>
        </div>
      )}
    </div>
  );
};

export default LanguageSwitcher;
