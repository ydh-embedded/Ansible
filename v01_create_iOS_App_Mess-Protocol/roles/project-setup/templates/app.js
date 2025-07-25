/**
 * {{ app_name }} - Main Application Controller
 * Generated by Ansible iOS/Android Project Generator v{{ script_version }}
 * Date: {{ ansible_date_time.date }}
 * 
 * Main application logic and initialization
 */

class {{ project_name.replace('-', '') }}MonitoringApp {
    constructor() {
        this.config = {
            version: '{{ version_name }}',
            projectName: '{{ project_name }}',
            appId: '{{ app_id }}',
            buildDate: '{{ ansible_date_time.date }}',
            isProduction: {% if build_type == 'production' %}true{% else %}false{% endif %},
            enableAnalytics: {% if enable_analytics %}true{% else %}false{% endif %},
            enableBackup: {% if enable_backup %}true{% else %}false{% endif %}
        };
        
        this.state = {
            isOnline: navigator.onLine,
            isLoading: false,
            currentTab: 'dashboard',
            lastUpdate: null,
            measurements: [],
            weatherData: null
        };
        
        this.modules = {};
        this.init();
    }

    /**
     * Initialize the application
     */
    async init() {
        console.log(`📱 {{ app_name }} v${this.config.version} initialized`);
        console.log(`🔧 Build: ${this.config.isProduction ? 'Production' : 'Development'}`);
        
        try {
            this.showLoading(true);
            
            await this.waitForDOMReady();
            await this.setupEventListeners();
            await this.initializeModules();
            await this.setupTabNavigation();
            await this.loadInitialData();
            
            this.hideLoading();
            this.updateLastUpdateTime();
            
            console.log('✅ Application initialization complete');
        } catch (error) {
            console.error('❌ Application initialization failed:', error);
            this.handleError(error);
        }
    }

    /**
     * Wait for DOM to be ready
     */
    waitForDOMReady() {
        return new Promise((resolve) => {
            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', resolve);
            } else {
                resolve();
            }
        });
    }

    /**
     * Setup event listeners
     */
    async setupEventListeners() {
        console.log('🔗 Setting up event listeners...');

        // Tab Navigation
        document.querySelectorAll('ion-tab-button').forEach(btn => {
            btn.addEventListener('click', (e) => this.handleTabChange(e));
        });

        // Action Buttons
        this.bindButton('protocol-btn', () => this.openProtocol());
        this.bindButton('export-btn', () => this.exportData());
        this.bindButton('transfer-btn', () => this.transferData());
        this.bindButton('settings-btn', () => this.openSettings());
        this.bindButton('sync-btn', () => this.syncData());
        this.bindButton('chart-refresh', () => this.refreshChart());
        this.bindButton('chart-settings', () => this.openChartSettings());

        // Quick Action FAB buttons
        this.bindButton('quick-measure', () => this.quickMeasurement());
        this.bindButton('quick-export', () => this.quickExport());

        // Network Status
        window.addEventListener('online', () => this.handleNetworkChange(true));
        window.addEventListener('offline', () => this.handleNetworkChange(false));

        // App State Changes (Cordova/Capacitor)
        document.addEventListener('deviceready', () => this.onDeviceReady());
        document.addEventListener('resume', () => this.onAppResume());
        document.addEventListener('pause', () => this.onAppPause());

        // Keyboard Shortcuts
        document.addEventListener('keydown', (e) => this.handleKeyboardShortcuts(e));

        console.log('✅ Event listeners setup complete');
    }

    /**
     * Bind click event to button with error handling
     */
    bindButton(id, handler) {
        const button = document.getElementById(id);
        if (button) {
            button.addEventListener('click', (e) => {
                e.preventDefault();
                try {
                    handler();
                } catch (error) {
                    console.error(`Error in ${id} handler:`, error);
                    this.showToast(`Fehler: ${error.message}`, 'danger');
                }
            });
        } else {
            console.warn(`⚠️ Button with ID '${id}' not found`);
        }
    }

    /**
     * Initialize application modules
     */
    async initializeModules() {
        console.log('🔧 Initializing modules...');

        // Initialize Weather Module
        if (window.WeatherModule) {
            this.modules.weather = new WeatherModule(this);
            await this.modules.weather.init();
        }

        // Initialize Measurement Module
        if (window.MeasurementModule) {
            this.modules.measurement = new MeasurementModule(this);
            await this.modules.measurement.init();
        }

        // Initialize Chart Module
        if (window.ChartModule) {
            this.modules.chart = new ChartModule(this);
            await this.modules.chart.init();
        }

        // Initialize Protocol Module
        if (window.ProtocolModule) {
            this.modules.protocol = new ProtocolModule(this);
        }

        // Initialize Export Module
        if (window.ExportModule) {
            this.modules.export = new ExportModule(this);
        }

        // Initialize Transfer Module
        if (window.TransferModule) {
            this.modules.transfer = new TransferModule(this);
        }

        {% if enable_analytics %}
        // Initialize Analytics
        if (this.config.enableAnalytics) {
            await this.initAnalytics();
        }
        {% endif %}

        console.log('✅ Modules initialization complete');
    }

    /**
     * Setup tab navigation
     */
    setupTabNavigation() {
        const tabs = document.querySelectorAll('ion-tab-button');
        tabs.forEach(tab => {
            tab.addEventListener('click', () => {
                // Remove active class from all tabs
                tabs.forEach(t => t.classList.remove('tab-selected'));
                // Add active class to clicked tab
                tab.classList.add('tab-selected');
            });
        });
    }

    /**
     * Load initial application data
     */
    async loadInitialData() {
        console.log('📊 Loading initial data...');

        try {
            // Load dashboard data in parallel
            const promises = [];

            if (this.modules.weather) {
                promises.push(this.modules.weather.loadData());
            }

            if (this.modules.measurement) {
                promises.push(this.modules.measurement.loadData());
            }

            if (this.modules.chart) {
                promises.push(this.modules.chart.loadData());
            }

            await Promise.allSettled(promises);
            console.log('✅ Initial data loaded');

        } catch (error) {
            console.error('❌ Failed to load initial data:', error);
            this.showToast('Fehler beim Laden der Daten', 'warning');
        }
    }

    /**
     * Handle tab change
     */
    handleTabChange(event) {
        const tab = event.target.getAttribute('tab');
        if (!tab) return;

        console.log('📱 Tab changed to:', tab);
        this.state.currentTab = tab;

        {% if enable_analytics %}
        // Track tab changes
        if (this.config.enableAnalytics) {
            this.trackEvent('tab_change', { tab: tab });
        }
        {% endif %}

        switch(tab) {
            case 'dashboard':
                this.loadDashboard();
                break;
            case 'measurements':
                this.openMeasurements();
                break;
            case 'protocol':
                this.openProtocol();
                break;
            case 'settings':
                this.openSettings();
                break;
        }
    }

    /**
     * Load dashboard data
     */
    async loadDashboard() {
        console.log('📊 Loading dashboard...');

        try {
            // Refresh all dashboard components
            const refreshPromises = [];

            if (this.modules.weather) {
                refreshPromises.push(this.modules.weather.refresh());
            }

            if (this.modules.measurement) {
                refreshPromises.push(this.modules.measurement.refresh());
            }

            if (this.modules.chart) {
                refreshPromises.push(this.modules.chart.refresh());
            }

            await Promise.allSettled(refreshPromises);
            this.updateLastUpdateTime();

        } catch (error) {
            console.error('❌ Dashboard load failed:', error);
            this.showToast('Dashboard konnte nicht geladen werden', 'danger');
        }
    }

    /**
     * Navigation methods
     */
    openMeasurements() {
        console.log('📏 Opening measurements view');
        // Implementation for measurements view
    }

    openProtocol() {
        console.log('📋 Opening protocol');
        window.location.href = 'sites/protocol.html';
    }

    openSettings() {
        console.log('⚙️ Opening settings');
        // Implementation for settings
    }

    /**
     * Action methods
     */
    async exportData() {
        console.log('📤 Exporting data...');
        if (this.modules.export) {
            await this.modules.export.exportData();
        }
    }

    async transferData() {
        console.log('☁️ Transferring data...');
        if (this.modules.transfer) {
            await this.modules.transfer.transferData();
        }
    }

    async syncData() {
        console.log('🔄 Syncing data...');
        this.showLoading(true);
        
        try {
            await this.loadDashboard();
            this.showToast('Daten erfolgreich synchronisiert', 'success');
        } catch (error) {
            this.showToast('Synchronisation fehlgeschlagen', 'danger');
        } finally {
            this.hideLoading();
        }
    }

    refreshChart() {
        console.log('📈 Refreshing chart...');
        if (this.modules.chart) {
            this.modules.chart.refresh();
        }
    }

    openChartSettings() {
        console.log('⚙️ Opening chart settings');
        // Implementation for chart settings
    }

    quickMeasurement() {
        console.log('⚡ Quick measurement');
        if (this.modules.measurement) {
            this.modules.measurement.quickMeasure();
        }
    }

    quickExport() {
        console.log('⚡ Quick export');
        if (this.modules.export) {
            this.modules.export.quickExport();
        }
    }

    /**
     * Device event handlers
     */
    onDeviceReady() {
        console.log('📱 Device ready');
        this.state.isDeviceReady = true;
    }

    onAppResume() {
        console.log('▶️ App resumed');
        this.loadDashboard();
    }

    onAppPause() {
        console.log('⏸️ App paused');
        // Save any pending data
    }

    /**
     * Network event handler
     */
    handleNetworkChange(isOnline) {
        this.state.isOnline = isOnline;
        console.log('🌐 Network status:', isOnline ? 'Online' : 'Offline');

        const statusBanner = document.querySelector('.status-banner');
        if (statusBanner) {
            if (isOnline) {
                statusBanner.setAttribute('color', 'success');
                statusBanner.querySelector('.status-title').textContent = 'System Online';
            } else {
                statusBanner.setAttribute('color', 'warning');
                statusBanner.querySelector('.status-title').textContent = 'Offline Modus';
            }
        }

        this.showToast(
            isOnline ? 'Verbindung wiederhergestellt' : 'Keine Internetverbindung',
            isOnline ? 'success' : 'warning'
        );
    }

    /**
     * Keyboard shortcuts handler
     */
    handleKeyboardShortcuts(event) {
        if (event.ctrlKey || event.metaKey) {
            switch(event.key) {
                case 'r':
                    event.preventDefault();
                    this.syncData();
                    break;
                case 'e':
                    event.preventDefault();
                    this.exportData();
                    break;
                case 's':
                    event.preventDefault();
                    this.openSettings();
                    break;
            }
        }
    }

    /**
     * UI Helper Methods
     */
    showLoading(show = true) {
        this.state.isLoading = show;
        const overlay = document.getElementById('loading-overlay');
        if (overlay) {
            overlay.style.display = show ? 'flex' : 'none';
        }
    }

    hideLoading() {
        this.showLoading(false);
    }

    async showToast(message, color = 'primary', duration = 3000) {
        // Create toast element dynamically
        const toast = document.createElement('ion-toast');
        toast.message = message;
        toast.duration = duration;
        toast.color = color;
        toast.position = 'bottom';
        
        document.body.appendChild(toast);
        await toast.present();
        
        setTimeout(() => {
            document.body.removeChild(toast);
        }, duration + 100);
    }

    updateLastUpdateTime() {
        const now = new Date();
        this.state.lastUpdate = now;
        
        const timeElement = document.getElementById('last-update');
        if (timeElement) {
            timeElement.textContent = now.toLocaleTimeString('de-DE', {
                hour: '2-digit',
                minute: '2-digit'
            });
        }
    }

    handleError(error) {
        console.error('❌ Application Error:', error);
        this.showToast(`Fehler: ${error.message}`, 'danger');
        
        {% if enable_analytics %}
        if (this.config.enableAnalytics) {
            this.trackEvent('error', {
                message: error.message,
                stack: error.stack
            });
        }
        {% endif %}
    }

    {% if enable_analytics %}
    /**
     * Analytics Methods
     */
    async initAnalytics() {
        console.log('📊 Initializing analytics...');
        // Initialize analytics service
        this.trackEvent('app_start', {
            version: this.config.version,
            platform: this.getPlatform()
        });
    }

    trackEvent(eventName, properties = {}) {
        console.log('📊 Track Event:', eventName, properties);
        // Implement analytics tracking
    }
    {% endif %}

    /**
     * Utility Methods
     */
    getPlatform() {
        if (window.Capacitor) {
            return window.Capacitor.platform;
        }
        return 'web';
    }

    getAppInfo() {
        return {
            name: this.config.projectName,
            version: this.config.version,
            buildDate: this.config.buildDate,
            platform: this.getPlatform(),
            isOnline: this.state.isOnline
        };
    }

    /**
     * Public API for other modules
     */
    refresh() {
        return this.loadDashboard();
    }

    getState() {
        return { ...this.state };
    }

    getConfig() {
        return { ...this.config };
    }
}

// Initialize App when DOM is ready
const app = new {{ project_name.replace('-', '') }}MonitoringApp();

// Make available globally
window.MonitoringApp = app;
window.{{ project_name.replace('-', '') }}App = app;

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {{ project_name.replace('-', '') }}MonitoringApp;
}

console.log('✅ {{ app_name }} Application Script Loaded');