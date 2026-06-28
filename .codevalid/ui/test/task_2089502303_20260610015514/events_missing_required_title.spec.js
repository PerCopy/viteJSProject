import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession, setupEventListMocks } from "../../helpers/mock-api.js";

test("Event Creation Fails Without Title", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "events_missing_required_title",
    testName: "Event Creation Fails Without Title",
  });

  await recorder.step("Seed authenticated session and empty events list");
  await setupAuthenticatedSession(page);
  await setupEventListMocks(page, { events: [] });

  await recorder.step("Navigate to events page");
  await page.goto("/events");
  await expect(page.getByRole("heading", { name: "Events Management Setup" })).toBeVisible();

  await recorder.step("Open form and leave title empty");
  await page.getByRole("button", { name: "Create New Event" }).click();
  await page.getByPlaceholder("Summarize event activities...").fill("Discussion forum");
  await page.getByLabel("Location / Venue *").fill("Virtual");
  await page.getByLabel("Start Date *").fill("2024-12-01");
  await page.getByLabel("End Date *").fill("2024-12-02");

  await recorder.step("Attempt submission");
  await page.getByRole("button", { name: "Publish Event" }).click();

  await recorder.step("Verify client-side validation prevents storing event");
  await expect(page.getByText("Title is required")).toBeVisible();
  await expect(page.getByText("No Events Found")).toBeVisible();
  await expect(page.getByText("Discussion forum")).toHaveCount(0);
  await expect(page.getByText("Virtual")).toHaveCount(0);

  console.log("CODEVALID_TEST_ASSERTION_OK:events_missing_required_title");
  await recorder.save(testInfo);
});
