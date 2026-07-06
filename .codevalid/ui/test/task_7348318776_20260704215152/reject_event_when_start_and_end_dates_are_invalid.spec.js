import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { seedAuthenticatedSession } from "../../helpers/mock-api.js";

test("Reject Event Creation With Invalid Date Range", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder(
    "reject_event_when_start_and_end_dates_are_invalid",
    "Reject Event Creation With Invalid Date Range"
  );

  const invalidForm = {
    title: "Chronology Validation Check",
    description: "A negative test for invalid event dates.",
    location: "Main Hall",
    startDate: "2026-11-05",
    endDate: "2026-11-01",
  };

  await recorder.step("Seed authenticated session and mock invalid date rejection");
  await seedAuthenticatedSession(page);

  await page.route("**/api/events", async (route) => {
    const method = route.request().method().toUpperCase();

    if (method === "GET") {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify([]),
      });
      return;
    }

    await route.fulfill({
      status: 400,
      contentType: "application/json",
      body: JSON.stringify({
        message: "Invalid event dates: start date must be before end date",
      }),
    });
  });

  await recorder.step("Navigate to events and open the create form");
  await page.goto("/events");
  await page.getByRole("button", { name: /create new event/i }).click();
  await expect(
    page.getByRole("heading", { name: "New Event Setup" })
  ).toBeVisible();

  await recorder.step("Enter valid text fields and invalid date ordering");
  await page.getByPlaceholder("e.g. Spring Hackathon 2026").fill(invalidForm.title);
  await page.getByPlaceholder("Summarize event activities...").fill(invalidForm.description);
  await page.getByPlaceholder("e.g. Auditorium A or Virtual").fill(invalidForm.location);
  await page.locator('input[name="startDate"]').fill(invalidForm.startDate);
  await page.locator('input[name="endDate"]').fill(invalidForm.endDate);

  await recorder.step("Submit and verify the system blocks creation");
  await page.getByRole("button", { name: /publish event/i }).click();
  await expect(
    page.getByText("Invalid event dates: start date must be before end date")
  ).toBeVisible();
  await expect(page.getByText("No Events Found")).toBeVisible();
  await expect(page.getByText(invalidForm.title)).not.toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:reject_event_when_start_and_end_dates_are_invalid");
  await recorder.save(testInfo);
});
