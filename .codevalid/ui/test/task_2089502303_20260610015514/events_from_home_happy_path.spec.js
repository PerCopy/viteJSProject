import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession, setupEventCreationScenario } from "../../helpers/mock-api.js";

test("Create Event via Navigation from Home Page", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "events_from_home_happy_path",
    testName: "Create Event via Navigation from Home Page",
  });

  const createdEvent = {
    id: "event-annual-summit",
    title: "Annual Summit",
    description: "Industry leaders gathering",
    location: "San Francisco",
    startDate: "2024-10-15",
    endDate: "2024-10-17",
    registrationCount: 0,
  };

  await recorder.step("Seed authenticated session and event mocks");
  await setupAuthenticatedSession(page);
  await setupEventCreationScenario(page, {
    initialEvents: [],
    expectedCreatePayload: {
      title: "Annual Summit",
      description: "Industry leaders gathering",
      location: "San Francisco",
      startDate: "2024-10-15",
      endDate: "2024-10-17",
    },
    createdEvent,
  });

  await recorder.step("Navigate to home route");
  await page.goto("/");
  await expect(page).toHaveURL(/\/$/);

  await recorder.step("Use navbar to navigate to events");
  await page.getByRole("link", { name: /Events Setup/i }).click();
  await expect(page).toHaveURL(/\/events$/);
  await expect(page.getByRole("heading", { name: "Events Management Setup" })).toBeVisible();

  await recorder.step("Open create form and fill event details");
  await page.getByRole("button", { name: "Create New Event" }).click();
  await page.getByLabel("Event Title *").fill("Annual Summit");
  await page.getByPlaceholder("Summarize event activities...").fill("Industry leaders gathering");
  await page.getByLabel("Location / Venue *").fill("San Francisco");
  await page.getByLabel("Start Date *").fill("2024-10-15");
  await page.getByLabel("End Date *").fill("2024-10-17");

  await recorder.step("Publish the event");
  await page.getByRole("button", { name: "Publish Event" }).click();

  await recorder.step("Verify event appears and form resets");
  await expect(page.getByText("Event created successfully!")).toBeVisible();
  await expect(page.getByText("Annual Summit")).toBeVisible();
  await expect(page.getByText("Industry leaders gathering")).toBeVisible();
  await expect(page.getByText("San Francisco")).toBeVisible();
  await expect(page.getByText("2024-10-15 to 2024-10-17")).toBeVisible();
  await expect(page.getByLabel("Event Title *")).toHaveValue("");
  await expect(page.getByPlaceholder("Summarize event activities...")).toHaveValue("");
  await expect(page.getByLabel("Location / Venue *")).toHaveValue("");
  await expect(page.getByText("Title is required")).toHaveCount(0);

  console.log("CODEVALID_TEST_ASSERTION_OK:events_from_home_happy_path");
  await recorder.save(testInfo);
});
