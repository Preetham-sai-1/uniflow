import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext.jsx';
import { getRequests } from '../../api/requestsApi.js';
import { Card, Badge, Spinner, StatusBadge } from '../../components/common/Components.jsx';
import Alert from '../../components/common/Alert.jsx';
import {
  Compass,
  FileText,
  Clock,
  CheckCircle2,
  ArrowRight,
  PlusCircle,
  Calendar,
  Layers,
} from 'lucide-react';

export default function StudentDashboard() {
  const { user } = useAuth();
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    let isMounted = true;
    async function fetchStudentRequests() {
      try {
        setLoading(true);
        setError('');
        const res = await getRequests();
        if (isMounted) {
          setRequests(res.items || []);
        }
      } catch (err) {
        if (isMounted) {
          setError(err.response?.data?.error?.message || 'Failed to load your requests.');
        }
      } finally {
        if (isMounted) {
          setLoading(false);
        }
      }
    }
    fetchStudentRequests();
    return () => {
      isMounted = false;
    };
  }, []);

  const totalRequests = requests.length;
  const activeRequests = requests.filter(
    (r) => !['COMPLETED', 'BOOKING_CONFIRMED', 'REJECTED'].includes(r.status)
  ).length;
  const completedJourneys = requests.filter(
    (r) => ['COMPLETED', 'BOOKING_CONFIRMED'].includes(r.status)
  ).length;

  const formatDate = (dateString) => {
    if (!dateString) return '—';
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  };

  return (
    <div>
      {/* Welcome Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: '1rem', marginBottom: '2rem' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.25rem' }}>
            <Badge variant="student">Student Portal</Badge>
            {user?.studentId && (
              <span style={{ fontSize: '0.8125rem', color: 'var(--slate-500)' }}>
                Roll: {user.studentId}
              </span>
            )}
          </div>
          <h1>Welcome, {user?.name || 'Student'}</h1>
          <p style={{ margin: 0 }}>
            Navigate your campus services and track approval checkpoints in real-time.
          </p>
        </div>

        <Link to="/student/services" className="btn btn-primary">
          <PlusCircle size={18} />
          <span>New Request</span>
        </Link>
      </div>

      {error && <Alert type="danger" message={error} style={{ marginBottom: '1.5rem' }} />}

      {/* Metrics Grid */}
      <div className="dashboard-grid">
        <div className="stat-card">
          <div className="stat-icon" style={{ background: 'var(--primary-50)', color: 'var(--primary-600)' }}>
            <FileText size={24} />
          </div>
          <div>
            <div className="stat-val">{loading ? '...' : totalRequests}</div>
            <div className="stat-label">Total Submissions</div>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-icon" style={{ background: 'var(--warning-50)', color: 'var(--warning-700)' }}>
            <Clock size={24} />
          </div>
          <div>
            <div className="stat-val">{loading ? '...' : activeRequests}</div>
            <div className="stat-label">In Progress</div>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-icon" style={{ background: 'var(--success-50)', color: 'var(--success-700)' }}>
            <CheckCircle2 size={24} />
          </div>
          <div>
            <div className="stat-val">{loading ? '...' : completedJourneys}</div>
            <div className="stat-label">Completed Journeys</div>
          </div>
        </div>
      </div>

      {/* Active & Recent Journeys */}
      <div style={{ marginTop: '2.5rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
          <h2>My Active Journeys</h2>
          <Link to="/student/services" style={{ fontSize: '0.875rem', fontWeight: 600 }}>
            Explore Catalogue →
          </Link>
        </div>

        {loading ? (
          <div style={{ textAlign: 'center', padding: '3rem 1rem' }}>
            <Spinner size="lg" />
            <p style={{ marginTop: '0.75rem', color: 'var(--slate-500)' }}>Loading your requests...</p>
          </div>
        ) : requests.length === 0 ? (
          <Card style={{ textAlign: 'center', padding: '3.5rem 1.5rem' }}>
            <div style={{ display: 'inline-flex', padding: '1rem', background: 'var(--primary-50)', borderRadius: '50%', color: 'var(--primary-600)', marginBottom: '1rem' }}>
              <Compass size={36} />
            </div>
            <h3>No requests submitted yet</h3>
            <p style={{ maxWidth: '460px', margin: '0 auto 1.5rem', color: 'var(--slate-600)', fontSize: '0.9375rem' }}>
              You don't have any active digital journeys. Choose from our campus services to submit your first request.
            </p>
            <Link to="/student/services" className="btn btn-primary" style={{ display: 'inline-flex' }}>
              <span>Browse Campus Services</span>
              <ArrowRight size={16} />
            </Link>
          </Card>
        ) : (
          <div className="table-container">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Request #</th>
                  <th>Service</th>
                  <th>Category</th>
                  <th>Submitted</th>
                  <th>Current Status</th>
                  <th style={{ textAlign: 'right' }}>Action</th>
                </tr>
              </thead>
              <tbody>
                {requests.map((req) => (
                  <tr key={req._id || req.id}>
                    <td>
                      <span style={{ fontWeight: 600, color: 'var(--slate-900)' }}>
                        {req.requestNumber}
                      </span>
                    </td>
                    <td>{req.service?.name || 'Service'}</td>
                    <td>
                      <Badge variant="info">{req.service?.category || 'General'}</Badge>
                    </td>
                    <td>{formatDate(req.createdAt)}</td>
                    <td>
                      <StatusBadge status={req.status} />
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <Link
                        to={`/student/requests/${req._id || req.id}`}
                        className="btn btn-secondary"
                        style={{ padding: '0.35rem 0.75rem', fontSize: '0.8125rem' }}
                      >
                        <span>View Journey</span>
                        <ArrowRight size={14} />
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Fast Shortcuts for 3 MVP Workflows */}
      <div style={{ marginTop: '3rem' }}>
        <h2>Available Guided Journeys</h2>
        <p style={{ fontSize: '0.9375rem', color: 'var(--slate-600)', marginBottom: '1rem' }}>
          Select any of the primary digital journeys to get started directly:
        </p>

        <div className="dashboard-grid">
          <Card>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '0.5rem' }}>
              <Badge variant="info">Academic</Badge>
              <span style={{ fontSize: '0.75rem', color: 'var(--slate-400)' }}>Est. 3 days</span>
            </div>
            <h3 style={{ fontSize: '1.125rem' }}>Bonafide Certificate</h3>
            <p style={{ fontSize: '0.875rem', color: 'var(--slate-600)', marginBottom: '1rem' }}>
              Enrolment verification for scholarship, visa, and banking purposes.
            </p>
            <Link to="/student/services/bonafide-certificate/apply" className="btn btn-secondary" style={{ width: '100%', justifyContent: 'center' }}>
              Apply for Certificate
            </Link>
          </Card>

          <Card>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '0.5rem' }}>
              <Badge variant="info">Identity</Badge>
              <span style={{ fontSize: '0.75rem', color: 'var(--slate-400)' }}>Est. 5 days</span>
            </div>
            <h3 style={{ fontSize: '1.125rem' }}>ID Card Replacement</h3>
            <p style={{ fontSize: '0.875rem', color: 'var(--slate-600)', marginBottom: '1rem' }}>
              Replace lost, stolen, or damaged institutional ID cards.
            </p>
            <Link to="/student/services/id-card-replacement/apply" className="btn btn-secondary" style={{ width: '100%', justifyContent: 'center' }}>
              Request ID Card
            </Link>
          </Card>

          <Card>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '0.5rem' }}>
              <Badge variant="info">Resources</Badge>
              <span style={{ fontSize: '0.75rem', color: 'var(--slate-400)' }}>Est. 1 day</span>
            </div>
            <h3 style={{ fontSize: '1.125rem' }}>Equipment Booking</h3>
            <p style={{ fontSize: '0.875rem', color: 'var(--slate-600)', marginBottom: '1rem' }}>
              Reserve cameras, projectors, and instruments for events or coursework.
            </p>
            <Link to="/student/services/equipment-booking/apply" className="btn btn-secondary" style={{ width: '100%', justifyContent: 'center' }}>
              Book Equipment
            </Link>
          </Card>
        </div>
      </div>
    </div>
  );
}
