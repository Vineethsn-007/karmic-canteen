import { StrictMode, Suspense } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import './i18n/i18n' // Initialize i18n multilingual support
import App from './App.jsx'

// Loading fallback component
const LoadingFallback = () => (
  <div style={{
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: '100vh',
    background: 'linear-gradient(135deg, #ffffff 0%, #f9fafb 100%)'
  }}>
    <div style={{
      textAlign: 'center',
      color: '#4a5568'
    }}>
      <div style={{
        width: '60px',
        height: '60px',
        border: '3px solid rgba(0, 0, 0, 0.1)',
        borderTopColor: '#0066cc',
        borderRadius: '50%',
        animation: 'spin 1s linear infinite',
        margin: '0 auto 16px'
      }}></div>
      <p>Loading...</p>
    </div>
  </div>
);

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <Suspense fallback={<LoadingFallback />}>
      <App />
    </Suspense>
  </StrictMode>,
)
