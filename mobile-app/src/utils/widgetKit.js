/**
 * WidgetKit Integration Utility
 *
 * Provides functions to update the iOS home screen widget with portfolio data.
 * This is a Gold/Lifetime feature only.
 */

import { NativeModules, Platform } from 'react-native';

const { WidgetKitModule } = NativeModules;

/**
 * Check if WidgetKit is available (iOS only)
 */
export const isWidgetKitAvailable = () => {
  return Platform.OS === 'ios' && WidgetKitModule !== null && WidgetKitModule !== undefined;
};

/**
 * Update the widget with current portfolio data
 *
 * @param {Object} data Portfolio data
 * @param {number} data.portfolioValue Total portfolio value in dollars
 * @param {number} data.dailyChangeAmount Today's change in dollars
 * @param {number} data.dailyChangePercent Today's change in percent
 * @param {number} data.goldSpot Current gold spot price
 * @param {number} data.silverSpot Current silver spot price
 * @param {boolean} data.hasSubscription Whether user has Gold/Lifetime access
 */
export const updateWidgetData = async (data) => {
  if (!isWidgetKitAvailable()) {
    console.log('WidgetKit not available (Android or module missing)');
    return false;
  }

  try {
    const widgetData = {
      portfolioValue: data.portfolioValue || 0,
      dailyChangeAmount: data.dailyChangeAmount || 0,
      dailyChangePercent: data.dailyChangePercent || 0,
      goldSpot: data.goldSpot || 0,
      silverSpot: data.silverSpot || 0,
      lastUpdated: new Date().toISOString(),
      hasSubscription: data.hasSubscription || false,
    };

    // Serialize to JSON and send to native module
    const jsonData = JSON.stringify(widgetData);
    WidgetKitModule.setWidgetData(jsonData);

    console.log('Widget data updated:', widgetData);
    return true;
  } catch (error) {
    console.error('Failed to update widget data:', error);
    return false;
  }
};

/**
 * Trigger a refresh of all widget timelines
 * Call this after updating data to ensure widgets refresh immediately
 */
export const refreshWidgets = async () => {
  if (!isWidgetKitAvailable()) {
    return false;
  }

  try {
    WidgetKitModule.reloadAllTimelines();
    console.log('Widget timelines refreshed');
    return true;
  } catch (error) {
    console.error('Failed to refresh widgets:', error);
    return false;
  }
};

/**
 * Update widget and trigger refresh in one call
 *
 * @param {Object} data Portfolio data (see updateWidgetData for structure)
 */
export const syncWidgetData = async (data) => {
  const updated = await updateWidgetData(data);
  if (updated) {
    await refreshWidgets();
  }
  return updated;
};

/**
 * Get current widget configurations
 * Returns array of widget info showing which widgets are on home screen
 */
export const getWidgetConfigurations = async () => {
  if (!isWidgetKitAvailable()) {
    return [];
  }

  try {
    const configs = await WidgetKitModule.getCurrentConfigurations();
    return configs;
  } catch (error) {
    console.error('Failed to get widget configurations:', error);
    return [];
  }
};

export default {
  isWidgetKitAvailable,
  updateWidgetData,
  refreshWidgets,
  syncWidgetData,
  getWidgetConfigurations,
};
