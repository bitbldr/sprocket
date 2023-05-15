/** @type {import('tailwindcss').Config} */
const tailwindColors = require("tailwindcss/colors");

module.exports = {
  content: ["./src/**/*.{html,js,gleam}"],
  theme: {
    extend: {
      colors: {
        ...tailwindColors,
        gray: tailwindColors.neutral,
      },
    },
  },
  plugins: [require("@tailwindcss/typography")],
};
