/**
 * Working Mode Selector Component
 * 
 * Prompts users to select their working mode (Office/Home)
 * Shows on first login and can be changed until deadline
 */

import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import './WorkingModeSelector.css';

const WorkingModeSelector = ({ onModeSelect, currentMode, canChange }) => {
  const { t } = useTranslation();
  const [selectedMode, setSelectedMode] = useState(currentMode || null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleModeSelect = (mode) => {
    if (!canChange && currentMode) {
      return; // Can't change after deadline
    }
    setSelectedMode(mode);
  };

  const handleSubmit = async () => {
    if (!selectedMode) return;
    
    setIsSubmitting(true);
    try {
      await onModeSelect(selectedMode);
    } catch (error) {
      console.error('Error setting working mode:', error);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="working-mode-overlay">
      <div className="working-mode-modal">
        <div className="mode-header">
          <div className="mode-icon">🏢</div>
          <h2>{t('workingMode.title')}</h2>
          <p className="mode-subtitle">{t('workingMode.subtitle')}</p>
        </div>

        <div className="mode-options">
          {/* Office Mode */}
          <button
            className={`mode-option ${selectedMode === 'office' ? 'selected' : ''}`}
            onClick={() => handleModeSelect('office')}
            disabled={!canChange && currentMode && currentMode !== 'office'}
          >
            <div className="mode-option-icon">🏢</div>
            <div className="mode-option-content">
              <h3>{t('workingMode.office')}</h3>
              <p>{t('workingMode.officeDesc')}</p>
            </div>
            {selectedMode === 'office' && (
              <div className="mode-check">✓</div>
            )}
          </button>

          {/* Home Mode */}
          <button
            className={`mode-option ${selectedMode === 'home' ? 'selected' : ''}`}
            onClick={() => handleModeSelect('home')}
            disabled={!canChange && currentMode && currentMode !== 'home'}
          >
            <div className="mode-option-icon">🏠</div>
            <div className="mode-option-content">
              <h3>{t('workingMode.home')}</h3>
              <p>{t('workingMode.homeDesc')}</p>
            </div>
            {selectedMode === 'home' && (
              <div className="mode-check">✓</div>
            )}
          </button>
        </div>

        {!canChange && currentMode && (
          <div className="mode-warning">
            <span className="warning-icon">⚠️</span>
            <p>{t('workingMode.deadlinePassed')}</p>
          </div>
        )}

        <div className="mode-actions">
          <button
            className="btn btn-primary btn-full"
            onClick={handleSubmit}
            disabled={!selectedMode || isSubmitting || (!canChange && currentMode)}
          >
            {isSubmitting ? t('common.loading') : t('workingMode.confirm')}
          </button>
          
          {canChange && currentMode && (
            <p className="mode-help-text">
              💡 {t('workingMode.canChange')}
            </p>
          )}
        </div>
      </div>
    </div>
  );
};

export default WorkingModeSelector;
