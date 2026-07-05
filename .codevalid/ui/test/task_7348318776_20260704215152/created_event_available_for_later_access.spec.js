import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { seedAuthenticatedSession, mockEventScenario } from "../../helpers/mock-api.js";

test("Created Event Remains Available After Reload", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder("created_event_available_for_later_access", "Created Event Remains Available After Reload");

  const eventDetails = {
    id: "event-persistent-event",
    title: "Persistent Event",
    description: "Persistence verification",
    location: "Online",
    startDate: "2026-10-01",
    endDate: "2026-10-02",
    registrationCount: 0,
  };

  await recorder.step("Seed authenticated session and mock events API", async () => {
    await seedAuthenticatedSession(page);
    await mockEventScenario(page, {
      initialEvents: [],
      createdEvent: eventDetails,
    });
  });

  await recorder.step("Open the Events page", async () => {
    await page.goto("/events");
    await expect(page.getByRole("heading", { name: "Events Management Setup" })).toBeVisible();
  });

  await recorder.step("Create an event with the requested details", async () => {
    await page.getByRole("button", { name: "Create New Event" }).click();
    await page.getByPlaceholder("e.g. Spring Hackathon 2026").fill(eventDetails.title);
    await page.getByPlaceholder("Summarize event activities...").fill(eventDetails.description);
    await page.getByPlaceholder("e.g. Auditorium A or Virtual").fill(eventDetails.location);
    await page.locator('input[name="startDate"]').fill(eventDetails.startDate);
    await page.locator('input[name="endDate"]').fill(eventDetails.endDate);
    await page.getByRole("button", { name: "Publish Event" }).click();
    await expect(page.getByText("Event created successfully!")).toBeVisible();
  });

  await recorder.step("Confirm the created event appears in the events list", async () => {
    await expect(page.getByRole("heading", { name: eventDetails.title })).toBeVisible();
    await expect(page.getByText(eventDetails.description)).toBeVisible();
    await expect(page.getByText(eventDetails.location)).toBeVisible();
    await expect(page.getByText(`${eventDetails.startDate} to ${eventDetails.endDate}`)).toBeVisible();
  });

  await recorder.step("Refresh the page and revisit the Events view", async () => {
    await page.reload();
    await expect(page.getByRole("heading", { name: "Events Management Setup" })).toBeVisible();
  });

  await recorder.step("Locate the previously created event after reload", async () => {
    await expect(page.getByRole("heading", { name: eventDetails.title })).toBeVisible();
    await expect(page.getByText(eventDetails.description)).toBeVisible();
    await expect(page.getByText(eventDetails.location)).toBeVisible();
    await expect(page.getByText(`${eventDetails.startDate} to ${eventDetails.endDate}`)).toBeVisible();
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:created_event_available_for_later_access");
  await recorder.save(testInfo);
});
