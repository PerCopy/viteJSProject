import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { seedAuthenticatedSession, mockEventScenario } from "../../helpers/mock-api.js";

test("Create Event Using Boundary Date Values", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder(
    "create_event_with_boundary_date_values",
    "Create Event Using Boundary Date Values"
  );

  const createdEvent = {
    id: "event_boundary_dates_001",
    title: "Boundary Date Validation Event",
    description: "An event created with immediately consecutive valid date values.",
    location: "Virtual",
    startDate: "2026-08-30",
    endDate: "2026-08-31",
    registrationCount: 0,
  };

  await recorder.recordStep("Seed authenticated session and mock boundary date event creation scenario");
  await seedAuthenticatedSession(page);
  await mockEventScenario(page, { initialEvents: [], createdEvent });

  await recorder.recordStep("Navigate to the events page and open the create form");
  await page.goto("/events");
  await expect(
    page.getByRole("heading", { name: "Events Management Setup" })
  ).toBeVisible();
  await page.getByRole("button", { name: "Create New Event" }).click();

  await recorder.recordStep("Enter valid event details using boundary date values where start date is immediately before end date");
  await page.getByPlaceholder("e.g. Spring Hackathon 2026").fill(createdEvent.title);
  await page.getByPlaceholder("Summarize event activities...").fill(createdEvent.description);
  await page.getByPlaceholder("e.g. Auditorium A or Virtual").fill(createdEvent.location);
  await page.locator('input[name="startDate"]').fill(createdEvent.startDate);
  await page.locator('input[name="endDate"]').fill(createdEvent.endDate);

  await recorder.recordStep("Submit the event creation form");
  await page.getByRole("button", { name: "Publish Event" }).click();

  await recorder.recordStep("Verify the boundary date event is created and stored correctly");
  await expect(page.getByText("Event created successfully!")).toBeVisible();
  await expect(page.getByRole("heading", { name: createdEvent.title })).toBeVisible();
  await expect(page.getByText(createdEvent.description)).toBeVisible();
  await expect(page.getByText(createdEvent.location)).toBeVisible();
  await expect(
    page.getByText(`${createdEvent.startDate} to ${createdEvent.endDate}`)
  ).toBeVisible();
  await expect(page.getByText("0 registered")).toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:create_event_with_boundary_date_values");
  await recorder.save(testInfo);
});
