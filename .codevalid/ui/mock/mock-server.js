/**
 * mock-server.js
 * A lightweight Express mock server that intercepts API requests
 * during Playwright test runs, returning deterministic mock data
 * instead of hitting a real backend.
 *
 * Usage (standalone):
 *   node .codevalid/ui/mock/mock-server.js
 *
 * The server listens on MOCK_PORT (default 5001) and mirrors the
 * same route surface as backend/server.js so Vite's proxy forwards
 * requests transparently.
 */

import express from "express";
import cors from "cors";
import {
  mockUsers,
  mockEvents,
  mockRegistrations,
  buildSigninResponse,
  buildSignupResponse,
} from "./mock-data.js";

const app = express();
const PORT = process.env.MOCK_PORT || 5001;

app.use(cors());
app.use(express.json());

// ── helpers ──────────────────────────────────────────────────────────────────

const generateId = (prefix) => `${prefix}_${Math.random().toString(36).substr(2, 9)}`;

// In-memory state (shallow copies so tests start from a known baseline)
let users = mockUsers.map((u) => ({ ...u }));
let events = mockEvents.map((e) => ({ ...e }));
let registrations = mockRegistrations.map((r) => ({ ...r }));

// ── health ────────────────────────────────────────────────────────────────────

app.get("/health", (_req, res) => res.json({ status: "ok", mock: true }));

// Allow tests to reset state between runs
app.post("/__reset__", (_req, res) => {
  users = mockUsers.map((u) => ({ ...u }));
  events = mockEvents.map((e) => ({ ...e }));
  registrations = mockRegistrations.map((r) => ({ ...r }));
  res.json({ reset: true });
});

// ── auth ─────────────────────────────────────────────────────────────────────

app.post("/api/auth/signup", (req, res) => {
  const { username, email, password, fullName, phone, organization } = req.body;

  if (!username || !email || !password || !fullName) {
    return res.status(400).json({
      message: "Username, email, password, and full name are required.",
    });
  }

  const existing = users.find(
    (u) =>
      u.email.toLowerCase() === email.toLowerCase() ||
      u.username.toLowerCase() === username.toLowerCase()
  );
  if (existing) {
    return res.status(400).json({ message: "Username or Email already registered." });
  }

  const newUser = {
    id: generateId("user"),
    username,
    email,
    password,
    fullName,
    phone: phone || "",
    organization: organization || "",
  };
  users.push(newUser);

  return res.status(201).json(buildSignupResponse(newUser));
});

app.post("/api/auth/signin", (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: "Email and password are required." });
  }

  const user = users.find((u) => u.email.toLowerCase() === email.toLowerCase());
  if (!user || user.password !== password) {
    return res.status(401).json({ message: "Invalid email or password." });
  }

  return res.status(200).json(buildSigninResponse(user));
});

// ── events ────────────────────────────────────────────────────────────────────

app.get("/api/events", (_req, res) => {
  const sorted = [...events].sort(
    (a, b) => new Date(a.startDate) - new Date(b.startDate)
  );
  const withCount = sorted.map((ev) => ({
    ...ev,
    registrationCount: registrations.filter((r) => r.eventId === ev.id).length,
  }));
  return res.status(200).json(withCount);
});

app.post("/api/events", (req, res) => {
  const { title, description, startDate, endDate, location } = req.body;

  if (!title || !startDate || !endDate || !location) {
    return res.status(400).json({
      message: "Title, start date, end date, and location are required.",
    });
  }

  const newEvent = {
    id: generateId("event"),
    title,
    description: description || "",
    startDate,
    endDate,
    location,
  };
  events.push(newEvent);
  return res.status(201).json({ ...newEvent, registrationCount: 0 });
});

// ── registrations ─────────────────────────────────────────────────────────────

app.get("/api/registrations/:eventId", (req, res) => {
  const { eventId } = req.params;
  const event = events.find((e) => e.id === eventId);
  if (!event) {
    return res.status(404).json({ message: "Event not found." });
  }

  const eventRegs = registrations
    .filter((r) => r.eventId === eventId)
    .sort((a, b) => new Date(b.registeredAt) - new Date(a.registeredAt));

  return res.status(200).json(eventRegs);
});

app.post("/api/registrations", (req, res) => {
  const { eventId, name, email, phone } = req.body;

  if (!eventId || !name || !email || !phone) {
    return res.status(400).json({
      message: "Event, name, email, and phone number are required.",
    });
  }

  const event = events.find((e) => e.id === eventId);
  if (!event) {
    return res.status(404).json({ message: "Event not found." });
  }

  const todayStr = new Date().toISOString().split("T")[0];
  if (todayStr < event.startDate) {
    return res.status(400).json({
      message: `Registration has not opened yet. Registration opens on ${event.startDate}.`,
    });
  }
  if (todayStr > event.endDate) {
    return res.status(400).json({
      message: `Registration is closed. The event ended on ${event.endDate}.`,
    });
  }

  const alreadyRegistered = registrations.some(
    (r) => r.eventId === eventId && r.email.toLowerCase() === email.toLowerCase()
  );
  if (alreadyRegistered) {
    return res.status(400).json({
      message: "This email is already registered for this event.",
    });
  }

  const newReg = {
    id: generateId("reg"),
    eventId,
    name,
    email,
    phone,
    registeredAt: new Date().toISOString(),
  };
  registrations.push(newReg);
  return res.status(201).json(newReg);
});

// ── start ─────────────────────────────────────────────────────────────────────

app.listen(PORT, () => {
  console.log(`[mock-server] Listening on http://localhost:${PORT}`);
});

export { app };
