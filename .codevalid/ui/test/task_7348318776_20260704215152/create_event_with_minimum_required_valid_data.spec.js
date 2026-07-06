import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { seedAuthenticatedSession, mockEventScenario } from "../../helpers/mock-api.js";

test("Create Event With Minimum Valid Data", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder(
    "create_event_with_minimum_required_valid_data",
    "Create Event With Minimum Valid Data"
  );

  const createdEvent = {
    id: "event-minimum-valid-001",
    title: "QA Sync",
    description: "",
    location: "Virtual",
    startDate: "2026-07-01",
    endDate: "2026-07-02",
    registrationCount: 0,
  };

  await recorder.step("Seed session and mock successful event creation");
  await seedAuthenticatedSession(page);
  await mockEventScenario(page, { initialEvents: [], createdEvent });

  await recorder.step("Open the events page and reveal the create form");
  await page.goto("/events");
  await page.getByRole("button", { name: /create new event/i }).click();

  await recorder.step("Enter valid required values for all event fields");
  await page.getByPlaceholder("e.g. Spring Hackathon 2026").fill(createdEvent.title);
  await page.getByPlaceholder("Summarize event activities...").fill(createdEvent.description);
  await page.getByPlaceholder("e.g. Auditorium A or Virtual").fill(createdEvent.location);
  await page.locator('input[name="startDate"]').fill(createdEvent.startDate);
  await page.locator('input[name="endDate"]').fill(createdEvent.endDate);

  await recorder.step("Submit and verify the event becomes available for later access");
  await page.getByRole("button", { name: /publish event/i }).click();
  await expect(page.getByText("Event created successfully!")).toBeVisible();
  await expect(page.getByText(createdEvent.title)).toBeVisible();
  await expect(page.getByText(createdEvent.location)).toBeVisible();
  await expect(
    page.getByText(`${createdEvent.startDate} to ${createdEvent.endDate}`)
  ).toBeVisible();

  await page.reload();
  await expect(page.getByText(createdEvent.title)).toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:create_event_with_minimum_required_valid_data");
  await recorder.save(testInfo);
});
