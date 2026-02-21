import React from 'react';
import Svg, { Ellipse, Path } from 'react-native-svg';

interface HoldingsIconProps {
  size?: number;
  color?: string;
}

export default function HoldingsIcon({ size = 24, color = '#fbbf24' }: HoldingsIconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      {/* Stack of coins — 3 coins stacked with cylinder sides */}
      {/* Bottom coin body */}
      <Path d="M5 17 C5 17 5 20 12 20 C19 20 19 17 19 17 L19 17 C19 17 19 20 12 20 C5 20 5 17 5 17 Z" fill={color} />
      <Ellipse cx="12" cy="17" rx="7" ry="2.5" fill={color} />
      {/* Bottom coin side */}
      <Path d="M5 17 L5 19.5 C5 21.2 8.1 22 12 22 C15.9 22 19 21.2 19 19.5 L19 17" fill={color} opacity={0.85} />
      <Ellipse cx="12" cy="17" rx="7" ry="2.5" fill={color} />

      {/* Middle coin side */}
      <Path d="M6 11.5 L6 14 C6 15.7 8.7 16.5 12 16.5 C15.3 16.5 18 15.7 18 14 L18 11.5" fill={color} opacity={0.8} />
      <Ellipse cx="12" cy="11.5" rx="6" ry="2.2" fill={color} opacity={0.9} />

      {/* Top coin side */}
      <Path d="M7 6 L7 8.5 C7 10.2 9.2 11 12 11 C14.8 11 17 10.2 17 8.5 L17 6" fill={color} opacity={0.65} />
      <Ellipse cx="12" cy="6" rx="5" ry="2" fill={color} opacity={0.75} />
    </Svg>
  );
}
