import React, { useState, useEffect } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { getServiceById } from '../../api/servicesApi.js';
import { submitRequest } from '../../api/requestsApi.js';
import { Card, Badge, Spinner } from '../../components/common/Components.jsx';
import Button from '../../components/common/Button.jsx';
import Alert from '../../components/common/Alert.jsx';
import { ArrowLeft, Clock, ShieldCheck, AlertCircle, Send } from 'lucide-react';

export default function RequestForm() {
  const { serviceId } = useParams();
  const navigate = useNavigate();

  const [service, setService] = useState(null);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [fieldErrors, setFieldErrors] = useState({});

  // Dynamic form state
  const [formData, setFormData] = useState({});

  useEffect(() => {
    let isMounted = true;
    async function fetchService() {
      try {
        setLoading(true);
        setError('');
        const data = await getServiceById(serviceId);
        if (isMounted) {
          setService(data);
          // Initialise default form values based on service formFields or defaults
          const initial = {};
          if (data.formFields && Array.isArray(data.formFields)) {
            data.formFields.forEach((field) => {
              if (field.type === 'number') {
                initial[field.name] = 1;
              } else if (field.type === 'select' && field.options?.length) {
                initial[field.name] = field.options[0];
              } else {
                initial[field.name] = '';
              }
            });
          }
          // Set sensible defaults if specific known service
          if (data.slug === 'bonafide-certificate') {
            initial.purpose = initial.purpose || 'Scholarship';
            initial.copies = initial.copies || 1;
            initial.additionalDetails = initial.additionalDetails || '';
          } else if (data.slug === 'id-card-replacement') {
            initial.reason = initial.reason || 'Lost';
            initial.policeComplaintRef = initial.policeComplaintRef || '';
            initial.contactNumber = initial.contactNumber || '';
          } else if (data.slug === 'equipment-booking') {
            initial.equipmentName = initial.equipmentName || '';
            initial.purpose = initial.purpose || '';
            initial.startTime = initial.startTime || '';
            initial.endTime = initial.endTime || '';
          }
          setFormData(initial);
        }
      } catch (err) {
        if (isMounted) {
          setError(err.response?.data?.error?.message || 'Failed to load service details.');
        }
      } finally {
        if (isMounted) {
          setLoading(false);
        }
      }
    }
    fetchService();
    return () => {
      isMounted = false;
    };
  }, [serviceId]);

  const handleInputChange = (field, value) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
    if (fieldErrors[field]) {
      setFieldErrors((prev) => ({ ...prev, [field]: '' }));
    }
  };

  const validateForm = () => {
    const errors = {};
    if (!service) return false;

    // Check required fields defined in service schema
    if (service.formFields && Array.isArray(service.formFields)) {
      service.formFields.forEach((field) => {
        if (field.required && (!formData[field.name] || String(formData[field.name]).trim() === '')) {
          errors[field.name] = `${field.label || field.name} is required.`;
        }
      });
    }

    // Specific service validations
    if (service.slug === 'bonafide-certificate') {
      if (!formData.purpose) errors.purpose = 'Purpose of certificate is required.';
      if (!formData.copies || Number(formData.copies) < 1) {
        errors.copies = 'Number of copies must be at least 1.';
      }
    } else if (service.slug === 'id-card-replacement') {
      if (!formData.reason) errors.reason = 'Reason for replacement is required.';
      if (!formData.contactNumber || !formData.contactNumber.trim()) {
        errors.contactNumber = 'Contact number is required for notification.';
      }
      if (formData.reason === 'Stolen' && (!formData.policeComplaintRef || !formData.policeComplaintRef.trim())) {
        errors.policeComplaintRef = 'Police complaint reference is required when reason is Stolen.';
      }
    } else if (service.slug === 'equipment-booking') {
      if (!formData.equipmentName || !formData.equipmentName.trim()) {
        errors.equipmentName = 'Equipment name is required.';
      }
      if (!formData.purpose || !formData.purpose.trim()) {
        errors.purpose = 'Purpose of booking is required.';
      }
      if (!formData.startTime) errors.startTime = 'Start time is required.';
      if (!formData.endTime) errors.endTime = 'End time is required.';
      if (formData.startTime && formData.endTime && new Date(formData.endTime) <= new Date(formData.startTime)) {
        errors.endTime = 'End time must be after start time.';
      }
    }

    setFieldErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!validateForm()) return;

    try {
      setSubmitting(true);
      setError('');
      const res = await submitRequest({
        serviceId: service.id || service._id,
        formData,
      });

      const newId = res.id || res._id;
      navigate(`/student/requests/${newId}`, {
        state: { message: `Request ${res.requestNumber || ''} created successfully!` },
      });
    } catch (err) {
      setError(
        err.response?.data?.error?.message ||
        'Failed to submit request. Please verify all fields.'
      );
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return (
      <div style={{ textAlign: 'center', padding: '4rem 1rem' }}>
        <Spinner size="lg" />
        <p style={{ marginTop: '1rem', color: 'var(--slate-500)' }}>Loading service details...</p>
      </div>
    );
  }

  if (error && !service) {
    return (
      <div>
        <Link to="/student/services" className="btn btn-secondary" style={{ marginBottom: '1.5rem', display: 'inline-flex' }}>
          <ArrowLeft size={16} /> Back to Services
        </Link>
        <Alert type="danger" message={error} />
      </div>
    );
  }

  return (
    <div style={{ maxWidth: '780px', margin: '0 auto' }}>
      {/* Back button */}
      <div style={{ marginBottom: '1.5rem' }}>
        <Link
          to="/student/services"
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '0.5rem',
            color: 'var(--slate-600)',
            fontSize: '0.875rem',
            fontWeight: 500,
          }}
        >
          <ArrowLeft size={16} /> Back to Service Directory
        </Link>
      </div>

      {/* Service Header Card */}
      <Card style={{ marginBottom: '2rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: '0.5rem', marginBottom: '0.75rem' }}>
          <Badge variant="student">Digital Journey</Badge>
          <span style={{ fontSize: '0.8125rem', color: 'var(--slate-500)', display: 'inline-flex', alignItems: 'center', gap: '0.25rem' }}>
            <Clock size={14} /> Est. turnaround: {service.estimatedDays || 3} business days
          </span>
        </div>
        <h1 style={{ fontSize: '1.75rem', marginBottom: '0.5rem' }}>{service.name}</h1>
        <p style={{ margin: 0, color: 'var(--slate-600)', fontSize: '0.9375rem' }}>
          {service.description}
        </p>

        {service.slug === 'id-card-replacement' && (
          <div style={{ marginTop: '1rem', padding: '0.75rem 1rem', background: '#fdf4ff', borderRadius: 'var(--radius-md)', border: '1px solid #f0abfc', display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.875rem', color: '#86198f' }}>
            <AlertCircle size={18} />
            <span>Note: A ₹100 replacement fee will be simulated after initial security verification.</span>
          </div>
        )}
      </Card>

      {/* Submission Form */}
      <Card>
        <h2 style={{ fontSize: '1.25rem', marginBottom: '1.25rem' }}>Request Details</h2>

        {error && <Alert type="danger" message={error} style={{ marginBottom: '1.5rem' }} />}

        <form onSubmit={handleSubmit}>
          {/* Bonafide Certificate Specific Form */}
          {service.slug === 'bonafide-certificate' && (
            <>
              <div className="form-group">
                <label htmlFor="purpose" className="form-label">
                  Purpose of Certificate <span style={{ color: 'var(--danger-500)' }}>*</span>
                </label>
                <select
                  id="purpose"
                  className="form-select"
                  value={formData.purpose || ''}
                  onChange={(e) => handleInputChange('purpose', e.target.value)}
                >
                  <option value="Scholarship">Scholarship Application</option>
                  <option value="Bank Account">Opening Bank Account</option>
                  <option value="Visa Application">Passport / Visa Application</option>
                  <option value="Internship">Internship / Job Application</option>
                  <option value="Other">Other Purpose</option>
                </select>
                {fieldErrors.purpose && <span className="form-error">{fieldErrors.purpose}</span>}
              </div>

              <div className="form-group">
                <label htmlFor="copies" className="form-label">
                  Number of Copies <span style={{ color: 'var(--danger-500)' }}>*</span>
                </label>
                <input
                  id="copies"
                  type="number"
                  min="1"
                  max="10"
                  className={`form-input ${fieldErrors.copies ? 'error' : ''}`}
                  value={formData.copies || 1}
                  onChange={(e) => handleInputChange('copies', parseInt(e.target.value, 10) || 1)}
                />
                {fieldErrors.copies && <span className="form-error">{fieldErrors.copies}</span>}
              </div>

              <div className="form-group">
                <label htmlFor="additionalDetails" className="form-label">
                  Additional Details / Custom Notes (Optional)
                </label>
                <textarea
                  id="additionalDetails"
                  rows="3"
                  className="form-textarea"
                  placeholder="e.g. Please include current CGPA or attendance percentage."
                  value={formData.additionalDetails || ''}
                  onChange={(e) => handleInputChange('additionalDetails', e.target.value)}
                />
              </div>
            </>
          )}

          {/* ID Card Replacement Specific Form */}
          {service.slug === 'id-card-replacement' && (
            <>
              <div className="form-group">
                <label htmlFor="reason" className="form-label">
                  Reason for Replacement <span style={{ color: 'var(--danger-500)' }}>*</span>
                </label>
                <select
                  id="reason"
                  className="form-select"
                  value={formData.reason || ''}
                  onChange={(e) => handleInputChange('reason', e.target.value)}
                >
                  <option value="Lost">Lost ID Card</option>
                  <option value="Stolen">Stolen ID Card</option>
                  <option value="Damaged">Damaged / Worn Out</option>
                </select>
                {fieldErrors.reason && <span className="form-error">{fieldErrors.reason}</span>}
              </div>

              {formData.reason === 'Stolen' && (
                <div className="form-group">
                  <label htmlFor="policeComplaintRef" className="form-label">
                    Police Complaint Reference / FIR No. <span style={{ color: 'var(--danger-500)' }}>*</span>
                  </label>
                  <input
                    id="policeComplaintRef"
                    type="text"
                    className={`form-input ${fieldErrors.policeComplaintRef ? 'error' : ''}`}
                    placeholder="e.g. FIR/2026/04912"
                    value={formData.policeComplaintRef || ''}
                    onChange={(e) => handleInputChange('policeComplaintRef', e.target.value)}
                  />
                  {fieldErrors.policeComplaintRef && (
                    <span className="form-error">{fieldErrors.policeComplaintRef}</span>
                  )}
                </div>
              )}

              <div className="form-group">
                <label htmlFor="contactNumber" className="form-label">
                  Contact Number for Verification <span style={{ color: 'var(--danger-500)' }}>*</span>
                </label>
                <input
                  id="contactNumber"
                  type="text"
                  className={`form-input ${fieldErrors.contactNumber ? 'error' : ''}`}
                  placeholder="+91 98765 43210"
                  value={formData.contactNumber || ''}
                  onChange={(e) => handleInputChange('contactNumber', e.target.value)}
                />
                {fieldErrors.contactNumber && (
                  <span className="form-error">{fieldErrors.contactNumber}</span>
                )}
              </div>
            </>
          )}

          {/* Equipment Booking Specific Form */}
          {service.slug === 'equipment-booking' && (
            <>
              <div className="form-group">
                <label htmlFor="equipmentName" className="form-label">
                  Equipment Required <span style={{ color: 'var(--danger-500)' }}>*</span>
                </label>
                <input
                  id="equipmentName"
                  type="text"
                  className={`form-input ${fieldErrors.equipmentName ? 'error' : ''}`}
                  placeholder="e.g. Canon EOS R10 Camera / Epson EB-X51 Projector"
                  value={formData.equipmentName || ''}
                  onChange={(e) => handleInputChange('equipmentName', e.target.value)}
                />
                {fieldErrors.equipmentName && (
                  <span className="form-error">{fieldErrors.equipmentName}</span>
                )}
              </div>

              <div className="form-group">
                <label htmlFor="bookingPurpose" className="form-label">
                  Purpose / Project Details <span style={{ color: 'var(--danger-500)' }}>*</span>
                </label>
                <textarea
                  id="bookingPurpose"
                  rows="3"
                  className={`form-textarea ${fieldErrors.purpose ? 'error' : ''}`}
                  placeholder="Describe the academic or club event requiring this equipment."
                  value={formData.purpose || ''}
                  onChange={(e) => handleInputChange('purpose', e.target.value)}
                />
                {fieldErrors.purpose && <span className="form-error">{fieldErrors.purpose}</span>}
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                <div className="form-group">
                  <label htmlFor="startTime" className="form-label">
                    Start Date & Time <span style={{ color: 'var(--danger-500)' }}>*</span>
                  </label>
                  <input
                    id="startTime"
                    type="datetime-local"
                    className={`form-input ${fieldErrors.startTime ? 'error' : ''}`}
                    value={formData.startTime || ''}
                    onChange={(e) => handleInputChange('startTime', e.target.value)}
                  />
                  {fieldErrors.startTime && (
                    <span className="form-error">{fieldErrors.startTime}</span>
                  )}
                </div>

                <div className="form-group">
                  <label htmlFor="endTime" className="form-label">
                    End Date & Time <span style={{ color: 'var(--danger-500)' }}>*</span>
                  </label>
                  <input
                    id="endTime"
                    type="datetime-local"
                    className={`form-input ${fieldErrors.endTime ? 'error' : ''}`}
                    value={formData.endTime || ''}
                    onChange={(e) => handleInputChange('endTime', e.target.value)}
                  />
                  {fieldErrors.endTime && (
                    <span className="form-error">{fieldErrors.endTime}</span>
                  )}
                </div>
              </div>
            </>
          )}

          {/* Generic fallback for custom services */}
          {!['bonafide-certificate', 'id-card-replacement', 'equipment-booking'].includes(service.slug) &&
            service.formFields?.map((field) => (
              <div key={field.name} className="form-group">
                <label htmlFor={field.name} className="form-label">
                  {field.label || field.name} {field.required && <span style={{ color: 'var(--danger-500)' }}>*</span>}
                </label>
                {field.type === 'select' ? (
                  <select
                    id={field.name}
                    className="form-select"
                    value={formData[field.name] || ''}
                    onChange={(e) => handleInputChange(field.name, e.target.value)}
                  >
                    {field.options?.map((opt) => (
                      <option key={opt} value={opt}>
                        {opt}
                      </option>
                    ))}
                  </select>
                ) : field.type === 'textarea' ? (
                  <textarea
                    id={field.name}
                    rows="3"
                    className="form-textarea"
                    value={formData[field.name] || ''}
                    onChange={(e) => handleInputChange(field.name, e.target.value)}
                  />
                ) : (
                  <input
                    id={field.name}
                    type={field.type === 'number' ? 'number' : 'text'}
                    className={`form-input ${fieldErrors[field.name] ? 'error' : ''}`}
                    value={formData[field.name] || ''}
                    onChange={(e) => handleInputChange(field.name, e.target.value)}
                  />
                )}
                {fieldErrors[field.name] && (
                  <span className="form-error">{fieldErrors[field.name]}</span>
                )}
              </div>
            ))}

          <div style={{ marginTop: '2rem', display: 'flex', justifyContent: 'flex-end', gap: '1rem' }}>
            <Link to="/student/services" className="btn btn-secondary">
              Cancel
            </Link>
            <Button
              type="submit"
              variant="primary"
              loading={submitting}
              icon={Send}
            >
              Submit Request
            </Button>
          </div>
        </form>
      </Card>
    </div>
  );
}
