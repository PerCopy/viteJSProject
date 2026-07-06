import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { seedAuthenticatedSession, mockEventScenario } from "../../helpers/mock-api.js";

test("Created Event Remains Available After Creation", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder(
    "created_event_available_for_later_access",
    "Created Event Remains Available After Creation"
  );

  const createdEvent = {
    id: "evt-developer-meetup",
    title: "Developer Meetup",
    description: "Networking event for developers",
    location: "San Francisco",
    startDate: "2026-08-01",
    endDate: "2026-08-02",
    registrationCount: 0,
  };

  await recorder.recordStep("Seed authenticated session and mock events API with persistence after creation");
  await seedAuthenticatedSession(page);
  await mockEventScenario(page, { initialEvents: [], createdEvent });

  await recorder.recordStep("Navigate to the Events page and open the create form");
  await page.goto("/events");
  await expect(
    page.getByRole("heading", { name: "Events Management Setup" })
  ).toBeVisible();
  await page.getByRole("button", { name: /create new event/i }).click();

  await recorder.recordStep("Fill in valid event details and submit");
  await page.locator('input[name="title"]').fill("Developer Meetup");
  await page.locator('textarea[name="description"]').fill("Networking event for developers");
  await page.locator('input[name="location"]').fill("San Francisco");
  await page.locator('input[name="startDate"]').fill("2026-08-01");
  await page.locator('input[name="endDate"]').fill("2026-08-02");
  await page.getByRole("button", { name: /publish event/i }).click();

  await recorder.recordStep("Verify the event appears immediately after creation");
  await expect(page.getByText("Developer Meetup")).toBeVisible();
  await expect(page.getByText("Networking event for developers")).toBeVisible();
  await expect(page.getByText("San Francisco")).toBeVisible();
  await expect(page.getByText("2026-08-01 to 2026-08-02")).toBeVisible();

  await recorder.recordStep("Refresh the Events page to verify later access");
  await page.reload();
  await expect(
    page.getByRole("heading", { name: "Events Management Setup" })
  ).toBeVisible();

  await recorder.recordStep("Verify the created event remains available after reload");
  await expect(page.getByText("Developer Meetup")).toBeVisible();
  await expect(page.getByText("Networking event for developers")).toBeVisible();
  await expect(page.getByText("San Francisco")).toBeVisible();
  await expect(page.getByText("2026-08-01 to 2026-08-02")).toBeVisible();
  await expect(page.getByText("0 registered")).toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:created_event_available_for_later_access");
  await recorder.save(testInfo);
});
