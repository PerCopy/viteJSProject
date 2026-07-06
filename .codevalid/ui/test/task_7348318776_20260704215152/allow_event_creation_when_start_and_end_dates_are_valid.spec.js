import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { seedAuthenticatedSession, mockEventScenario } from "../../helpers/mock-api.js";

test("Allow Event Creation When Start Date Is Before End Date", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder(
    "allow_event_creation_when_start_and_end_dates_are_valid",
    "Allow Event Creation When Start Date Is Before End Date"
  );

  const createdEvent = {
    id: "event_valid_dates_001",
    title: "Partner Enablement Workshop",
    description: "Training and certification sessions for partner teams.",
    location: "Innovation Lab",
    startDate: "2026-07-14",
    endDate: "2026-07-16",
    registrationCount: 0,
  };

  await recorder.recordStep("Seed authenticated session and mock valid event creation scenario");
  await seedAuthenticatedSession(page);
  await mockEventScenario(page, { initialEvents: [], createdEvent });

  await recorder.recordStep("Navigate to the events page and open the create form");
  await page.goto("/events");
  await expect(
    page.getByRole("heading", { name: "Events Management Setup" })
  ).toBeVisible();
  await page.getByRole("button", { name: "Create New Event" }).click();

  await recorder.recordStep("Enter valid event details with start date before end date");
  await page.getByPlaceholder("e.g. Spring Hackathon 2026").fill(createdEvent.title);
  await page.getByPlaceholder("Summarize event activities...").fill(createdEvent.description);
  await page.getByPlaceholder("e.g. Auditorium A or Virtual").fill(createdEvent.location);
  await page.locator('input[name="startDate"]').fill(createdEvent.startDate);
  await page.locator('input[name="endDate"]').fill(createdEvent.endDate);

  await recorder.recordStep("Submit the event creation form");
  await page.getByRole("button", { name: "Publish Event" }).click();

  await recorder.recordStep("Verify the system creates the event and stores all submitted details");
  await expect(page.getByText("Event created successfully!")).toBeVisible();
  await expect(page.getByRole("heading", { name: createdEvent.title })).toBeVisible();
  await expect(page.getByText(createdEvent.description)).toBeVisible();
  await expect(page.getByText(createdEvent.location)).toBeVisible();
  await expect(
    page.getByText(`${createdEvent.startDate} to ${createdEvent.endDate}`)
  ).toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:allow_event_creation_when_start_and_end_dates_are_valid");
  await recorder.save(testInfo);
});
