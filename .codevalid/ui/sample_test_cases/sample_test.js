/**
 * Sample Playwright test for the CodeValid UI validation suite.
 *
 * Covers:
 *  1. Sign-in page loads and renders expected elements.
 *  2. Successful sign-in with mocked API credentials navigates to Home.
 *  3. Invalid credentials show an error message.
 *
 * The ExecutionRecorder helper is used to capture a structured flow log
 * which is later uploaded to S3 by global-teardown.js.
 */

import { test, expect } from "@playwright/test";
import { setupMockRoutes } from "../mocks/mock-handlers.js";
import { ExecutionRecorder } from "../helpers/execution-recorder.js";

// ─── Sign-in page renders correctly ───────────────────────────────────────────
test("CV-001: sign-in page loads with required fields", async ({
  page,
}, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "CV-001",
    testTitle: "sign-in page loads with required fields",
  });

  await setupMockRoutes(page);

  await recorder.step("Navigate to /signin", async () => {
    await page.goto("/signin");
  });

  await recorder.step("Assert heading is visible", async () => {
    await expect(page.getByRole("heading", { name: /welcome back/i })).toBeVisible();
  });

  await recorder.step("Assert email input is present", async () => {
    await expect(page.locator('input[name="email"]')).toBeVisible();
  });

  await recorder.step("Assert password input is present", async () => {
    await expect(page.locator('input[name="password"]')).toBeVisible();
  });

  await recorder.step("Assert submit button is present", async () => {
    await expect(page.getByRole("button", { name: /sign in/i })).toBeVisible();
  });

  await recorder.save(testInfo);
});

// ─── Successful sign-in ────────────────────────────────────────────────────────
test("CV-002: successful sign-in redirects to home", async ({
  page,
}, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "CV-002",
    testTitle: "successful sign-in redirects to home",
  });

  await setupMockRoutes(page);

  await recorder.step("Navigate to /signin", async () => {
    await page.goto("/signin");
  });

  await recorder.step("Fill email field", async () => {
    await page.locator('input[name="email"]').fill("john@example.com");
  });

  await recorder.step("Fill password field", async () => {
    await page.locator('input[name="password"]').fill("password123");
  });

  await recorder.step("Submit the form", async () => {
    await page.getByRole("button", { name: /sign in/i }).click();
  });

  await recorder.step("Assert redirect to home page", async () => {
    await expect(page).toHaveURL("/", { timeout: 10000 });
  });

  await recorder.save(testInfo);
});

// ─── Invalid credentials show error ────────────────────────────────────────────
test("CV-003: invalid credentials display error message", async ({
  page,
}, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "CV-003",
    testTitle: "invalid credentials display error message",
  });

  await setupMockRoutes(page);

  await recorder.step("Navigate to /signin", async () => {
    await page.goto("/signin");
  });

  await recorder.step("Fill email field with wrong email", async () => {
    await page.locator('input[name="email"]').fill("wrong@example.com");
  });

  await recorder.step("Fill password field with wrong password", async () => {
    await page.locator('input[name="password"]').fill("wrongpassword");
  });

  await recorder.step("Submit the form", async () => {
    await page.getByRole("button", { name: /sign in/i }).click();
  });

  await recorder.step("Assert error message appears", async () => {
    await expect(
      page.getByText(/invalid email or password/i)
    ).toBeVisible({ timeout: 10000 });
  });

  await recorder.save(testInfo);
});
