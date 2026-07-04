/**
 * mock-data.js
 * Static mock data used by the mock server to respond to API requests
 * during Playwright test runs.
 */

export const mockUsers = [
  {
    id: "user_testuser01",
    username: "testuser",
    email: "testuser@example.com",
    password: "Password123!",
    fullName: "Test User",
    phone: "555-000-0001",
    organization: "CodeValid QA",
  },
  {
    id: "user_adminuser01",
    username: "adminuser",
    email: "admin@example.com",
    password: "AdminPass456!",
    fullName: "Admin User",
    phone: "555-000-0002",
    organization: "CodeValid",
  },
];

export const mockEvents = [
  {
    id: "event_001",
    title: "Annual Tech Conference 2026",
    description: "A premier gathering for technology enthusiasts and professionals.",
    startDate: "2026-01-01",
    endDate: "2026-12-31",
    location: "San Francisco Convention Center",
    registrationCount: 2,
  },
  {
    id: "event_002",
    title: "React Summit",
    description: "Deep dives into the React ecosystem.",
    startDate: "2026-01-01",
    endDate: "2026-12-31",
    location: "New York, NY",
    registrationCount: 0,
  },
  {
    id: "event_003",
    title: "DevOps Days",
    description: "Best practices in CI/CD, containers, and cloud-native infrastructure.",
    startDate: "2026-01-01",
    endDate: "2026-12-31",
    location: "Austin, TX",
    registrationCount: 1,
  },
];

export const mockRegistrations = [
  {
    id: "reg_001",
    eventId: "event_001",
    name: "Alice Smith",
    email: "alice@example.com",
    phone: "555-100-0001",
    registeredAt: "2026-06-01T10:00:00.000Z",
  },
  {
    id: "reg_002",
    eventId: "event_001",
    name: "Bob Jones",
    email: "bob@example.com",
    phone: "555-100-0002",
    registeredAt: "2026-06-02T11:00:00.000Z",
  },
  {
    id: "reg_003",
    eventId: "event_003",
    name: "Carol White",
    email: "carol@example.com",
    phone: "555-100-0003",
    registeredAt: "2026-06-03T09:30:00.000Z",
  },
];

/** Successful sign-in response shape */
export function buildSigninResponse(user) {
  const { password: _pw, ...userWithoutPassword } = user;
  return {
    user: userWithoutPassword,
    token: `mock-jwt-token-for-${user.id}`,
  };
}

/** Successful sign-up response shape */
export function buildSignupResponse(user) {
  const { password: _pw, ...userWithoutPassword } = user;
  return {
    user: userWithoutPassword,
    token: `mock-jwt-token-for-${user.id}`,
  };
}
