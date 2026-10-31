import React, { useState, useEffect } from 'react';
import { useParams, Link, useLocation } from 'react-router-dom';
import { getRequestById, confirmPayment } from '../../api/requestsApi.js';
import { Card, Badge, Spinner, StatusBadge } from '../../components/common/Components.jsx';
import Button from '../../components/common/Button.jsx';
import Alert from '../../components/common/Alert.jsx';
import {
  ArrowLeft,
  Clock,
  CheckCircle2,
  XCircle,
  AlertCircle,
  CreditCard,
  Calendar,
  User,
  Building,
  FileText,
  Sparkles,
} from 'lucide-react';

export default function RequestDetail() {
  const { id } = useParams();
  const location = useLocation();

  const [request, setRequest] = useState(null);
  const [loading, setLoading] = useState(true);
  const [paying, setPaying] = useState(false);
  const [error, setError] = useState('');
  const [successMessage, setSuccessMessage] = useState(location.state?.message || '');

  const fetchRequestDetails = async () => {
    try {
      setLoading(true);
      setError('');
      const data = await getRequestById(id);
      setRequest(data);
    } catch (err) {
      setError(err.response?.data?.error?.message || 'Failed to load request details.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchRequestDetails();
  }, [id]);

  const handleSimulatePayment = async () => {
    try {
      setPaying(true);
      setError('');
      const updated = await confirmPayment(id);
      setRequest(updated);
      setSuccessMessage('Payment of ₹100 simulated successfully! Request advanced to Administrative Approval.');
    } catch (err) {
      setError(err.response?.data?.error?.message || 'Payment simulation failed.');
    } finally {
      setPaying(false);
    }
  };

  const formatDate = (dateString) => {
    if (!dateString) return '—';
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  if (loading) {
    return (
      <div style={{ textAlign: 'center', padding: '4rem 1rem' }}>
        <Spinner size="lg" />
        <p style={{ marginTop: '1rem', color: 'var(--slate-500)' }}>Loading journey timeline...</p>
      </div>
    );
  }

  if (error && !request) {
    return (
      <div>
        <Link to="/student" className="btn btn-secondary" style={{ marginBottom: '1.5rem', display: 'inline-flex' }}>
          <ArrowLeft size={16} /> Back to Dashboard
        </Link>
        <Alert type="danger" message={error} />
      </div>
    );
  }

  const isCompleted = request.status === 'COMPLETED' || request.status === 'BOOKING_CONFIRMED';
  const isRejected = request.status === 'REJECTED';
  const isPaymentRequired = request.status === 'PAYMENT_REQUIRED';

  return (
    <div style={{ maxWidth: '880px', margin: '0 auto' }}>
      {/* Back button */}
      <div style={{ marginBottom: '1.5rem' }}>
        <Link
          to="/student"
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '0.5rem',
            color: 'var(--slate-600)',
            fontSize: '0.875rem',
            fontWeight: 500,
          }}
        >
          <ArrowLeft size={16} /> Back to Student Dashboard
        </Link>
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

      {/* Main Request Header */}
      <Card style={{ marginBottom: '1.5rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: '1rem' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.25rem' }}>
              <span style={{ fontSize: '0.8125rem', fontWeight: 600, color: 'var(--slate-500)' }}>
                {request.requestNumber}
              </span>
              <Badge variant="info">{request.service?.category || 'Service'}</Badge>
            </div>
            <h1 style={{ fontSize: '1.625rem', marginBottom: '0.25rem' }}>
              {request.service?.name}
            </h1>
            <div style={{ display: 'flex', alignItems: 'center', gap: '1.25rem', fontSize: '0.8125rem', color: 'var(--slate-500)', marginTop: '0.5rem' }}>
              <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.25rem' }}>
                <Calendar size={14} /> Submitted: {formatDate(request.createdAt)}
              </span>
              <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.25rem' }}>
                <Clock size={14} /> Est: {request.service?.estimatedDays || 2} days
              </span>
            </div>
          </div>

          <div>
            <StatusBadge status={request.status} />
          </div>
        </div>

        {/* Completion Banner */}
        {isCompleted && (
          <div style={{ marginTop: '1.5rem', padding: '1rem 1.25rem', background: 'var(--success-50)', borderRadius: 'var(--radius-md)', border: '1px solid var(--success-500)', display: 'flex', alignItems: 'center', gap: '0.75rem', color: 'var(--success-700)' }}>
            <Sparkles size={24} />
            <div>
              <div style={{ fontWeight: 600, fontSize: '0.9375rem' }}>Journey Successfully Completed!</div>
              <div style={{ fontSize: '0.8125rem' }}>
                {request.status === 'BOOKING_CONFIRMED'
                  ? 'Your equipment booking has been confirmed. Please show your Request ID at the facility desk during your reserved slot.'
                  : 'Your request has been fully verified and approved by the administrative authority.'}
              </div>
            </div>
          </div>
        )}

        {/* Rejection Banner */}
        {isRejected && (
          <div style={{ marginTop: '1.5rem', padding: '1rem 1.25rem', background: 'var(--danger-50)', borderRadius: 'var(--radius-md)', border: '1px solid var(--danger-500)', display: 'flex', alignItems: 'center', gap: '0.75rem', color: 'var(--danger-700)' }}>
            <XCircle size={24} />
            <div>
              <div style={{ fontWeight: 600, fontSize: '0.9375rem' }}>Request Terminated (Rejected)</div>
              <div style={{ fontSize: '0.8125rem' }}>
                This request was rejected during institutional review. See the timeline below for the specific reason provided.
              </div>
            </div>
          </div>
        )}

        {/* Payment Simulation UI */}
        {isPaymentRequired && (
          <div className="payment-card">
            <div className="payment-header">
              <div className="payment-icon">
                <CreditCard size={22} />
              </div>
              <div>
                <h3 style={{ margin: 0, color: '#581c87', fontSize: '1.125rem' }}>
                  Replacement Fee Payment Required
                </h3>
                <p style={{ margin: 0, fontSize: '0.8125rem', color: '#7e22ce' }}>
                  Security review passed. Please complete the simulated fee payment to advance to administrative sign-off.
                </p>
              </div>
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: '#fff', padding: '0.875rem 1.25rem', borderRadius: 'var(--radius-md)', border: '1px solid #f3e8ff' }}>
              <div>
                <div style={{ fontSize: '0.75rem', color: 'var(--slate-500)', textTransform: 'uppercase', fontWeight: 600 }}>Amount Due</div>
                <div style={{ fontSize: '1.375rem', fontWeight: 700, color: 'var(--slate-900)' }}>₹100.00</div>
              </div>
              <Button
                variant="primary"
                loading={paying}
                onClick={handleSimulatePayment}
                style={{ background: '#7e22ce', borderColor: '#6b21a8' }}
              >
                Pay Now (Simulate)
              </Button>
            </div>
          </div>
        )}
      </Card>

      {/* Journey Timeline Stepper */}
      <Card style={{ marginBottom: '1.5rem' }}>
        <h2 style={{ fontSize: '1.25rem', marginBottom: '0.5rem' }}>Journey Progress Timeline</h2>
        <p style={{ fontSize: '0.875rem', color: 'var(--slate-600)', margin: 0 }}>
          Live status progression across institutional review checkpoints.
        </p>

        <div className="timeline">
          {request.runtimeSteps && request.runtimeSteps.map((step, idx) => {
            const isStepCompleted = step.status === 'APPROVED' || step.status === 'PAYMENT_COMPLETED';
            const isStepRejected = step.status === 'REJECTED';
            const isStepActive = idx === request.currentStepIndex && !isCompleted && !isRejected;
            const isUpcoming = idx > request.currentStepIndex && !isCompleted && !isRejected;

            let stepClass = 'upcoming';
            if (isStepCompleted) stepClass = 'completed';
            else if (isStepRejected) stepClass = 'rejected';
            else if (isStepActive) stepClass = 'active';

            return (
              <div key={idx} className={`timeline-step ${stepClass}`}>
                <div className="timeline-icon-col">
                  <div className={`timeline-icon ${stepClass}`}>
                    {isStepCompleted ? (
                      <CheckCircle2 size={18} />
                    ) : isStepRejected ? (
                      <XCircle size={18} />
                    ) : (
                      idx + 1
                    )}
                  </div>
                </div>

                <div className="timeline-body">
                  <div className="timeline-header">
                    <div>
                      <div className="timeline-title">{step.name}</div>
                      <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center', marginTop: '0.25rem' }}>
                        <span style={{ fontSize: '0.75rem', color: 'var(--slate-500)' }}>
                          Assigned: <strong>{step.assignedRole?.toUpperCase()}</strong>
                        </span>
                        {step.isPaymentStep && (
                          <Badge variant="purple" style={{ fontSize: '0.7rem' }}>
                            Fee Step
                          </Badge>
                        )}
                      </div>
                    </div>

                    <div>
                      {isStepCompleted && (
                        <Badge variant="success">Completed</Badge>
                      )}
                      {isStepActive && (
                        <Badge variant="warning">Awaiting Action</Badge>
                      )}
                      {isStepRejected && (
                        <Badge variant="danger">Rejected</Badge>
                      )}
                      {isUpcoming && (
                        <span style={{ fontSize: '0.75rem', color: 'var(--slate-400)' }}>Upcoming</span>
                      )}
                    </div>
                  </div>

                  {step.actionedAt && (
                    <div className="timeline-meta">
                      Actioned on {formatDate(step.actionedAt)}
                      {step.actor?.name && ` by ${step.actor.name}`}
                    </div>
                  )}

                  {step.comment && (
                    <div className={`timeline-comment ${isStepRejected ? 'rejection' : ''}`}>
                      <strong>{isStepRejected ? 'Rejection Reason:' : 'Note:'}</strong> {step.comment}
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </Card>

      {/* Submitted Details Card */}
      <Card style={{ marginBottom: '1.5rem' }}>
        <h2 style={{ fontSize: '1.25rem', marginBottom: '1rem' }}>Submitted Information</h2>
        {request.formData && Object.keys(request.formData).length > 0 ? (
          <div className="details-grid">
            {Object.entries(request.formData).map(([key, value]) => {
              // Format key name nicely
              const label = key
                .replace(/([A-Z])/g, ' $1')
                .replace(/^./, (str) => str.toUpperCase());

              let displayValue = String(value);
              if (key === 'startTime' || key === 'endTime') {
                displayValue = formatDate(value);
              }

              return (
                <div key={key}>
                  <div className="details-item-label">{label}</div>
                  <div className="details-item-value">{displayValue || '—'}</div>
                </div>
              );
            })}
          </div>
        ) : (
          <p style={{ color: 'var(--slate-500)', fontSize: '0.875rem' }}>No custom fields provided.</p>
        )}
      </Card>

      {/* Institutional Audit History */}
      {request.auditLog && request.auditLog.length > 0 && (
        <Card>
          <h2 style={{ fontSize: '1.125rem', marginBottom: '0.75rem' }}>Audit Trail</h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', fontSize: '0.8125rem' }}>
            {request.auditLog.map((log, index) => (
              <div
                key={index}
                style={{
                  padding: '0.5rem 0.75rem',
                  background: 'var(--slate-50)',
                  borderRadius: 'var(--radius-sm)',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  flexWrap: 'wrap',
                  gap: '0.5rem',
                }}
              >
                <div>
                  <strong style={{ color: 'var(--slate-800)' }}>{log.action}</strong>
                  {log.comment && <span style={{ color: 'var(--slate-600)', marginLeft: '0.5rem' }}>— {log.comment}</span>}
                </div>
                <div style={{ color: 'var(--slate-400)' }}>
                  {formatDate(log.timestamp)}
                </div>
              </div>
            ))}
          </div>
        </Card>
      )}
    </div>
  );
}
