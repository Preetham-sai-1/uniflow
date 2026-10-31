import React from 'react';
import { AlertCircle, CheckCircle, Info } from 'lucide-react';

export default function Alert({ type = 'info', message, children, className = '' }) {
  if (!message && !children) return null;

  const iconMap = {
    danger: <AlertCircle size={18} style={{ flexShrink: 0 }} />,
    success: <CheckCircle size={18} style={{ flexShrink: 0 }} />,
    info: <Info size={18} style={{ flexShrink: 0 }} />,
  };

  return (
    <div className={`alert alert-${type} ${className}`} role="alert">
      {iconMap[type] || iconMap.info}
      <div>{message || children}</div>
    </div>
  );
}
