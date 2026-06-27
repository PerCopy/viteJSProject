/**
 * Mock data definitions for CodeValid UI tests.
 * These fixtures are used by the mock server to return deterministic responses
 * so tests run without a real backend.
 */

export const mockUsers = [
  {
    id: "user_testuser1",
    username: "testuser",
    email: "test@example.com",
    password: "password123",
    fullName: "Test User",
    phone: "+1 (555) 000-0001",
    organization: "CodeValid",
  },
];

// Use dates spanning today so the "active" registration window is always open
const today = new Date();
const pad = (n) => String(n).padStart(2, "0");
const fmt = (d) =>
  `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;

const startDate = fmt(new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000)); // 7 days ago
const endDate = fmt(new Date(today.getTime() + 30 * 24 * 60 * 60 * 1000)); // 30 days from now

export const mockEvents = [
  {
    id: "event_mock001",
    title: "Tech Conference 2026",
    description: "Annual technology conference for developers.",
    startDate,
    endDate,
    location: "San Francisco, CA",
    registrationCount: 1,
  },
  {
    id: "event_mock002",
    title: "AI Summit",
    description: "Exploring the frontiers of artificial intelligence.",
    startDate,
    endDate,
    location: "New York, NY",
    registrationCount: 0,
  },
];

export const mockRegistrations = [
  {
    id: "reg_mock001",
    eventId: "event_mock001",
    name: "Alice Johnson",
    email: "alice@example.com",
    phone: "+1 (555) 100-2000",
    registeredAt: new Date(today.getTime() - 2 * 24 * 60 * 60 * 1000).toISOString(),
  },
];

export const mockAuthResponses = {
  signinSuccess: {
    user: {
      id: mockUsers[0].id,
      username: mockUsers[0].username,
      email: mockUsers[0].email,
      fullName: mockUsers[0].fullName,
      phone: mockUsers[0].phone,
      organization: mockUsers[0].organization,
    },
    token: `simulated-jwt-token-for-${mockUsers[0].id}`,
  },
  signinFailure: {
    message: "Invalid email or password.",
  },
  signupSuccess: (user) => ({
    user: {
      id: user.id,
      username: user.username,
      email: user.email,
      fullName: user.fullName,
      phone: user.phone || "",
      organization: user.organization || "",
    },
    token: `simulated-jwt-token-for-${user.id}`,
  }),
};
