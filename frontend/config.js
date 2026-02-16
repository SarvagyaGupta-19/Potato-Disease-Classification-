// Configuration for different environments
const CONFIG = {
    development: {
        BACKEND_URL: 'http://localhost:8000',
        API_TIMEOUT: 30000,
        ENABLE_ANALYTICS: false
    },
    production: {
        // TODO: Replace with your actual Render backend URL after deployment
        BACKEND_URL: 'https://potato-disease-backend-latest.onrender.com',
        API_TIMEOUT: 30000,
        ENABLE_ANALYTICS: true
    }
};

// Auto-detect environment based on hostname
const isLocalhost = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';
const ENVIRONMENT = isLocalhost ? 'development' : 'production';

// Export active configuration globally
const APP_CONFIG = CONFIG[ENVIRONMENT];

console.log(`🚀 Running in ${ENVIRONMENT} mode`);
console.log(`📡 API URL: ${APP_CONFIG.BACKEND_URL}`);
