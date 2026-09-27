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
    medical_cert: 'Fit for Construction & Height Work',
    medical_validity: '2027-12-31',
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
    <div style={{ padding: '28px', maxWidth: '1440px', margin: '0 auto' }}>
      {/* Top Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '20px' }}>
        <div>
          <h2 style={{ fontSize: '1.3rem', fontWeight: 800, color: '#fff' }}>
            {user?.role === 'Vendor' ? 'Contractor Workforce Portal' : 'Employee & Contractor Master'}
          </h2>
          <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
            Digitized profiles, document compliance, and QR credentialing
          </p>
        </div>

        <button onClick={() => setShowCreateModal(true)} className="btn btn-primary">
          <UserPlus size={16} />
          <span>Register New Worker</span>
        </button>
      </div>

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
                        <div style={{ display: 'flex', gap: '6px' }}>
                          <button
                            onClick={() => setSelectedEmployeeForCard(emp)}
                            className="btn btn-secondary"
                            title="Digital ID Card"
                            style={{ padding: '6px 8px', fontSize: '0.7rem' }}
                          >
                            <CreditCard size={14} />
                          </button>
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
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px', marginBottom: '14px' }}>
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

                <div className="form-group">
                  <label className="form-label">Aadhaar Card No.</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="XXXX XXXX XXXX"
                    value={formData.aadhaar_no}
                    onChange={(e) => setFormData({ ...formData, aadhaar_no: e.target.value })}
                  />
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
                <button type="submit" className="btn btn-primary">
                  Generate ID & Save
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
                  style={{ width: '70px', height: '70px', borderRadius: '12px', objectFit: 'cover' }}
                />
                <div>
                  <h4 style={{ fontSize: '1.1rem', fontWeight: 800, color: '#fff' }}>{viewEmployeeDrawer.full_name}</h4>
                  <p style={{ fontSize: '0.8rem', color: '#38bdf8', fontWeight: 600 }}>{viewEmployeeDrawer.designation} • {viewEmployeeDrawer.employee_id}</p>
                  <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Vendor: {viewEmployeeDrawer.vendor_name}</p>
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', fontSize: '0.8rem', background: 'rgba(0,0,0,0.2)', padding: '12px', borderRadius: 'var(--radius-md)', marginBottom: '16px' }}>
                <div><strong>Mobile:</strong> {viewEmployeeDrawer.mobile}</div>
                <div><strong>Blood Group:</strong> <span style={{ color: '#f43f5e' }}>{viewEmployeeDrawer.blood_group}</span></div>
                <div><strong>Aadhaar:</strong> {viewEmployeeDrawer.aadhaar_no}</div>
                <div><strong>Medical Status:</strong> {viewEmployeeDrawer.medical_cert}</div>
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
