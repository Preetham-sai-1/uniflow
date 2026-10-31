import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext.jsx';
import Input from '../../components/common/Input.jsx';
import Button from '../../components/common/Button.jsx';
import Alert from '../../components/common/Alert.jsx';
import { UserPlus } from 'lucide-react';

export default function Register() {
  const { register } = useAuth();
  const navigate = useNavigate();

  const [formData, setFormData] = useState({
    name: '',
    email: '',
    studentId: '',
    password: '',
    confirmPassword: '',
  });

  const [errors, setErrors] = useState({});
  const [apiError, setApiError] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  const handleChange = (e) => {
    const { id, value } = e.target;
    setFormData((prev) => ({ ...prev, [id]: value }));
    if (errors[id]) {
      setErrors((prev) => ({ ...prev, [id]: null }));
    }
  };

  const validate = () => {
    const newErrors = {};

    if (!formData.name.trim()) {
      newErrors.name = 'Full name is required.';
    } else if (formData.name.trim().length < 2) {
      newErrors.name = 'Name must be at least 2 characters.';
    }

    if (!formData.email.trim()) {
      newErrors.email = 'Institutional email is required.';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email.trim())) {
      newErrors.email = 'Please provide a valid email address.';
    }

    if (!formData.password) {
      newErrors.password = 'Password is required.';
    } else if (formData.password.length < 8) {
      newErrors.password = 'Password must be at least 8 characters long.';
    }

    if (!formData.confirmPassword) {
      newErrors.confirmPassword = 'Confirm your password.';
    } else if (formData.password !== formData.confirmPassword) {
      newErrors.confirmPassword = 'Passwords do not match.';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setApiError(null);

    if (!validate()) return;

    setSubmitting(true);
    try {
      await register({
        name: formData.name.trim(),
        email: formData.email.trim(),
        studentId: formData.studentId.trim(),
        password: formData.password,
      });

      // Auto-logged in upon successful registration -> go to student dashboard
      navigate('/student', { replace: true });
    } catch (err) {
      if (err.details && Array.isArray(err.details)) {
        const fieldErrors = {};
        err.details.forEach((d) => {
          fieldErrors[d.field] = d.message;
        });
        setErrors((prev) => ({ ...prev, ...fieldErrors }));
      }
      setApiError(err.message || 'Registration failed. Please check the form.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div>
      <h1 style={{ fontSize: '1.25rem', textAlign: 'center', marginBottom: '0.25rem' }}>
        Student Registration
      </h1>
      <p style={{ fontSize: '0.8125rem', textAlign: 'center', color: 'var(--slate-500)', marginBottom: '1.25rem' }}>
        Create your student account to access digital campus services.
      </p>

      {apiError && <Alert type="danger" message={apiError} />}

      <form onSubmit={handleSubmit} noValidate>
        <Input
          id="name"
          label="Full Name"
          type="text"
          value={formData.name}
          onChange={handleChange}
          error={errors.name}
          placeholder="e.g. Arjun Sharma"
          required
          autoComplete="name"
        />

        <Input
          id="email"
          label="Institutional Email"
          type="email"
          value={formData.email}
          onChange={handleChange}
          error={errors.email}
          placeholder="e.g. arjun.sharma@college.edu"
          required
          autoComplete="email"
        />

        <Input
          id="studentId"
          label="Student Roll / ID Number"
          type="text"
          value={formData.studentId}
          onChange={handleChange}
          error={errors.studentId}
          placeholder="e.g. CS2021001"
          hint="Optional: helps your department verify records faster"
        />

        <Input
          id="password"
          label="Password"
          isPassword
          value={formData.password}
          onChange={handleChange}
          error={errors.password}
          placeholder="Minimum 8 characters"
          required
          autoComplete="new-password"
        />

        <Input
          id="confirmPassword"
          label="Confirm Password"
          isPassword
          value={formData.confirmPassword}
          onChange={handleChange}
          error={errors.confirmPassword}
          placeholder="Re-enter password"
          required
          autoComplete="new-password"
        />

        <Button
          type="submit"
          variant="primary"
          className="btn-block"
          loading={submitting}
          style={{ marginTop: '0.75rem' }}
        >
          <UserPlus size={18} />
          Create Student Account
        </Button>
      </form>

      <div className="auth-footer">
        <p>
          Already registered?{' '}
          <Link to="/login" style={{ fontWeight: 600 }}>
            Sign In
          </Link>
        </p>
      </div>
    </div>
  );
}
