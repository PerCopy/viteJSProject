import React, { useEffect, useState } from "react";
import { Plus, MapPin, Calendar as CalendarIcon, Users, Loader2, Info, CheckCircle2, AlertTriangle, Clock } from "lucide-react";
import { api } from "../utils/api";
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "../components/ui/Card";
import { Input } from "../components/ui/Input";
import { Button } from "../components/ui/Button";

export default function Events() {
  const [events, setEvents] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showCreateForm, setShowCreateForm] = useState(false);
  
  const [formData, setFormData] = useState({
    title: "",
    description: "",
    startDate: "",
    endDate: "",
    location: ""
  });
  const [errors, setErrors] = useState({});
  const [apiError, setApiError] = useState("");
  const [successMsg, setSuccessMsg] = useState("");

  const fetchEvents = async () => {
    try {
      setIsLoading(true);
      const data = await api.getEvents();
      setEvents(data);
    } catch (err) {
      console.error("Failed to load events", err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchEvents();
  }, []);

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
    if (!formData.title.trim()) newErrors.title = "Title is required";
    if (!formData.location.trim()) newErrors.location = "Location is required";
    if (!formData.startDate) newErrors.startDate = "Start date is required";
    if (!formData.endDate) newErrors.endDate = "End date is required";


    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!validateForm()) return;

    setIsSubmitting(true);
    setApiError("");
    setSuccessMsg("");

    try {
      const newEvent = await api.createEvent(formData);
      setEvents((prev) => [...prev, newEvent].sort((a, b) => new Date(a.startDate) - new Date(b.startDate)));
      setSuccessMsg("Event created successfully!");
      setFormData({
        title: "",
        description: "",
        startDate: "",
        endDate: "",
        location: ""
      });
      // Close form after a delay
      setTimeout(() => {
        setShowCreateForm(false);
        setSuccessMsg("");
      }, 1500);
    } catch (err) {
      setApiError(err.message || "Failed to create event. Please try again.");
    } finally {
      setIsSubmitting(false);
    }
  };

  const getEventStatus = (startDate, endDate) => {
    const todayStr = new Date().toISOString().split("T")[0];
    if (todayStr < startDate) {
      return {
        label: "Upcoming",
        style: "bg-blue-500/10 text-blue-400 border-blue-500/20 text-glow-accent",
        icon: <Clock size={12} className="inline mr-1" />
      };
    } else if (todayStr > endDate) {
      return {
        label: "Closed",
        style: "bg-red-500/10 text-red-400 border-red-500/20",
        icon: <AlertTriangle size={12} className="inline mr-1" />
      };
    } else {
      return {
        label: "Active",
        style: "bg-green-500/10 text-green-400 border-green-500/20 text-glow",
        icon: <CheckCircle2 size={12} className="inline mr-1" />
      };
    }
  };

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pb-12">
      {/* Header section */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8">
        <div>
          <h1 className="text-3xl font-extrabold text-white tracking-tight">
            Events Management Setup
          </h1>
          <p className="text-gray-400 mt-1 text-sm">
            Create, edit, and audit configuration schedules for upcoming and past events.
          </p>
        </div>

        <Button
          onClick={() => {
            setShowCreateForm(!showCreateForm);
            setApiError("");
            setSuccessMsg("");
          }}
          className="flex items-center gap-2 self-start md:self-center bg-indigo-600 hover:bg-indigo-500"
        >
          <Plus size={16} />
          {showCreateForm ? "Close Form" : "Create New Event"}
        </Button>
      </div>

      {/* Main layout */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 items-start">
        {/* Create form pane */}
        {showCreateForm && (
          <div className="lg:col-span-1 glass-card p-6 rounded-xl border border-white/10 animate-fade-in">
            <h2 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
              <CalendarIcon size={18} className="text-indigo-400" />
              New Event Setup
            </h2>

            <form onSubmit={handleSubmit} className="space-y-4">
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
                label="Event Title *"
                name="title"
                type="text"
                placeholder="e.g. Spring Hackathon 2026"
                value={formData.title}
                onChange={handleChange}
                error={errors.title}
              />

              <div className="w-full flex flex-col gap-1.5 text-left">
                <label className="text-xs font-semibold text-gray-300 uppercase tracking-wider">
                  Description
                </label>
                <textarea
                  name="description"
                  rows={3}
                  placeholder="Summarize event activities..."
                  value={formData.description}
                  onChange={handleChange}
                  className="w-full px-3.5 py-2 text-sm rounded-md glass-input focus:border-indigo-500/50 focus:ring-indigo-500/20 focus:outline-none resize-none"
                />
              </div>

              <Input
                label="Location / Venue *"
                name="location"
                type="text"
                placeholder="e.g. Auditorium A or Virtual"
                value={formData.location}
                onChange={handleChange}
                error={errors.location}
              />

              <div className="grid grid-cols-2 gap-4">
                <Input
                  label="Start Date *"
                  name="startDate"
                  type="date"
                  value={formData.startDate}
                  onChange={handleChange}
                  error={errors.startDate}
                />
                <Input
                  label="End Date *"
                  name="endDate"
                  type="date"
                  value={formData.endDate}
                  onChange={handleChange}
                  error={errors.endDate}
                />
              </div>

              <Button
                type="submit"
                disabled={isSubmitting}
                className="w-full mt-2 flex items-center justify-center gap-2"
              >
                {isSubmitting ? (
                  <>
                    <Loader2 size={16} className="animate-spin" />
                    Saving Event...
                  </>
                ) : (
                  "Publish Event"
                )}
              </Button>
            </form>
          </div>
        )}

        {/* Events listing pane */}
        <div className={showCreateForm ? "lg:col-span-2 space-y-4" : "lg:col-span-3 space-y-4"}>
          {isLoading ? (
            <div className="flex flex-col items-center justify-center py-20 gap-3">
              <Loader2 size={36} className="text-indigo-500 animate-spin" />
              <p className="text-gray-400 text-sm">Fetching scheduled events...</p>
            </div>
          ) : events.length === 0 ? (
            <Card className="text-center py-16">
              <div className="mx-auto w-12 h-12 bg-white/5 border border-white/5 rounded-full flex items-center justify-center text-gray-400 mb-4">
                <CalendarIcon size={24} />
              </div>
              <h3 className="text-lg font-bold text-white mb-1">No Events Found</h3>
              <p className="text-sm text-gray-400 max-w-sm mx-auto">
                Configure your first event schedules by clicking the "Create New Event" button.
              </p>
            </Card>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {events.map((event) => {
                const status = getEventStatus(event.startDate, event.endDate);
                return (
                  <div
                    key={event.id}
                    className="glass rounded-xl p-5 hover:border-indigo-500/30 transition-all duration-300 relative overflow-hidden group flex flex-col justify-between"
                  >
                    {/* Hover Glow decoration */}
                    <div className="absolute top-0 right-0 w-24 h-24 bg-indigo-500/5 rounded-full blur-xl group-hover:bg-indigo-500/10 transition-colors" />

                    <div>
                      {/* Title & Status Badge */}
                      <div className="flex items-start justify-between gap-3 mb-2">
                        <h3 className="text-lg font-extrabold text-white group-hover:text-indigo-300 transition-colors tracking-tight line-clamp-1">
                          {event.title}
                        </h3>
                        <span
                          className={`px-2 py-0.5 text-[10px] font-bold uppercase rounded border tracking-wider flex items-center ${status.style}`}
                        >
                          {status.icon}
                          {status.label}
                        </span>
                      </div>

                      {/* Description */}
                      <p className="text-xs text-gray-400 line-clamp-2 mb-4 leading-relaxed">
                        {event.description || "No description provided."}
                      </p>
                    </div>

                    {/* Meta info */}
                    <div className="border-t border-white/5 pt-3 mt-3 space-y-2 text-xs text-gray-400">
                      <div className="flex items-center gap-2">
                        <MapPin size={12} className="text-indigo-400" />
                        <span className="truncate">{event.location}</span>
                      </div>
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          <CalendarIcon size={12} className="text-indigo-400" />
                          <span>
                            {event.startDate} to {event.endDate}
                          </span>
                        </div>
                        <div className="flex items-center gap-1 bg-white/5 px-2 py-0.5 rounded text-white font-medium">
                          <Users size={10} className="text-indigo-300" />
                          <span>{event.registrationCount || 0} registered</span>
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
