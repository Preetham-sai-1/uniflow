import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext.jsx';
import AuthLayout from '../layouts/AuthLayout.jsx';
import { StudentLayout, StaffAdminLayout } from '../layouts/AppLayouts.jsx';
import ProtectedRoute from './ProtectedRoute.jsx';
import RoleRoute from './RoleRoute.jsx';

import Login from '../pages/auth/Login.jsx';
import Register from '../pages/auth/Register.jsx';
import StudentDashboard from '../pages/student/StudentDashboard.jsx';
import ServiceCatalogue from '../pages/student/ServiceCatalogue.jsx';
import RequestForm from '../pages/student/RequestForm.jsx';
import RequestDetail from '../pages/student/RequestDetail.jsx';
import StaffQueue from '../pages/staff/StaffQueue.jsx';
import AdminDashboard from '../pages/admin/AdminDashboard.jsx';
import Unauthorized from '../pages/Unauthorized.jsx';
import NotFound from '../pages/NotFound.jsx';
import { Spinner } from '../components/common/Components.jsx';

// Root redirect based on authentication and role
function RootRedirect() {
  const { isAuthenticated, role, loading } = useAuth();

  if (loading) {
    return (
      <div className="loading-screen">
        <Spinner size="lg" />
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  if (role === 'admin') return <Navigate to="/admin" replace />;
  if (role === 'staff') return <Navigate to="/staff" replace />;
  return <Navigate to="/student" replace />;
}

// Redirect authenticated users away from login/register
function PublicOnlyRoute({ children }) {
  const { isAuthenticated, role, loading } = useAuth();

  if (loading) {
    return (
      <div className="loading-screen">
        <Spinner size="lg" />
      </div>
    );
  }

  if (isAuthenticated) {
    if (role === 'admin') return <Navigate to="/admin" replace />;
    if (role === 'staff') return <Navigate to="/staff" replace />;
    return <Navigate to="/student" replace />;
  }

  return children;
}

export default function AppRoutes() {
  return (
    <Routes>
      {/* Root redirect */}
      <Route path="/" element={<RootRedirect />} />

      {/* Public Auth routes */}
      <Route
        element={
          <PublicOnlyRoute>
            <AuthLayout />
          </PublicOnlyRoute>
        }
      >
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />
      </Route>

      {/* Protected Student Portal */}
      <Route element={<ProtectedRoute />}>
        <Route element={<RoleRoute allowedRoles={['student']} />}>
          <Route element={<StudentLayout />}>
            <Route path="/student" element={<StudentDashboard />} />
            <Route path="/student/services" element={<ServiceCatalogue />} />
            <Route path="/student/services/:serviceId/apply" element={<RequestForm />} />
          </Route>
        </Route>
      </Route>

      {/* Request Detail — accessible to student owner, staff, and admin */}
      <Route element={<ProtectedRoute />}>
        <Route element={<RoleRoute allowedRoles={['student', 'staff', 'admin']} />}>
          <Route element={<StudentLayout />}>
            <Route path="/student/requests/:id" element={<RequestDetail />} />
          </Route>
        </Route>
      </Route>

      {/* Protected Staff Portal */}
      <Route element={<ProtectedRoute />}>
        <Route element={<RoleRoute allowedRoles={['staff', 'admin']} />}>
          <Route element={<StaffAdminLayout />}>
            <Route path="/staff" element={<StaffQueue />} />
          </Route>
        </Route>
      </Route>

      {/* Protected Admin Portal */}
      <Route element={<ProtectedRoute />}>
        <Route element={<RoleRoute allowedRoles={['admin']} />}>
          <Route element={<StaffAdminLayout />}>
            <Route path="/admin" element={<AdminDashboard />} />
          </Route>
        </Route>
      </Route>

      {/* Utility routes */}
      <Route path="/unauthorized" element={<Unauthorized />} />
      <Route path="*" element={<NotFound />} />
    </Routes>
  );
}
