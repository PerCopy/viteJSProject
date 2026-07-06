import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { seedAuthenticatedSession, mockEventScenario } from "../../helpers/mock-api.js";

test("Store All Submitted Event Fields In Created Record", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder(
    "store_all_submitted_event_fields",
    "Store All Submitted Event Fields In Created Record"
  );

  const createdEvent = {
    id: "event-store-fields-001",
    title: "Partner Summit 2026",
    description: "Executive sessions, product demos, and partner planning workshops.",
    location: "Virtual Conference Hub",
    startDate: "2026-08-18",
    endDate: "2026-08-20",
    registrationCount: 0,
  };

  await recorder.step("Seed authenticated session and register event mocks");
  await seedAuthenticatedSession(page);
  await mockEventScenario(page, { initialEvents: [], createdEvent });

  await recorder.step("Open the events page");
  await page.goto("/events");
  await expect(
    page.getByRole("heading", { name: "Events Management Setup" })
  ).toBeVisible();

  await recorder.step("Open the creation form and enter all event fields");
  await page.getByRole("button", { name: /create new event/i }).click();
  await page.getByPlaceholder("e.g. Spring Hackathon 2026").fill(createdEvent.title);
  await page.getByPlaceholder("Summarize event activities...").fill(createdEvent.description);
  await page.getByPlaceholder("e.g. Auditorium A or Virtual").fill(createdEvent.location);
  await page.locator('input[name="startDate"]').fill(createdEvent.startDate);
  await page.locator('input[name="endDate"]').fill(createdEvent.endDate);

  await recorder.step("Submit the event creation form");
  await page.getByRole("button", { name: /publish event/i }).click();
  await expect(page.getByText("Event created successfully!")).toBeVisible();

  await recorder.step("Access the created event record in the events listing");
  await expect(page.getByText(createdEvent.title)).toBeVisible();
  await expect(page.getByText(createdEvent.description)).toBeVisible();
  await expect(page.getByText(createdEvent.location)).toBeVisible();
  await expect(
    page.getByText(`${createdEvent.startDate} to ${createdEvent.endDate}`)
  ).toBeVisible();

  await recorder.step("Reload and confirm the stored fields remain available");
  await page.reload();
  await expect(page.getByText(createdEvent.title)).toBeVisible();
  await expect(page.getByText(createdEvent.description)).toBeVisible();
  await expect(page.getByText(createdEvent.location)).toBeVisible();
  await expect(
    page.getByText(`${createdEvent.startDate} to ${createdEvent.endDate}`)
  ).toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:store_all_submitted_event_fields");
  await recorder.save(testInfo);
});
