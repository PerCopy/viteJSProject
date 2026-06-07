import React, { useEffect, useState } from "react";
import { Users, Mail, Phone, Calendar as CalendarIcon, UserPlus, CheckCircle2, AlertCircle, Sparkles, Loader2, ArrowRight } from "lucide-react";
import { api } from "../utils/api";
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "../components/ui/Card";
import { Input } from "../components/ui/Input";
import { Button } from "../components/ui/Button";

export default function Home() {
  const [events, setEvents] = useState([]);
  const [selectedEventId, setSelectedEventId] = useState("");
  const [registrations, setRegistrations] = useState([]);
  
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    phone: ""
  });
  const [errors, setErrors] = useState({});
  const [isLoadingEvents, setIsLoadingEvents] = useState(true);
  const [isLoadingRegistrations, setIsLoadingRegistrations] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [apiError, setApiError] = useState("");
  const [successMsg, setSuccessMsg] = useState("");

  useEffect(() => {
    const fetchEvents = async () => {
      try {
        const data = await api.getEvents();
        setEvents(data);
        if (data.length > 0) {
          setSelectedEventId(data[0].id); // Auto-select first event
        }
      } catch (err) {
        console.error("Failed to load events", err);
      } finally {
        setIsLoadingEvents(false);
      }
    };
    fetchEvents();
  }, []);

  const selectedEvent = events.find((e) => e.id === selectedEventId);

  const fetchRegistrations = async (eventId) => {
    if (!eventId) return;
    try {
      setIsLoadingRegistrations(true);
      const data = await api.getRegistrations(eventId);
      setRegistrations(data);
    } catch (err) {
      console.error("Failed to fetch registrations", err);
    } finally {
      setIsLoadingRegistrations(false);
    }
  };

  useEffect(() => {
    if (selectedEventId) {
      fetchRegistrations(selectedEventId);
      // Reset form alerts on event change
      setApiError("");
      setSuccessMsg("");
      setFormData({ name: "", email: "", phone: "" });
      setErrors({});
    }
  }, [selectedEventId]);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
    if (errors[name]) {
      setErrors((prev) => ({ ...prev, [name]: "" }));
    }
    setApiError("");
    setSuccessMsg("");
  };

  const validateForm = () => {
    const newErrors = {};
    if (!formData.name.trim()) newErrors.name = "Attendee name is required";
    if (!formData.phone.trim()) newErrors.phone = "Phone number is required";
    
    if (!formData.email.trim()) {
      newErrors.email = "Email is required";
    } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
      newErrors.email = "Invalid email address";
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleRegister = async (e) => {
    e.preventDefault();
    if (!validateForm() || !selectedEventId) return;

    setIsSubmitting(true);
    setApiError("");
    setSuccessMsg("");

    try {
      const response = await api.registerForEvent({
        eventId: selectedEventId,
        ...formData
      });
      // Append registration to current list
      setRegistrations((prev) => [response, ...prev]);
      setSuccessMsg("Attendee registered successfully!");
      setFormData({ name: "", email: "", phone: "" });
      
      // Update events count locally so grid counts update
      setEvents((prevEvents) =>
        prevEvents.map((evt) =>
          evt.id === selectedEventId
            ? { ...evt, registrationCount: (evt.registrationCount || 0) + 1 }
            : evt
        )
      );
    } catch (err) {
      setApiError(err.message || "Failed to register attendee. Check event active dates.");
    } finally {
      setIsSubmitting(false);
    }
  };

  // Helper to check if event is active for registration
  const getEventRegistrationStatus = (event) => {
    if (!event) return { isOpen: false, status: "Unknown", color: "text-gray-400" };
    const todayStr = new Date().toISOString().split("T")[0];
    if (todayStr < event.startDate) {
      return {
        isOpen: false,
        status: "Registration Upcoming",
        color: "text-blue-400 bg-blue-500/10 border-blue-500/20",
        message: `Registration opens on ${event.startDate}.`
      };
    } else if (todayStr > event.endDate) {
      return {
        isOpen: false,
        status: "Registration Closed",
        color: "text-red-400 bg-red-500/10 border-red-500/20",
        message: `Registration closed on ${event.endDate}.`
      };
    } else {
      return {
        isOpen: true,
        status: "Registration Active",
        color: "text-green-400 bg-green-500/10 border-green-500/20 text-glow",
        message: "You can register attendees for this event."
      };
    }
  };

  const regStatus = getEventRegistrationStatus(selectedEvent);

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pb-12">
      {/* Welcome Banner */}
      <div className="mb-8 p-6 glass rounded-2xl relative overflow-hidden border border-white/5 shadow-2xl flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        {/* Glow effect */}
        <div className="absolute -right-10 -top-10 w-40 h-40 bg-indigo-500/10 rounded-full blur-2xl pointer-events-none" />
        
        <div>
          <h1 className="text-2xl font-extrabold text-white flex items-center gap-2 tracking-tight">
            <Sparkles className="text-indigo-400 animate-pulse-slow" size={22} />
            Registration Desk
          </h1>
          <p className="text-gray-400 text-sm mt-0.5">
            Add new attendees or view registered audiences per individual setup configurations.
          </p>
        </div>

        {/* Dropdown Selector */}
        {!isLoadingEvents && events.length > 0 && (
          <div className="flex flex-col text-left min-w-[240px]">
            <label className="text-[10px] font-bold text-indigo-400 uppercase tracking-widest mb-1 pl-1">
              Select Active Event
            </label>
            <select
              value={selectedEventId}
              onChange={(e) => setSelectedEventId(e.target.value)}
              className="bg-gray-900 border border-white/10 text-white rounded-lg px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500 cursor-pointer shadow-md"
            >
              {events.map((evt) => (
                <option key={evt.id} value={evt.id}>
                  {evt.title}
                </option>
              ))}
            </select>
          </div>
        )}
      </div>

      {isLoadingEvents ? (
        <div className="flex flex-col items-center justify-center py-20 gap-3">
          <Loader2 size={36} className="text-indigo-500 animate-spin" />
          <p className="text-gray-400 text-sm">Fetching workspace directories...</p>
        </div>
      ) : events.length === 0 ? (
        <Card className="text-center py-16">
          <div className="mx-auto w-12 h-12 bg-white/5 border border-white/5 rounded-full flex items-center justify-center text-gray-400 mb-4">
            <CalendarIcon size={24} />
          </div>
          <h3 className="text-lg font-bold text-white mb-1">No Active Events</h3>
          <p className="text-sm text-gray-400 max-w-sm mx-auto mb-4">
            You must create an event before registering any user.
          </p>
          <Button onClick={() => window.location.assign("/events")} className="bg-indigo-600">
            Go to Events Setup
          </Button>
        </Card>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 items-start">
          {/* Left: Registration Form Card */}
          <div className="lg:col-span-1">
            <Card className="border border-white/5 shadow-xl">
              <CardHeader>
                <div className="flex items-center justify-between gap-2">
                  <CardTitle className="text-lg font-bold flex items-center gap-1.5">
                    <UserPlus size={18} className="text-indigo-400" />
                    Register User
                  </CardTitle>
                  <span className={`px-2 py-0.5 text-[9px] font-extrabold uppercase rounded border tracking-wider ${regStatus.color}`}>
                    {regStatus.status}
                  </span>
                </div>
                {selectedEvent && (
                  <CardDescription className="mt-2 text-xs leading-relaxed">
                    Event Dates: <strong className="text-gray-300">{selectedEvent.startDate}</strong> to <strong className="text-gray-300">{selectedEvent.endDate}</strong>.
                  </CardDescription>
                )}
              </CardHeader>

              <CardContent className="mt-1">
                {/* Notice banner for dates */}
                <div className={`p-2.5 rounded-lg border text-[11px] mb-4 font-medium flex items-start gap-2 ${
                  regStatus.isOpen 
                    ? "bg-green-500/5 border-green-500/10 text-green-400" 
                    : "bg-amber-500/5 border-amber-500/10 text-amber-400"
                }`}>
                  {regStatus.isOpen ? (
                    <CheckCircle2 size={14} className="shrink-0 mt-0.5" />
                  ) : (
                    <AlertCircle size={14} className="shrink-0 mt-0.5" />
                  )}
                  <span>{regStatus.message}</span>
                </div>

                <form onSubmit={handleRegister} className="space-y-4">
                  {apiError && (
                    <div className="p-2.5 rounded-lg bg-red-500/10 border border-red-500/20 text-red-400 text-xs font-medium">
                      {apiError}
                    </div>
                  )}
                  {successMsg && (
                    <div className="p-2.5 rounded-lg bg-green-500/10 border border-green-500/20 text-green-400 text-xs font-medium">
                      {successMsg}
                    </div>
                  )}

                  <Input
                    label="Full Name *"
                    name="name"
                    type="text"
                    placeholder="Jane Smith"
                    value={formData.name}
                    onChange={handleChange}
                    error={errors.name}
                    disabled={!regStatus.isOpen || isSubmitting}
                  />

                  <Input
                    label="Email Address *"
                    name="email"
                    type="email"
                    placeholder="jane@smith.com"
                    value={formData.email}
                    onChange={handleChange}
                    error={errors.email}
                    disabled={!regStatus.isOpen || isSubmitting}
                  />

                  <Input
                    label="Phone Number *"
                    name="phone"
                    type="tel"
                    placeholder="+1 (555) 000-0000"
                    value={formData.phone}
                    onChange={handleChange}
                    error={errors.phone}
                    disabled={!regStatus.isOpen || isSubmitting}
                  />

                  <Button
                    type="submit"
                    disabled={!regStatus.isOpen || isSubmitting}
                    className="w-full mt-2 py-2 text-sm font-semibold flex items-center justify-center gap-1.5"
                  >
                    {isSubmitting ? (
                      <>
                        <Loader2 size={16} className="animate-spin" />
                        Registering...
                      </>
                    ) : (
                      <>
                        Confirm Registration
                        <ArrowRight size={14} />
                      </>
                    )}
                  </Button>
                </form>
              </CardContent>
            </Card>
          </div>

          {/* Right: Registered Users List */}
          <div className="lg:col-span-2 space-y-4">
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-bold text-white flex items-center gap-2">
                <Users size={18} className="text-indigo-400" />
                Registered Audience
                <span className="bg-indigo-600/20 text-indigo-400 border border-indigo-500/20 px-2 py-0.5 rounded-full text-xs font-bold font-mono">
                  {registrations.length} Total
                </span>
              </h2>
            </div>

            {isLoadingRegistrations ? (
              <div className="flex flex-col items-center justify-center py-20 gap-3 glass p-6 rounded-xl">
                <Loader2 size={28} className="text-indigo-500 animate-spin" />
                <p className="text-gray-400 text-xs">Querying attendees list...</p>
              </div>
            ) : registrations.length === 0 ? (
              <div className="glass rounded-xl p-8 text-center border border-white/5">
                <div className="mx-auto w-10 h-10 bg-white/5 border border-white/5 rounded-full flex items-center justify-center text-gray-400 mb-3">
                  <Users size={18} />
                </div>
                <h3 className="text-sm font-bold text-white mb-0.5">No Registered Attendees</h3>
                <p className="text-xs text-gray-400 max-w-xs mx-auto">
                  {regStatus.isOpen
                    ? "Nobody has registered for this event yet. Use the form on the left to add attendees."
                    : "No registrants found. This event has no attendees."}
                </p>
              </div>
            ) : (
              <div className="glass rounded-xl border border-white/5 overflow-hidden shadow-xl">
                <div className="overflow-x-auto">
                  <table className="w-full text-left border-collapse">
                    <thead>
                      <tr className="border-b border-white/5 bg-white/5 text-[10px] font-bold text-indigo-400 uppercase tracking-wider">
                        <th className="px-5 py-3">Attendee</th>
                        <th className="px-5 py-3">Email</th>
                        <th className="px-5 py-3">Phone</th>
                        <th className="px-5 py-3 text-right">Registration Date</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-white/5 text-xs text-gray-300">
                      {registrations.map((reg) => (
                        <tr key={reg.id} className="hover:bg-white/5 transition-colors">
                          <td className="px-5 py-3 font-semibold text-white">{reg.name}</td>
                          <td className="px-5 py-3">
                            <span className="flex items-center gap-1.5 text-gray-400 hover:text-indigo-300 cursor-pointer">
                              <Mail size={12} className="text-indigo-400" />
                              {reg.email}
                            </span>
                          </td>
                          <td className="px-5 py-3">
                            <span className="flex items-center gap-1.5 text-gray-400">
                              <Phone size={12} className="text-indigo-400" />
                              {reg.phone}
                            </span>
                          </td>
                          <td className="px-5 py-3 text-right text-gray-500 font-mono text-[10px]">
                            {new Date(reg.registeredAt).toLocaleString()}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
