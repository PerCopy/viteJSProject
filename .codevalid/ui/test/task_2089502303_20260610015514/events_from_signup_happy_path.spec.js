import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupUnauthenticatedSession, setupEventCreationScenario, mockSignUpPageApis } from "../../helpers/mock-api.js";

test("Create Event via Navigation from SignUp Page", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "events_from_signup_happy_path",
    testName: "Create Event via Navigation from SignUp Page",
  });

  const initialEvents = [];
  const createdEvent = {
    id: "event-product-demo",
    title: "Product Demo",
    description: "Live product walkthrough",
    location: "New York",
    startDate: "2024-11-05",
    endDate: "2024-11-06",
    registrationCount: 0,
  };

  await recorder.step("Mock sign-up page and event APIs");
  await setupUnauthenticatedSession(page);
  await mockSignUpPageApis(page);
  await setupEventCreationScenario(page, {
    initialEvents,
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

  await recorder.step("Navigate from sign-up page to events page");
  const eventsNav = page.getByRole("link", { name: /events/i }).first();
  await expect(eventsNav).toBeVisible();
  await eventsNav.click();
  await expect(page).toHaveURL(/\/events$/);

  await recorder.step("Open create form and enter event details");
  await page.getByRole("button", { name: "Create New Event" }).click();
  await page.getByLabel("Event Title *").fill("Product Demo");
  await page.getByPlaceholder("Summarize event activities...").fill("Live product walkthrough");
  await page.getByLabel("Location / Venue *").fill("New York");
  await page.getByLabel("Start Date *").fill("2024-11-05");
  await page.getByLabel("End Date *").fill("2024-11-06");

  await recorder.step("Submit form and verify created event");
  await page.getByRole("button", { name: "Publish Event" }).click();
  await expect(page.getByText("Event created successfully!")).toBeVisible();
  await expect(page.getByText("Product Demo")).toBeVisible();
  await expect(page.getByText("Live product walkthrough")).toBeVisible();
  await expect(page.getByText("New York")).toBeVisible();
  await expect(page.getByText("2024-11-05 to 2024-11-06")).toBeVisible();
  await expect(page.getByText("0 registered")).toBeVisible();
  await expect(page.getByText("Title is required")).toHaveCount(0);
  await expect(page.getByLabel("Event Title *")).toHaveValue("");
  await expect(page.getByPlaceholder("Summarize event activities...")).toHaveValue("");
  await expect(page.getByLabel("Location / Venue *")).toHaveValue("");
  await expect(page.getByLabel("Start Date *")).toHaveValue("");
  await expect(page.getByLabel("End Date *")).toHaveValue("");

  console.log("CODEVALID_TEST_ASSERTION_OK:events_from_signup_happy_path");
  await recorder.save(testInfo);
});
