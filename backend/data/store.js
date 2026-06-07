// In-memory data store for the Event Registration Application

// Prepopulate data for demonstration and testing purposes
const users = [
  {
    id: "user_1",
    username: "johndoe",
    email: "john@example.com",
    password: "password123", // In a real app we'd bcrypt hash this, which we'll simulate or do simply
    fullName: "John Doe",
    phone: "+1 (555) 019-2834",
    organization: "Acme Tech Solutions"
  },
  {
    id: "user_2",
    username: "janemiller",
    email: "jane@example.com",
    password: "password123",
    fullName: "Jane Miller",
    phone: "+1 (555) 014-9876",
    organization: "Innovate Labs"
  }
];

const today = new Date();
const formatDate = (date) => date.toISOString().split("T")[0];

const events = [
  {
    id: "event_1",
    title: "Global Tech Summit 2026",
    description: "The premier event for AI, cloud computing, and next-gen web technologies. Hear from world-class industry leaders.",
    startDate: formatDate(new Date(today.getTime() - 2 * 24 * 60 * 60 * 1000)), // started 2 days ago
    endDate: formatDate(new Date(today.getTime() + 5 * 24 * 60 * 60 * 1000)),  // ends in 5 days
    location: "San Francisco, CA & Virtual"
  },
  {
    id: "event_2",
    title: "React & Modern Web Design Workshop",
    description: "Hands-on workshop focusing on component-based development, animations, and high-performance frontend engineering.",
    startDate: formatDate(new Date(today.getTime() + 10 * 24 * 60 * 60 * 1000)), // starts in 10 days
    endDate: formatDate(new Date(today.getTime() + 12 * 24 * 60 * 60 * 1000)),  // ends in 12 days
    location: "Austin, TX"
  },
  {
    id: "event_3",
    title: "Legacy Backend Systems Seminar",
    description: "A deep dive into migrating legacy enterprise databases to modern distributed systems.",
    startDate: formatDate(new Date(today.getTime() - 15 * 24 * 60 * 60 * 1000)), // started 15 days ago
    endDate: formatDate(new Date(today.getTime() - 12 * 24 * 60 * 60 * 1000)),  // ended 12 days ago
    location: "Online Webcast"
  }
];

const registrations = [
  {
    id: "reg_1",
    eventId: "event_1",
    name: "Alice Vance",
    email: "alice@vance.com",
    phone: "+1 (555) 012-3456",
    registeredAt: new Date(today.getTime() - 1 * 24 * 60 * 60 * 1000).toISOString()
  },
  {
    id: "reg_2",
    eventId: "event_1",
    name: "Bob Builder",
    email: "bob@builder.com",
    phone: "+1 (555) 018-7654",
    registeredAt: new Date(today.getTime() - 12 * 60 * 60 * 1000).toISOString()
  }
];

export {
  users,
  events,
  registrations
};
