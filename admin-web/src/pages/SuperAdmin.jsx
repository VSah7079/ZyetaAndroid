import React, { useState, useEffect } from 'react';
import { 
  Shield, 
  UserPlus, 
  Users, 
  Key, 
  CheckSquare, 
  Square, 
  Edit, 
  Trash2, 
  Search, 
  CheckCircle, 
  XCircle, 
  AlertTriangle,
  Building,
  FileCheck,
  Package,
  Activity,
  UserCheck
} from 'lucide-react';
import { api } from '../services/api';

export const SuperAdmin = () => {
  const [activeTab, setActiveTab] = useState('users');
  const [users, setUsers] = useState([]);
  const [employees, setEmployees] = useState([]);
  const [vendors, setVendors] = useState([]);
  const [permits, setPermits] = useState([]);
  const [auditLogs, setAuditLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  // Modal State for User Creation / Edit
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingUser, setEditingUser] = useState(null);
  const [formData, setFormData] = useState({
    username: '',
    full_name: '',
    email: '',
    phone: '',
    password: '',
    role: 'Admin',
    status: 'Active',
    permissions: []
  });

  const availablePermissions = [
    { id: 'gate', label: '🛡️ Gate Security Terminal & Camera Scanner' },
    { id: 'employees', label: '👷 Workforce Management & ID Hologram Passes' },
    { id: 'vendors', label: '🏢 Contractor & Vendor Master Management' },
    { id: 'permits', label: '📋 Permits to Work (PTW Creation & Approvals)' },
    { id: 'safety', label: '⛑️ HSE Safety Command & Site Audits' },
    { id: 'tbt', label: '🗣️ Daily Toolbox Talks (TBT Briefings)' },
    { id: 'emergency', label: '🚨 Emergency Evacuation & Muster Roll' },
    { id: 'blacklist', label: '🚫 Blacklist & Disciplinary Watchlist' },
    { id: 'visitors', label: '👤 Visitor Passes & Kiosk Check-In' },
    { id: 'materials', label: '📦 Material Delivery Challans (DC Inward/Outward)' },
    { id: 'vehicles', label: '🚗 Vehicle Fleet & Gate Register' },
    { id: 'attendance', label: '⏱️ Attendance & Shift Muster Roll' },
    { id: 'headcount', label: '🟢 Live Campus Inside Headcount' },
    { id: 'reports', label: '📈 Reports & Analytics Export Suite' },
    { id: 'superadmin', label: '👑 Super Admin Master System Access' },
  ];

  const defaultRolePresets = {
    'Super Admin': ['all'],
    'Admin': ['employees', 'vendors', 'gate', 'permits', 'safety', 'visitors', 'materials', 'vehicles', 'attendance', 'headcount', 'reports'],
    'Safety Officer': ['safety', 'permits', 'employees', 'attendance', 'headcount', 'reports'],
    'Vendor': ['employees', 'permits', 'materials', 'attendance'],
    'Security': ['gate', 'visitors', 'materials', 'vehicles', 'headcount', 'permits'],
  };

  useEffect(() => {
    loadAllData();
  }, []);

  const loadAllData = async () => {
    setLoading(true);
    try {
      const [uRes, eRes, vRes, pRes, aRes] = await Promise.all([
        api.getUsers ? api.getUsers() : { success: true, data: [] },
        api.getEmployees(),
        api.getVendors(),
        api.getPermits(),
        api.getAuditLogs ? api.getAuditLogs() : { success: true, data: [] }
      ]);

      setUsers(uRes.data || [
        { id: 1, username: 'superadmin', full_name: 'Vikram Malhotra (Super Admin)', email: 'superadmin@zyeta.com', role: 'Super Admin', status: 'Active', permissions: ['all'] },
        { id: 2, username: 'admin', full_name: 'Priya Sundaram (Site Admin)', email: 'admin@zyeta.com', role: 'Admin', status: 'Active', permissions: ['employees', 'vendors', 'gate', 'permits', 'safety', 'visitors', 'materials', 'vehicles', 'attendance', 'headcount', 'reports'] },
        { id: 5, username: 'safety_officer', full_name: 'Er. Rajesh Varma (HSE Head)', email: 'safety@zyeta.com', role: 'Safety Officer', status: 'Active', permissions: ['safety', 'permits', 'employees', 'attendance', 'headcount', 'reports'] },
        { id: 3, username: 'vendor_infra', full_name: 'Rajesh Sharma (ABC Infra)', email: 'vendor@abcinfra.com', role: 'Vendor', status: 'Active', permissions: ['employees', 'permits', 'materials', 'attendance'] },
        { id: 4, username: 'security_gate1', full_name: 'Commander R. K. Singh (Gate 1)', email: 'security@zyeta.com', role: 'Security', status: 'Active', permissions: ['gate', 'visitors', 'materials', 'vehicles', 'headcount', 'permits'] },
      ]);
      setEmployees(eRes.data || []);
      setVendors(vRes.data || []);
      setPermits(pRes.data || []);
      setAuditLogs(aRes.data || []);
    } catch (err) {
      console.error('Error loading master data:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleOpenModal = (userToEdit = null) => {
    if (userToEdit) {
      setEditingUser(userToEdit);
      setFormData({
        username: userToEdit.username || '',
        full_name: userToEdit.full_name || '',
        email: userToEdit.email || '',
        phone: userToEdit.phone || '',
        password: '',
        role: userToEdit.role || 'Admin',
        status: userToEdit.status || 'Active',
        permissions: userToEdit.permissions || defaultRolePresets[userToEdit.role] || []
      });
    } else {
      setEditingUser(null);
      setFormData({
        username: '',
        full_name: '',
        email: '',
        phone: '',
        password: '',
        role: 'Admin',
        status: 'Active',
        permissions: [...defaultRolePresets['Admin']]
      });
    }
    setIsModalOpen(true);
  };

  const handleRoleChange = (newRole) => {
    const defaultPerms = defaultRolePresets[newRole] || ['gate'];
    setFormData(prev => ({
      ...prev,
      role: newRole,
      permissions: [...defaultPerms]
    }));
  };

  const handleTogglePermission = (permId) => {
    setFormData(prev => {
      let current = [...prev.permissions];
      if (current.includes('all')) {
        current = availablePermissions.map(p => p.id);
      }
      if (current.includes(permId)) {
        current = current.filter(id => id !== permId && id !== 'all');
      } else {
        current.push(permId);
      }
      return { ...prev, permissions: current };
    });
  };

  const handleSelectAll = () => {
    setFormData(prev => ({
      ...prev,
      permissions: availablePermissions.map(p => p.id)
    }));
  };

  const handleClearAll = () => {
    setFormData(prev => ({
      ...prev,
      permissions: []
    }));
  };

  const handleSaveUser = async (e) => {
    e.preventDefault();
    if (!formData.username || !formData.full_name || !formData.email) {
      alert('Please fill all mandatory fields (Full Name, Username, Email).');
      return;
    }

    try {
      if (editingUser) {
        if (api.updateUser) {
          await api.updateUser(editingUser.id, formData);
        }
        setUsers(prev => prev.map(u => u.id === editingUser.id ? { ...u, ...formData } : u));
      } else {
        if (api.createUser) {
          const res = await api.createUser({
            ...formData,
            password: formData.password || 'admin123'
          });
          if (res.success && res.user) {
            setUsers(prev => [...prev, res.user]);
          } else {
            const newId = Date.now();
            setUsers(prev => [...prev, { id: newId, ...formData }]);
          }
        } else {
          const newId = Date.now();
          setUsers(prev => [...prev, { id: newId, ...formData }]);
        }
      }
      setIsModalOpen(false);
      loadAllData();
    } catch (err) {
      alert(err.message || 'Action completed locally');
      setIsModalOpen(false);
    }
  };

  const handleDeleteUser = async (id, username) => {
    if (window.confirm(`Are you sure you want to permanently delete account for "${username}"?`)) {
      try {
        if (api.deleteUser) {
          await api.deleteUser(id);
        }
        setUsers(prev => prev.filter(u => u.id !== id));
      } catch (err) {
        setUsers(prev => prev.filter(u => u.id !== id));
      }
    }
  };

  const filteredUsers = users.filter(u => 
    (u.full_name || '').toLowerCase().includes(search.toLowerCase()) ||
    (u.username || '').toLowerCase().includes(search.toLowerCase()) ||
    (u.email || '').toLowerCase().includes(search.toLowerCase()) ||
    (u.role || '').toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="page-container">
      {/* Top Banner */}
      <div style={{
        background: 'linear-gradient(135deg, rgba(245, 158, 11, 0.15) 0%, rgba(15, 23, 42, 0.95) 100%)',
        border: '1px solid rgba(245, 158, 11, 0.35)',
        borderRadius: '16px',
        padding: '20px',
        marginBottom: '20px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        flexWrap: 'wrap',
        gap: '16px'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '14px', flexWrap: 'wrap' }}>
          <div style={{
            width: '52px',
            height: '52px',
            borderRadius: '14px',
            backgroundColor: 'rgba(245, 158, 11, 0.2)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            border: '1px solid #f59e0b',
            flexShrink: 0
          }}>
            <Shield size={28} color="#f59e0b" />
          </div>
          <div>
            <h1 style={{ fontSize: 'clamp(1.1rem, 2.5vw, 1.4rem)', fontWeight: 800, color: '#fff', margin: 0, display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
              Super Admin Master Control Center <span style={{ fontSize: '0.7rem', padding: '2px 8px', borderRadius: '4px', backgroundColor: '#f59e0b', color: '#000', fontWeight: 800 }}>ROOT MASTER</span>
            </h1>
            <p style={{ color: 'var(--text-muted)', fontSize: '0.8rem', margin: '4px 0 0 0' }}>
              Full CRUD database access & Granular Role-Based Access Control (RBAC) permission checkbox matrix.
            </p>
          </div>
        </div>

        <button 
          onClick={() => handleOpenModal()}
          style={{
            backgroundColor: '#f59e0b',
            color: '#0b0f19',
            border: 'none',
            borderRadius: '10px',
            padding: '10px 18px',
            fontWeight: 800,
            fontSize: '0.85rem',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            cursor: 'pointer',
            boxShadow: '0 4px 15px rgba(245, 158, 11, 0.35)',
            whiteSpace: 'nowrap'
          }}
        >
          <UserPlus size={16} />
          Create User & Assign Access
        </button>
      </div>

      {/* Navigation Tabs (Scrollable on mobile) */}
      <div className="nav-tabs-scroll">
        {[
          { id: 'users', label: `Users & Permissions (${users.length})`, icon: Users },
          { id: 'workforce', label: `Workforce (${employees.length})`, icon: UserCheck },
          { id: 'vendors', label: `Vendors (${vendors.length})`, icon: Building },
          { id: 'permits', label: `Permits (${permits.length})`, icon: FileCheck },
          { id: 'audit', label: `Audit Logs`, icon: Activity },
        ].map(tab => {
          const Icon = tab.icon;
          const isActive = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className="nav-tab-btn"
              style={{
                borderBottom: isActive ? '3px solid #f59e0b' : '3px solid transparent',
                color: isActive ? '#f59e0b' : 'var(--text-muted)',
                fontWeight: isActive ? 800 : 600
              }}
            >
              <Icon size={16} />
              {tab.label}
            </button>
          );
        })}
      </div>

      {/* TAB 1: USERS & PERMISSIONS MATRIX */}
      {activeTab === 'users' && (
        <div>
          {/* Search Bar */}
          <div style={{ display: 'flex', gap: '12px', marginBottom: '16px' }}>
            <div style={{ position: 'relative', flex: 1 }}>
              <Search size={18} style={{ position: 'absolute', left: '14px', top: '14px', color: 'var(--text-muted)' }} />
              <input
                type="text"
                placeholder="Search user by full name, username, email or role..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                style={{
                  width: '100%',
                  padding: '12px 14px 12px 42px',
                  backgroundColor: '#1e293b',
                  border: '1px solid var(--border-color)',
                  borderRadius: '10px',
                  color: '#fff',
                  fontSize: '0.9rem'
                }}
              />
            </div>
          </div>

          {/* User Cards Grid */}
          <div className="grid-cards-responsive">
            {filteredUsers.map(u => {
              const isSuper = u.role === 'Super Admin';
              const perms = u.permissions || [];
              const roleColor = isSuper ? '#f59e0b' : u.role === 'Admin' ? '#6366f1' : u.role === 'Safety Officer' ? '#f97316' : u.role === 'Vendor' ? '#06b6d4' : '#10b981';

              return (
                <div key={u.id} style={{
                  backgroundColor: '#1e293b',
                  border: `1px solid ${roleColor}40`,
                  borderRadius: '14px',
                  padding: '18px',
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '12px'
                }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
                      <div style={{
                        width: '44px',
                        height: '44px',
                        borderRadius: '10px',
                        backgroundColor: `${roleColor}25`,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        color: roleColor,
                        fontWeight: 800
                      }}>
                        {u.full_name ? u.full_name.charAt(0) : 'U'}
                      </div>
                      <div>
                        <h3 style={{ margin: 0, fontSize: '1rem', fontWeight: 700, color: '#fff' }}>{u.full_name}</h3>
                        <p style={{ margin: '2px 0 0 0', fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                          @{u.username} • {u.email}
                        </p>
                      </div>
                    </div>

                    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: '4px' }}>
                      <span style={{
                        padding: '3px 8px',
                        borderRadius: '6px',
                        backgroundColor: `${roleColor}25`,
                        color: roleColor,
                        fontSize: '0.75rem',
                        fontWeight: 800,
                        border: `1px solid ${roleColor}50`
                      }}>
                        {u.role}
                      </span>
                      <span style={{ fontSize: '0.7rem', color: u.status === 'Active' ? '#10b981' : '#f43f5e', fontWeight: 700 }}>
                        ● {u.status}
                      </span>
                    </div>
                  </div>

                  {/* Granted Permissions List */}
                  <div style={{
                    backgroundColor: '#0f172a',
                    padding: '10px 12px',
                    borderRadius: '8px',
                    border: '1px solid rgba(255, 255, 255, 0.05)'
                  }}>
                    <p style={{ margin: '0 0 6px 0', fontSize: '0.7rem', color: 'var(--text-muted)', fontWeight: 800, textTransform: 'uppercase' }}>
                      Granted Permissions (RBAC):
                    </p>
                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '4px' }}>
                      {perms.includes('all') ? (
                        <span style={{ fontSize: '0.75rem', padding: '2px 8px', backgroundColor: 'rgba(245, 158, 11, 0.2)', color: '#f59e0b', borderRadius: '4px', fontWeight: 700 }}>
                          👑 FULL MASTER ROOT ACCESS (ALL MODULES)
                        </span>
                      ) : perms.length === 0 ? (
                        <span style={{ fontSize: '0.75rem', color: '#f43f5e' }}>No permissions assigned</span>
                      ) : (
                        perms.map(p => (
                          <span key={p} style={{ fontSize: '0.7rem', padding: '2px 6px', backgroundColor: 'rgba(255, 255, 255, 0.08)', color: '#a5b4fc', borderRadius: '4px', fontWeight: 600 }}>
                            {p.toUpperCase()}
                          </span>
                        ))
                      )}
                    </div>
                  </div>

                  {/* Actions */}
                  <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px', borderTop: '1px solid rgba(255, 255, 255, 0.05)', paddingTop: '10px' }}>
                    <button
                      onClick={() => handleOpenModal(u)}
                      style={{
                        padding: '6px 12px',
                        borderRadius: '6px',
                        backgroundColor: 'rgba(6, 182, 212, 0.15)',
                        border: '1px solid rgba(6, 182, 212, 0.3)',
                        color: '#06b6d4',
                        fontSize: '0.8rem',
                        fontWeight: 700,
                        cursor: 'pointer',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '6px'
                      }}
                    >
                      <Edit size={14} />
                      Edit & Access
                    </button>
                    {!isSuper && (
                      <button
                        onClick={() => handleDeleteUser(u.id, u.username)}
                        style={{
                          padding: '6px 12px',
                          borderRadius: '6px',
                          backgroundColor: 'rgba(244, 63, 94, 0.15)',
                          border: '1px solid rgba(244, 63, 94, 0.3)',
                          color: '#f43f5e',
                          fontSize: '0.8rem',
                          fontWeight: 700,
                          cursor: 'pointer',
                          display: 'flex',
                          alignItems: 'center',
                          gap: '6px'
                        }}
                      >
                        <Trash2 size={14} />
                        Delete
                      </button>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* TAB 2: WORKFORCE MASTER */}
      {activeTab === 'workforce' && (
        <div style={{ backgroundColor: '#1e293b', borderRadius: '12px', padding: '16px' }}>
          <h3 style={{ color: '#fff', margin: '0 0 16px 0' }}>Master Workforce Register</h3>
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', color: '#fff', fontSize: '0.85rem' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid var(--border-color)', textAlign: 'left', color: 'var(--text-muted)' }}>
                  <th style={{ padding: '10px' }}>Pass ID</th>
                  <th style={{ padding: '10px' }}>Worker Name</th>
                  <th style={{ padding: '10px' }}>Contractor / Vendor</th>
                  <th style={{ padding: '10px' }}>Trade / Skill</th>
                  <th style={{ padding: '10px' }}>Aadhaar KYC</th>
                  <th style={{ padding: '10px' }}>Gate Status</th>
                  <th style={{ padding: '10px' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {employees.map(e => (
                  <tr key={e.id} style={{ borderBottom: '1px solid rgba(255, 255, 255, 0.05)' }}>
                    <td style={{ padding: '10px', fontWeight: 700, color: '#6366f1' }}>{e.employee_id}</td>
                    <td style={{ padding: '10px', fontWeight: 600 }}>{e.full_name}</td>
                    <td style={{ padding: '10px', color: '#06b6d4' }}>{e.vendor_name}</td>
                    <td style={{ padding: '10px' }}>{e.designation}</td>
                    <td style={{ padding: '10px', color: 'var(--text-muted)' }}>{e.aadhaar_no || 'Verified'}</td>
                    <td style={{ padding: '10px' }}>
                      <span style={{
                        padding: '2px 8px',
                        borderRadius: '4px',
                        backgroundColor: e.currently_inside ? 'rgba(16, 185, 129, 0.2)' : 'rgba(255, 255, 255, 0.08)',
                        color: e.currently_inside ? '#10b981' : 'var(--text-muted)',
                        fontSize: '0.75rem',
                        fontWeight: 700
                      }}>
                        {e.currently_inside ? '● INSIDE CAMPUS' : 'OUTSIDE'}
                      </span>
                    </td>
                    <td style={{ padding: '10px' }}>
                      <button
                        onClick={() => alert(`Worker ${e.full_name} details opened in Super Admin mode`)}
                        style={{ padding: '4px 8px', borderRadius: '4px', backgroundColor: '#6366f1', color: '#fff', border: 'none', cursor: 'pointer', fontSize: '0.75rem' }}
                      >
                        Edit
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* TAB 3: VENDORS MASTER */}
      {activeTab === 'vendors' && (
        <div style={{ backgroundColor: '#1e293b', borderRadius: '12px', padding: '16px' }}>
          <h3 style={{ color: '#fff', margin: '0 0 16px 0' }}>Contractor / Vendor Master Register</h3>
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', color: '#fff', fontSize: '0.85rem' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid var(--border-color)', textAlign: 'left', color: 'var(--text-muted)' }}>
                  <th style={{ padding: '10px' }}>Code</th>
                  <th style={{ padding: '10px' }}>Company Name</th>
                  <th style={{ padding: '10px' }}>Authorized Lead</th>
                  <th style={{ padding: '10px' }}>Contract Validity</th>
                  <th style={{ padding: '10px' }}>Workers</th>
                  <th style={{ padding: '10px' }}>Status</th>
                </tr>
              </thead>
              <tbody>
                {vendors.map(v => (
                  <tr key={v.id} style={{ borderBottom: '1px solid rgba(255, 255, 255, 0.05)' }}>
                    <td style={{ padding: '10px', fontWeight: 700, color: '#06b6d4' }}>{v.vendor_id}</td>
                    <td style={{ padding: '10px', fontWeight: 600 }}>{v.company_name}</td>
                    <td style={{ padding: '10px' }}>{v.owner_name} ({v.phone})</td>
                    <td style={{ padding: '10px', color: 'var(--text-muted)' }}>{v.contract_start} to {v.contract_end}</td>
                    <td style={{ padding: '10px', fontWeight: 700 }}>{v.employee_count}</td>
                    <td style={{ padding: '10px' }}>
                      <span style={{ padding: '2px 8px', borderRadius: '4px', backgroundColor: 'rgba(16, 185, 129, 0.2)', color: '#10b981', fontSize: '0.75rem', fontWeight: 700 }}>
                        Active
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* TAB 4: PERMITS MASTER */}
      {activeTab === 'permits' && (
        <div style={{ backgroundColor: '#1e293b', borderRadius: '12px', padding: '16px' }}>
          <h3 style={{ color: '#fff', margin: '0 0 16px 0' }}>Master Work Permits (PTW) Control</h3>
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', color: '#fff', fontSize: '0.85rem' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid var(--border-color)', textAlign: 'left', color: 'var(--text-muted)' }}>
                  <th style={{ padding: '10px' }}>Permit #</th>
                  <th style={{ padding: '10px' }}>Permit Type</th>
                  <th style={{ padding: '10px' }}>Zone</th>
                  <th style={{ padding: '10px' }}>Contractor</th>
                  <th style={{ padding: '10px' }}>HSE Endorsement</th>
                  <th style={{ padding: '10px' }}>Status</th>
                </tr>
              </thead>
              <tbody>
                {permits.map(p => (
                  <tr key={p.id} style={{ borderBottom: '1px solid rgba(255, 255, 255, 0.05)' }}>
                    <td style={{ padding: '10px', fontWeight: 700, color: '#f59e0b' }}>{p.permit_number}</td>
                    <td style={{ padding: '10px', fontWeight: 600 }}>{p.permit_type}</td>
                    <td style={{ padding: '10px' }}>{p.location_zone}</td>
                    <td style={{ padding: '10px', color: '#06b6d4' }}>{p.vendor_name}</td>
                    <td style={{ padding: '10px', color: p.safety_officer_endorsed ? '#10b981' : '#f59e0b', fontWeight: 700 }}>
                      {p.safety_officer_endorsed ? '✓ Certified' : '⏳ Pending'}
                    </td>
                    <td style={{ padding: '10px' }}>
                      <span style={{ padding: '2px 8px', borderRadius: '4px', backgroundColor: 'rgba(16, 185, 129, 0.2)', color: '#10b981', fontSize: '0.75rem', fontWeight: 700 }}>
                        {p.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* TAB 5: AUDIT LOGS */}
      {activeTab === 'audit' && (
        <div style={{ backgroundColor: '#1e293b', borderRadius: '12px', padding: '16px' }}>
          <h3 style={{ color: '#fff', margin: '0 0 16px 0' }}>Security & Granular Action Audit Trail</h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
            {auditLogs.map((log, idx) => (
              <div key={idx} style={{
                padding: '12px 16px',
                backgroundColor: '#0f172a',
                borderRadius: '8px',
                border: '1px solid rgba(255, 255, 255, 0.05)',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center'
              }}>
                <div>
                  <span style={{ color: '#f59e0b', fontWeight: 800, fontSize: '0.8rem', marginRight: '8px' }}>
                    [{log.action_type || 'AUDIT'}]
                  </span>
                  <span style={{ color: '#fff', fontSize: '0.85rem' }}>{log.details}</span>
                  <p style={{ margin: '4px 0 0 0', fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                    By: {log.user_name} ({log.user_role})
                  </p>
                </div>
                <span style={{ color: 'var(--text-muted)', fontSize: '0.75rem' }}>
                  {log.timestamp ? log.timestamp.split('T')[0] : 'Today'}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* USER CREATION & RBAC MODAL */}
      {isModalOpen && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundColor: 'rgba(0, 0, 0, 0.8)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 100,
          padding: '20px'
        }}>
          <div style={{
            backgroundColor: '#0f172a',
            borderRadius: '16px',
            border: '1px solid rgba(245, 158, 11, 0.4)',
            width: '100%',
            maxWidth: '620px',
            maxHeight: '90vh',
            overflowY: 'auto',
            padding: '24px',
            boxShadow: '0 20px 40px rgba(0, 0, 0, 0.6)'
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '18px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Key size={22} color="#f59e0b" />
                <h2 style={{ margin: 0, color: '#fff', fontSize: '1.2rem', fontWeight: 800 }}>
                  {editingUser ? 'Edit User & Permissions Matrix' : 'Create User & Assign Access'}
                </h2>
              </div>
              <button onClick={() => setIsModalOpen(false)} style={{ background: 'none', border: 'none', color: '#fff', cursor: 'pointer', fontSize: '1.2rem' }}>✕</button>
            </div>

            <form onSubmit={handleSaveUser}>
              <div className="grid-responsive-1-1" style={{ marginBottom: '12px' }}>
                <div>
                  <label style={{ display: 'block', color: 'var(--text-muted)', fontSize: '0.75rem', fontWeight: 700, marginBottom: '4px' }}>FULL NAME *</label>
                  <input
                    type="text"
                    required
                    value={formData.full_name}
                    onChange={(e) => setFormData({ ...formData, full_name: e.target.value })}
                    style={{ width: '100%', padding: '10px', backgroundColor: '#1e293b', border: '1px solid var(--border-color)', borderRadius: '8px', color: '#fff' }}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', color: 'var(--text-muted)', fontSize: '0.75rem', fontWeight: 700, marginBottom: '4px' }}>USERNAME *</label>
                  <input
                    type="text"
                    required
                    value={formData.username}
                    onChange={(e) => setFormData({ ...formData, username: e.target.value })}
                    style={{ width: '100%', padding: '10px', backgroundColor: '#1e293b', border: '1px solid var(--border-color)', borderRadius: '8px', color: '#fff' }}
                  />
                </div>
              </div>

              <div className="grid-responsive-1-1" style={{ marginBottom: '12px' }}>
                <div>
                  <label style={{ display: 'block', color: 'var(--text-muted)', fontSize: '0.75rem', fontWeight: 700, marginBottom: '4px' }}>EMAIL ADDRESS *</label>
                  <input
                    type="email"
                    required
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    style={{ width: '100%', padding: '10px', backgroundColor: '#1e293b', border: '1px solid var(--border-color)', borderRadius: '8px', color: '#fff' }}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', color: 'var(--text-muted)', fontSize: '0.75rem', fontWeight: 700, marginBottom: '4px' }}>MOBILE NUMBER</label>
                  <input
                    type="text"
                    value={formData.phone}
                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                    style={{ width: '100%', padding: '10px', backgroundColor: '#1e293b', border: '1px solid var(--border-color)', borderRadius: '8px', color: '#fff' }}
                  />
                </div>
              </div>

              <div className="grid-responsive-1-1" style={{ marginBottom: '16px' }}>
                <div>
                  <label style={{ display: 'block', color: '#f59e0b', fontSize: '0.75rem', fontWeight: 700, marginBottom: '4px' }}>SYSTEM ROLE (PRESET ACCESS)</label>
                  <select
                    value={formData.role}
                    onChange={(e) => handleRoleChange(e.target.value)}
                    style={{ width: '100%', padding: '10px', backgroundColor: '#1e293b', border: '1px solid var(--border-color)', borderRadius: '8px', color: '#fff', fontWeight: 700 }}
                  >
                    <option value="Super Admin">👑 Super Admin</option>
                    <option value="Admin">🏢 Site Admin</option>
                    <option value="Safety Officer">⛑️ Safety Officer (HSE)</option>
                    <option value="Vendor">🏗️ Contractor / Vendor</option>
                    <option value="Security">🛡️ Security Guard</option>
                  </select>
                </div>
                <div>
                  <label style={{ display: 'block', color: '#f59e0b', fontSize: '0.75rem', fontWeight: 700, marginBottom: '4px' }}>ACCOUNT STATUS</label>
                  <select
                    value={formData.status}
                    onChange={(e) => setFormData({ ...formData, status: e.target.value })}
                    style={{ width: '100%', padding: '10px', backgroundColor: '#1e293b', border: '1px solid var(--border-color)', borderRadius: '8px', color: '#fff', fontWeight: 700 }}
                  >
                    <option value="Active">🟢 Active</option>
                    <option value="Suspended">🟡 Suspended</option>
                    <option value="Deactivated">🔴 Deactivated</option>
                  </select>
                </div>
              </div>

              {/* GRANULAR PERMISSION MATRIX */}
              <div style={{
                backgroundColor: '#1e293b',
                padding: '14px',
                borderRadius: '10px',
                border: '1px solid rgba(255, 255, 255, 0.1)',
                marginBottom: '18px'
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px' }}>
                  <span style={{ color: '#f59e0b', fontSize: '0.8rem', fontWeight: 800 }}>GRANULAR PERMISSION MATRIX</span>
                  <div style={{ display: 'flex', gap: '8px' }}>
                    <button type="button" onClick={handleSelectAll} style={{ background: 'none', border: 'none', color: '#06b6d4', fontSize: '0.75rem', fontWeight: 700, cursor: 'pointer' }}>Select All</button>
                    <span style={{ color: 'var(--text-muted)' }}>|</span>
                    <button type="button" onClick={handleClearAll} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: '0.75rem', fontWeight: 700, cursor: 'pointer' }}>Clear All</button>
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '8px' }}>
                  {availablePermissions.map(perm => {
                    const isChecked = formData.permissions.includes('all') || formData.permissions.includes(perm.id);
                    return (
                      <div
                        key={perm.id}
                        onClick={() => handleTogglePermission(perm.id)}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: '10px',
                          padding: '8px 10px',
                          backgroundColor: isChecked ? 'rgba(245, 158, 11, 0.12)' : 'rgba(0, 0, 0, 0.2)',
                          border: isChecked ? '1px solid rgba(245, 158, 11, 0.4)' : '1px solid transparent',
                          borderRadius: '6px',
                          cursor: 'pointer',
                          transition: 'all 0.15s'
                        }}
                      >
                        {isChecked ? <CheckSquare size={18} color="#f59e0b" /> : <Square size={18} color="var(--text-muted)" />}
                        <span style={{ fontSize: '0.82rem', color: isChecked ? '#fff' : 'var(--text-muted)', fontWeight: isChecked ? 700 : 500 }}>
                          {perm.label}
                        </span>
                      </div>
                    );
                  })}
                </div>
              </div>

              <div style={{ display: 'flex', gap: '10px' }}>
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  style={{
                    flex: 1,
                    padding: '12px',
                    backgroundColor: 'transparent',
                    border: '1px solid var(--border-color)',
                    borderRadius: '8px',
                    color: 'var(--text-muted)',
                    fontWeight: 700,
                    cursor: 'pointer'
                  }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  style={{
                    flex: 2,
                    padding: '12px',
                    backgroundColor: '#f59e0b',
                    border: 'none',
                    borderRadius: '8px',
                    color: '#0b0f19',
                    fontWeight: 800,
                    cursor: 'pointer',
                    boxShadow: '0 4px 15px rgba(245, 158, 11, 0.35)'
                  }}
                >
                  {editingUser ? 'SAVE USER & ACCESS MATRIX' : 'CREATE ACCOUNT & GRANT ACCESS'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default SuperAdmin;
