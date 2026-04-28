/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./public/**/*.{html,js}"],
  theme: {
    extend: {
      colors: {
        marca: {
          preto: "#0a0a0a",
          branco: "#ffffff",
          cinza: "#1a1a1a",
          claro: "#f5f5f5"
        }
      },
      fontFamily: {
        sans: ["Inter", "system-ui", "sans-serif"]
      }
    }
  },
  plugins: []
};
