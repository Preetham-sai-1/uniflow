import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext.jsx';
import { getAdminStats, getAllRequests } from '../../api/adminApi.js';
import { Card, Badge, Spinner, StatusBadge } from '../../components/common/Components.jsx';
import Alert from '../../components/common/Alert.jsx';
import {
  ShieldCheck,
  BarChart3,
  Users,
  Layers,
  Activity,
  CheckCircle2,
  Clock,
  XCircle,
  Search,
  ArrowRight,
  ClipboardList,
} from 'lucide-react';

export default function AdminDashboard() {
  const { user } = useAuth();
  const [stats, setStats] = useState(null);
  const [requests, setRequests] = useState([]);
  const [loadingStats, setLoadingStats] = useState(true);
  const [loadingRequests, setLoadingRequests] = useState(true);
  const [error, setError] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    let isMounted = true;
    async function fetchStats() {
      try {
        setLoadingStats(true);
        const data = await getAdminStats();
        if (isMounted) setStats(data);
      } catch (err) {
        if (isMounted) {
          setError(err.response?.data?.error?.message || 'Failed to load admin stats.');
        }
      } finally {
        if (isMounted) setLoadingStats(false);
      }
    }
    fetchStats();
    return () => {
      isMounted = false;
    };
  }, []);

  useEffect(() => {
    let isMounted = true;
    async function fetchRequests() {
      try {
        setLoadingRequests(true);
        const params = {};
        if (statusFilter !== 'ALL') {
          params.status = statusFilter;
        }
        const res = await getAllRequests(params);
        if (isMounted) setRequests(res.items || []);
      } catch (err) {
        if (isMounted) {
          // Do not override primary error if stats succeeded
          console.error(err);
        }
      } finally {
        if (isMounted) setLoadingRequests(false);
      }
    }
    fetchRequests();
    return () => {
      isMounted = false;
    };
  }, [statusFilter]);

  const formatDate = (dateString) => {
    if (!dateString) return '—';
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  };

  const filteredRequests = requests.filter((r) => {
    const q = searchQuery.toLowerCase();
    return (
      r.requestNumber?.toLowerCase().includes(q) ||
      r.service?.name?.toLowerCase().includes(q) ||
      r.student?.name?.toLowerCase().includes(q) ||
      r.student?.email?.toLowerCase().includes(q) ||
      r.student?.studentId?.toLowerCase().includes(q)
    );
  });

  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: '1rem', marginBottom: '2rem' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.25rem' }}>
            <Badge variant="admin">Administrative Console</Badge>
            <span style={{ fontSize: '0.8125rem', color: 'var(--slate-500)' }}>
              Superuser Role
            </span>
          </div>
          <h1>Institutional Control Center</h1>
          <p style={{ margin: 0 }}>
            Cross-department workflow metrics, request volume, and administrative operations.
          </p>
        </div>

        <Link to="/staff" className="btn btn-secondary">
          <ClipboardList size={18} />
          <span>Go to Staff Queue</span>
        </Link>
      </div>

      {error && <Alert type="danger" message={error} style={{ marginBottom: '1.5rem' }} />}

      {/* Metrics Grid */}
      <div className="dashboard-grid">
        <div className="stat-card">
          <div className="stat-icon" style={{ background: 'var(--primary-50)', color: 'var(--primary-600)' }}>
            <Layers size={24} />
          </div>
          <div>
            <div className="stat-val">{loadingStats ? '...' : stats?.requests?.total ?? 0}</div>
            <div className="stat-label">Total Submissions</div>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-icon" style={{ background: 'var(--warning-50)', color: 'var(--warning-700)' }}>
            <Clock size={24} />
          </div>
          <div>
            <div className="stat-val">{loadingStats ? '...' : stats?.requests?.pending ?? 0}</div>
            <div className="stat-label">Pending Approval</div>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-icon" style={{ background: 'var(--success-50)', color: 'var(--success-700)' }}>
            <CheckCircle2 size={24} />
          </div>
          <div>
            <div className="stat-val">{loadingStats ? '...' : stats?.requests?.completed ?? 0}</div>
            <div className="stat-label">Completed Journeys</div>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-icon" style={{ background: 'var(--danger-50)', color: 'var(--danger-700)' }}>
            <XCircle size={24} />
          </div>
          <div>
            <div className="stat-val">{loadingStats ? '...' : stats?.requests?.rejected ?? 0}</div>
            <div className="stat-label">Rejected Requests</div>
          </div>
        </div>
      </div>

      {/* Breakdown by Service */}
      {stats?.byService && stats.byService.length > 0 && (
        <div style={{ marginTop: '2.5rem' }}>
          <h2>Workflow Volume Breakdown</h2>
          <div className="dashboard-grid" style={{ marginTop: '1rem' }}>
            {stats.byService.map((item, idx) => (
              <Card key={idx}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
                  <h3 style={{ fontSize: '1rem', margin: 0 }}>{item.serviceName}</h3>
                  <Badge variant="info">{item.total} total</Badge>
                </div>
                <div style={{ fontSize: '0.8125rem', color: 'var(--slate-500)', display: 'flex', justifyContent: 'space-between' }}>
                  <span>Awaiting Action:</span>
                  <strong style={{ color: item.pending > 0 ? 'var(--warning-700)' : 'var(--success-700)' }}>
                    {item.pending} pending
                  </strong>
                </div>
              </Card>
            ))}
          </div>
        </div>
      )}

      {/* Institutional Request Explorer */}
      <div style={{ marginTop: '3rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem', marginBottom: '1rem' }}>
          <h2>Institutional Request Explorer</h2>

          <div style={{ position: 'relative', width: '280px' }}>
            <input
              type="text"
              className="form-input"
              placeholder="Filter by student, roll no..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              style={{ paddingLeft: '2.25rem' }}
            />
            <Search
              size={16}
              style={{ position: 'absolute', left: '0.75rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--slate-400)' }}
            />
          </div>
        </div>

        {/* Filter Pills */}
        <div className="filter-bar">
          {['ALL', 'PENDING', 'COMPLETED', 'REJECTED'].map((filter) => (
            <button
              key={filter}
              type="button"
              className={`filter-pill ${statusFilter === filter ? 'active' : ''}`}
              onClick={() => setStatusFilter(filter)}
            >
              {filter}
            </button>
          ))}
        </div>

        {loadingRequests ? (
          <div style={{ textAlign: 'center', padding: '3rem 1rem' }}>
            <Spinner size="lg" />
            <p style={{ marginTop: '0.75rem', color: 'var(--slate-500)' }}>Loading institutional requests...</p>
          </div>
        ) : filteredRequests.length === 0 ? (
          <Card style={{ textAlign: 'center', padding: '3rem 1.5rem' }}>
            <Activity size={36} style={{ color: 'var(--slate-400)', marginBottom: '0.75rem' }} />
            <h3>No requests match your criteria</h3>
            <p style={{ color: 'var(--slate-500)', margin: 0, fontSize: '0.875rem' }}>
              No campus requests found with the selected filter.
            </p>
          </Card>
        ) : (
          <div className="table-container">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Request #</th>
                  <th>Service</th>
                  <th>Student</th>
                  <th>Submitted</th>
                  <th>Status</th>
                  <th style={{ textAlign: 'right' }}>Action</th>
                </tr>
              </thead>
              <tbody>
                {filteredRequests.map((req) => (
                  <tr key={req._id || req.id}>
                    <td>
                      <span style={{ fontWeight: 600, color: 'var(--slate-900)' }}>
                        {req.requestNumber}
                      </span>
                    </td>
                    <td>{req.service?.name || 'Service'}</td>
                    <td>
                      <div>
                        <div style={{ fontWeight: 500 }}>{req.student?.name || 'Student'}</div>
                        <div style={{ fontSize: '0.75rem', color: 'var(--slate-400)' }}>
                          {req.student?.email} {req.student?.studentId ? `(${req.student.studentId})` : ''}
                        </div>
                      </div>
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
                        Inspect
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
