// Cliente HTTP unificado para chamadas /api/*
const API = {
  token: () => localStorage.getItem("dn_token"),
  setToken: (t) => localStorage.setItem("dn_token", t),
  logout: () => { localStorage.removeItem("dn_token"); location.href = "/admin/login.html"; },

  async req(method, path, body) {
    const headers = { "Content-Type": "application/json" };
    const t = API.token();
    if (t) headers["Authorization"] = "Bearer " + t;
    const res = await fetch(path, {
      method,
      headers,
      body: body ? JSON.stringify(body) : undefined,
    });
    if (res.status === 401 && location.pathname.startsWith("/admin")) API.logout();
    if (res.status === 204) return null;
    const data = await res.json().catch(() => ({}));
    if (!res.ok) throw new Error(data.erro || "erro na requisicao");
    return data;
  },
  get: (p)         => API.req("GET", p),
  post: (p, b)     => API.req("POST", p, b),
  put: (p, b)      => API.req("PUT", p, b),
  del: (p)         => API.req("DELETE", p),
};
