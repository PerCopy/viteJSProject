import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../helpers/execution-recorder.js";
import { seedAuthenticatedSession, mockEventScenario } from "../helpers/mock-api.js";

test("Create Event Successfully With Valid Details", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder("create_event_successfully_with_valid_data", testInfo);

  const eventDetails = {
    id: "event-annual-tech-conference",
    title: "Annual Tech Conference",
    description: "A conference for developers and technology leaders",
    location: "New York Convention Center",
    startDate: "2026-09-10",
    endDate: "2026-09-12",
    registrationCount: 0,
  };

  await recorder.step("Seed authenticated session and mock events API", async () => {
    await seedAuthenticatedSession(page);
    await mockEventScenario(page, {
      initialEvents: [],
      createdEvent: eventDetails,
    });
  });

  await recorder.step("Open the Events page", async () => {
    await page.goto("/events");
    await expect(page.getByRole("heading", { name: "Events Management Setup" })).toBeVisible();
    await expect(page.getByRole("button", { name: "Create New Event" })).toBeVisible();
  });

  await recorder.step("Open the create event form", async () => {
    await page.getByRole("button", { name: "Create New Event" }).click();
    await expect(page.getByRole("heading", { name: "New Event Setup" })).toBeVisible();
  });

  await recorder.step("Enter event title", async () => {
    await page.getByPlaceholder("e.g. Spring Hackathon 2026").fill(eventDetails.title);
  });

  await recorder.step("Enter event description", async () => {
    await page.getByPlaceholder("Summarize event activities...").fill(eventDetails.description);
  });

  await recorder.step("Enter event location", async () => {
    await page.getByPlaceholder("e.g. Auditorium A or Virtual").fill(eventDetails.location);
  });

  await recorder.step("Enter start and end dates", async () => {
    await page.getByLabel("Start Date *").fill(eventDetails.startDate);
    await page.getByLabel("End Date *").fill(eventDetails.endDate);
  });

  await recorder.step("Submit the event creation form", async () => {
    await page.getByRole("button", { name: "Publish Event" }).click();
    await expect(page.getByText("Event created successfully!")).toBeVisible();
  });

  await recorder.step("Locate the newly created event record and verify stored details", async () => {
    await expect(page.getByRole("heading", { name: eventDetails.title })).toBeVisible();
    await expect(page.getByText(eventDetails.description)).toBeVisible();
    await expect(page.getByText(eventDetails.location)).toBeVisible();
    await expect(page.getByText(`${eventDetails.startDate} to ${eventDetails.endDate}`)).toBeVisible();
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:create_event_successfully_with_valid_data");
  await recorder.save(testInfo);
});
