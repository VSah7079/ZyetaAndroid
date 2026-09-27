import React, { useState, useEffect } from 'react';
import { Building2, Plus, Phone, Mail, FileText, CheckCircle, AlertTriangle, Users, Calendar } from 'lucide-react';
import { api } from '../services/api';

export const Vendors = () => {
  const [vendors, setVendors] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [selectedVendorDetails, setSelectedVendorDetails] = useState(null);

  const [formData, setFormData] = useState({
    company_name: '',
    owner_name: '',
    email: '',
    phone: '',
    address: '',
    gst_pan: '',
    contract_start: new Date().toISOString().split('T')[0],
    contract_end: '2027-12-31'
  });

  const fetchVendors = async () => {
    try {
      const res = await api.getVendors();
      if (res.success) setVendors(res.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchVendors();
  }, []);

  const handleCreate = async (e) => {
    e.preventDefault();
    try {
      const res = await api.createVendor(formData);
      if (res.success) {
        setShowModal(false);
        fetchVendors();
      }
    } catch (err) {
      alert(err.message);
    }
  };

  const handleViewVendor = async (id) => {
    try {
      const res = await api.getVendorById(id);
      if (res.success) {
        setSelectedVendorDetails(res.data);
      }
    } catch (err) {
      alert(err.message);
    }
  };

  return (
    <div style={{ padding: '28px', maxWidth: '1440px', margin: '0 auto' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px' }}>
        <div>
          <h2 style={{ fontSize: '1.3rem', fontWeight: 800, color: '#fff' }}>Contractor & Vendor Management</h2>
          <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
            Contractor compliance, workforce strength, contract terms and document verification
          </p>
        </div>

        <button onClick={() => setShowModal(true)} className="btn btn-primary">
          <Plus size={16} />
          <span>Onboard New Contractor</span>
        </button>
      </div>

      {/* Vendor Cards Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(360px, 1fr))', gap: '20px' }}>
        {vendors.map((v) => (
          <div key={v.id} className="glass-card" style={{ padding: '20px', display: 'flex', flexDirection: 'column' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '12px' }}>
              <div>
                <span className="mono" style={{ fontSize: '0.72rem', color: '#a5b4fc', fontWeight: 600 }}>{v.vendor_id}</span>
                <h3 style={{ fontSize: '1.1rem', fontWeight: 700, color: '#fff', marginTop: '2px' }}>{v.company_name}</h3>
                <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Contact: {v.owner_name}</p>
              </div>
              <span className={`badge ${v.status === 'Active' ? 'badge-active' : 'badge-expired'}`}>{v.status}</span>
            </div>

            <div style={{ background: 'rgba(0,0,0,0.25)', padding: '12px', borderRadius: 'var(--radius-md)', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px', marginBottom: '14px', fontSize: '0.75rem' }}>
              <div>
                <span style={{ color: 'var(--text-muted)', display: 'block' }}>Total Workforce</span>
                <strong style={{ fontSize: '1rem', color: '#fff' }}>{v.employee_count || 0}</strong>
              </div>
              <div>
                <span style={{ color: 'var(--text-muted)', display: 'block' }}>Currently On Site</span>
                <strong style={{ fontSize: '1rem', color: '#34d399' }}>{v.inside_count || 0}</strong>
              </div>
              <div>
                <span style={{ color: 'var(--text-muted)', display: 'block' }}>Active Permits</span>
                <strong style={{ fontSize: '1rem', color: '#fbbf24' }}>{v.active_permits || 0}</strong>
              </div>
              <div>
                <span style={{ color: 'var(--text-muted)', display: 'block' }}>Contract End</span>
                <span style={{ color: '#e2e8f0' }}>{v.contract_end}</span>
              </div>
            </div>

            <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', display: 'flex', flexDirection: 'column', gap: '4px', marginBottom: '16px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <Phone size={13} color="var(--text-muted)" />
                <span>{v.phone}</span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <Mail size={13} color="var(--text-muted)" />
                <span>{v.email}</span>
              </div>
            </div>

            <div style={{ marginTop: 'auto' }}>
              <button
                onClick={() => handleViewVendor(v.id)}
                className="btn btn-secondary"
                style={{ width: '100%', fontSize: '0.8rem' }}
              >
                View Contractor Portal & Compliance
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* Onboard Vendor Modal */}
      {showModal && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '600px' }}>
            <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ fontSize: '1.05rem', fontWeight: 700, color: '#fff' }}>Onboard Contractor / Vendor</h3>
              <button onClick={() => setShowModal(false)} style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}>✕</button>
            </div>

            <form onSubmit={handleCreate} style={{ padding: '20px' }}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
                <div className="form-group" style={{ gridColumn: 'span 2' }}>
                  <label className="form-label">Company Legal Name *</label>
                  <input
                    type="text"
                    required
                    className="form-control"
                    placeholder="e.g. Apex MEP Solutions Pvt Ltd"
                    value={formData.company_name}
                    onChange={(e) => setFormData({ ...formData, company_name: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Authorized Contact Person</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Suresh Kumar"
                    value={formData.owner_name}
                    onChange={(e) => setFormData({ ...formData, owner_name: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Phone Number *</label>
                  <input
                    type="text"
                    required
                    className="form-control"
                    placeholder="+91 9876543210"
                    value={formData.phone}
                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Email Address</label>
                  <input
                    type="email"
                    className="form-control"
                    placeholder="vendor@domain.com"
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">GST / PAN Number</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="29ABCDE1234F1Z5"
                    value={formData.gst_pan}
                    onChange={(e) => setFormData({ ...formData, gst_pan: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Contract Start Date</label>
                  <input
                    type="date"
                    className="form-control"
                    value={formData.contract_start}
                    onChange={(e) => setFormData({ ...formData, contract_start: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Contract End Date</label>
                  <input
                    type="date"
                    className="form-control"
                    value={formData.contract_end}
                    onChange={(e) => setFormData({ ...formData, contract_end: e.target.value })}
                  />
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '16px' }}>
                <button type="button" onClick={() => setShowModal(false)} className="btn btn-secondary">
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary">
                  Save Contractor
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Vendor Details & Compliance Drawer */}
      {selectedVendorDetails && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '750px' }}>
            <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ fontSize: '1.05rem', fontWeight: 700, color: '#fff' }}>
                Contractor 360° Portal: {selectedVendorDetails.company_name}
              </h3>
              <button onClick={() => setSelectedVendorDetails(null)} style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}>✕</button>
            </div>

            <div style={{ padding: '20px' }}>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '10px', marginBottom: '20px' }}>
                <div style={{ background: 'rgba(0,0,0,0.3)', padding: '10px', borderRadius: '8px', textAlign: 'center' }}>
                  <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>Workforce</span>
                  <p style={{ fontSize: '1.2rem', fontWeight: 800, color: '#fff' }}>{selectedVendorDetails.stats.total_employees}</p>
                </div>
                <div style={{ background: 'rgba(0,0,0,0.3)', padding: '10px', borderRadius: '8px', textAlign: 'center' }}>
                  <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>Inside Now</span>
                  <p style={{ fontSize: '1.2rem', fontWeight: 800, color: '#34d399' }}>{selectedVendorDetails.stats.currently_inside}</p>
                </div>
                <div style={{ background: 'rgba(0,0,0,0.3)', padding: '10px', borderRadius: '8px', textAlign: 'center' }}>
                  <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>Active Permits</span>
                  <p style={{ fontSize: '1.2rem', fontWeight: 800, color: '#fbbf24' }}>{selectedVendorDetails.stats.active_permits}</p>
                </div>
                <div style={{ background: 'rgba(0,0,0,0.3)', padding: '10px', borderRadius: '8px', textAlign: 'center' }}>
                  <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>Expiring Docs</span>
                  <p style={{ fontSize: '1.2rem', fontWeight: 800, color: '#f43f5e' }}>{selectedVendorDetails.stats.expiring_compliance_docs}</p>
                </div>
              </div>

              <h5 style={{ fontSize: '0.85rem', fontWeight: 700, color: '#fff', marginBottom: '8px' }}>Registered Workers</h5>
              <div className="table-container" style={{ maxHeight: '200px', overflowY: 'auto', marginBottom: '16px' }}>
                <table className="custom-table" style={{ fontSize: '0.75rem' }}>
                  <thead>
                    <tr>
                      <th>ID</th>
                      <th>Name</th>
                      <th>Designation</th>
                      <th>Mobile</th>
                      <th>Inside</th>
                    </tr>
                  </thead>
                  <tbody>
                    {selectedVendorDetails.employees.map((e) => (
                      <tr key={e.id}>
                        <td className="mono">{e.employee_id}</td>
                        <td style={{ fontWeight: 600, color: '#fff' }}>{e.full_name}</td>
                        <td>{e.designation}</td>
                        <td>{e.mobile}</td>
                        <td><span className={`badge ${e.currently_inside ? 'badge-inside' : 'badge-absent'}`}>{e.currently_inside ? 'YES' : 'NO'}</span></td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
