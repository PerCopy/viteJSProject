// API Client for Event Registration Web Application

const BASE_URL = ""; // Empty string because we are proxying requests through Vite

// --- Auth state helpers ---
export const saveUserSession = (user, token) => {
  localStorage.setItem("user", JSON.stringify(user));
  localStorage.setItem("token", token);
};

export const clearUserSession = () => {
  localStorage.removeItem("user");
  localStorage.removeItem("token");
};

export const getCurrentUser = () => {
  const userStr = localStorage.getItem("user");
  if (!userStr) return null;
  try {
    return JSON.parse(userStr);
  } catch (e) {
    return null;
  }
};

export const getAuthToken = () => {
  return localStorage.getItem("token");
};

export const isAuthenticated = () => {
  return !!getAuthToken();
};

// --- API Request helper ---
async function request(endpoint, options = {}) {
  const token = getAuthToken();
  const headers = {
    "Content-Type": "application/json",
    ...options.headers,
  };

  if (token) {
    headers["Authorization"] = `Bearer ${token}`;
  }

  const config = {
    ...options,
    headers,
  };

  const response = await fetch(endpoint, config);
  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.message || "Something went wrong");
  }

  return data;
}

// --- API Calls ---

export const api = {
  // Auth
  signup: (userData) => {
    return request("/api/auth/signup", {
      method: "POST",
      body: JSON.stringify(userData),
    });
  },

  signin: (credentials) => {
    return request("/api/auth/signin", {
      method: "POST",
      body: JSON.stringify(credentials),
    });
  },

  // Events
  getEvents: () => {
    return request("/api/events");
  },

  createEvent: (eventData) => {
    return request("/api/events", {
      method: "POST",
      body: JSON.stringify(eventData),
    });
  },

  // Registrations
  getRegistrations: (eventId) => {
    return request(`/api/registrations/${eventId}`);
  },

  registerForEvent: (registrationData) => {
    return request("/api/registrations", {
      method: "POST",
      body: JSON.stringify(registrationData),
    });
  },
};
