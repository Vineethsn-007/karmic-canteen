/**
 * Working From Home Component
 * 
 * Displays when user selects "Working from Home"
 * Shows a friendly message and option to change mode
 */

import React from 'react';
import { useTranslation } from 'react-i18next';
import './WorkingFromHome.css';

const WorkingFromHome = ({ onChangeMode, canChange, deadline }) => {
  const { t } = useTranslation();

  return (
    <div className="working-from-home">
      <div className="wfh-card">
        <div className="wfh-icon-container">
          <div className="wfh-icon">🏠</div>
          <div className="wfh-icon-bg"></div>
        </div>

        <h1 className="wfh-title">{t('workingMode.wfhTitle')}</h1>
        <p className="wfh-message">{t('workingMode.wfhMessage')}</p>

        <div className="wfh-info-box">
          <div className="info-item">
            <span className="info-icon">📍</span>
            <div className="info-content">
              <strong>{t('workingMode.location')}</strong>
              <p>{t('workingMode.home')}</p>
            </div>
          </div>

          <div className="info-item">
            <span className="info-icon">🍽️</span>
            <div className="info-content">
              <strong>{t('workingMode.mealStatus')}</strong>
              <p>{t('workingMode.noMealNeeded')}</p>
            </div>
          </div>

          {deadline && (
            <div className="info-item">
              <span className="info-icon">⏰</span>
              <div className="info-content">
                <strong>{t('workingMode.changeUntil')}</strong>
                <p>{deadline}</p>
              </div>
            </div>
          )}
        </div>

        {canChange ? (
          <div className="wfh-actions">
            <button
              className="btn btn-primary btn-full"
              onClick={onChangeMode}
            >
              {t('workingMode.changeToOffice')}
            </button>
            <p className="wfh-help-text">
              💡 {t('workingMode.canChangeHelp')}
            </p>
          </div>
        ) : (
          <div className="wfh-locked">
            <span className="lock-icon">🔒</span>
            <p>{t('workingMode.cannotChange')}</p>
          </div>
        )}

        <div className="wfh-tips">
          <h3>{t('workingMode.tipsTitle')}</h3>
          <ul>
            <li>
              <span className="tip-icon">✅</span>
              {t('workingMode.tip1')}
            </li>
            <li>
              <span className="tip-icon">✅</span>
              {t('workingMode.tip2')}
            </li>
            <li>
              <span className="tip-icon">✅</span>
              {t('workingMode.tip3')}
            </li>
          </ul>
        </div>
      </div>
    </div>
  );
};

export default WorkingFromHome;
