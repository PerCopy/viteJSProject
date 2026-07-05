import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  mockEventScenario,
  seedAuthenticatedSession,
} from "../../helpers/mock-api.js";

test("Created Event Is Available After Creation", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder("created_event_persists_for_later_access", "Created Event Is Available After Creation");

  const persistedEvent = {
    id: "evt-persist-001",
    title: "Partner Summit 2026",
    description: "Annual strategy meeting with partners and stakeholders.",
    location: "Innovation Hub - Floor 3",
    startDate: "2026-06-15",
    endDate: "2026-06-16",
    registrationCount: 0,
  };

  await recorder.step("Seed authenticated session for protected events page");
  await seedAuthenticatedSession(page);

  await recorder.step("Mock empty initial events list and successful create event response");
  await mockEventScenario(page, {
    initialEvents: [],
    createdEvent: persistedEvent,
  });

  await recorder.step("Navigate to the event creation interface");
  await page.goto("/events");
  await expect(page.getByRole("heading", { name: "Events Management Setup" })).toBeVisible();

  await recorder.step("Create a new event using valid title, description, location, start date, and end date values");
  await page.getByRole("button", { name: /Create New Event/i }).click();
  await page.getByPlaceholder("e.g. Spring Hackathon 2026").fill(persistedEvent.title);
  await page.getByPlaceholder("Summarize event activities...").fill(persistedEvent.description);
  await page.getByPlaceholder("e.g. Auditorium A or Virtual").fill(persistedEvent.location);
  await page.locator('input[name="startDate"]').fill(persistedEvent.startDate);
  await page.locator('input[name="endDate"]').fill(persistedEvent.endDate);

  await recorder.step("Complete the event submission");
  await page.getByRole("button", { name: "Publish Event" }).click();
  await expect(page.getByText("Event created successfully!")).toBeVisible();

  await recorder.step("Navigate to the application area where created events can be accessed");
  await page.goto("/events");
  await expect(page.getByRole("heading", { name: "Events Management Setup" })).toBeVisible();

  await recorder.step("Locate the newly created event and confirm stored details persist");
  await expect(page.getByText(persistedEvent.title)).toBeVisible();
  await expect(page.getByText(persistedEvent.description)).toBeVisible();
  await expect(page.getByText(persistedEvent.location)).toBeVisible();
  await expect(page.getByText(`${persistedEvent.startDate} to ${persistedEvent.endDate}`)).toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:created_event_persists_for_later_access");
  await recorder.save(testInfo);
});
