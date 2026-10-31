import React, { useState, useEffect } from 'react';
import { useAuth } from '../../context/AuthContext.jsx';
import { getStaffQueue, approveStaffStep, rejectStaffStep } from '../../api/staffApi.js';
import { Card, Badge, Spinner, StatusBadge } from '../../components/common/Components.jsx';
import Button from '../../components/common/Button.jsx';
import Alert from '../../components/common/Alert.jsx';
import {
  ClipboardList,
  Clock,
  CheckCircle2,
  XCircle,
  AlertCircle,
  User,
  X,
  FileCheck,
  Search,
} from 'lucide-react';

export default function StaffQueue() {
  const { user } = useAuth();
  const [queue, setQueue] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [successMessage, setSuccessMessage] = useState('');
  const [searchQuery, setSearchQuery] = useState('');

  // Action modal state
  const [activeItem, setActiveItem] = useState(null);
  const [actionType, setActionType] = useState('APPROVE'); // 'APPROVE' or 'REJECT'
  const [comment, setComment] = useState('');
  const [submittingAction, setSubmittingAction] = useState(false);
  const [modalError, setModalError] = useState('');

  const fetchQueue = async () => {
    try {
      setLoading(true);
      setError('');
      const data = await getStaffQueue();
      setQueue(data || []);
    } catch (err) {
      setError(err.response?.data?.error?.message || 'Failed to load review queue.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchQueue();
  }, []);

  const openActionModal = (item, type = 'APPROVE') => {
    setActiveItem(item);
    setActionType(type);
    setComment('');
    setModalError('');
  };

  const closeActionModal = () => {
    setActiveItem(null);
    setComment('');
    setModalError('');
  };

  const handleActionSubmit = async (e) => {
    e.preventDefault();
    if (!activeItem) return;

    if (actionType === 'REJECT' && (!comment || !comment.trim())) {
      setModalError('A rejection reason is strictly required by institutional policy.');
      return;
    }

    try {
      setSubmittingAction(true);
      setModalError('');

      if (actionType === 'APPROVE') {
        await approveStaffStep(activeItem.requestId, activeItem.stepIndex, comment);
        setSuccessMessage(`Step "${activeItem.stepName}" for ${activeItem.requestNumber} approved.`);
      } else {
        await rejectStaffStep(activeItem.requestId, activeItem.stepIndex, comment);
        setSuccessMessage(`Request ${activeItem.requestNumber} rejected with reason logged.`);
      }

      closeActionModal();
      await fetchQueue();
    } catch (err) {
      setModalError(err.response?.data?.error?.message || 'Failed to action step.');
    } finally {
      setSubmittingAction(false);
    }
  };

  const filteredQueue = queue.filter((item) => {
    const q = searchQuery.toLowerCase();
    return (
      item.requestNumber?.toLowerCase().includes(q) ||
      item.serviceName?.toLowerCase().includes(q) ||
      item.studentName?.toLowerCase().includes(q) ||
      item.studentEmail?.toLowerCase().includes(q) ||
      item.stepName?.toLowerCase().includes(q)
    );
  });

  return (
    <div>
      {/* Header */}
      <div style={{ marginBottom: '2rem' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.25rem' }}>
          <Badge variant="staff">Staff Review Queue</Badge>
          <span style={{ fontSize: '0.8125rem', color: 'var(--slate-500)' }}>
            Logged in as: {user?.name} ({user?.role})
          </span>
        </div>
        <h1>Departmental Review Queue</h1>
        <p style={{ margin: 0 }}>
          Review, verify, and approve pending student requests for your assigned workflow checkpoints.
        </p>
      </div>

      {successMessage && (
        <Alert
          type="success"
          message={successMessage}
          onClose={() => setSuccessMessage('')}
          style={{ marginBottom: '1.5rem' }}
        />
      )}

      {error && <Alert type="danger" message={error} style={{ marginBottom: '1.5rem' }} />}

      {/* Metrics */}
      <div className="dashboard-grid">
        <div className="stat-card">
          <div className="stat-icon" style={{ background: 'var(--warning-50)', color: 'var(--warning-700)' }}>
            <Clock size={24} />
          </div>
          <div>
            <div className="stat-val">{loading ? '...' : queue.length}</div>
            <div className="stat-label">Pending Reviews</div>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-icon" style={{ background: 'var(--primary-50)', color: 'var(--primary-600)' }}>
            <ClipboardList size={24} />
          </div>
          <div>
            <div className="stat-val">{loading ? '...' : queue.filter((q) => q.waitingHours > 24).length}</div>
            <div className="stat-label">Waiting &gt; 24 Hours</div>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-icon" style={{ background: 'var(--success-50)', color: 'var(--success-700)' }}>
            <CheckCircle2 size={24} />
          </div>
          <div>
            <div className="stat-val">{user?.role === 'admin' ? 'All Roles' : 'Staff Queue'}</div>
            <div className="stat-label">Active Filter Scope</div>
          </div>
        </div>
      </div>

      {/* Search and Table */}
      <div style={{ marginTop: '2.5rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem', marginBottom: '1rem' }}>
          <h2>Pending Review Items ({filteredQueue.length})</h2>

          <div style={{ position: 'relative', width: '280px' }}>
            <input
              type="text"
              className="form-input"
              placeholder="Search by student, request #..."
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

        {loading ? (
          <div style={{ textAlign: 'center', padding: '3rem 1rem' }}>
            <Spinner size="lg" />
            <p style={{ marginTop: '0.75rem', color: 'var(--slate-500)' }}>Loading pending queue...</p>
          </div>
        ) : filteredQueue.length === 0 ? (
          <Card style={{ textAlign: 'center', padding: '3.5rem 1.5rem' }}>
            <div style={{ display: 'inline-flex', padding: '1rem', background: 'var(--success-50)', borderRadius: '50%', color: 'var(--success-700)', marginBottom: '1rem' }}>
              <CheckCircle2 size={36} />
            </div>
            <h3>Queue is all clear!</h3>
            <p style={{ color: 'var(--slate-600)', margin: 0, fontSize: '0.9375rem' }}>
              There are currently no student requests awaiting review at this checkpoint.
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
                  <th>Assigned Step</th>
                  <th>Waiting</th>
                  <th style={{ textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredQueue.map((item) => (
                  <tr key={item.stepId}>
                    <td>
                      <span style={{ fontWeight: 600, color: 'var(--slate-900)' }}>
                        {item.requestNumber}
                      </span>
                    </td>
                    <td>
                      <div>
                        <strong>{item.serviceName}</strong>
                        {item.serviceCategory && (
                          <div style={{ fontSize: '0.75rem', color: 'var(--slate-400)' }}>
                            {item.serviceCategory}
                          </div>
                        )}
                      </div>
                    </td>
                    <td>
                      <div>
                        <div style={{ fontWeight: 500 }}>{item.studentName}</div>
                        <div style={{ fontSize: '0.75rem', color: 'var(--slate-400)' }}>
                          {item.studentEmail} {item.studentIdNumber ? `(${item.studentIdNumber})` : ''}
                        </div>
                      </div>
                    </td>
                    <td>
                      <Badge variant="info">{item.stepName}</Badge>
                    </td>
                    <td>
                      <span style={{ fontSize: '0.8125rem', color: item.waitingHours > 24 ? 'var(--danger-700)' : 'var(--slate-500)' }}>
                        {item.waitingHours}h ago
                      </span>
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <div style={{ display: 'inline-flex', gap: '0.5rem' }}>
                        <button
                          type="button"
                          className="btn btn-primary"
                          style={{ padding: '0.35rem 0.75rem', fontSize: '0.8125rem' }}
                          onClick={() => openActionModal(item, 'APPROVE')}
                        >
                          Approve
                        </button>
                        <button
                          type="button"
                          className="btn btn-secondary"
                          style={{ padding: '0.35rem 0.75rem', fontSize: '0.8125rem', color: 'var(--danger-700)', borderColor: 'var(--danger-500)' }}
                          onClick={() => openActionModal(item, 'REJECT')}
                        >
                          Reject
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Action Modal */}
      {activeItem && (
        <div className="modal-backdrop" onClick={closeActionModal}>
          <div className="modal-dialog" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3 style={{ margin: 0, fontSize: '1.125rem' }}>
                {actionType === 'APPROVE' ? 'Approve Workflow Step' : 'Reject Request'}
              </h3>
              <button
                type="button"
                onClick={closeActionModal}
                style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--slate-400)' }}
              >
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleActionSubmit}>
              <div className="modal-body">
                {modalError && <Alert type="danger" message={modalError} style={{ marginBottom: '1rem' }} />}

                {/* Request Overview in Modal */}
                <div style={{ background: 'var(--slate-50)', padding: '0.875rem 1rem', borderRadius: 'var(--radius-md)', border: '1px solid var(--slate-200)', marginBottom: '1.25rem', fontSize: '0.875rem' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.25rem' }}>
                    <span style={{ color: 'var(--slate-500)' }}>Request ID:</span>
                    <strong>{activeItem.requestNumber}</strong>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.25rem' }}>
                    <span style={{ color: 'var(--slate-500)' }}>Service:</span>
                    <strong>{activeItem.serviceName}</strong>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.25rem' }}>
                    <span style={{ color: 'var(--slate-500)' }}>Student:</span>
                    <strong>{activeItem.studentName}</strong>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span style={{ color: 'var(--slate-500)' }}>Step to Action:</span>
                    <Badge variant="info">{activeItem.stepName}</Badge>
                  </div>
                </div>

                {/* Action Toggle */}
                <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '1.25rem' }}>
                  <button
                    type="button"
                    className={`btn ${actionType === 'APPROVE' ? 'btn-primary' : 'btn-secondary'}`}
                    style={{ flex: 1, justifyContent: 'center' }}
                    onClick={() => {
                      setActionType('APPROVE');
                      setModalError('');
                    }}
                  >
                    <CheckCircle2 size={16} /> Approve
                  </button>
                  <button
                    type="button"
                    className={`btn ${actionType === 'REJECT' ? 'btn-danger' : 'btn-secondary'}`}
                    style={{ flex: 1, justifyContent: 'center' }}
                    onClick={() => {
                      setActionType('REJECT');
                      setModalError('');
                    }}
                  >
                    <XCircle size={16} /> Reject
                  </button>
                </div>

                {/* Comment Field */}
                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label htmlFor="staffComment" className="form-label">
                    {actionType === 'APPROVE' ? 'Verification Comment (Optional)' : 'Rejection Reason (Mandatory)'}{' '}
                    {actionType === 'REJECT' && <span style={{ color: 'var(--danger-500)' }}>*</span>}
                  </label>
                  <textarea
                    id="staffComment"
                    rows="3"
                    className="form-textarea"
                    placeholder={
                      actionType === 'APPROVE'
                        ? 'e.g. Enrolment verified. Documents confirmed.'
                        : 'e.g. Student ID does not match active records. Please resubmit with correct ID.'
                    }
                    value={comment}
                    onChange={(e) => setComment(e.target.value)}
                  />
                  {actionType === 'REJECT' && (
                    <span style={{ fontSize: '0.75rem', color: 'var(--danger-700)', marginTop: '0.25rem', display: 'block' }}>
                      Per institutional rule, a specific reason must be provided to the student.
                    </span>
                  )}
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={closeActionModal}>
                  Cancel
                </button>
                <Button
                  type="submit"
                  variant={actionType === 'APPROVE' ? 'primary' : 'danger'}
                  loading={submittingAction}
                >
                  Confirm {actionType === 'APPROVE' ? 'Approval' : 'Rejection'}
                </Button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
