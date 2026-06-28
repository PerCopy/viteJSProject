import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession, setupEventListMocks } from "../../helpers/mock-api.js";

test("Events List Is Empty on Initial Load", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "events_empty_state_initial_load",
    testName: "Events List Is Empty on Initial Load",
  });

  await recorder.step("Seed authenticated session and empty events response");
  await setupAuthenticatedSession(page);
  await setupEventListMocks(page, { events: [] });

  await recorder.step("Navigate to events page");
  await page.goto("/events");
  await expect(page.getByRole("heading", { name: "Events Management Setup" })).toBeVisible();

  await recorder.step("Verify initial empty state");
  await expect(page.getByText("No Events Found")).toBeVisible();
  await expect(page.getByText(/Configure your first event schedules/i)).toBeVisible();

  await recorder.step("Verify create form is accessible and editable when opened");
  await page.getByRole("button", { name: "Create New Event" }).click();
  await expect(page.getByRole("heading", { name: "New Event Setup" })).toBeVisible();
  await expect(page.getByLabel("Event Title *")).toBeEditable();
  await expect(page.getByPlaceholder("Summarize event activities...")).toBeEditable();
  await expect(page.getByLabel("Location / Venue *")).toBeEditable();
  await expect(page.getByLabel("Start Date *")).toBeEditable();
  await expect(page.getByLabel("End Date *")).toBeEditable();
  await expect(page.getByRole("button", { name: "Publish Event" })).toBeEnabled();

  console.log("CODEVALID_TEST_ASSERTION_OK:events_empty_state_initial_load");
  await recorder.save(testInfo);
});
