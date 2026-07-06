import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { seedAuthenticatedSession, mockEventScenario } from "../../helpers/mock-api.js";

test("Created Event Record Remains Available After Creation", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder(
    "created_event_record_persists_after_submission",
    "Created Event Record Remains Available After Creation"
  );

  const createdEvent = {
    id: "event_persist_001",
    title: "Engineering Summit 2026",
    description: "Quarterly summit covering roadmap planning and demos.",
    location: "Virtual Campus",
    startDate: "2026-04-20",
    endDate: "2026-04-21",
    registrationCount: 0,
  };

  await recorder.recordStep("Seed authenticated session and mock event persistence scenario");
  await seedAuthenticatedSession(page);
  await mockEventScenario(page, { initialEvents: [], createdEvent });

  await recorder.recordStep("Navigate to the events page and open the creation form");
  await page.goto("/events");
  await expect(
    page.getByRole("heading", { name: "Events Management Setup" })
  ).toBeVisible();
  await page.getByRole("button", { name: "Create New Event" }).click();

  await recorder.recordStep("Create a new event with valid details");
  await page.getByPlaceholder("e.g. Spring Hackathon 2026").fill(createdEvent.title);
  await page.getByPlaceholder("Summarize event activities...").fill(createdEvent.description);
  await page.getByPlaceholder("e.g. Auditorium A or Virtual").fill(createdEvent.location);
  await page.locator('input[name="startDate"]').fill(createdEvent.startDate);
  await page.locator('input[name="endDate"]').fill(createdEvent.endDate);
  await page.getByRole("button", { name: "Publish Event" }).click();
  await expect(page.getByText("Event created successfully!")).toBeVisible();

  await recorder.recordStep("Access available event records after submission");
  await page.reload();
  await expect(
    page.getByRole("heading", { name: "Events Management Setup" })
  ).toBeVisible();

  await recorder.recordStep("Verify the created event record remains available with the same submitted values");
  await expect(page.getByRole("heading", { name: createdEvent.title })).toBeVisible();
  await expect(page.getByText(createdEvent.description)).toBeVisible();
  await expect(page.getByText(createdEvent.location)).toBeVisible();
  await expect(
    page.getByText(`${createdEvent.startDate} to ${createdEvent.endDate}`)
  ).toBeVisible();
  await expect(page.getByText("0 registered")).toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:created_event_record_persists_after_submission");
  await recorder.save(testInfo);
});
