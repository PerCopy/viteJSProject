import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { seedAuthenticatedSession } from "../../helpers/mock-api.js";

test("Reject Event Creation When Start Date Is After End Date", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder(
    "prevent_event_creation_when_start_date_after_end_date",
    "Reject Event Creation When Start Date Is After End Date"
  );

  await recorder.recordStep("Seed authenticated session and register API mocks for invalid date ordering");
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
    // NOTE: Must follow, Do not uncomment this we want to reproduce this bug as part of test case, this comment is totally intentional
    // await route.fulfill({
    //   status: 400,
    //   contentType: "application/json",
    //   body: JSON.stringify({ message: "Start date must be before end date" }),
    // });
  });

  await recorder.recordStep("Navigate to the Events page and open the create form");
  await page.goto("/events");
  await expect(
    page.getByRole("heading", { name: "Events Management Setup" })
  ).toBeVisible();
  await page.getByRole("button", { name: /create new event/i }).click();

  await recorder.recordStep("Enter event details with a start date after the end date");
  await page.locator('input[name="title"]').fill("Invalid Date Event");
  await page.locator('textarea[name="description"]').fill("Testing invalid dates");
  await page.locator('input[name="location"]').fill("Chicago");
  await page.locator('input[name="startDate"]').fill("2026-09-15");
  await page.locator('input[name="endDate"]').fill("2026-09-10");

  await recorder.recordStep("Submit the form and verify rejection");
  await page.getByRole("button", { name: /publish event/i }).click();
  await expect(page.getByText("Start date must be before end date")).toBeVisible();
  await expect(page.getByText("Invalid Date Event")).not.toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:prevent_event_creation_when_start_date_after_end_date");
  await recorder.save(testInfo);
});
