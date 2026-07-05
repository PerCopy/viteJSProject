import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../helpers/execution-recorder.js";
import {
  mockEventScenario,
  seedAuthenticatedSession,
} from "../helpers/mock-api.js";

test("Create Event Using Same Start and End Date", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder("create_event_with_same_start_and_end_date", "Create Event Using Same Start and End Date");

  const singleDayEvent = {
    id: "evt-sameday-001",
    title: "Board Review Day",
    description: "Single-day review session for quarterly milestones.",
    location: "Conference Room B",
    startDate: "2026-08-20",
    endDate: "2026-08-20",
    registrationCount: 0,
  };

  await recorder.step("Seed authenticated session for protected events page");
  await seedAuthenticatedSession(page);

  await recorder.step("Mock initial events API and successful same-day event creation API");
  await mockEventScenario(page, {
    initialEvents: [],
    createdEvent: singleDayEvent,
  });

  await recorder.step("Open the event creation interface");
  await page.goto("/events");
  await page.getByRole("button", { name: /Create New Event/i }).click();

  await recorder.step("Enter a valid title");
  await page.getByPlaceholder("e.g. Spring Hackathon 2026").fill(singleDayEvent.title);

  await recorder.step("Enter a valid description");
  await page.getByPlaceholder("Summarize event activities...").fill(singleDayEvent.description);

  await recorder.step("Enter a valid location");
  await page.getByPlaceholder("e.g. Auditorium A or Virtual").fill(singleDayEvent.location);

  await recorder.step("Enter a start date");
  await page.getByLabel("Start Date *").fill(singleDayEvent.startDate);

  await recorder.step("Enter the same value for the end date");
  await page.getByLabel("End Date *").fill(singleDayEvent.endDate);

  await recorder.step("Submit the event creation form");
  await page.getByRole("button", { name: "Publish Event" }).click();

  await recorder.step("Verify the event record is created and stores matching start and end date");
  await expect(page.getByText("Event created successfully!")).toBeVisible();
  await expect(page.getByText(singleDayEvent.title)).toBeVisible();
  await expect(page.getByText(singleDayEvent.description)).toBeVisible();
  await expect(page.getByText(singleDayEvent.location)).toBeVisible();
  await expect(page.getByText(`${singleDayEvent.startDate} to ${singleDayEvent.endDate}`)).toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:create_event_with_same_start_and_end_date");
  await recorder.save(testInfo);
});
