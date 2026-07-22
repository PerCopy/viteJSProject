import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { seedAuthenticatedSession } from "../../helpers/mock-api.js";

test("Reject Event Creation When Start Date Equals End Date", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder(
    "prevent_event_creation_when_start_date_equals_end_date",
    "Reject Event Creation When Start Date Equals End Date"
  );

  await recorder.recordStep("Seed authenticated session and register API mocks for equal date validation failure");
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
      body: JSON.stringify({ message: "Start date must be before end date" }),
    });
  });

  await recorder.recordStep("Navigate to the Events page and open the create form");
  await page.goto("/events");
  await expect(
    page.getByRole("heading", { name: "Events Management Setup" })
  ).toBeVisible();
  await page.getByRole("button", { name: /create new event/i }).click();

  await recorder.recordStep("Enter event details with equal start and end dates");
  await page.locator('input[name="title"]').fill("Single Day Validation Event");
  await page.locator('textarea[name="description"]').fill("Testing equal dates validation");
  await page.locator('input[name="location"]').fill("Austin");
  await page.locator('input[name="startDate"]').fill("2026-11-20");
  await page.locator('input[name="endDate"]').fill("2026-11-20");

  await recorder.recordStep("Submit the form and verify validation error is shown");
  await page.getByRole("button", { name: /publish event/i }).click();
  await expect(page.getByText("Start date must be before end date")).toBeVisible();
  await expect(page.getByText("Single Day Validation Event")).not.toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:prevent_event_creation_when_start_date_equals_end_date");
  await recorder.save(testInfo);
});
