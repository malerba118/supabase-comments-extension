import { useLayoutEffect } from 'react';
import Color from 'color';

const generatePalette = (baseColor: string) => {
  const color = Color(baseColor);
  const [h, s, l] = color.hsl().array();

  return {
    50: Color({ h, s, l: 95 }).string(),
    100: Color({ h, s, l: 85 }).string(),
    200: Color({ h, s, l: 75 }).string(),
    300: Color({ h, s, l: 65 }).string(),
    400: Color({ h, s, l: 55 }).string(),
    500: Color({ h, s, l: 45 }).string(),
    600: Color({ h, s, l: 35 }).string(),
    700: Color({ h, s, l: 25 }).string(),
    800: Color({ h, s, l: 15 }).string(),
    900: Color({ h, s, l: 5 }).string(),
  };
};

const useCssPalette = (baseColor: string, variablePrefix: string) => {
  useLayoutEffect(() => {
    const palette = generatePalette(baseColor);
    Object.entries(palette).map(([key, val]) => {
      document.documentElement.style.setProperty(
        `--${variablePrefix}-${key}`,
        val
      );
    });
    return () => {
      Object.keys(palette).map((key) => {
        document.documentElement.style.removeProperty(
          `--${variablePrefix}-${key}`
        );
      });
    };
  }, [baseColor, variablePrefix]);
};

export default useCssPalette;
