/**
 * Mock API route handlers for Playwright tests.
 *
 * Usage inside a test or fixture:
 *
 *   import { setupMockRoutes } from "../mocks/mock-handlers.js";
 *
 *   test.beforeEach(async ({ page }) => {
 *     await setupMockRoutes(page);
 *   });
 *
 * All outgoing fetch/XHR calls to /api/* are intercepted and answered with the
 * mock data defined in mock-data.js so that no real backend is required.
 */

import {
  mockUsers,
  mockEvents,
  mockRegistrations,
  mockCredentials,
} from "./mock-data.js";

/**
 * Attach Playwright route interceptors to the given page.
 * @param {import("@playwright/test").Page} page
 */
export async function setupMockRoutes(page) {
  // POST /api/auth/signin
  await page.route("**/api/auth/signin", async (route) => {
    const body = route.request().postDataJSON();
    if (
      body?.email === mockCredentials.email &&
      body?.password === mockCredentials.password
    ) {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          user: mockCredentials.user,
          token: mockCredentials.token,
        }),
      });
    } else {
      await route.fulfill({
        status: 401,
        contentType: "application/json",
        body: JSON.stringify({ message: "Invalid email or password." }),
      });
    }
  });

  // POST /api/auth/signup
  await page.route("**/api/auth/signup", async (route) => {
    const body = route.request().postDataJSON();
    const exists = mockUsers.some(
      (u) =>
        u.email.toLowerCase() === body?.email?.toLowerCase() ||
        u.username?.toLowerCase() === body?.username?.toLowerCase()
    );
    if (exists) {
      await route.fulfill({
        status: 400,
        contentType: "application/json",
        body: JSON.stringify({ message: "Username or Email already registered." }),
      });
      return;
    }
    const newUser = {
      id: `user_mock_${Date.now()}`,
      username: body.username,
      email: body.email,
      fullName: body.fullName,
      phone: body.phone || "",
      organization: body.organization || "",
    };
    await route.fulfill({
      status: 201,
      contentType: "application/json",
      body: JSON.stringify({
        user: newUser,
        token: `simulated-jwt-token-for-${newUser.id}`,
      }),
    });
  });

  // GET /api/events
  await page.route("**/api/events", async (route) => {
    if (route.request().method() === "GET") {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify(mockEvents),
      });
    } else {
      // POST /api/events – create a new event
      const body = route.request().postDataJSON();
      const newEvent = {
        id: `event_mock_${Date.now()}`,
        title: body.title,
        description: body.description || "",
        startDate: body.startDate,
        endDate: body.endDate,
        location: body.location,
        registrationCount: 0,
      };
      await route.fulfill({
        status: 201,
        contentType: "application/json",
        body: JSON.stringify(newEvent),
      });
    }
  });

  // GET /api/registrations/:eventId
  await page.route("**/api/registrations/**", async (route) => {
    if (route.request().method() === "GET") {
      const url = route.request().url();
      const eventId = url.split("/api/registrations/")[1].split("?")[0];
      const regs = mockRegistrations[eventId] ?? [];
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify(regs),
      });
    } else {
      // POST /api/registrations
      const body = route.request().postDataJSON();
      const newReg = {
        id: `reg_mock_${Date.now()}`,
        eventId: body.eventId,
        name: body.name,
        email: body.email,
        phone: body.phone,
        registeredAt: new Date().toISOString(),
      };
      await route.fulfill({
        status: 201,
        contentType: "application/json",
        body: JSON.stringify(newReg),
      });
    }
  });
}
