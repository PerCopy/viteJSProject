import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { seedAuthenticatedSession, mockEventScenario } from "../../helpers/mock-api.js";

test("Created Event Remains Accessible After Creation", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder(
    "created_event_remains_accessible_after_creation",
    "Created Event Remains Accessible After Creation"
  );

  const createdEvent = {
    id: "event-accessible-later-001",
    title: "Community Meetup 2026",
    description: "Networking, demos, and lightning talks for the local tech community.",
    location: "Innovation Center",
    startDate: "2026-10-14",
    endDate: "2026-10-15",
    registrationCount: 0,
  };

  await recorder.step("Seed authentication and prepare persistent event API mocks");
  await seedAuthenticatedSession(page);
  await mockEventScenario(page, { initialEvents: [], createdEvent });

  await recorder.step("Create a new event using valid event details");
  await page.goto("/events");
  await page.getByRole("button", { name: /create new event/i }).click();
  await page.getByPlaceholder("e.g. Spring Hackathon 2026").fill(createdEvent.title);
  await page.getByPlaceholder("Summarize event activities...").fill(createdEvent.description);
  await page.getByPlaceholder("e.g. Auditorium A or Virtual").fill(createdEvent.location);
  await page.locator('input[name="startDate"]').fill(createdEvent.startDate);
  await page.locator('input[name="endDate"]').fill(createdEvent.endDate);
  await page.getByRole("button", { name: /publish event/i }).click();
  await expect(page.getByText("Event created successfully!")).toBeVisible();
  await expect(page.getByText(createdEvent.title)).toBeVisible();

  await recorder.step("Revisit the events page to access the created record again");
  await page.goto("/events");
  await expect(
    page.getByRole("heading", { name: "Events Management Setup" })
  ).toBeVisible();
  await expect(page.getByText(createdEvent.title)).toBeVisible();
  await expect(page.getByText(createdEvent.description)).toBeVisible();
  await expect(page.getByText(createdEvent.location)).toBeVisible();
  await expect(
    page.getByText(`${createdEvent.startDate} to ${createdEvent.endDate}`)
  ).toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:created_event_remains_accessible_after_creation");
  await recorder.save(testInfo);
});
