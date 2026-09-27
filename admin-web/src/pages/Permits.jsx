import React, { useState, useEffect } from 'react';
import { FileCheck, Plus, CheckCircle, XCircle, ShieldCheck, AlertTriangle, Clock, MapPin, Building } from 'lucide-react';
import { api } from '../services/api';
import { useAuth } from '../context/AuthContext';

export const Permits = () => {
  const { user } = useAuth();
  const [permits, setPermits] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedStatus, setSelectedStatus] = useState('');
  const [selectedType, setSelectedType] = useState('');
  
  // Modals
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [selectedPermitDetails, setSelectedPermitDetails] = useState(null);
  const [rejectReason, setRejectReason] = useState('');
  const [showRejectBox, setShowRejectBox] = useState(false);

  // New Permit Form
  const [formData, setFormData] = useState({
    permit_type: 'Hot Work Permit',
    applicant_name: user?.full_name || '',
    applicant_contact: user?.phone || '',
    description: '',
    location_zone: 'Building B - 2nd Floor',
    start_time: `${new Date().toISOString().split('T')[0]}T09:00`,
    end_time: `${new Date().toISOString().split('T')[0]}T18:00`,
    safety_checklist: {
      fire_extinguisher_placed: true,
      ppe_flame_resistant: true,
      spark_shield_installed: true,
      standby_watcher: true
    }
  });

  const permitTypes = [
    'Work Permit',
    'Hot Work Permit',
    'Height Work Permit',
    'Electrical Permit',
    'Entry Permit',
    'Material Movement Permit',
    'Vehicle Permit',
    'Visitor Permit'
  ];

  const fetchPermits = async () => {
    try {
      const res = await api.getPermits({
        status: selectedStatus,
        permit_type: selectedType
      });
      if (res.success) setPermits(res.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPermits();
  }, [selectedStatus, selectedType]);

  const handleCreatePermit = async (e) => {
    e.preventDefault();
    try {
      const res = await api.createPermit(formData);
      if (res.success) {
        setShowCreateModal(false);
        fetchPermits();
      }
    } catch (err) {
      alert(err.message);
    }
  };

  const handleApprove = async (id) => {
    try {
      const res = await api.approvePermit(id);
      if (res.success) {
        setSelectedPermitDetails(null);
        fetchPermits();
      }
    } catch (err) {
      alert(err.message);
    }
  };

  const handleReject = async (id) => {
    if (!rejectReason) {
      alert('Please specify rejection reason');
      return;
    }
    try {
      const res = await api.rejectPermit(id, rejectReason);
      if (res.success) {
        setSelectedPermitDetails(null);
        setShowRejectBox(false);
        setRejectReason('');
        fetchPermits();
      }
    } catch (err) {
      alert(err.message);
    }
  };

  const handleGateVerify = async (id) => {
    try {
      const res = await api.verifyPermitGate(id);
      if (res.success) {
        alert('Permit verified by Security Gate successfully!');
        setSelectedPermitDetails(null);
        fetchPermits();
      }
    } catch (err) {
      alert(err.message);
    }
  };

  return (
    <div style={{ padding: '28px', maxWidth: '1440px', margin: '0 auto' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '20px' }}>
        <div>
          <h2 style={{ fontSize: '1.3rem', fontWeight: 800, color: '#fff' }}>Permit & Safety Authorization</h2>
          <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
            Digital permits-to-work, hazardous activity compliance, and safety verification
          </p>
        </div>

        <button onClick={() => setShowCreateModal(true)} className="btn btn-primary">
          <Plus size={16} />
          <span>Request New Permit</span>
        </button>
      </div>

      {/* Filter Toolbar */}
      <div className="glass-panel" style={{ padding: '16px', marginBottom: '20px', display: 'flex', gap: '14px', flexWrap: 'wrap' }}>
        <div style={{ width: '220px' }}>
          <select
            className="form-control"
            value={selectedType}
            onChange={(e) => setSelectedType(e.target.value)}
          >
            <option value="">All Permit Types</option>
            {permitTypes.map((t) => (
              <option key={t} value={t}>{t}</option>
            ))}
          </select>
        </div>

        <div style={{ width: '180px' }}>
          <select
            className="form-control"
            value={selectedStatus}
            onChange={(e) => setSelectedStatus(e.target.value)}
          >
            <option value="">All Statuses</option>
            <option value="Pending">Pending Review</option>
            <option value="Active">Active / Approved</option>
            <option value="Rejected">Rejected</option>
            <option value="Expired">Expired</option>
          </select>
        </div>
      </div>

      {/* Grid of Permits */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(360px, 1fr))', gap: '20px' }}>
        {permits.map((p) => {
          let badgeClass = 'badge-pending';
          if (p.status === 'Active' || p.status === 'Approved') badgeClass = 'badge-active';
          if (p.status === 'Rejected' || p.status === 'Expired') badgeClass = 'badge-denied';

          return (
            <div key={p.id} className="glass-card" style={{ padding: '20px', display: 'flex', flexDirection: 'column' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '10px' }}>
                <div>
                  <span className="mono" style={{ fontSize: '0.72rem', color: '#a5b4fc', fontWeight: 600 }}>{p.permit_number}</span>
                  <h4 style={{ fontSize: '1.05rem', fontWeight: 700, color: '#fff', marginTop: '2px' }}>{p.permit_type}</h4>
                </div>
                <span className={`badge ${badgeClass}`}>{p.status}</span>
              </div>

              <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', marginBottom: '12px', flex: 1 }}>
                {p.description}
              </p>

              <div style={{ background: 'rgba(0,0,0,0.25)', padding: '10px 12px', borderRadius: 'var(--radius-md)', fontSize: '0.75rem', display: 'flex', flexDirection: 'column', gap: '5px', marginBottom: '14px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <MapPin size={13} color="var(--accent-cyan)" />
                  <span style={{ color: '#fff' }}>{p.location_zone}</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <Building size={13} color="var(--text-muted)" />
                  <span style={{ color: 'var(--text-secondary)' }}>{p.vendor_name}</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <Clock size={13} color="var(--text-muted)" />
                  <span style={{ color: 'var(--text-secondary)' }}>
                    {new Date(p.start_time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })} - {new Date(p.end_time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                  </span>
                </div>
              </div>

              <button
                onClick={() => { setSelectedPermitDetails(p); setShowRejectBox(false); }}
                className="btn btn-secondary"
                style={{ width: '100%', fontSize: '0.8rem' }}
              >
                Review & Verification Action
              </button>
            </div>
          );
        })}
      </div>

      {/* Create Permit Modal */}
      {showCreateModal && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '600px' }}>
            <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ fontSize: '1.05rem', fontWeight: 700, color: '#fff' }}>Create Safety Permit Request</h3>
              <button onClick={() => setShowCreateModal(false)} style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}>✕</button>
            </div>

            <form onSubmit={handleCreatePermit} style={{ padding: '20px' }}>
              <div className="form-group">
                <label className="form-label">Permit Category *</label>
                <select
                  className="form-control"
                  value={formData.permit_type}
                  onChange={(e) => setFormData({ ...formData, permit_type: e.target.value })}
                >
                  {permitTypes.map((t) => (
                    <option key={t} value={t}>{t}</option>
                  ))}
                </select>
              </div>

              <div className="form-group">
                <label className="form-label">Scope of Work / Description *</label>
                <textarea
                  required
                  rows="3"
                  className="form-control"
                  placeholder="Describe the exact task, machinery used, and precautions..."
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                />
              </div>

              <div className="form-group">
                <label className="form-label">Location / Site Zone *</label>
                <input
                  type="text"
                  required
                  className="form-control"
                  placeholder="e.g. Tower B - Level 4 Electrical Riser"
                  value={formData.location_zone}
                  onChange={(e) => setFormData({ ...formData, location_zone: e.target.value })}
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                <div className="form-group">
                  <label className="form-label">Valid From *</label>
                  <input
                    type="datetime-local"
                    required
                    className="form-control"
                    value={formData.start_time}
                    onChange={(e) => setFormData({ ...formData, start_time: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Valid Until *</label>
                  <input
                    type="datetime-local"
                    required
                    className="form-control"
                    value={formData.end_time}
                    onChange={(e) => setFormData({ ...formData, end_time: e.target.value })}
                  />
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '16px' }}>
                <button type="button" onClick={() => setShowCreateModal(false)} className="btn btn-secondary">
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary">
                  Submit for Approval
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Review & Approve Drawer */}
      {selectedPermitDetails && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '640px' }}>
            <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ fontSize: '1.05rem', fontWeight: 700, color: '#fff' }}>
                Review: {selectedPermitDetails.permit_number}
              </h3>
              <button onClick={() => setSelectedPermitDetails(null)} style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}>✕</button>
            </div>

            <div style={{ padding: '20px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px' }}>
                <h4 style={{ fontSize: '1.1rem', fontWeight: 800, color: '#fff' }}>{selectedPermitDetails.permit_type}</h4>
                <span className={`badge ${selectedPermitDetails.status === 'Active' ? 'badge-active' : 'badge-pending'}`}>
                  {selectedPermitDetails.status}
                </span>
              </div>

              <div style={{ background: 'rgba(0,0,0,0.25)', padding: '12px', borderRadius: 'var(--radius-md)', fontSize: '0.8rem', display: 'flex', flexDirection: 'column', gap: '6px', marginBottom: '16px' }}>
                <div><strong>Contractor:</strong> {selectedPermitDetails.vendor_name}</div>
                <div><strong>Applicant:</strong> {selectedPermitDetails.applicant_name} ({selectedPermitDetails.applicant_contact})</div>
                <div><strong>Location:</strong> {selectedPermitDetails.location_zone}</div>
                <div><strong>Validity:</strong> {new Date(selectedPermitDetails.start_time).toLocaleString()} to {new Date(selectedPermitDetails.end_time).toLocaleString()}</div>
                <div><strong>Description:</strong> {selectedPermitDetails.description}</div>
              </div>

              {selectedPermitDetails.approved_by && (
                <div style={{ padding: '10px 14px', background: 'rgba(16, 185, 129, 0.1)', border: '1px solid rgba(16, 185, 129, 0.3)', borderRadius: 'var(--radius-md)', color: '#34d399', fontSize: '0.8rem', marginBottom: '16px' }}>
                  ✅ <strong>Approved By:</strong> {selectedPermitDetails.approved_by} on {new Date(selectedPermitDetails.approved_at).toLocaleString()}
                </div>
              )}

              {/* Action Buttons for Admin */}
              {(user?.role === 'Super Admin' || user?.role === 'Admin') && selectedPermitDetails.status === 'Pending' && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                  {!showRejectBox ? (
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
                      <button onClick={() => handleApprove(selectedPermitDetails.id)} className="btn btn-success" style={{ padding: '12px' }}>
                        <CheckCircle size={18} />
                        <span>Approve Permit</span>
                      </button>
                      <button onClick={() => setShowRejectBox(true)} className="btn btn-danger" style={{ padding: '12px' }}>
                        <XCircle size={18} />
                        <span>Reject with Remarks</span>
                      </button>
                    </div>
                  ) : (
                    <div style={{ background: 'rgba(244, 63, 94, 0.1)', padding: '14px', borderRadius: 'var(--radius-md)' }}>
                      <label className="form-label" style={{ color: '#fb7185' }}>Rejection Reason *</label>
                      <textarea
                        rows="2"
                        className="form-control"
                        placeholder="State reason for rejection..."
                        value={rejectReason}
                        onChange={(e) => setRejectReason(e.target.value)}
                      />
                      <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px', marginTop: '10px' }}>
                        <button onClick={() => setShowRejectBox(false)} className="btn btn-secondary">Cancel</button>
                        <button onClick={() => handleReject(selectedPermitDetails.id)} className="btn btn-danger">Confirm Rejection</button>
                      </div>
                    </div>
                  )}
                </div>
              )}

              {/* Gate Security Verification Button */}
              {user?.role === 'Security' && selectedPermitDetails.status === 'Active' && !selectedPermitDetails.security_verified_at && (
                <button onClick={() => handleGateVerify(selectedPermitDetails.id)} className="btn btn-primary" style={{ width: '100%', padding: '12px' }}>
                  <ShieldCheck size={18} />
                  <span>Verify Permit at Security Gate</span>
                </button>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
