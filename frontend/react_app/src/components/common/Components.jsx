import React from 'react';

export function Badge({ children, variant = 'info', className = '' }) {
  return <span className={`badge badge-${variant} ${className}`}>{children}</span>;
}

export function Card({ children, className = '', ...props }) {
  return (
    <div className={`card ${className}`} {...props}>
      {children}
    </div>
  );
}

export function Spinner({ size = 'md', className = '' }) {
  return <div className={`spinner spinner-primary ${className}`} aria-label="Loading..." />;
}

export function StatusBadge({ status, className = '' }) {
  if (!status) return null;

  let variant = 'info';
  let label = status.replace(/_/g, ' ');

  switch (status) {
    case 'COMPLETED':
    case 'BOOKING_CONFIRMED':
    case 'PAYMENT_COMPLETED':
    case 'APPROVED':
      variant = 'success';
      label = status === 'BOOKING_CONFIRMED' ? 'Confirmed' : status === 'COMPLETED' ? 'Completed' : label;
      break;
    case 'REJECTED':
      variant = 'danger';
      label = 'Rejected';
      break;
    case 'PAYMENT_REQUIRED':
      variant = 'purple';
      label = 'Payment Required';
      break;
    case 'DEPARTMENT_VERIFICATION_PENDING':
      variant = 'warning';
      label = 'Dept Verification';
      break;
    case 'STAFF_REVIEW_PENDING':
      variant = 'warning';
      label = 'Staff Review';
      break;
    case 'SECURITY_REVIEW_PENDING':
      variant = 'warning';
      label = 'Security Review';
      break;
    case 'ADMIN_APPROVAL_PENDING':
      variant = 'warning';
      label = 'Admin Approval';
      break;
    case 'SUBMITTED':
    case 'PENDING':
      variant = 'warning';
      label = 'Pending';
      break;
    default:
      variant = 'info';
  }

  return (
    <Badge variant={variant} className={className}>
      {label}
    </Badge>
  );
}
