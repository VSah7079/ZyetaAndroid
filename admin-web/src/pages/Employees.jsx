import React, { useState, useEffect } from 'react';
import { 
  Users, 
  UserPlus, 
  Search, 
  Filter, 
  QrCode, 
  CreditCard, 
  Eye, 
  Trash2, 
  CheckCircle, 
  AlertTriangle,
  Building,
  Shield,
  FileText
} from 'lucide-react';
import { api } from '../services/api';
import { useAuth } from '../context/AuthContext';
import { DigitalIdCard } from '../components/DigitalIdCard';

export const Employees = () => {
  const { user } = useAuth();
  const [employees, setEmployees] = useState([]);
  const [vendors, setVendors] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [selectedVendor, setSelectedVendor] = useState('');
  const [selectedStatus, setSelectedStatus] = useState('');
  
  // Modals
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [selectedEmployeeForCard, setSelectedEmployeeForCard] = useState(null);
  const [viewEmployeeDrawer, setViewEmployeeDrawer] = useState(null);

  // New Employee Form State
  const [uploadingField, setUploadingField] = useState(null);
  const [formData, setFormData] = useState({
    full_name: '',
    father_name: '',
    dob: '1995-01-01',
    gender: 'Male',
    mobile: '',
    alternate_mobile: '',
    email: '',
    address: '',
    city: 'Bangalore',
    state: 'Karnataka',
    pincode: '560001',
    emergency_name: '',
    emergency_relation: 'Parent',
    emergency_phone: '',
    blood_group: 'B+',
    medical_cert: 'Fit for Construction & Height Work (Grade A)',
    medical_validity: '2027-12-31',
    medical_doc: '',
    aadhaar_doc: '',
    vendor_id: '',
    department_id: '1',
    designation: 'Specialist Technician',
    skill: 'Skilled Operator',
    employee_type: 'Contractor',
    joining_date: new Date().toISOString().split('T')[0],
    shift_id: '1',
    aadhaar_no: '',
    pan_no: '',
    police_verification_expiry: '2027-12-31',
    profile_photo: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'
  });

  const fetchData = async () => {
    try {
      const [empRes, venRes] = await Promise.all([
        api.getEmployees({
          search,
          vendor_id: selectedVendor,
          status: selectedStatus
        }),
        api.getVendors()
      ]);

      if (empRes.success) setEmployees(empRes.data);
      if (venRes.success) setVendors(venRes.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [search, selectedVendor, selectedStatus]);

  const handleManualUpload = async (field, e) => {
    const file = e.target.files[0];
    if (!file) return;
    try {
      setUploadingField(field);
      const res = await api.uploadFile(file);
      if (res.success) {
        if (field === 'profile_photo') {
          setFormData(prev => ({ ...prev, profile_photo: `http://localhost:5000${res.data.url}` }));
        } else if (field === 'aadhaar_doc') {
          setFormData(prev => ({ ...prev, aadhaar_doc: res.data.filename }));
        } else if (field === 'medical_doc') {
          setFormData(prev => ({ ...prev, medical_doc: res.data.filename }));
        }
      }
    } catch (err) {
      alert('Upload failed: ' + err.message);
    } finally {
      setUploadingField(null);
    }
  };

  const handleApproveStage = async (id, stage, action) => {
    try {
      const res = await api.approveEmployeeStage(id, stage, action, `${stage === 'admin' ? 'Site Admin KYC' : 'Safety HSE Clearance'} approved by ${user?.fullName || user?.role}`);
      if (res.success) {
        fetchData();
        if (viewEmployeeDrawer && viewEmployeeDrawer.id === id) {
          open360View(id);
        }
      }
    } catch (err) {
      alert(err.message || 'Approval action failed');
    }
  };

  const handleCreateEmployee = async (e) => {
    e.preventDefault();
    try {
      const res = await api.createEmployee(formData);
      if (res.success) {
        setShowCreateModal(false);
        fetchData();
      }
    } catch (err) {
      alert(err.message || 'Creation failed');
    }
  };

  const handleDeactivate = async (id) => {
    if (window.confirm('Are you sure you want to deactivate this employee? Gate access will be blocked immediately.')) {
      try {
        await api.deleteEmployee(id);
        fetchData();
      } catch (err) {
        alert(err.message);
      }
    }
  };

  const open360View = async (id) => {
    try {
      const res = await api.getEmployeeById(id);
      if (res.success) {
        setViewEmployeeDrawer(res.data);
      }
    } catch (err) {
      alert(err.message);
    }
  };

  return (
    <div className="page-container">
      {/* Top Header */}
      <div className="page-header">
        <div>
          <h2 style={{ fontSize: 'clamp(1.1rem, 2.2vw, 1.3rem)', fontWeight: 800, color: '#fff' }}>
            {user?.role === 'Vendor' ? 'Contractor Workforce Portal' : 'Employee & Contractor Master'}
          </h2>
          <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
            Digitized profiles, document compliance, and QR credentialing
          </p>
        </div>

        <button onClick={() => setShowCreateModal(true)} className="btn btn-primary" style={{ whiteSpace: 'nowrap' }}>
          <UserPlus size={16} />
          <span>Register New Worker</span>
        </button>
      </div>

      {/* 3-Tier Pipeline Banner for Vendors */}
      {user?.role === 'Vendor' && (
        <div style={{
          background: 'linear-gradient(135deg, rgba(99, 102, 241, 0.12), rgba(6, 182, 212, 0.08))',
          border: '1px solid rgba(99, 102, 241, 0.3)',
          borderRadius: '12px',
          padding: '12px 18px',
          marginBottom: '20px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: '12px'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div style={{ width: '36px', height: '36px', borderRadius: '50%', background: 'rgba(99, 102, 241, 0.25)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Shield size={20} color="#818cf8" />
            </div>
            <div>
              <strong style={{ color: '#fff', fontSize: '0.85rem' }}>ID Badge Issuance Pipeline</strong>
              <p style={{ margin: 0, fontSize: '0.75rem', color: '#cbd5e1' }}>
                1. Site Admin KYC (Aadhaar & Contract) ➔ 2. Safety (Medical & HSE) ➔ 3. Super Admin Gate ID Card Issuance
              </p>
            </div>
          </div>
          <span style={{ fontSize: '0.72rem', color: '#34d399', background: 'rgba(52, 211, 153, 0.12)', border: '1px solid rgba(52, 211, 153, 0.3)', padding: '4px 10px', borderRadius: '20px', fontWeight: 600 }}>
            ● Approved Workers get Instant Digital ID & QR Pass
          </span>
        </div>
      )}

      {/* Filter Bar */}
      <div className="glass-panel" style={{ padding: '16px', marginBottom: '20px', display: 'flex', gap: '14px', flexWrap: 'wrap', alignItems: 'center' }}>
        <div style={{ flex: 1, minWidth: '220px', position: 'relative' }}>
          <Search size={16} color="var(--text-muted)" style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)' }} />
          <input
            type="text"
            className="form-control"
            placeholder="Search by name, ID, mobile, designation..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            style={{ paddingLeft: '36px' }}
          />
        </div>

        {user?.role !== 'Vendor' && (
          <div style={{ width: '200px' }}>
            <select
              className="form-control"
              value={selectedVendor}
              onChange={(e) => setSelectedVendor(e.target.value)}
            >
              <option value="">All Contractors</option>
              {vendors.map((v) => (
                <option key={v.id} value={v.id}>{v.company_name}</option>
              ))}
            </select>
          </div>
        )}

        <div style={{ width: '160px' }}>
          <select
            className="form-control"
            value={selectedStatus}
            onChange={(e) => setSelectedStatus(e.target.value)}
          >
            <option value="">All Statuses</option>
            <option value="Active">Active</option>
            <option value="Pending Approval">Pending Approval</option>
            <option value="Deactivated">Deactivated</option>
          </select>
        </div>
      </div>

      {/* Table List */}
      <div className="glass-panel" style={{ padding: '1px' }}>
        <div className="table-container">
          <table className="custom-table">
            <thead>
              <tr>
                <th>Photo / ID</th>
                <th>Full Name</th>
                <th>Contractor / Vendor</th>
                <th>Designation & Skill</th>
                <th>Contact</th>
                <th>Compliance</th>
                <th>Presence</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {employees.length === 0 ? (
                <tr>
                  <td colSpan="8" style={{ textAlign: 'center', padding: '32px', color: 'var(--text-muted)' }}>
                    No workforce records found.
                  </td>
                </tr>
              ) : (
                employees.map((emp) => {
                  const today = new Date();
                  const isPvcExpired = emp.police_verification_expiry && new Date(emp.police_verification_expiry) < today;

                  return (
                    <tr key={emp.id}>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                          <img
                            src={emp.profile_photo || 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'}
                            alt="avatar"
                            style={{ width: '38px', height: '38px', borderRadius: '8px', objectFit: 'cover' }}
                          />
                          <div>
                            <span className="mono" style={{ fontSize: '0.75rem', color: '#a5b4fc', fontWeight: 600 }}>
                              {emp.employee_id}
                            </span>
                            <span style={{ fontSize: '0.65rem', color: 'var(--text-muted)', display: 'block' }}>
                              {emp.blood_group}
                            </span>
                          </div>
                        </div>
                      </td>
                      <td>
                        <span style={{ fontWeight: 700, color: '#fff' }}>{emp.full_name}</span>
                        <span style={{ fontSize: '0.7rem', color: 'var(--text-secondary)', display: 'block' }}>
                          Type: {emp.employee_type}
                        </span>
                      </td>
                      <td>
                        <span style={{ fontSize: '0.8rem', color: '#e2e8f0' }}>{emp.vendor_name}</span>
                      </td>
                      <td>
                        <span style={{ fontSize: '0.8rem', color: '#38bdf8', fontWeight: 600 }}>{emp.designation}</span>
                        <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)', display: 'block' }}>{emp.skill}</span>
                      </td>
                      <td>
                        <span style={{ fontSize: '0.8rem', color: '#cbd5e1' }}>{emp.mobile}</span>
                      </td>
                      <td>
                        {isPvcExpired ? (
                          <span className="badge badge-expired">PVC EXPIRED</span>
                        ) : (
                          <span className="badge badge-verified">VERIFIED</span>
                        )}
                      </td>
                      <td>
                        <span className={`badge ${emp.currently_inside ? 'badge-inside' : 'badge-absent'}`}>
                          {emp.currently_inside ? 'INSIDE' : 'OUTSIDE'}
                        </span>
                      </td>
                      <td>
                        <div style={{ display: 'flex', gap: '6px', alignItems: 'center' }}>
                          {emp.status === 'Active' ? (
                            <button
                              onClick={() => setSelectedEmployeeForCard(emp)}
                              className="btn btn-secondary"
                              title="Official Digital ID Card & Gate Pass"
                              style={{
                                padding: '5px 9px',
                                fontSize: '0.72rem',
                                color: '#818cf8',
                                borderColor: 'rgba(99, 102, 241, 0.4)',
                                background: 'rgba(99, 102, 241, 0.12)',
                                display: 'inline-flex',
                                alignItems: 'center',
                                gap: '4px'
                              }}
                            >
                              <CreditCard size={13} />
                              <span>ID Card</span>
                            </button>
                          ) : (
                            <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                              <div style={{ display: 'flex', gap: '4px', flexWrap: 'wrap' }}>
                                <span style={{
                                  fontSize: '0.65rem',
                                  color: emp.approvals?.admin?.status === 'Approved' ? '#34d399' : '#fbbf24',
                                  background: emp.approvals?.admin?.status === 'Approved' ? 'rgba(52, 211, 153, 0.1)' : 'rgba(245, 158, 11, 0.1)',
                                  border: `1px solid ${emp.approvals?.admin?.status === 'Approved' ? 'rgba(52, 211, 153, 0.3)' : 'rgba(245, 158, 11, 0.3)'}`,
                                  padding: '2px 5px',
                                  borderRadius: '4px'
                                }}>
                                  KYC: {emp.approvals?.admin?.status || 'Pending'}
                                </span>
                                <span style={{
                                  fontSize: '0.65rem',
                                  color: emp.approvals?.safety?.status === 'Approved' ? '#34d399' : '#fbbf24',
                                  background: emp.approvals?.safety?.status === 'Approved' ? 'rgba(52, 211, 153, 0.1)' : 'rgba(245, 158, 11, 0.1)',
                                  border: `1px solid ${emp.approvals?.safety?.status === 'Approved' ? 'rgba(52, 211, 153, 0.3)' : 'rgba(245, 158, 11, 0.3)'}`,
                                  padding: '2px 5px',
                                  borderRadius: '4px'
                                }}>
                                  HSE: {emp.approvals?.safety?.status || 'Pending'}
                                </span>
                              </div>
                              {user?.role !== 'Vendor' && (
                                <div style={{ display: 'flex', gap: '4px' }}>
                                  {(user?.role === 'Admin' || user?.role === 'Super Admin') && emp.approvals?.admin?.status !== 'Approved' && (
                                    <button
                                      onClick={() => handleApproveStage(emp.id, 'admin', 'Approved')}
                                      className="btn btn-primary"
                                      style={{ padding: '2px 6px', fontSize: '0.65rem', background: '#059669', borderColor: '#059669' }}
                                      title="Approve Site Admin KYC"
                                    >
                                      ✓ KYC
                                    </button>
                                  )}
                                  {(user?.role === 'Safety Officer' || user?.role === 'Admin' || user?.role === 'Super Admin') && emp.approvals?.safety?.status !== 'Approved' && (
                                    <button
                                      onClick={() => handleApproveStage(emp.id, 'safety', 'Approved')}
                                      className="btn btn-primary"
                                      style={{ padding: '2px 6px', fontSize: '0.65rem', background: '#0891b2', borderColor: '#0891b2' }}
                                      title="Approve Medical HSE"
                                    >
                                      ✓ HSE
                                    </button>
                                  )}
                                </div>
                              )}
                            </div>
                          )}
                          <button
                            onClick={() => open360View(emp.id)}
                            className="btn btn-secondary"
                            title="360° Profile"
                            style={{ padding: '6px 8px', fontSize: '0.7rem' }}
                          >
                            <Eye size={14} />
                          </button>
                          {user?.role !== 'Vendor' && (
                            <button
                              onClick={() => handleDeactivate(emp.id)}
                              className="btn btn-secondary"
                              title="Deactivate Access"
                              style={{ padding: '6px 8px', fontSize: '0.7rem', color: '#f43f5e' }}
                            >
                              <Trash2 size={14} />
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Register Employee Modal */}
      {showCreateModal && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '720px' }}>
            <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ fontSize: '1.05rem', fontWeight: 700, color: '#fff' }}>Register New Workforce / Contractor</h3>
              <button onClick={() => setShowCreateModal(false)} style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}>✕</button>
            </div>

            <form onSubmit={handleCreateEmployee} style={{ padding: '20px' }}>
              <div className="grid-responsive-1-1" style={{ marginBottom: '14px' }}>
                {/* 1. MANUAL PROFILE PHOTO UPLOAD */}
                <div className="form-group" style={{ gridColumn: '1 / -1', background: 'rgba(255,255,255,0.03)', padding: '12px', borderRadius: '10px', border: '1px solid rgba(255,255,255,0.08)' }}>
                  <label className="form-label" style={{ color: '#38bdf8', fontWeight: 700 }}>1. Worker Profile Photo (Choose File / फ़ोटो चुनें) *</label>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '14px', flexWrap: 'wrap' }}>
                    <img
                      src={formData.profile_photo || 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'}
                      alt="preview"
                      style={{ width: '56px', height: '56px', borderRadius: '10px', objectFit: 'cover', border: '2px solid #06b6d4' }}
                    />
                    <div style={{ flex: 1, minWidth: '220px' }}>
                      <input
                        type="file"
                        accept="image/*"
                        onChange={(e) => handleManualUpload('profile_photo', e)}
                        className="form-control"
                        style={{ padding: '6px' }}
                      />
                      <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)', display: 'block', marginTop: '3px' }}>
                        {uploadingField === 'profile_photo' ? '⏳ Uploading photo...' : 'Select custom portrait or capture camera photo'}
                      </span>
                    </div>
                  </div>
                </div>

                <div className="form-group">
                  <label className="form-label">Full Name *</label>
                  <input
                    type="text"
                    required
                    className="form-control"
                    placeholder="e.g. Rajesh Sharma"
                    value={formData.full_name}
                    onChange={(e) => setFormData({ ...formData, full_name: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Father / Guardian Name</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Suresh Sharma"
                    value={formData.father_name}
                    onChange={(e) => setFormData({ ...formData, father_name: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Primary Mobile *</label>
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
                  <label className="form-label">Blood Group</label>
                  <select
                    className="form-control"
                    value={formData.blood_group}
                    onChange={(e) => setFormData({ ...formData, blood_group: e.target.value })}
                  >
                    <option value="A+">A+</option>
                    <option value="A-">A-</option>
                    <option value="B+">B+</option>
                    <option value="B-">B-</option>
                    <option value="O+">O+</option>
                    <option value="O-">O-</option>
                    <option value="AB+">AB+</option>
                    <option value="AB-">AB-</option>
                  </select>
                </div>

                <div className="form-group">
                  <label className="form-label">Designation</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Welder, Scaffolder, Electrician"
                    value={formData.designation}
                    onChange={(e) => setFormData({ ...formData, designation: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Contractor / Vendor</label>
                  <select
                    className="form-control"
                    value={formData.vendor_id}
                    onChange={(e) => setFormData({ ...formData, vendor_id: e.target.value })}
                  >
                    <option value="">Direct Hire</option>
                    {vendors.map((v) => (
                      <option key={v.id} value={v.id}>{v.company_name}</option>
                    ))}
                  </select>
                </div>

                {/* 2. MANUAL AADHAAR CARD UPLOAD */}
                <div className="form-group">
                  <label className="form-label">Aadhaar Card No. (12 Digits)</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="XXXX XXXX XXXX"
                    value={formData.aadhaar_no}
                    onChange={(e) => setFormData({ ...formData, aadhaar_no: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label" style={{ color: '#06b6d4', fontWeight: 600 }}>2. Aadhaar Document Upload (Choose File / फ़ाइल चुनें) *</label>
                  <input
                    type="file"
                    accept=".pdf,image/*"
                    onChange={(e) => handleManualUpload('aadhaar_doc', e)}
                    className="form-control"
                    style={{ padding: '6px' }}
                  />
                  {formData.aadhaar_doc ? (
                    <span style={{ fontSize: '0.72rem', color: '#10b981', display: 'block', marginTop: '3px' }}>
                      ✓ Attached: {formData.aadhaar_doc}
                    </span>
                  ) : (
                    <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)', display: 'block', marginTop: '3px' }}>
                      {uploadingField === 'aadhaar_doc' ? '⏳ Uploading Aadhaar...' : 'Upload front & back scanned copy'}
                    </span>
                  )}
                </div>

                {/* 3. MANUAL MEDICAL FITNESS CERTIFICATE UPLOAD */}
                <div className="form-group">
                  <label className="form-label">Medical Fitness Scope</label>
                  <select
                    className="form-control"
                    value={formData.medical_cert}
                    onChange={(e) => setFormData({ ...formData, medical_cert: e.target.value })}
                  >
                    <option value="Fit for Construction & Height Work (Grade A)">Fit for Height Work & Scaffolding (Grade A)</option>
                    <option value="Fit for Heavy Rigging & Equipment Operator">Fit for Heavy Rigging & Operator</option>
                    <option value="Fit for Confined Space & Hot Work">Fit for Confined Space & Hot Work</option>
                    <option value="Fit for General Labour & Civil Works">Fit for General Labour & Civil Works</option>
                  </select>
                </div>

                <div className="form-group">
                  <label className="form-label" style={{ color: '#10b981', fontWeight: 600 }}>3. Medical Fitness Certificate (Choose File / फ़ाइल चुनें) *</label>
                  <input
                    type="file"
                    accept=".pdf,image/*"
                    onChange={(e) => handleManualUpload('medical_doc', e)}
                    className="form-control"
                    style={{ padding: '6px' }}
                  />
                  {formData.medical_doc ? (
                    <span style={{ fontSize: '0.72rem', color: '#10b981', display: 'block', marginTop: '3px' }}>
                      ✓ Attached: {formData.medical_doc}
                    </span>
                  ) : (
                    <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)', display: 'block', marginTop: '3px' }}>
                      {uploadingField === 'medical_doc' ? '⏳ Uploading Medical...' : 'Upload occupational health fitness certificate'}
                    </span>
                  )}
                </div>

                <div className="form-group">
                  <label className="form-label">Police Verification Expiry</label>
                  <input
                    type="date"
                    className="form-control"
                    value={formData.police_verification_expiry}
                    onChange={(e) => setFormData({ ...formData, police_verification_expiry: e.target.value })}
                  />
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '16px' }}>
                <button type="button" onClick={() => setShowCreateModal(false)} className="btn btn-secondary">
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" style={{ background: '#06b6d4', borderColor: '#06b6d4' }}>
                  Submit for Dual Admin & Safety Clearance
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* 360 Degree Profile Drawer */}
      {viewEmployeeDrawer && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '680px' }}>
            <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ fontSize: '1.05rem', fontWeight: 700, color: '#fff' }}>
                360° Workforce Profile: {viewEmployeeDrawer.full_name}
              </h3>
              <button onClick={() => setViewEmployeeDrawer(null)} style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}>✕</button>
            </div>

            <div style={{ padding: '20px' }}>
              <div style={{ display: 'flex', gap: '16px', marginBottom: '16px', alignItems: 'center' }}>
                <img
                  src={viewEmployeeDrawer.profile_photo || 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'}
                  alt="emp"
                  style={{ width: '70px', height: '70px', borderRadius: '12px', objectFit: 'cover', border: '2px solid #06b6d4' }}
                />
                <div>
                  <h4 style={{ fontSize: '1.1rem', fontWeight: 800, color: '#fff' }}>{viewEmployeeDrawer.full_name}</h4>
                  <p style={{ fontSize: '0.8rem', color: '#38bdf8', fontWeight: 600 }}>{viewEmployeeDrawer.designation} • {viewEmployeeDrawer.employee_id}</p>
                  <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Vendor: {viewEmployeeDrawer.vendor_name}</p>
                </div>
              </div>

              {/* DUAL APPROVAL PIPELINE BANNER */}
              <div style={{ background: 'rgba(99, 102, 241, 0.08)', border: '1px solid rgba(99, 102, 241, 0.3)', borderRadius: '10px', padding: '14px', marginBottom: '16px' }}>
                <strong style={{ fontSize: '0.85rem', color: '#fff', display: 'block', marginBottom: '8px' }}>
                  Multi-Tier Clearance Gate:
                </strong>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px', paddingBottom: '8px', borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
                  <div>
                    <span style={{ fontSize: '0.82rem', color: '#cbd5e1', fontWeight: 600 }}>1. Site Admin KYC (Aadhaar & Contract)</span>
                    <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)', display: 'block' }}>Doc: {viewEmployeeDrawer.aadhaar_doc || 'aadhaar_card_front_back.pdf'}</span>
                  </div>
                  {viewEmployeeDrawer.approvals?.admin?.status === 'Approved' ? (
                    <span style={{ color: '#34d399', fontWeight: 700, fontSize: '0.8rem' }}>✓ Approved by {viewEmployeeDrawer.approvals.admin.approved_by || 'Admin'}</span>
                  ) : (
                    (user?.role === 'Admin' || user?.role === 'Super Admin') ? (
                      <div style={{ display: 'flex', gap: '6px' }}>
                        <button onClick={() => handleApproveStage(viewEmployeeDrawer.id, 'admin', 'Approved')} className="btn btn-primary" style={{ padding: '4px 10px', fontSize: '0.72rem', background: '#059669', borderColor: '#059669' }}>Approve KYC</button>
                        <button onClick={() => handleApproveStage(viewEmployeeDrawer.id, 'admin', 'Rejected')} className="btn btn-secondary" style={{ padding: '4px 8px', fontSize: '0.72rem', color: '#f43f5e' }}>Reject</button>
                      </div>
                    ) : <span style={{ color: '#fbbf24', fontSize: '0.78rem' }}>⏳ Awaiting Site Admin</span>
                  )}
                </div>

                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <span style={{ fontSize: '0.82rem', color: '#cbd5e1', fontWeight: 600 }}>2. Safety Officer (Medical & HSE Clearance)</span>
                    <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)', display: 'block' }}>Doc: {viewEmployeeDrawer.medical_doc || 'medical_fitness_cert.pdf'}</span>
                  </div>
                  {viewEmployeeDrawer.approvals?.safety?.status === 'Approved' ? (
                    <span style={{ color: '#34d399', fontWeight: 700, fontSize: '0.8rem' }}>✓ Approved by {viewEmployeeDrawer.approvals.safety.approved_by || 'Safety Officer'}</span>
                  ) : (
                    (user?.role === 'Safety Officer' || user?.role === 'Admin' || user?.role === 'Super Admin') ? (
                      <div style={{ display: 'flex', gap: '6px' }}>
                        <button onClick={() => handleApproveStage(viewEmployeeDrawer.id, 'safety', 'Approved')} className="btn btn-primary" style={{ padding: '4px 10px', fontSize: '0.72rem', background: '#0891b2', borderColor: '#0891b2' }}>Approve HSE</button>
                        <button onClick={() => handleApproveStage(viewEmployeeDrawer.id, 'safety', 'Rejected')} className="btn btn-secondary" style={{ padding: '4px 8px', fontSize: '0.72rem', color: '#f43f5e' }}>Reject</button>
                      </div>
                    ) : <span style={{ color: '#fbbf24', fontSize: '0.78rem' }}>⏳ Awaiting Safety Officer</span>
                  )}
                </div>
              </div>

              <div className="grid-responsive-1-1" style={{ gap: '10px', fontSize: '0.8rem', background: 'rgba(0,0,0,0.2)', padding: '12px', borderRadius: 'var(--radius-md)', marginBottom: '16px' }}>
                <div><strong>Mobile:</strong> {viewEmployeeDrawer.mobile}</div>
                <div><strong>Blood Group:</strong> <span style={{ color: '#f43f5e' }}>{viewEmployeeDrawer.blood_group}</span></div>
                <div><strong>Aadhaar Number:</strong> {viewEmployeeDrawer.aadhaar_no || 'N/A'}</div>
                <div><strong>Aadhaar Doc File:</strong> <span style={{ color: '#38bdf8' }}>{viewEmployeeDrawer.aadhaar_doc || 'aadhaar_card_front_back.pdf'}</span></div>
                <div><strong>Medical Fitness:</strong> {viewEmployeeDrawer.medical_cert}</div>
                <div><strong>Medical Doc File:</strong> <span style={{ color: '#10b981' }}>{viewEmployeeDrawer.medical_doc || 'medical_fitness_cert.pdf'}</span></div>
                <div><strong>Police Verification:</strong> {viewEmployeeDrawer.police_verification_expiry}</div>
                <div><strong>Shift:</strong> {viewEmployeeDrawer.shift_name}</div>
              </div>

              <h5 style={{ fontSize: '0.85rem', fontWeight: 700, color: '#fff', marginBottom: '8px' }}>Recent Gate History</h5>
              <div className="table-container" style={{ maxHeight: '160px', overflowY: 'auto' }}>
                <table className="custom-table" style={{ fontSize: '0.75rem' }}>
                  <thead>
                    <tr>
                      <th>Time</th>
                      <th>Movement</th>
                      <th>Gate</th>
                      <th>Officer</th>
                    </tr>
                  </thead>
                  <tbody>
                    {viewEmployeeDrawer.gate_history?.map((g) => (
                      <tr key={g.id}>
                        <td>{new Date(g.timestamp).toLocaleString()}</td>
                        <td><span className={`badge ${g.movement_type === 'ENTRY' ? 'badge-active' : 'badge-denied'}`}>{g.movement_type}</span></td>
                        <td>{g.gate_name}</td>
                        <td>{g.security_user_name}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Printable ID Card Modal */}
      <DigitalIdCard
        employee={selectedEmployeeForCard}
        isOpen={!!selectedEmployeeForCard}
        onClose={() => setSelectedEmployeeForCard(null)}
      />
    </div>
  );
};
