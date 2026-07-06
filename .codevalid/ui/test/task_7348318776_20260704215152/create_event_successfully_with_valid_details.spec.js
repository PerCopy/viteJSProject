import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { seedAuthenticatedSession, mockEventScenario } from "../../helpers/mock-api.js";

test("Create Event Successfully With Valid Details", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder(
    "create_event_successfully_with_valid_details",
    "Create Event Successfully With Valid Details"
  );

  const createdEvent = {
    id: "event-tech-conference-2026",
    title: "Tech Conference 2026",
    description: "Annual technology conference for developers",
    location: "New York City",
    startDate: "2026-08-10",
    endDate: "2026-08-12",
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
  await expect(
    page.getByRole("heading", { name: "New Event Setup" })
  ).toBeVisible();

  await recorder.step("Enter title, description, location, start date, and end date");
  await page.locator('input[name="title"]').fill("Tech Conference 2026");
  await page
    .locator('textarea[name="description"]')
    .fill("Annual technology conference for developers");
  await page.locator('input[name="location"]').fill("New York City");
  await page.locator('input[name="startDate"]').fill("2026-08-10");
  await page.locator('input[name="endDate"]').fill("2026-08-12");

  await recorder.step("Submit the event creation form");
  await page.getByRole("button", { name: /Publish Event/i }).click();

  await recorder.step("Verify the event is created and displayed with submitted details");
  await expect(page.getByText("Event created successfully!")).toBeVisible();
  await expect(page.getByText("Tech Conference 2026")).toBeVisible();
  await expect(
    page.getByText("Annual technology conference for developers")
  ).toBeVisible();
  await expect(page.getByText("New York City")).toBeVisible();
  await expect(page.getByText("2026-08-10 to 2026-08-12")).toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:create_event_successfully_with_valid_details");
  await recorder.save(testInfo);
});
