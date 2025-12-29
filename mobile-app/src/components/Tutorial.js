/**
 * Stack Tracker Pro - First Launch Tutorial
 * 3-screen onboarding experience
 */

import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Modal,
  Dimensions,
  Platform,
} from 'react-native';

const { width: SCREEN_WIDTH } = Dimensions.get('window');

const Tutorial = ({ visible, onComplete }) => {
  const [currentScreen, setCurrentScreen] = useState(0);

  const screens = [
    {
      emoji: '🪙',
      title: 'Track Your Stack',
      description: 'Keep tabs on your precious metals portfolio. Track gold, silver, and everything in between with precision.',
      highlight: 'Your data stays on YOUR device. 100% private.',
    },
    {
      emoji: '📷',
      title: 'Scan Receipts with AI',
      description: 'Just snap a photo of your receipt and let Claude AI extract all the details automatically.',
      highlight: 'No manual entry. No hassle.',
    },
    {
      emoji: '👑',
      title: 'Go Gold for Unlimited',
      description: 'Free tier: 25 items, 5 scans. Gold tier: unlimited items, unlimited scans, cloud backup, and advanced analytics.',
      highlight: 'Start stacking for free!',
    },
  ];

  const handleNext = () => {
    if (currentScreen < screens.length - 1) {
      setCurrentScreen(currentScreen + 1);
    } else {
      onComplete();
    }
  };

  const handleSkip = () => {
    onComplete();
  };

  const currentScreenData = screens[currentScreen];

  return (
    <Modal visible={visible} animationType="fade" transparent>
      <View style={styles.overlay}>
        <View style={styles.container}>
          {/* Skip Button */}
          <TouchableOpacity
            onPress={handleSkip}
            style={styles.skipButton}
            hitSlop={{ top: 20, bottom: 20, left: 20, right: 20 }}
          >
            <Text style={styles.skipText}>Skip</Text>
          </TouchableOpacity>

          {/* Content */}
          <View style={styles.content}>
            <Text style={styles.emoji}>{currentScreenData.emoji}</Text>
            <Text style={styles.title}>{currentScreenData.title}</Text>
            <Text style={styles.description}>{currentScreenData.description}</Text>
            <View style={styles.highlightBox}>
              <Text style={styles.highlight}>{currentScreenData.highlight}</Text>
            </View>
          </View>

          {/* Progress Dots */}
          <View style={styles.progressContainer}>
            {screens.map((_, index) => (
              <View
                key={index}
                style={[
                  styles.dot,
                  index === currentScreen && styles.dotActive,
                ]}
              />
            ))}
          </View>

          {/* Page Indicator */}
          <Text style={styles.pageIndicator}>
            {currentScreen + 1} of {screens.length}
          </Text>

          {/* Next Button */}
          <TouchableOpacity style={styles.nextButton} onPress={handleNext}>
            <Text style={styles.nextButtonText}>
              {currentScreen === screens.length - 1 ? 'Get Started' : 'Next'}
            </Text>
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: '#0f0f0f',
    justifyContent: 'center',
    alignItems: 'center',
  },
  container: {
    width: SCREEN_WIDTH * 0.9,
    maxWidth: 400,
    backgroundColor: '#1a1a2e',
    borderRadius: 24,
    padding: 32,
    paddingTop: 60,
    alignItems: 'center',
  },
  skipButton: {
    position: 'absolute',
    top: 20,
    right: 20,
    padding: 8,
  },
  skipText: {
    color: '#71717a',
    fontSize: 16,
  },
  content: {
    alignItems: 'center',
    marginBottom: 40,
  },
  emoji: {
    fontSize: 80,
    marginBottom: 24,
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
    color: '#fff',
    textAlign: 'center',
    marginBottom: 16,
  },
  description: {
    fontSize: 16,
    color: '#a1a1aa',
    textAlign: 'center',
    lineHeight: 24,
    marginBottom: 20,
  },
  highlightBox: {
    backgroundColor: 'rgba(251, 191, 36, 0.1)',
    borderRadius: 12,
    padding: 16,
    borderWidth: 1,
    borderColor: 'rgba(251, 191, 36, 0.3)',
  },
  highlight: {
    fontSize: 14,
    fontWeight: '600',
    color: '#fbbf24',
    textAlign: 'center',
  },
  progressContainer: {
    flexDirection: 'row',
    gap: 8,
    marginBottom: 12,
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: 'rgba(255,255,255,0.2)',
  },
  dotActive: {
    backgroundColor: '#fbbf24',
    width: 24,
  },
  pageIndicator: {
    fontSize: 12,
    color: '#71717a',
    marginBottom: 24,
  },
  nextButton: {
    backgroundColor: '#fbbf24',
    paddingVertical: 16,
    paddingHorizontal: 48,
    borderRadius: 12,
    width: '100%',
    alignItems: 'center',
  },
  nextButtonText: {
    fontSize: 18,
    fontWeight: '700',
    color: '#1a1a2e',
  },
});

export default Tutorial;
