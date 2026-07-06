import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { seedAuthenticatedSession } from "../../helpers/mock-api.js";

test("Prevent Event Creation With Missing Required Inputs", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder(
    "prevent_event_creation_with_missing_required_fields",
    "Prevent Event Creation With Missing Required Inputs"
  );

  let postCalled = false;

  await recorder.recordStep("Seed authenticated session and register event API mocks");
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

    postCalled = true;
    await route.fulfill({
      status: 201,
      contentType: "application/json",
      body: JSON.stringify({
        id: "evt-unexpected",
        title: "",
        description: "Incomplete event submission",
        location: "Seattle",
        startDate: "2026-12-01",
        endDate: "2026-12-05",
        registrationCount: 0,
      }),
    });
  });

  await recorder.recordStep("Navigate to the Events page and open the create form");
  await page.goto("/events");
  await expect(
    page.getByRole("heading", { name: "Events Management Setup" })
  ).toBeVisible();
  await page.getByRole("button", { name: /create new event/i }).click();

  await recorder.recordStep("Fill optional and required fields except the title");
  await page.locator('textarea[name="description"]').fill("Incomplete event submission");
  await page.locator('input[name="location"]').fill("Seattle");
  await page.locator('input[name="startDate"]').fill("2026-12-01");
  await page.locator('input[name="endDate"]').fill("2026-12-05");

  await recorder.recordStep("Submit the form and verify client-side validation prevents event creation");
  await page.getByRole("button", { name: /publish event/i }).click();
  await expect(page.getByText("Title is required")).toBeVisible();
  await expect(page.getByText("No Events Found")).toBeVisible();
  await expect.poll(() => postCalled).toBeFalsy();

  console.log("CODEVALID_TEST_ASSERTION_OK:prevent_event_creation_with_missing_required_fields");
  await recorder.save(testInfo);
});
