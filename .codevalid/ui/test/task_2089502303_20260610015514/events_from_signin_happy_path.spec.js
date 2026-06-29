import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupUnauthenticatedSession, setupEventCreationScenario, mockSignInPageApis } from "../../helpers/mock-api.js";

test("Create Event via Navigation from SignIn Page", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "events_from_signin_happy_path",
    testName: "Create Event via Navigation from SignIn Page",
  });

  const initialEvents = [];
  const createdEvent = {
    id: "event-webinar-series",
    title: "Webinar Series",
    description: "Free online sessions",
    location: "Online",
    startDate: "2024-08-20",
    endDate: "2024-08-22",
    registrationCount: 0,
  };

  await recorder.step("Mock sign-in page and event APIs");
  await setupUnauthenticatedSession(page);
  await mockSignInPageApis(page);
  await setupEventCreationScenario(page, {
    initialEvents,
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

  await recorder.step("Navigate from sign-in page to events page");
  const eventsNav = page.getByRole("link", { name: /events/i }).first();
  await expect(eventsNav).toBeVisible();
  await eventsNav.click();
  await expect(page).toHaveURL(/\/events$/);

  await recorder.step("Open the create event form and enter details");
  await page.getByRole("button", { name: "Create New Event" }).click();
  await page.getByLabel("Event Title *").fill("Webinar Series");
  await page.getByPlaceholder("Summarize event activities...").fill("Free online sessions");
  await page.getByLabel("Location / Venue *").fill("Online");
  await page.getByLabel("Start Date *").fill("2024-08-20");
  await page.getByLabel("End Date *").fill("2024-08-22");

  await recorder.step("Submit the event form");
  await page.getByRole("button", { name: "Publish Event" }).click();

  await recorder.step("Verify the event appears and no errors display");
  await expect(page.getByText("Event created successfully!")).toBeVisible();
  await expect(page.getByText("Webinar Series")).toBeVisible();
  await expect(page.getByText("Free online sessions")).toBeVisible();
  await expect(page.getByText("Online")).toBeVisible();
  await expect(page.getByText("2024-08-20 to 2024-08-22")).toBeVisible();
  await expect(page.getByText("0 registered")).toBeVisible();
  await expect(page.getByText("Title is required")).toHaveCount(0);
  await expect(page.getByLabel("Event Title *")).toHaveValue("");
  await expect(page.getByPlaceholder("Summarize event activities...")).toHaveValue("");
  await expect(page.getByLabel("Location / Venue *")).toHaveValue("");
  await expect(page.getByLabel("Start Date *")).toHaveValue("");
  await expect(page.getByLabel("End Date *")).toHaveValue("");

  console.log("CODEVALID_TEST_ASSERTION_OK:events_from_signin_happy_path");
  await recorder.save(testInfo);
});
