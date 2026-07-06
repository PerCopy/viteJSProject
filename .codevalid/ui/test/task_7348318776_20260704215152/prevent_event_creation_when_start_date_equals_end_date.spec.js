import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { seedAuthenticatedSession } from "../../helpers/mock-api.js";

test("Prevent Event Creation When Start Date Equals End Date", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder(
    "prevent_event_creation_when_start_date_equals_end_date",
    "Prevent Event Creation When Start Date Equals End Date"
  );

  const apiErrorMessage = "Start date must be before end date";

  await recorder.step("Seed authenticated session and mock equal date validation APIs");
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

    await route.fulfill({
      status: 400,
      contentType: "application/json",
      body: JSON.stringify({ message: apiErrorMessage }),
    });
  });

  await recorder.step("Open the Events page");
  await page.goto("/events");
  await expect(
    page.getByRole("heading", { name: "Events Management Setup" })
  ).toBeVisible();

  await recorder.step("Open the create event form");
  await page.getByRole("button", { name: /Create New Event/i }).click();

  await recorder.step("Enter invalid event details where start date equals end date");
  await page.locator('input[name="title"]').fill("Single Day Validation Event");
  await page
    .locator('textarea[name="description"]')
    .fill("Validation test for equal dates");
  await page.locator('input[name="location"]').fill("Boston");
  await page.locator('input[name="startDate"]').fill("2026-10-05");
  await page.locator('input[name="endDate"]').fill("2026-10-05");

  await recorder.step("Submit the event creation form");
  await page.getByRole("button", { name: /Publish Event/i }).click();

  await recorder.step("Verify validation error is shown and no event record is created");
  await expect(page.getByText(apiErrorMessage)).toBeVisible();
  await expect(page.getByText("Single Day Validation Event")).not.toBeVisible();
  await expect(page.getByText("Boston")).not.toBeVisible();
  await expect(page.getByText("2026-10-05 to 2026-10-05")).not.toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:prevent_event_creation_when_start_date_equals_end_date");
  await recorder.save(testInfo);
});
