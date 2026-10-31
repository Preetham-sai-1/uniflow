import React, { useState } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext.jsx';
import Input from '../../components/common/Input.jsx';
import Button from '../../components/common/Button.jsx';
import Alert from '../../components/common/Alert.jsx';
import { LogIn } from 'lucide-react';

export default function Login() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const [formData, setFormData] = useState({
    email: '',
    password: '',
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
    if (!formData.email.trim()) {
      newErrors.email = 'Email address is required.';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email.trim())) {
      newErrors.email = 'Please enter a valid email address.';
    }

    if (!formData.password) {
      newErrors.password = 'Password is required.';
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
      const result = await login(formData.email.trim(), formData.password);
      const user = result.user;

      // Redirect to original target if valid, otherwise role portal
      const from = location.state?.from?.pathname;
      if (from && from !== '/login' && from !== '/register' && from !== '/unauthorized') {
        navigate(from, { replace: true });
      } else {
        if (user.role === 'admin') {
          navigate('/admin', { replace: true });
        } else if (user.role === 'staff') {
          navigate('/staff', { replace: true });
        } else {
          navigate('/student', { replace: true });
        }
      }
    } catch (err) {
      setApiError(err.message || 'Login failed. Please check your email and password.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div>
      <h1 style={{ fontSize: '1.25rem', textAlign: 'center', marginBottom: '1.25rem' }}>
        Sign In to Your Account
      </h1>

      {apiError && <Alert type="danger" message={apiError} />}

      <form onSubmit={handleSubmit} noValidate>
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
          id="password"
          label="Password"
          isPassword
          value={formData.password}
          onChange={handleChange}
          error={errors.password}
          placeholder="Enter your password"
          required
          autoComplete="current-password"
        />

        <Button
          type="submit"
          variant="primary"
          className="btn-block"
          loading={submitting}
          style={{ marginTop: '0.5rem' }}
        >
          <LogIn size={18} />
          Sign In
        </Button>
      </form>

      <div className="auth-footer">
        <p style={{ marginBottom: '0.5rem' }}>
          New student?{' '}
          <Link to="/register" style={{ fontWeight: 600 }}>
            Register as a Student
          </Link>
        </p>
        <p style={{ fontSize: '0.75rem', color: 'var(--slate-400)', marginTop: '0.75rem' }}>
          Staff and administrative accounts are provisioned by institution administrators.
        </p>
      </div>
    </div>
  );
}
