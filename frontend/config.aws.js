// AWS Production Configuration
// Updated for AWS deployment with ALB/CloudFront

const CONFIG = {
    development: {
        BACKEND_URL: 'http://localhost:8000',
        API_TIMEOUT: 30000,
        ENABLE_ANALYTICS: false,
        DEBUG: true
    },
    production: {
        // Option 1: Set this to your ALB URL after backend deployment
        BACKEND_URL: 'http://YOUR-ALB-DNS-HERE.us-east-1.elb.amazonaws.com',
        
        // Option 2: Or use custom domain if configured
        // BACKEND_URL: 'https://api.yourdomain.com',
        
        API_TIMEOUT: 30000,
        ENABLE_ANALYTICS: true,
        DEBUG: false
    }
};

// Auto-detect environment
const ENVIRONMENT = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1' 
    ? 'development' 
    : 'production';

// Export active configuration
const APP_CONFIG = CONFIG[ENVIRONMENT];

// Log configuration (only in development)
if (ENVIRONMENT === 'development') {
    console.log(`🚀 Running in ${ENVIRONMENT} mode`);
    console.log(`📡 API URL: ${APP_CONFIG.BACKEND_URL}`);
}

// Validate production configuration
if (ENVIRONMENT === 'production' && APP_CONFIG.BACKEND_URL.includes('YOUR-ALB-DNS-HERE')) {
    console.error('⚠️ Production backend URL not configured! Update frontend/config.js with your ALB URL.');
}
