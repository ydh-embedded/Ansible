import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: '{{ app_id }}',
  appName: '{{ app_name }}',
  webDir: 'src',
  bundledWebRuntime: false,
  backgroundColor: '{{ background_color }}',
  
  server: {
    hostname: 'localhost',
    androidScheme: 'https'
  },

  ios: {
    scheme: '{{ project_name | lower | replace("-", "") }}',
    backgroundColor: '{{ background_color }}',
    contentInset: 'automatic',
    scrollEnabled: true,
    allowsLinkPreview: false,
    preferredContentMode: 'mobile'
  },

  android: {
    backgroundColor: '{{ background_color }}',
    allowMixedContent: true,
    captureInput: true,
    webContentsDebuggingEnabled: {% if build_type == 'development' %}true{% else %}false{% endif %}
  },

  plugins: {
    StatusBar: {
      style: 'DEFAULT',
      backgroundColor: '{{ background_color }}',
      overlaysWebView: false
    },
    
    Keyboard: {
      resize: 'ionic',
      resizeOnFullScreen: true
    },
    
    SplashScreen: {
      launchShowDuration: 2000,
      backgroundColor: '{{ background_color }}',
      showSpinner: true,
      spinnerColor: '{{ primary_color }}',
      androidSpinnerStyle: 'small',
      iosSpinnerStyle: 'small'
    },

    App: {
      disallowOverscroll: true
    },

    Haptics: {
      // Haptic feedback configuration
    }{% if enable_analytics %},

    GoogleAnalytics: {
      trackingId: 'GA_TRACKING_ID'
    }{% endif %}{% if enable_backup %},

    Filesystem: {
      androidRequestPermissions: true
    }{% endif %}
  }{% if enable_enterprise %},

  // Enterprise Configuration
  cordova: {
    preferences: {
      ScrollEnabled: 'false',
      BackupWebStorage: 'none',
      SplashMaintainAspectRatio: 'true',
      FadeSplashScreenDuration: '300',
      SplashShowOnlyFirstTime: 'false',
      SplashScreen: 'screen',
      SplashScreenDelay: '3000'
    }
  }{% endif %}
};

export default config;