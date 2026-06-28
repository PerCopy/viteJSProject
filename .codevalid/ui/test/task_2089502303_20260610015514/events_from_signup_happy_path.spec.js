import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession, setupEventCreationScenario } from "../../helpers/mock-api.js";

test("Create Event via Navigation from SignUp Page", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "events_from_signup_happy_path",
    testName: "Create Event via Navigation from SignUp Page",
  });

  const createdEvent = {
    id: "event-product-demo",
    title: "Product Demo",
    description: "Live product walkthrough",
    location: "New York",
    startDate: "2024-11-05",
    endDate: "2024-11-06",
    registrationCount: 0,
  };

  await recorder.step("Mock events API for signup-origin scenario");
  await setupEventCreationScenario(page, {
    initialEvents: [],
    expectedCreatePayload: {
      title: "Product Demo",
      description: "Live product walkthrough",
      location: "New York",
      startDate: "2024-11-05",
      endDate: "2024-11-06",
    },
    createdEvent,
  });

  await recorder.step("Navigate to sign-up page");
  await page.goto("/signup");
  await expect(page).toHaveURL(/\/signup$/);

  await recorder.step("Seed auth after landing on sign-up and navigate to events");
  await setupAuthenticatedSession(page);
  await page.goto("/events");
  await expect(page.getByRole("heading", { name: "Events Management Setup" })).toBeVisible();

  await recorder.step("Create a new event");
  await page.getByRole("button", { name: "Create New Event" }).click();
  await page.getByLabel("Event Title *").fill("Product Demo");
  await page.getByPlaceholder("Summarize event activities...").fill("Live product walkthrough");
  await page.getByLabel("Location / Venue *").fill("New York");
  await page.getByLabel("Start Date *").fill("2024-11-05");
  await page.getByLabel("End Date *").fill("2024-11-06");
  await page.getByRole("button", { name: "Publish Event" }).click();

  await recorder.step("Verify created event details and reset form");
  await expect(page.getByText("Event created successfully!")).toBeVisible();
  await expect(page.getByText("Product Demo")).toBeVisible();
  await expect(page.getByText("Live product walkthrough")).toBeVisible();
  await expect(page.getByText("New York")).toBeVisible();
  await expect(page.getByText("2024-11-05 to 2024-11-06")).toBeVisible();
  await expect(page.getByLabel("Event Title *")).toHaveValue("");

  console.log("CODEVALID_TEST_ASSERTION_OK:events_from_signup_happy_path");
  await recorder.save(testInfo);
});
