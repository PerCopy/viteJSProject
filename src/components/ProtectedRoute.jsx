import React from "react";
import { Navigate, Outlet } from "react-router-dom";
import { isAuthenticated } from "../utils/api";

export default function ProtectedRoute() {
  if (!isAuthenticated()) {
    return <Navigate to="/signin" replace />;
  }

  return <Outlet />;
}
