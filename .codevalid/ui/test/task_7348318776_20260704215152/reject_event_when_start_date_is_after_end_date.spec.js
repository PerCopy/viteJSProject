import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { seedAuthenticatedSession } from "../../helpers/mock-api.js";

test("Reject Event Creation When Start Date Is After End Date", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder(
    "reject_event_when_start_date_is_after_end_date",
    "Reject Event Creation When Start Date Is After End Date"
  );

  const invalidForm = {
    title: "Invalid Date Ordering Event",
    description: "This submission intentionally uses an invalid date range.",
    location: "Room B",
    startDate: "2026-09-12",
    endDate: "2026-09-10",
  };

  await recorder.step("Seed authenticated session and register API routes");
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
      body: JSON.stringify({ message: "Start date must be before end date" }),
    });
  });

  await recorder.step("Open the events page");
  await page.goto("/events");
  await expect(
    page.getByRole("heading", { name: "Events Management Setup" })
  ).toBeVisible();

  await recorder.step("Open the creation form and enter event details with invalid chronology");
  await page.getByRole("button", { name: /create new event/i }).click();
  await page.getByPlaceholder("e.g. Spring Hackathon 2026").fill(invalidForm.title);
  await page.getByPlaceholder("Summarize event activities...").fill(invalidForm.description);
  await page.getByPlaceholder("e.g. Auditorium A or Virtual").fill(invalidForm.location);
  await page.locator('input[name="startDate"]').fill(invalidForm.startDate);
  await page.locator('input[name="endDate"]').fill(invalidForm.endDate);

  await recorder.step("Submit the form and verify validation feedback");
  await page.getByRole("button", { name: /publish event/i }).click();
  await expect(page.getByText("Start date must be before end date")).toBeVisible();
  await expect(page.getByText(invalidForm.title)).not.toBeVisible();
  await expect(page.getByText("No Events Found")).toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:reject_event_when_start_date_is_after_end_date");
  await recorder.save(testInfo);
});
