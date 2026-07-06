import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { seedAuthenticatedSession, mockEventScenario } from "../../helpers/mock-api.js";

test("Created Event Remains Available After Creation", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder(
    "created_event_remains_available_after_creation",
    "Created Event Remains Available After Creation"
  );

  const createdEvent = {
    id: "event-persistent-access-001",
    title: "Persistent Access Summit 2026",
    description: "Created event remains available after refresh",
    location: "Seattle",
    startDate: "2026-12-01",
    endDate: "2026-12-03",
    registrationCount: 0,
  };

  await recorder.step("Seed authenticated session and mock persistent event APIs");
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

  await recorder.step("Create a new event with valid details");
  await page.getByRole("button", { name: /Create New Event/i }).click();
  await page.locator('input[name="title"]').fill(createdEvent.title);
  await page.locator('textarea[name="description"]').fill(createdEvent.description);
  await page.locator('input[name="location"]').fill(createdEvent.location);
  await page.locator('input[name="startDate"]').fill(createdEvent.startDate);
  await page.locator('input[name="endDate"]').fill(createdEvent.endDate);
  await page.getByRole("button", { name: /Publish Event/i }).click();

  await expect(page.getByText("Event created successfully!")).toBeVisible();
  await expect(page.getByText(createdEvent.title)).toBeVisible();

  await recorder.step("Refresh the Events page");
  await page.reload();
  await expect(
    page.getByRole("heading", { name: "Events Management Setup" })
  ).toBeVisible();

  await recorder.step("Locate the newly created event and verify details remain available");
  await expect(page.getByText(createdEvent.title)).toBeVisible();
  await expect(page.getByText(createdEvent.description)).toBeVisible();
  await expect(page.getByText(createdEvent.location)).toBeVisible();
  await expect(
    page.getByText(`${createdEvent.startDate} to ${createdEvent.endDate}`)
  ).toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:created_event_remains_available_after_creation");
  await recorder.save(testInfo);
});
