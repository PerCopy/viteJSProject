import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { seedAuthenticatedSession, mockEventScenario } from "../../helpers/mock-api.js";

test("Create Event Successfully With Valid Inputs", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder(
    "create_event_successfully_with_valid_details",
    "Create Event Successfully With Valid Inputs"
  );

  const createdEvent = {
    id: "evt-tech-summit-2026",
    title: "Tech Summit 2026",
    description: "Annual technology conference",
    location: "New York City",
    startDate: "2026-05-10",
    endDate: "2026-05-12",
    registrationCount: 0,
  };

  await recorder.recordStep("Seed authenticated session and event API mocks");
  await seedAuthenticatedSession(page);
  await mockEventScenario(page, { initialEvents: [], createdEvent });

  await recorder.recordStep("Navigate to the Events page");
  await page.goto("/events");
  await expect(
    page.getByRole("heading", { name: "Events Management Setup" })
  ).toBeVisible();

  await recorder.recordStep("Open the create event form");
  await page.getByRole("button", { name: /create new event/i }).click();
  await expect(
    page.getByRole("heading", { name: "New Event Setup" })
  ).toBeVisible();

  await recorder.recordStep("Enter valid event details");
  await page.locator('input[name="title"]').fill("Tech Summit 2026");
  await page.locator('textarea[name="description"]').fill("Annual technology conference");
  await page.locator('input[name="location"]').fill("New York City");
  await page.locator('input[name="startDate"]').fill("2026-05-10");
  await page.locator('input[name="endDate"]').fill("2026-05-12");

  await recorder.recordStep("Submit the event creation form");
  await page.getByRole("button", { name: /publish event/i }).click();

  await recorder.recordStep("Verify success message and created event record are displayed");
  await expect(page.getByText("Event created successfully!")).toBeVisible();
  await expect(page.getByText("Tech Summit 2026")).toBeVisible();
  await expect(page.getByText("Annual technology conference")).toBeVisible();
  await expect(page.getByText("New York City")).toBeVisible();
  await expect(page.getByText("2026-05-10 to 2026-05-12")).toBeVisible();
  await expect(page.getByText("0 registered")).toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:create_event_successfully_with_valid_details");
  await recorder.save(testInfo);
});
