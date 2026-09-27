import React, { useState, useEffect } from 'react';
import { UserCheck, Plus, UserX, Clock, Phone, Building, Search, CheckCircle } from 'lucide-react';
import { api } from '../services/api';

export const Visitors = () => {
  const [visitors, setVisitors] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [showModal, setShowModal] = useState(false);

  const [formData, setFormData] = useState({
    visitor_name: '',
    mobile: '',
    company: '',
    person_to_meet: 'Priya Sundaram (Admin)',
    purpose: 'Client Inspection & Meeting',
    vehicle_number: '',
    id_proof_type: 'Aadhaar',
    id_proof_number: '',
    instant_entry: true
  });

  const fetchVisitors = async () => {
    try {
      const res = await api.getVisitors({
        search,
        status: statusFilter
      });
      if (res.success) setVisitors(res.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchVisitors();
  }, [search, statusFilter]);

  const handleRegister = async (e) => {
    e.preventDefault();
    try {
      const res = await api.registerVisitor(formData);
      if (res.success) {
        setShowModal(false);
        fetchVisitors();
      }
    } catch (err) {
      alert(err.message);
    }
  };

  const handleCheckout = async (id) => {
    try {
      const res = await api.checkoutVisitor(id);
      if (res.success) {
        fetchVisitors();
      }
    } catch (err) {
      alert(err.message);
    }
  };

  return (
    <div style={{ padding: '28px', maxWidth: '1440px', margin: '0 auto' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '20px' }}>
        <div>
          <h2 style={{ fontSize: '1.3rem', fontWeight: 800, color: '#fff' }}>Visitor Pass & Kiosk Management</h2>
          <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
            Digital visitor badges, host pre-approval, vehicle logs and departure tracking
          </p>
        </div>

        <button onClick={() => setShowModal(true)} className="btn btn-primary">
          <Plus size={16} />
          <span>Register New Visitor</span>
        </button>
      </div>

      {/* Filter Bar */}
      <div className="glass-panel" style={{ padding: '16px', marginBottom: '20px', display: 'flex', gap: '14px', flexWrap: 'wrap' }}>
        <div style={{ flex: 1, minWidth: '220px' }}>
          <input
            type="text"
            className="form-control"
            placeholder="Search visitor name, pass code, host or company..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        <div style={{ width: '180px' }}>
          <select
            className="form-control"
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
          >
            <option value="">All Statuses</option>
            <option value="Inside">Currently Inside</option>
            <option value="Pre-Registered">Pre-Registered</option>
            <option value="Exited">Checked Out</option>
          </select>
        </div>
      </div>

      {/* Table */}
      <div className="glass-panel" style={{ padding: '1px' }}>
        <div className="table-container">
          <table className="custom-table">
            <thead>
              <tr>
                <th>Pass Code</th>
                <th>Visitor Name</th>
                <th>Organization</th>
                <th>Host Person to Meet</th>
                <th>Purpose</th>
                <th>Check-in Time</th>
                <th>Status</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {visitors.length === 0 ? (
                <tr>
                  <td colSpan="8" style={{ textAlign: 'center', padding: '32px', color: 'var(--text-muted)' }}>
                    No visitor records found.
                  </td>
                </tr>
              ) : (
                visitors.map((v) => (
                  <tr key={v.id}>
                    <td className="mono" style={{ color: '#a5b4fc', fontWeight: 600 }}>{v.pass_code}</td>
                    <td>
                      <span style={{ fontWeight: 700, color: '#fff' }}>{v.visitor_name}</span>
                      <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)', display: 'block' }}>{v.mobile}</span>
                    </td>
                    <td>{v.company || 'Individual'}</td>
                    <td style={{ color: '#38bdf8', fontWeight: 600 }}>{v.person_to_meet}</td>
                    <td>{v.purpose}</td>
                    <td>
                      <span style={{ fontSize: '0.8rem', color: '#e2e8f0' }}>
                        {v.actual_entry ? new Date(v.actual_entry).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : 'Pending'}
                      </span>
                    </td>
                    <td>
                      <span className={`badge ${
                        v.status === 'Inside' ? 'badge-inside' :
                        v.status === 'Pre-Registered' ? 'badge-pending' : 'badge-active'
                      }`}>
                        {v.status}
                      </span>
                    </td>
                    <td>
                      {v.status === 'Inside' && (
                        <button
                          onClick={() => handleCheckout(v.id)}
                          className="btn btn-secondary"
                          style={{ padding: '4px 10px', fontSize: '0.72rem', color: '#fb7185' }}
                        >
                          Check Out
                        </button>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* New Visitor Modal */}
      {showModal && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '600px' }}>
            <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ fontSize: '1.05rem', fontWeight: 700, color: '#fff' }}>Register Visitor Pass</h3>
              <button onClick={() => setShowModal(false)} style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}>✕</button>
            </div>

            <form onSubmit={handleRegister} style={{ padding: '20px' }}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                <div className="form-group">
                  <label className="form-label">Visitor Full Name *</label>
                  <input
                    type="text"
                    required
                    className="form-control"
                    placeholder="e.g. Dr. Anand Deshmukh"
                    value={formData.visitor_name}
                    onChange={(e) => setFormData({ ...formData, visitor_name: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Visitor Mobile *</label>
                  <input
                    type="text"
                    required
                    className="form-control"
                    placeholder="+91 9876543210"
                    value={formData.mobile}
                    onChange={(e) => setFormData({ ...formData, mobile: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Company / Organization</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Schneider Electric, Third-party"
                    value={formData.company}
                    onChange={(e) => setFormData({ ...formData, company: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Person to Meet (Host) *</label>
                  <input
                    type="text"
                    required
                    className="form-control"
                    placeholder="e.g. Priya Sundaram (Admin)"
                    value={formData.person_to_meet}
                    onChange={(e) => setFormData({ ...formData, person_to_meet: e.target.value })}
                  />
                </div>

                <div className="form-group" style={{ gridColumn: 'span 2' }}>
                  <label className="form-label">Purpose of Visit *</label>
                  <input
                    type="text"
                    required
                    className="form-control"
                    placeholder="e.g. Quality Audit, Substation Inspection"
                    value={formData.purpose}
                    onChange={(e) => setFormData({ ...formData, purpose: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Vehicle Number</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="KA 05 MN 1234"
                    value={formData.vehicle_number}
                    onChange={(e) => setFormData({ ...formData, vehicle_number: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">ID Proof Type</label>
                  <select
                    className="form-control"
                    value={formData.id_proof_type}
                    onChange={(e) => setFormData({ ...formData, id_proof_type: e.target.value })}
                  >
                    <option value="Aadhaar">Aadhaar Card</option>
                    <option value="Driving License">Driving License</option>
                    <option value="Voter ID">Voter ID</option>
                    <option value="Passport">Passport</option>
                  </select>
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '16px' }}>
                <button type="button" onClick={() => setShowModal(false)} className="btn btn-secondary">
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary">
                  Issue Pass & Check In
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
