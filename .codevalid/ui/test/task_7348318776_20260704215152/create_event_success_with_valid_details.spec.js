import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { seedAuthenticatedSession, mockEventScenario } from "../../helpers/mock-api.js";

test("Create Event Successfully With Valid Details", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder(
    "create_event_success_with_valid_details",
    "Create Event Successfully With Valid Details"
  );

  const createdEvent = {
    id: "event_valid_details_001",
    title: "Spring Hackathon 2026",
    description: "A collaborative 48-hour student build event.",
    location: "Auditorium A",
    startDate: "2026-03-10",
    endDate: "2026-03-12",
    registrationCount: 0,
  };

  await recorder.recordStep("Seed authenticated session and mock empty events list");
  await seedAuthenticatedSession(page);
  await mockEventScenario(page, { initialEvents: [], createdEvent });

  await recorder.recordStep("Navigate to the events management page");
  await page.goto("/events");
  await expect(
    page.getByRole("heading", { name: "Events Management Setup" })
  ).toBeVisible();
  await expect(page.getByText("No Events Found")).toBeVisible();

  await recorder.recordStep("Open the create event form");
  await page.getByRole("button", { name: "Create New Event" }).click();
  await expect(page.getByRole("heading", { name: "New Event Setup" })).toBeVisible();

  await recorder.recordStep("Enter valid event title, description, location, start date, and end date");
  await page.getByPlaceholder("e.g. Spring Hackathon 2026").fill(createdEvent.title);
  await page.getByPlaceholder("Summarize event activities...").fill(createdEvent.description);
  await page.getByPlaceholder("e.g. Auditorium A or Virtual").fill(createdEvent.location);
  await page.locator('input[name="startDate"]').fill(createdEvent.startDate);
  await page.locator('input[name="endDate"]').fill(createdEvent.endDate);

  await recorder.recordStep("Submit the event creation form");
  await page.getByRole("button", { name: "Publish Event" }).click();

  await recorder.recordStep("Verify the new event record is created with the submitted values");
  await expect(page.getByText("Event created successfully!")).toBeVisible();
  await expect(page.getByRole("heading", { name: createdEvent.title })).toBeVisible();
  await expect(page.getByText(createdEvent.description)).toBeVisible();
  await expect(page.getByText(createdEvent.location)).toBeVisible();
  await expect(
    page.getByText(`${createdEvent.startDate} to ${createdEvent.endDate}`)
  ).toBeVisible();
  await expect(page.getByText("0 registered")).toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:create_event_success_with_valid_details");
  await recorder.save(testInfo);
});
