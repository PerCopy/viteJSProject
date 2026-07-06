import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { seedAuthenticatedSession, mockEventScenario } from "../../helpers/mock-api.js";

test("Create Event With Special Characters And Long Text", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder(
    "create_event_with_special_characters_and_long_text",
    "Create Event With Special Characters And Long Text"
  );

  const longDescription =
    "Launch agenda 2026: keynotes, demos, partner booths, Q&A, awards, and networking. Includes symbols ! @ # $ % ^ & * ( ) _ + [ ] { } ; : ' \" , . < > / ? with room codes A1-B2-C3 and attendee notes 12345.";

  const createdEvent = {
    id: "event-special-chars-long-text-001",
    title: "Launch & Networking Expo 2026 #1",
    description: longDescription,
    location: "San Francisco - Hall A/B",
    startDate: "2026-11-01",
    endDate: "2026-11-03",
    registrationCount: 0,
  };

  await recorder.step("Seed authenticated session and mock event APIs");
  await seedAuthenticatedSession(page);
  await mockEventScenario(page, {
    initialEvents: [],
    createdEvent,
  });

  await recorder.step("Open the Events page");
  await page.goto("/events");
  await expect(
    page.getByRole("heading", { name: "Events Management Setup" })
  ).toBeVisible();

  await recorder.step("Open the create event form");
  await page.getByRole("button", { name: /Create New Event/i }).click();

  await recorder.step("Enter special characters and long text event details");
  await page.locator('input[name="title"]').fill(createdEvent.title);
  await page.locator('textarea[name="description"]').fill(createdEvent.description);
  await page.locator('input[name="location"]').fill(createdEvent.location);
  await page.locator('input[name="startDate"]').fill(createdEvent.startDate);
  await page.locator('input[name="endDate"]').fill(createdEvent.endDate);

  await recorder.step("Submit the event creation form");
  await page.getByRole("button", { name: /Publish Event/i }).click();

  await recorder.step("Locate the created event record and verify exact submitted values");
  await expect(page.getByText("Event created successfully!")).toBeVisible();
  await expect(page.getByText(createdEvent.title)).toBeVisible();
  await expect(page.getByText(createdEvent.description)).toBeVisible();
  await expect(page.getByText(createdEvent.location)).toBeVisible();
  await expect(
    page.getByText(`${createdEvent.startDate} to ${createdEvent.endDate}`)
  ).toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:create_event_with_special_characters_and_long_text");
  await recorder.save(testInfo);
});
