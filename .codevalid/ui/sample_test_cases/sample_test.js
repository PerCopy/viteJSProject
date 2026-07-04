/**
 * sample_test.js
 * CodeValid sample Playwright test for the Eminence Hub Event Registration Portal.
 *
 * Covers:
 *  1. Sign-in page renders correctly
 *  2. Successful sign-in with mock credentials navigates to home
 *  3. Sign-in with invalid credentials shows an error message
 *  4. Sign-up page renders and validates required fields
 *
 * The app backend is replaced by the mock server (mock-server.js) which is
 * started via the Vite dev server proxy (port 5001) so no real network calls
 * are made during CI.
 */

import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../helpers/execution-recorder.js";

// ── Test suite: Sign In ───────────────────────────────────────────────────────

test.describe("Sign In page", () => {
  test("renders the sign-in form with email and password fields", async ({
    page,
  }, testInfo) => {
    const recorder = new ExecutionRecorder({
      testId: "sample-signin-render",
      testTitle: "Sign-in form renders correctly",
    });

    await recorder.step("Navigate to /signin", async () => {
      await page.goto("/signin");
    });

    await recorder.step("Assert page title visible", async () => {
      await expect(page.getByText("Welcome Back")).toBeVisible();
    });

    await recorder.step("Assert email input visible", async () => {
      await expect(page.getByPlaceholder("john@example.com")).toBeVisible();
    });

    await recorder.step("Assert password input visible", async () => {
      await expect(page.getByPlaceholder("••••••••")).toBeVisible();
    });

    await recorder.step("Assert submit button visible", async () => {
      await expect(page.getByRole("button", { name: /sign in/i })).toBeVisible();
    });

    await recorder.save(testInfo);
  });

  test("shows validation errors when submitted with empty fields", async ({
    page,
  }, testInfo) => {
    const recorder = new ExecutionRecorder({
      testId: "sample-signin-validation",
      testTitle: "Sign-in validation errors on empty submit",
    });

    await recorder.step("Navigate to /signin", async () => {
      await page.goto("/signin");
    });

    await recorder.step("Click submit without filling form", async () => {
      await page.getByRole("button", { name: /sign in/i }).click();
    });

    await recorder.step("Assert email validation error", async () => {
      await expect(page.getByText(/email is required/i)).toBeVisible();
    });

    await recorder.save(testInfo);
  });

  test("successful sign-in redirects to home page", async ({
    page,
  }, testInfo) => {
    const recorder = new ExecutionRecorder({
      testId: "sample-signin-success",
      testTitle: "Successful sign-in redirects to home",
    });

    await recorder.step("Navigate to /signin", async () => {
      await page.goto("/signin");
    });

    // Intercept the API call and return mock data so the test is independent
    // of whichever backend (real or mock-server) is running.
    await page.route("/api/auth/signin", async (route) => {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          user: {
            id: "user_testuser01",
            username: "testuser",
            email: "testuser@example.com",
            fullName: "Test User",
            phone: "555-000-0001",
            organization: "CodeValid QA",
          },
          token: "mock-jwt-token-for-user_testuser01",
        }),
      });
    });

    await recorder.step("Fill email", async () => {
      await page.getByPlaceholder("john@example.com").fill("testuser@example.com");
    });

    await recorder.step("Fill password", async () => {
      await page.getByPlaceholder("••••••••").fill("Password123!");
    });

    await recorder.step("Click Sign In", async () => {
      await page.getByRole("button", { name: /sign in/i }).click();
    });

    await recorder.step("Assert redirected to home (/)", async () => {
      await expect(page).toHaveURL("/");
    });

    await recorder.save(testInfo);
  });

  test("shows error message on invalid credentials", async ({
    page,
  }, testInfo) => {
    const recorder = new ExecutionRecorder({
      testId: "sample-signin-invalid",
      testTitle: "Sign-in shows error on invalid credentials",
    });

    await recorder.step("Navigate to /signin", async () => {
      await page.goto("/signin");
    });

    // Mock a 401 response
    await page.route("/api/auth/signin", async (route) => {
      await route.fulfill({
        status: 401,
        contentType: "application/json",
        body: JSON.stringify({ message: "Invalid email or password." }),
      });
    });

    await recorder.step("Fill email", async () => {
      await page.getByPlaceholder("john@example.com").fill("wrong@example.com");
    });

    await recorder.step("Fill password", async () => {
      await page.getByPlaceholder("••••••••").fill("wrongpassword");
    });

    await recorder.step("Click Sign In", async () => {
      await page.getByRole("button", { name: /sign in/i }).click();
    });

    await recorder.step("Assert error message visible", async () => {
      await expect(
        page.getByText(/invalid email or password/i)
      ).toBeVisible();
    });

    await recorder.save(testInfo);
  });
});

// ── Test suite: Sign Up ───────────────────────────────────────────────────────

test.describe("Sign Up page", () => {
  test("renders the sign-up form", async ({ page }, testInfo) => {
    const recorder = new ExecutionRecorder({
      testId: "sample-signup-render",
      testTitle: "Sign-up form renders correctly",
    });

    await recorder.step("Navigate to /signup", async () => {
      await page.goto("/signup");
    });

    await recorder.step("Assert heading visible", async () => {
      // Look for a heading or prominent text that exists on the signup page
      const heading = page.getByRole("heading").first();
      await expect(heading).toBeVisible();
    });

    await recorder.step("Assert sign-in link present", async () => {
      await expect(page.getByRole("link", { name: /sign in/i })).toBeVisible();
    });

    await recorder.save(testInfo);
  });
});
