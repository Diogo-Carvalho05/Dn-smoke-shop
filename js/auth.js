// Helpers de autenticacao via Supabase Auth (admin)
const Auth = {
  async login(email, senha) {
    const { data, error } = await sb.auth.signInWithPassword({ email, password: senha });
    if (error) throw error;
    return data;
  },

  async logout() {
    await sb.auth.signOut();
    location.href = "/admin/login.html";
  },

  async user() {
    const { data } = await sb.auth.getUser();
    return data.user;
  },

  // Redireciona pro login se nao tiver sessao. Usar em paginas /admin/*.
  async requireLogin() {
    const u = await this.user();
    if (!u) {
      location.href = "/admin/login.html";
      return null;
    }
    return u;
  },
};
