import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession, setupEventCreationScenario } from "../../helpers/mock-api.js";

test("Create Event via Navigation from SignIn Page", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "events_from_signin_happy_path",
    testName: "Create Event via Navigation from SignIn Page",
  });

  const createdEvent = {
    id: "event-webinar-series",
    title: "Webinar Series",
    description: "Free online sessions",
    location: "Online",
    startDate: "2024-08-20",
    endDate: "2024-08-22",
    registrationCount: 0,
  };

  await recorder.step("Mock events API for creation flow");
  await setupEventCreationScenario(page, {
    initialEvents: [],
    expectedCreatePayload: {
      title: "Webinar Series",
      description: "Free online sessions",
      location: "Online",
      startDate: "2024-08-20",
      endDate: "2024-08-22",
    },
    createdEvent,
  });

  await recorder.step("Navigate to sign-in page");
  await page.goto("/signin");
  await expect(page).toHaveURL(/\/signin$/);

  await recorder.step("Seed auth after landing on sign-in and navigate to events");
  await setupAuthenticatedSession(page);
  await page.goto("/events");
  await expect(page).toHaveURL(/\/events$/);

  await recorder.step("Fill and submit event form");
  await page.getByRole("button", { name: "Create New Event" }).click();
  await page.getByLabel("Event Title *").fill("Webinar Series");
  await page.getByPlaceholder("Summarize event activities...").fill("Free online sessions");
  await page.getByLabel("Location / Venue *").fill("Online");
  await page.getByLabel("Start Date *").fill("2024-08-20");
  await page.getByLabel("End Date *").fill("2024-08-22");
  await page.getByRole("button", { name: "Publish Event" }).click();

  await recorder.step("Assert created event is listed without errors");
  await expect(page.getByText("Event created successfully!")).toBeVisible();
  await expect(page.getByText("Webinar Series")).toBeVisible();
  await expect(page.getByText("Free online sessions")).toBeVisible();
  await expect(page.getByText("Online")).toBeVisible();
  await expect(page.getByText("2024-08-20 to 2024-08-22")).toBeVisible();
  await expect(page.getByText("Title is required")).toHaveCount(0);

  console.log("CODEVALID_TEST_ASSERTION_OK:events_from_signin_happy_path");
  await recorder.save(testInfo);
});
