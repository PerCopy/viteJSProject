import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession, setupEventCreationScenario } from "../../helpers/mock-api.js";

test("Events List Is Empty on Initial Load", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "events_empty_state_initial_load",
    testName: "Events List Is Empty on Initial Load",
  });

  await recorder.step("Mock authenticated session and empty events list");
  await setupAuthenticatedSession(page);
  await setupEventCreationScenario(page, {
    initialEvents: [],
    failOnCreate: false,
  });

  await recorder.step("Navigate to /events");
  await page.goto("/events");
  await expect(page.getByRole("heading", { name: "Events Management Setup" })).toBeVisible();

  await recorder.step("Verify empty state is shown");
  await expect(page.getByText("No Events Found")).toBeVisible();
  await expect(page.getByText('Configure your first event schedules by clicking the "Create New Event" button.')).toBeVisible();

  await recorder.step("Open create event form and verify fields are editable");
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
