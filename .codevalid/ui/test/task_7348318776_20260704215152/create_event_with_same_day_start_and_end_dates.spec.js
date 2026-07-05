import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../helpers/execution-recorder.js";
import { seedAuthenticatedSession, mockEventScenario } from "../helpers/mock-api.js";

test("Create Event With Same Start and End Date", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder("create_event_with_same_day_start_and_end_dates", testInfo);

  const eventDetails = {
    id: "event-one-day-workshop",
    title: "One Day Workshop",
    description: "Single day event",
    location: "Room 101",
    startDate: "2026-11-15",
    endDate: "2026-11-15",
    registrationCount: 0,
  };

  await recorder.step("Seed authenticated session and mock events API", async () => {
    await seedAuthenticatedSession(page);
    await mockEventScenario(page, {
      initialEvents: [],
      createdEvent: eventDetails,
    });
  });

  await recorder.step("Open the Events page and the create form", async () => {
    await page.goto("/events");
    await expect(page.getByRole("heading", { name: "Events Management Setup" })).toBeVisible();
    await page.getByRole("button", { name: "Create New Event" }).click();
    await expect(page.getByRole("heading", { name: "New Event Setup" })).toBeVisible();
  });

  await recorder.step("Enter the event fields including same start and end date", async () => {
    await page.getByPlaceholder("e.g. Spring Hackathon 2026").fill(eventDetails.title);
    await page.getByPlaceholder("Summarize event activities...").fill(eventDetails.description);
    await page.getByPlaceholder("e.g. Auditorium A or Virtual").fill(eventDetails.location);
    await page.getByLabel("Start Date *").fill(eventDetails.startDate);
    await page.getByLabel("End Date *").fill(eventDetails.endDate);
  });

  await recorder.step("Submit the event creation form", async () => {
    await page.getByRole("button", { name: "Publish Event" }).click();
    await expect(page.getByText("Event created successfully!")).toBeVisible();
  });

  await recorder.step("Locate the created event and verify the same stored dates", async () => {
    await expect(page.getByRole("heading", { name: eventDetails.title })).toBeVisible();
    await expect(page.getByText(eventDetails.description)).toBeVisible();
    await expect(page.getByText(eventDetails.location)).toBeVisible();
    await expect(page.getByText(`${eventDetails.startDate} to ${eventDetails.endDate}`)).toBeVisible();
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:create_event_with_same_day_start_and_end_dates");
  await recorder.save(testInfo);
});
