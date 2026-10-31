import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { getServices } from '../../api/servicesApi.js';
import { Card, Badge, Spinner } from '../../components/common/Components.jsx';
import Alert from '../../components/common/Alert.jsx';
import { Compass, Clock, ArrowRight, Layers, FileCheck, Shield, Laptop } from 'lucide-react';

export default function ServiceCatalogue() {
  const [services, setServices] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('All');

  useEffect(() => {
    let isMounted = true;
    async function fetchCatalogue() {
      try {
        setLoading(true);
        setError('');
        const data = await getServices();
        if (isMounted) {
          setServices(data || []);
        }
      } catch (err) {
        if (isMounted) {
          setError(err.response?.data?.error?.message || 'Failed to load service catalogue.');
        }
      } finally {
        if (isMounted) {
          setLoading(false);
        }
      }
    }
    fetchCatalogue();
    return () => {
      isMounted = false;
    };
  }, []);

  const categories = ['All', 'Academic', 'Identity', 'Resources'];

  const filteredServices = selectedCategory === 'All'
    ? services
    : services.filter((s) => s.category?.toLowerCase() === selectedCategory.toLowerCase());

  const getServiceIcon = (slug, category) => {
    if (slug === 'bonafide-certificate' || category === 'Academic') {
      return <FileCheck size={24} color="var(--primary-600)" />;
    }
    if (slug === 'id-card-replacement' || category === 'Identity') {
      return <Shield size={24} color="#7e22ce" />;
    }
    return <Laptop size={24} color="#059669" />;
  };

  return (
    <div>
      {/* Header */}
      <div style={{ marginBottom: '1.75rem' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.25rem' }}>
          <Badge variant="student">Digital Services</Badge>
        </div>
        <h1>Campus Service Catalogue</h1>
        <p style={{ margin: 0 }}>
          Select an institutional service to initiate your self-guided digital journey.
        </p>
      </div>

      {error && <Alert type="danger" message={error} style={{ marginBottom: '1.5rem' }} />}

      {/* Filter Tabs */}
      <div className="filter-bar">
        {categories.map((cat) => (
          <button
            key={cat}
            type="button"
            className={`filter-pill ${selectedCategory === cat ? 'active' : ''}`}
            onClick={() => setSelectedCategory(cat)}
          >
            {cat}
          </button>
        ))}
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', padding: '4rem 1rem' }}>
          <Spinner size="lg" />
          <p style={{ marginTop: '1rem', color: 'var(--slate-500)' }}>Loading available services...</p>
        </div>
      ) : filteredServices.length === 0 ? (
        <Card style={{ textAlign: 'center', padding: '3rem 1.5rem' }}>
          <Layers size={40} style={{ color: 'var(--slate-400)', marginBottom: '1rem' }} />
          <h3>No services found</h3>
          <p style={{ color: 'var(--slate-500)', margin: 0 }}>
            No campus services match the "{selectedCategory}" category right now.
          </p>
        </Card>
      ) : (
        <div className="dashboard-grid" style={{ gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))' }}>
          {filteredServices.map((service) => (
            <Card
              key={service.id || service._id}
              style={{
                display: 'flex',
                flexDirection: 'column',
                justifyContent: 'space-between',
                height: '100%',
              }}
            >
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1rem' }}>
                  <div style={{ padding: '0.625rem', background: 'var(--slate-100)', borderRadius: 'var(--radius-md)' }}>
                    {getServiceIcon(service.slug, service.category)}
                  </div>
                  <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
                    <Badge variant="info">{service.category}</Badge>
                    <span style={{ fontSize: '0.75rem', color: 'var(--slate-400)', display: 'inline-flex', alignItems: 'center', gap: '0.25rem' }}>
                      <Clock size={12} /> {service.estimatedDays || 2}d
                    </span>
                  </div>
                </div>

                <h3 style={{ marginBottom: '0.5rem' }}>{service.name}</h3>
                <p style={{ fontSize: '0.875rem', color: 'var(--slate-600)', lineHeight: '1.5', marginBottom: '1.25rem' }}>
                  {service.description}
                </p>
              </div>

              <div style={{ paddingTop: '1rem', borderTop: '1px solid var(--slate-100)' }}>
                <Link
                  to={`/student/services/${service.id || service.slug || service._id}/apply`}
                  className="btn btn-primary"
                  style={{ width: '100%', justifyContent: 'center' }}
                >
                  <span>Start Journey</span>
                  <ArrowRight size={16} />
                </Link>
              </div>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
