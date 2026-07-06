import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { seedAuthenticatedSession, mockEventScenario } from "../../helpers/mock-api.js";

test("Create Event Successfully With Valid Inputs", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder(
    "create_event_successfully_with_valid_inputs",
    "Create Event Successfully With Valid Inputs"
  );

  const createdEvent = {
    id: "event-create-success-001",
    title: "Spring Hackathon 2026",
    description: "A two-day innovation event for students and mentors.",
    location: "Auditorium A",
    startDate: "2026-05-10",
    endDate: "2026-05-12",
    registrationCount: 0,
  };

  await recorder.step("Seed authenticated session and mock event APIs");
  await seedAuthenticatedSession(page);
  await mockEventScenario(page, { initialEvents: [], createdEvent });

  await recorder.step("Open the protected events page");
  await page.goto("/events");
  await expect(
    page.getByRole("heading", { name: "Events Management Setup" })
  ).toBeVisible();

  await recorder.step("Open the event creation interface");
  await page.getByRole("button", { name: /create new event/i }).click();
  await expect(
    page.getByRole("heading", { name: "New Event Setup" })
  ).toBeVisible();

  await recorder.step("Enter a valid title");
  await page.getByPlaceholder("e.g. Spring Hackathon 2026").fill(createdEvent.title);

  await recorder.step("Enter a valid description");
  await page.getByPlaceholder("Summarize event activities...").fill(createdEvent.description);

  await recorder.step("Enter a valid location");
  await page.getByPlaceholder("e.g. Auditorium A or Virtual").fill(createdEvent.location);

  await recorder.step("Enter a valid start date that occurs before the end date");
  await page.locator('input[name="startDate"]').fill(createdEvent.startDate);

  await recorder.step("Enter a valid end date after the start date");
  await page.locator('input[name="endDate"]').fill(createdEvent.endDate);

  await recorder.step("Submit the event creation form");
  await page.getByRole("button", { name: /publish event/i }).click();

  await expect(page.getByText("Event created successfully!")).toBeVisible();
  await expect(page.getByText(createdEvent.title)).toBeVisible();
  await expect(page.getByText(createdEvent.description)).toBeVisible();
  await expect(page.getByText(createdEvent.location)).toBeVisible();
  await expect(
    page.getByText(`${createdEvent.startDate} to ${createdEvent.endDate}`)
  ).toBeVisible();
  await expect(page.getByText("0 registered")).toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:create_event_successfully_with_valid_inputs");
  await recorder.save(testInfo);
});
