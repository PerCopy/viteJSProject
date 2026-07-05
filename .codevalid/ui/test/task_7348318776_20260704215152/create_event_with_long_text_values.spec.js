import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../helpers/execution-recorder.js";
import { seedAuthenticatedSession, mockEventScenario } from "../helpers/mock-api.js";

test("Create Event With Long Description And Location Values", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder("create_event_with_long_text_values", testInfo);

  const eventDetails = {
    id: "event-enterprise-planning-summit",
    title: "Enterprise Planning Summit",
    description: "A multi-session enterprise planning event covering roadmap alignment, cross-functional governance, capacity planning, quarterly execution milestones, stakeholder communication, and operational readiness across regional business units.",
    location: "Grand Convention and Exhibition Center, West Atrium, Level 4, Conference Wing C, 1250 Innovation Boulevard, Business District Campus",
    startDate: "2027-01-20",
    endDate: "2027-01-25",
    registrationCount: 0,
  };

  await recorder.step("Seed authenticated session and mock events API", async () => {
    await seedAuthenticatedSession(page);
    await mockEventScenario(page, {
      initialEvents: [],
      createdEvent: eventDetails,
    });
  });

  await recorder.step("Open the Events page and create form", async () => {
    await page.goto("/events");
    await expect(page.getByRole("heading", { name: "Events Management Setup" })).toBeVisible();
    await page.getByRole("button", { name: "Create New Event" }).click();
  });

  await recorder.step("Enter long description and location values", async () => {
    await page.getByPlaceholder("e.g. Spring Hackathon 2026").fill(eventDetails.title);
    await page.getByPlaceholder("Summarize event activities...").fill(eventDetails.description);
    await page.getByPlaceholder("e.g. Auditorium A or Virtual").fill(eventDetails.location);
    await page.getByLabel("Start Date *").fill(eventDetails.startDate);
    await page.getByLabel("End Date *").fill(eventDetails.endDate);
  });

  await recorder.step("Submit the event creation form", async () => {
    await page.getByRole("button", { name: "Publish Event" }).click();
    await expect(page.getByText("Event created successfully!")).toBeVisible();
  });

  await recorder.step("Locate the created event and verify full long values are stored", async () => {
    await expect(page.getByRole("heading", { name: eventDetails.title })).toBeVisible();
    await expect(page.getByText(eventDetails.description)).toBeVisible();
    await expect(page.getByText(eventDetails.location)).toBeVisible();
    await expect(page.getByText(`${eventDetails.startDate} to ${eventDetails.endDate}`)).toBeVisible();
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:create_event_with_long_text_values");
  await recorder.save(testInfo);
});
