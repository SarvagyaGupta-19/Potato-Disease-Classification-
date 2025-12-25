// Configuration for different environments
const CONFIG = {
    development: {
        BACKEND_URL: 'http://localhost:8000',
        API_TIMEOUT: 30000,
        ENABLE_ANALYTICS: false
    },
    production: {
        BACKEND_URL: window.location.origin.includes('localhost') 
            ? 'http://localhost:8000' 
            : 'https://potato-disease-classification-production.up.railway.app',
        API_TIMEOUT: 30000,
        ENABLE_ANALYTICS: true
    }
};

// Auto-detect environment
const ENVIRONMENT = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1' 
    ? 'development' 
    : 'production';

// Export active configuration
const APP_CONFIG = CONFIG[ENVIRONMENT];

console.log(`🚀 Running in ${ENVIRONMENT} mode`);
console.log(`📡 API URL: ${APP_CONFIG.BACKEND_URL}`);
