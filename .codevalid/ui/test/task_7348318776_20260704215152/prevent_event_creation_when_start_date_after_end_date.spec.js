import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { seedAuthenticatedSession, mockEventScenario } from "../../helpers/mock-api.js";

test("Prevent Event Creation When Start Date Is After End Date", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder(
    "prevent_event_creation_when_start_date_after_end_date",
    "Prevent Event Creation When Start Date Is After End Date"
  );

  const apiErrorMessage = "Start date must be before end date";

  await recorder.step("Seed authenticated session and mock invalid date event APIs");
  await seedAuthenticatedSession(page);
  await page.route("**/api/events", async (route) => {
    const method = route.request().method().toUpperCase();

    if (method === "GET") {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify([]),
      });
      return;
    }
  });

  await recorder.step("Open the Events page");
  await page.goto("/events");
  await expect(
    page.getByRole("heading", { name: "Events Management Setup" })
  ).toBeVisible();

  await recorder.step("Open the create event form");
  await page.getByRole("button", { name: /Create New Event/i }).click();

  await recorder.step("Enter invalid event details where start date is after end date");
  await page.locator('input[name="title"]').fill("Invalid Date Event");
  await page
    .locator('textarea[name="description"]')
    .fill("Testing invalid date validation");
  await page.locator('input[name="location"]').fill("Chicago");
  await page.locator('input[name="startDate"]').fill("2026-09-20");
  await page.locator('input[name="endDate"]').fill("2026-09-18");

  await recorder.step("Submit the event creation form");
  await page.getByRole("button", { name: /Publish Event/i }).click();

  await recorder.step("Verify validation error is shown and no event record is created");
  await expect(page.getByText(apiErrorMessage)).toBeVisible();
  await expect(page.getByText("Invalid Date Event")).not.toBeVisible();
  await expect(page.getByText("Chicago")).not.toBeVisible();
  await expect(page.getByText("2026-09-20 to 2026-09-18")).not.toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:prevent_event_creation_when_start_date_after_end_date");
  await recorder.save(testInfo);
});
