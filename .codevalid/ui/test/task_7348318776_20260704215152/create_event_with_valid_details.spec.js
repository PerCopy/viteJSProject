import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  mockEventScenario,
  seedAuthenticatedSession,
} from "../../helpers/mock-api.js";

test("Create Event Successfully With Valid Inputs", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder("create_event_with_valid_details", "Create Event Successfully With Valid Inputs");

  const eventPayload = {
    id: "evt-valid-001",
    title: "Spring Hackathon 2026",
    description: "A collaborative build event for students and mentors.",
    location: "Auditorium A",
    startDate: "2026-04-10",
    endDate: "2026-04-12",
    registrationCount: 0,
  };

  await recorder.step("Seed authenticated session for protected events page");
  await seedAuthenticatedSession(page);

  await recorder.step("Mock initial empty events list and successful event creation APIs");
  await mockEventScenario(page, {
    initialEvents: [],
    createdEvent: eventPayload,
  });

  await recorder.step("Navigate to the events management interface");
  await page.goto("/events");
  await expect(page.getByRole("heading", { name: "Events Management Setup" })).toBeVisible();
  await expect(page.getByText("No Events Found")).toBeVisible();

  await recorder.step("Open the new event form");
  await page.getByRole("button", { name: /Create New Event/i }).click();
  await expect(page.getByRole("heading", { name: "New Event Setup" })).toBeVisible();

  await recorder.step("Enter a valid title into the title field");
  await page.getByPlaceholder("e.g. Spring Hackathon 2026").fill(eventPayload.title);

  await recorder.step("Enter a valid description into the description field");
  await page.getByPlaceholder("Summarize event activities...").fill(eventPayload.description);

  await recorder.step("Enter a valid location into the location field");
  await page.getByPlaceholder("e.g. Auditorium A or Virtual").fill(eventPayload.location);

  await recorder.step("Enter a valid start date");
  await page.locator('input[name="startDate"]').fill(eventPayload.startDate);

  await recorder.step("Enter a valid end date later than or equal to the start date");
  await page.locator('input[name="endDate"]').fill(eventPayload.endDate);

  await recorder.step("Submit the event creation form");
  await page.getByRole("button", { name: "Publish Event" }).click();

  await recorder.step("Verify success feedback and access the created event record from the listing");
  await expect(page.getByText("Event created successfully!")).toBeVisible();
  await expect(page.getByText(eventPayload.title)).toBeVisible();
  await expect(page.getByText(eventPayload.description)).toBeVisible();
  await expect(page.getByText(eventPayload.location)).toBeVisible();
  await expect(page.getByText(`${eventPayload.startDate} to ${eventPayload.endDate}`)).toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:create_event_with_valid_details");
  await recorder.save(testInfo);
});
