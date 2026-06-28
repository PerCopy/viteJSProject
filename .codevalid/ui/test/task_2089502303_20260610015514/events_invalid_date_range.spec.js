import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession, setupEventListMocks } from "../../helpers/mock-api.js";

test("Event Creation Fails When End Date Precedes Start Date", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "events_invalid_date_range",
    testName: "Event Creation Fails When End Date Precedes Start Date",
  });

  await recorder.step("Seed authenticated session and empty events API");
  await setupAuthenticatedSession(page);
  await setupEventListMocks(page, { events: [] });

  await recorder.step("Navigate to events page");
  await page.goto("/events");
  await page.getByRole("button", { name: "Create New Event" }).click();

  await recorder.step("Fill invalid date range in form");
  await page.getByLabel("Event Title *").fill("Holiday Party");
  await page.getByPlaceholder("Summarize event activities...").fill("Year-end celebration");
  await page.getByLabel("Location / Venue *").fill("Office");
  await page.getByLabel("Start Date *").fill("2024-12-31");
  await page.getByLabel("End Date *").fill("2024-12-25");

  await recorder.step("Submit invalid form");
  await page.getByRole("button", { name: "Publish Event" }).click();

  await recorder.step("Assert validation error and no event created");
  await expect(page.getByText("End date must be after or equal to start date")).toBeVisible();
  await expect(page.getByText("Holiday Party")).toHaveCount(0);
  await expect(page.getByText("Year-end celebration")).toHaveCount(0);
  await expect(page.getByText("No Events Found")).toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:events_invalid_date_range");
  await recorder.save(testInfo);
});
