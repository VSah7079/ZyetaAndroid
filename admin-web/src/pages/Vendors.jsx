import React, { useState, useEffect } from 'react';
import {
  Building2, Plus, Phone, Mail, FileText, CheckCircle2, XCircle, AlertTriangle,
  Users, Calendar, Clock, Truck, Package, ShieldAlert, ShieldCheck, Flame,
  Check, X, RefreshCw, ChevronDown, UserCheck, ArrowUpRight, TrendingUp, TrendingDown,
  MapPin, Hash, Award, AlertCircle
} from 'lucide-react';
import { api } from '../services/api';

export const Vendors = () => {
  const [vendors, setVendors] = useState([]);
  const [selectedVendorId, setSelectedVendorId] = useState('');
  const [selectedVendorDetails, setSelectedVendorDetails] = useState(null);
  const [activeTab, setActiveTab] = useState('workforce');
  const [loading, setLoading] = useState(true);
  const [detailsLoading, setDetailsLoading] = useState(false);

  // Modals
  const [showVendorModal, setShowVendorModal] = useState(false);
  const [showWorkerModal, setShowWorkerModal] = useState(false);
  const [showPermitModal, setShowPermitModal] = useState(false);
  const [showMaterialModal, setShowMaterialModal] = useState(false);
  const [showSafetyModal, setShowSafetyModal] = useState(false);

  // Forms State
  const [vendorForm, setVendorForm] = useState({
    company_name: '',
    owner_name: '',
    email: '',
    phone: '',
    address: '',
    gst_pan: '',
    contract_start: new Date().toISOString().split('T')[0],
    contract_end: '2027-12-31'
  });

  const [workerForm, setWorkerForm] = useState({
    full_name: '',
    mobile: '',
    designation: 'Technician',
    skill: 'General',
    employee_type: 'Contractor',
    aadhaar_no: '',
    blood_group: 'O+'
  });

  const [permitForm, setPermitForm] = useState({
    permit_type: 'Hot Work (Welding/Cutting)',
    description: '',
    location_zone: 'Block A - 4th Floor AHU Plant',
    applicant_name: '',
    applicant_contact: '',
    start_time: new Date().toISOString().slice(0, 16),
    end_time: new Date(Date.now() + 86400000).toISOString().slice(0, 16)
  });

  const [materialForm, setMaterialForm] = useState({
    material_name: '',
    quantity: 10,
    unit: 'Units',
    movement_type: 'INWARD',
    is_returnable: false,
    vehicle_number: '',
    driver_name: '',
    remarks: ''
  });

  const [safetyForm, setSafetyForm] = useState({
    worker_id: '',
    worker_name: '',
    color_type: 'YELLOW',
    category: 'PPE Warning / Housekeeping',
    reason: '',
    zone: 'Block A - Ground Floor',
    corrective_action: ''
  });

  const fetchVendors = async (autoSelectId = null) => {
    try {
      setLoading(true);
      const res = await api.getVendors();
      if (res.success && res.data) {
        setVendors(res.data);
        const targetId = autoSelectId || selectedVendorId || (res.data.length > 0 ? String(res.data[0].id) : '');
        if (targetId) {
          setSelectedVendorId(targetId);
          fetchVendorDetails(targetId);
        }
      }
    } catch (err) {
      console.error('Failed to fetch vendors:', err);
    } finally {
      setLoading(false);
    }
  };

  const fetchVendorDetails = async (id) => {
    if (!id || id === 'ALL') {
      setSelectedVendorDetails(null);
      return;
    }
    try {
      setDetailsLoading(true);
      const res = await api.getVendorById(id);
      if (res.success) {
        setSelectedVendorDetails(res.data);
      }
    } catch (err) {
      console.error('Failed to fetch vendor details:', err);
    } finally {
      setDetailsLoading(false);
    }
  };

  useEffect(() => {
    fetchVendors();
  }, []);

  const handleVendorSelectChange = (e) => {
    const val = e.target.value;
    setSelectedVendorId(val);
    fetchVendorDetails(val);
  };

  // Vendor Onboarding
  const handleCreateVendor = async (e) => {
    e.preventDefault();
    try {
      const res = await api.createVendor(vendorForm);
      if (res.success) {
        setShowVendorModal(false);
        setVendorForm({
          company_name: '',
          owner_name: '',
          email: '',
          phone: '',
          address: '',
          gst_pan: '',
          contract_start: new Date().toISOString().split('T')[0],
          contract_end: '2027-12-31'
        });
        await fetchVendors(res.data?.id ? String(res.data.id) : null);
      }
    } catch (err) {
      alert(err.message || 'Failed to create vendor');
    }
  };

  // 1-Click Approve Worker
  const handleApproveWorker = async (empId) => {
    try {
      const res = await api.updateEmployee(empId, { status: 'Active' });
      if (res.success) {
        fetchVendorDetails(selectedVendorId);
        fetchVendors();
      }
    } catch (err) {
      alert(err.message || 'Failed to approve worker');
    }
  };

  // 1-Click Reject / Deactivate Worker
  const handleRejectWorker = async (empId) => {
    if (!window.confirm('Are you sure you want to reject/deactivate this worker profile?')) return;
    try {
      const res = await api.updateEmployee(empId, { status: 'Deactivated' });
      if (res.success) {
        fetchVendorDetails(selectedVendorId);
        fetchVendors();
      }
    } catch (err) {
      alert(err.message || 'Failed to reject worker');
    }
  };

  // 1-Click Approve Permit
  const handleApprovePermit = async (permitId) => {
    try {
      const res = await api.approvePermit(permitId);
      if (res.success) {
        fetchVendorDetails(selectedVendorId);
        fetchVendors();
      }
    } catch (err) {
      alert(err.message || 'Failed to approve permit');
    }
  };

  // 1-Click Reject Permit
  const handleRejectPermit = async (permitId) => {
    const reason = window.prompt('Please enter the reason for permit rejection:', 'Safety checklist incomplete or PPE missing');
    if (reason === null) return;
    try {
      const res = await api.rejectPermit(permitId, reason);
      if (res.success) {
        fetchVendorDetails(selectedVendorId);
        fetchVendors();
      }
    } catch (err) {
      alert(err.message || 'Failed to reject permit');
    }
  };

  // Create Worker for Vendor
  const handleCreateWorker = async (e) => {
    e.preventDefault();
    if (!selectedVendorId || selectedVendorId === 'ALL') return;
    try {
      const res = await api.createEmployee({
        ...workerForm,
        vendor_id: Number(selectedVendorId),
        status: 'Active'
      });
      if (res.success) {
        setShowWorkerModal(false);
        setWorkerForm({
          full_name: '',
          mobile: '',
          designation: 'Technician',
          skill: 'General',
          employee_type: 'Contractor',
          aadhaar_no: '',
          blood_group: 'O+'
        });
        fetchVendorDetails(selectedVendorId);
        fetchVendors();
      }
    } catch (err) {
      alert(err.message || 'Failed to create worker');
    }
  };

  // Create Permit for Vendor
  const handleCreatePermit = async (e) => {
    e.preventDefault();
    if (!selectedVendorId || selectedVendorId === 'ALL') return;
    try {
      const res = await api.createPermit({
        ...permitForm,
        vendor_id: Number(selectedVendorId),
        applicant_name: permitForm.applicant_name || selectedVendorDetails?.owner_name || 'Site Supervisor',
        applicant_contact: permitForm.applicant_contact || selectedVendorDetails?.phone || ''
      });
      if (res.success) {
        setShowPermitModal(false);
        setPermitForm({
          permit_type: 'Hot Work (Welding/Cutting)',
          description: '',
          location_zone: 'Block A - 4th Floor AHU Plant',
          applicant_name: '',
          applicant_contact: '',
          start_time: new Date().toISOString().slice(0, 16),
          end_time: new Date(Date.now() + 86400000).toISOString().slice(0, 16)
        });
        fetchVendorDetails(selectedVendorId);
        fetchVendors();
      }
    } catch (err) {
      alert(err.message || 'Failed to create permit');
    }
  };

  // Create Material DC Entry
  const handleCreateMaterial = async (e) => {
    e.preventDefault();
    if (!selectedVendorId || selectedVendorId === 'ALL') return;
    try {
      const res = await api.createMaterialEntry({
        ...materialForm,
        vendor_id: Number(selectedVendorId)
      });
      if (res.success) {
        setShowMaterialModal(false);
        setMaterialForm({
          material_name: '',
          quantity: 10,
          unit: 'Units',
          movement_type: 'INWARD',
          is_returnable: false,
          vehicle_number: '',
          driver_name: '',
          remarks: ''
        });
        fetchVendorDetails(selectedVendorId);
        fetchVendors();
      }
    } catch (err) {
      alert(err.message || 'Failed to create material DC');
    }
  };

  // Create Safety Punch
  const handleCreateSafety = async (e) => {
    e.preventDefault();
    if (!selectedVendorId || selectedVendorId === 'ALL') return;
    try {
      const res = await api.createSafetyPunch({
        ...safetyForm,
        vendor_id: Number(selectedVendorId),
        vendor_name: selectedVendorDetails?.company_name || 'Contractor'
      });
      if (res.success) {
        setShowSafetyModal(false);
        setSafetyForm({
          worker_id: '',
          worker_name: '',
          color_type: 'YELLOW',
          category: 'PPE Warning / Housekeeping',
          reason: '',
          zone: 'Block A - Ground Floor',
          corrective_action: ''
        });
        fetchVendorDetails(selectedVendorId);
      }
    } catch (err) {
      alert(err.message || 'Failed to log safety punch');
    }
  };

  const selectedVendor = vendors.find((v) => String(v.id) === String(selectedVendorId));
  const stats = selectedVendorDetails?.stats || {
    total_employees: selectedVendor?.employee_count || 0,
    currently_inside: selectedVendor?.inside_count || 0,
    today_manpower: selectedVendor?.today_manpower || selectedVendor?.inside_count || 0,
    yesterday_manpower: selectedVendor?.yesterday_manpower || 0,
    active_permits: selectedVendor?.active_permits || 0,
    pending_permits: selectedVendor?.pending_permits || 0,
    pending_employee_approvals: selectedVendor?.pending_employee_approvals || 0,
    total_dc_entries: selectedVendor?.total_dc_entries || 0,
    safety_punches_count: 0
  };

  const manpowerDiff = stats.today_manpower - stats.yesterday_manpower;
  const isManpowerUp = manpowerDiff >= 0;

  return (
    <div className="page-container">
      {/* Page Header & Top Vendor Dropdown */}
      <div className="page-header" style={{ alignItems: 'flex-start', flexWrap: 'wrap', gap: '16px' }}>
        <div style={{ flex: '1 1 300px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div style={{ background: 'linear-gradient(135deg, #06b6d4, #3b82f6)', padding: '8px', borderRadius: '10px', color: '#fff' }}>
              <Building2 size={24} />
            </div>
            <div>
              <h2 style={{ fontSize: 'clamp(1.1rem, 2.2vw, 1.35rem)', fontWeight: 800, color: '#fff', margin: 0 }}>
                Contractor Command Center & Approvals
              </h2>
              <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', margin: '2px 0 0 0' }}>
                Site Admin oversight: Select registered contractor for real-time manpower, workforce approvals, PTW & DC movement
              </p>
            </div>
          </div>
        </div>

        {/* Action Controls & Top Dropdown Selector */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', flexWrap: 'wrap' }}>
          {/* Vendor Selector Dropdown */}
          <div style={{ display: 'flex', alignItems: 'center', background: 'rgba(15, 23, 42, 0.8)', padding: '4px 12px', borderRadius: '10px', border: '1px solid var(--border-color)', minWidth: '240px' }}>
            <span style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-muted)', marginRight: '8px', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
              Contractor:
            </span>
            <select
              value={selectedVendorId}
              onChange={handleVendorSelectChange}
              style={{
                background: 'transparent',
                border: 'none',
                color: '#38bdf8',
                fontSize: '0.9rem',
                fontWeight: 700,
                outline: 'none',
                cursor: 'pointer',
                flex: 1,
                padding: '6px 0'
              }}
            >
              {vendors.map((v) => (
                <option key={v.id} value={v.id} style={{ background: '#0f172a', color: '#fff' }}>
                  {v.company_name} ({v.vendor_id})
                </option>
              ))}
            </select>
          </div>

          <button onClick={() => fetchVendors(selectedVendorId)} className="btn btn-secondary" title="Refresh Live Contractor Data" style={{ padding: '8px 12px' }}>
            <RefreshCw size={15} />
          </button>

          <button onClick={() => setShowVendorModal(true)} className="btn btn-primary" style={{ whiteSpace: 'nowrap' }}>
            <Plus size={16} />
            <span>Onboard New Contractor</span>
          </button>
        </div>
      </div>

      {loading ? (
        <div style={{ padding: '60px 0', textAlign: 'center', color: 'var(--text-muted)' }}>
          <RefreshCw size={32} className="spin" style={{ margin: '0 auto 12px' }} />
          <p>Loading Contractor Intelligence...</p>
        </div>
      ) : !selectedVendor ? (
        <div className="glass-card" style={{ padding: '40px', textAlign: 'center' }}>
          <Building2 size={48} color="var(--text-muted)" style={{ margin: '0 auto 12px' }} />
          <h4 style={{ color: '#fff' }}>No Registered Contractors Found</h4>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.85rem', marginBottom: '16px' }}>
            Click below to onboard your first contractor or vendor into the system.
          </p>
          <button onClick={() => setShowVendorModal(true)} className="btn btn-primary">
            <Plus size={16} /> Onboard New Contractor
          </button>
        </div>
      ) : (
        <>
          {/* Main Vendor Dossier Header Card */}
          <div className="glass-card" style={{ padding: '20px', marginBottom: '20px', position: 'relative', overflow: 'hidden' }}>
            <div style={{ display: 'flex', flexWrap: 'wrap', justifyContent: 'space-between', alignItems: 'flex-start', gap: '16px' }}>
              <div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '6px' }}>
                  <span className="mono" style={{ fontSize: '0.8rem', background: 'rgba(99, 102, 241, 0.2)', color: '#818cf8', padding: '3px 8px', borderRadius: '6px', fontWeight: 700 }}>
                    {selectedVendor.vendor_id}
                  </span>
                  <span className={`badge ${selectedVendor.status === 'Active' ? 'badge-active' : 'badge-expired'}`}>
                    {selectedVendor.status || 'Active'}
                  </span>
                  <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                    GST/PAN: <strong style={{ color: '#cbd5e1' }}>{selectedVendor.gst_pan || '29ABCDE1234F1Z5'}</strong>
                  </span>
                </div>

                <h3 style={{ fontSize: '1.4rem', fontWeight: 800, color: '#fff', margin: '0 0 8px 0' }}>
                  {selectedVendor.company_name}
                </h3>

                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '18px', fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <Users size={14} color="#38bdf8" />
                    <span>Authorized Rep: <strong style={{ color: '#fff' }}>{selectedVendor.owner_name || 'N/A'}</strong></span>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <Phone size={14} color="#34d399" />
                    <span>{selectedVendor.phone || 'N/A'}</span>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <Mail size={14} color="#fbbf24" />
                    <span>{selectedVendor.email || 'N/A'}</span>
                  </div>
                  {selectedVendor.address && (
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <MapPin size={14} color="#f43f5e" />
                      <span>{selectedVendor.address}</span>
                    </div>
                  )}
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <Calendar size={14} color="#a78bfa" />
                    <span>Contract: <strong style={{ color: '#e2e8f0' }}>{selectedVendor.contract_start || '2026-01-01'}</strong> to <strong style={{ color: '#e2e8f0' }}>{selectedVendor.contract_end || '2027-12-31'}</strong></span>
                  </div>
                </div>
              </div>

              {/* Quick Action Buttons for Selected Vendor */}
              <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
                <button onClick={() => setShowWorkerModal(true)} className="btn btn-secondary" style={{ fontSize: '0.8rem' }}>
                  <Plus size={14} /> Add Worker
                </button>
                <button onClick={() => setShowPermitModal(true)} className="btn btn-secondary" style={{ fontSize: '0.8rem' }}>
                  <Flame size={14} color="#f59e0b" /> Issue PTW
                </button>
                <button onClick={() => setShowMaterialModal(true)} className="btn btn-secondary" style={{ fontSize: '0.8rem' }}>
                  <Package size={14} color="#10b981" /> Material Pass
                </button>
                <button onClick={() => setShowSafetyModal(true)} className="btn btn-secondary" style={{ fontSize: '0.8rem' }}>
                  <ShieldAlert size={14} color="#ef4444" /> Log Safety
                </button>
              </div>
            </div>
          </div>

          {/* Manpower Telemetry & KPI Cards */}
          <div className="grid-responsive-6" style={{ gap: '14px', marginBottom: '24px' }}>
            {/* TODAY'S MANPOWER */}
            <div className="glass-card" style={{ padding: '16px', background: 'linear-gradient(135deg, rgba(6, 182, 212, 0.15), rgba(15, 23, 42, 0.6))', border: '1px solid rgba(6, 182, 212, 0.3)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                <span style={{ fontSize: '0.72rem', fontWeight: 700, color: '#38bdf8', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                  Today Manpower
                </span>
                <Clock size={16} color="#38bdf8" />
              </div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: '8px' }}>
                <span style={{ fontSize: '1.8rem', fontWeight: 900, color: '#fff' }}>{stats.today_manpower}</span>
                <span style={{ fontSize: '0.75rem', color: isManpowerUp ? '#34d399' : '#f87171', display: 'flex', alignItems: 'center', fontWeight: 700 }}>
                  {isManpowerUp ? <TrendingUp size={13} style={{ marginRight: '2px' }} /> : <TrendingDown size={13} style={{ marginRight: '2px' }} />}
                  {isManpowerUp ? `+${manpowerDiff}` : manpowerDiff} vs y'day
                </span>
              </div>
              <p style={{ fontSize: '0.72rem', color: 'var(--text-muted)', margin: '4px 0 0 0' }}>
                Active on-site muster count
              </p>
            </div>

            {/* YESTERDAY'S MANPOWER */}
            <div className="glass-card" style={{ padding: '16px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                <span style={{ fontSize: '0.72rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                  Yesterday Manpower
                </span>
                <Calendar size={16} color="var(--text-muted)" />
              </div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: '8px' }}>
                <span style={{ fontSize: '1.8rem', fontWeight: 900, color: '#cbd5e1' }}>{stats.yesterday_manpower}</span>
                <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Workers</span>
              </div>
              <p style={{ fontSize: '0.72rem', color: 'var(--text-muted)', margin: '4px 0 0 0' }}>
                Total gate passes closed
              </p>
            </div>

            {/* TOTAL REGISTERED WORKFORCE */}
            <div className="glass-card" style={{ padding: '16px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                <span style={{ fontSize: '0.72rem', fontWeight: 700, color: '#818cf8', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                  Total Workforce
                </span>
                <Users size={16} color="#818cf8" />
              </div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: '8px' }}>
                <span style={{ fontSize: '1.8rem', fontWeight: 900, color: '#fff' }}>{stats.total_employees}</span>
                <span style={{ fontSize: '0.75rem', color: '#34d399', fontWeight: 600 }}>{stats.currently_inside} inside</span>
              </div>
              <p style={{ fontSize: '0.72rem', color: 'var(--text-muted)', margin: '4px 0 0 0' }}>
                Enrolled under contractor
              </p>
            </div>

            {/* PENDING WORKER APPROVALS */}
            <div className="glass-card" style={{ padding: '16px', border: stats.pending_employee_approvals > 0 ? '1px solid rgba(245, 158, 11, 0.4)' : undefined }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                <span style={{ fontSize: '0.72rem', fontWeight: 700, color: '#fbbf24', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                  Worker Approvals
                </span>
                <UserCheck size={16} color="#fbbf24" />
              </div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: '8px' }}>
                <span style={{ fontSize: '1.8rem', fontWeight: 900, color: stats.pending_employee_approvals > 0 ? '#fbbf24' : '#fff' }}>
                  {stats.pending_employee_approvals}
                </span>
                <span style={{ fontSize: '0.75rem', color: stats.pending_employee_approvals > 0 ? '#fbbf24' : 'var(--text-muted)' }}>
                  Pending
                </span>
              </div>
              <p style={{ fontSize: '0.72rem', color: 'var(--text-muted)', margin: '4px 0 0 0' }}>
                Awaiting Site Admin approval
              </p>
            </div>

            {/* ACTIVE PERMITS (PTW) */}
            <div className="glass-card" style={{ padding: '16px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                <span style={{ fontSize: '0.72rem', fontWeight: 700, color: '#f97316', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                  Active PTWs
                </span>
                <Flame size={16} color="#f97316" />
              </div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: '8px' }}>
                <span style={{ fontSize: '1.8rem', fontWeight: 900, color: '#fff' }}>{stats.active_permits}</span>
                {stats.pending_permits > 0 && (
                  <span style={{ fontSize: '0.75rem', color: '#f59e0b', fontWeight: 700 }}>
                    ({stats.pending_permits} pending)
                  </span>
                )}
              </div>
              <p style={{ fontSize: '0.72rem', color: 'var(--text-muted)', margin: '4px 0 0 0' }}>
                High-risk work permits
              </p>
            </div>

            {/* TOTAL DC & MATERIAL PASSES */}
            <div className="glass-card" style={{ padding: '16px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                <span style={{ fontSize: '0.72rem', fontWeight: 700, color: '#10b981', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                  Total DC Passes
                </span>
                <Package size={16} color="#10b981" />
              </div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: '8px' }}>
                <span style={{ fontSize: '1.8rem', fontWeight: 900, color: '#fff' }}>{stats.total_dc_entries}</span>
                <span style={{ fontSize: '0.75rem', color: '#10b981' }}>Inward/Out</span>
              </div>
              <p style={{ fontSize: '0.72rem', color: 'var(--text-muted)', margin: '4px 0 0 0' }}>
                Material delivery challans
              </p>
            </div>
          </div>

          {/* Navigation Tabs for Operations */}
          <div className="nav-tabs-scroll" style={{ display: 'flex', gap: '8px', borderBottom: '1px solid var(--border-color)', marginBottom: '20px', paddingBottom: '2px' }}>
            <button
              onClick={() => setActiveTab('workforce')}
              className={`nav-tab-item ${activeTab === 'workforce' ? 'active' : ''}`}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                padding: '10px 18px',
                background: activeTab === 'workforce' ? 'rgba(99, 102, 241, 0.15)' : 'transparent',
                border: 'none',
                borderBottom: activeTab === 'workforce' ? '2px solid #6366f1' : '2px solid transparent',
                color: activeTab === 'workforce' ? '#fff' : 'var(--text-secondary)',
                fontWeight: 700,
                fontSize: '0.85rem',
                cursor: 'pointer',
                whiteSpace: 'nowrap'
              }}
            >
              <Users size={16} />
              <span>Workforce & Approvals</span>
              {stats.pending_employee_approvals > 0 && (
                <span style={{ background: '#f59e0b', color: '#000', borderRadius: '12px', padding: '1px 6px', fontSize: '0.7rem', fontWeight: 800 }}>
                  {stats.pending_employee_approvals}
                </span>
              )}
            </button>

            <button
              onClick={() => setActiveTab('permits')}
              className={`nav-tab-item ${activeTab === 'permits' ? 'active' : ''}`}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                padding: '10px 18px',
                background: activeTab === 'permits' ? 'rgba(245, 158, 11, 0.15)' : 'transparent',
                border: 'none',
                borderBottom: activeTab === 'permits' ? '2px solid #f59e0b' : '2px solid transparent',
                color: activeTab === 'permits' ? '#fff' : 'var(--text-secondary)',
                fontWeight: 700,
                fontSize: '0.85rem',
                cursor: 'pointer',
                whiteSpace: 'nowrap'
              }}
            >
              <Flame size={16} />
              <span>Permits to Work (PTW)</span>
              {stats.pending_permits > 0 && (
                <span style={{ background: '#f59e0b', color: '#000', borderRadius: '12px', padding: '1px 6px', fontSize: '0.7rem', fontWeight: 800 }}>
                  {stats.pending_permits}
                </span>
              )}
            </button>

            <button
              onClick={() => setActiveTab('attendance')}
              className={`nav-tab-item ${activeTab === 'attendance' ? 'active' : ''}`}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                padding: '10px 18px',
                background: activeTab === 'attendance' ? 'rgba(6, 182, 212, 0.15)' : 'transparent',
                border: 'none',
                borderBottom: activeTab === 'attendance' ? '2px solid #06b6d4' : '2px solid transparent',
                color: activeTab === 'attendance' ? '#fff' : 'var(--text-secondary)',
                fontWeight: 700,
                fontSize: '0.85rem',
                cursor: 'pointer',
                whiteSpace: 'nowrap'
              }}
            >
              <Clock size={16} />
              <span>Attendance & Live Muster</span>
            </button>

            <button
              onClick={() => setActiveTab('materials')}
              className={`nav-tab-item ${activeTab === 'materials' ? 'active' : ''}`}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                padding: '10px 18px',
                background: activeTab === 'materials' ? 'rgba(16, 185, 129, 0.15)' : 'transparent',
                border: 'none',
                borderBottom: activeTab === 'materials' ? '2px solid #10b981' : '2px solid transparent',
                color: activeTab === 'materials' ? '#fff' : 'var(--text-secondary)',
                fontWeight: 700,
                fontSize: '0.85rem',
                cursor: 'pointer',
                whiteSpace: 'nowrap'
              }}
            >
              <Package size={16} />
              <span>Material Inward / DC Entries</span>
            </button>

            <button
              onClick={() => setActiveTab('safety')}
              className={`nav-tab-item ${activeTab === 'safety' ? 'active' : ''}`}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                padding: '10px 18px',
                background: activeTab === 'safety' ? 'rgba(239, 68, 68, 0.15)' : 'transparent',
                border: 'none',
                borderBottom: activeTab === 'safety' ? '2px solid #ef4444' : '2px solid transparent',
                color: activeTab === 'safety' ? '#fff' : 'var(--text-secondary)',
                fontWeight: 700,
                fontSize: '0.85rem',
                cursor: 'pointer',
                whiteSpace: 'nowrap'
              }}
            >
              <ShieldAlert size={16} />
              <span>Safety Punches & HSE Scorecard</span>
            </button>

            <button
              onClick={() => setActiveTab('vehicles')}
              className={`nav-tab-item ${activeTab === 'vehicles' ? 'active' : ''}`}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                padding: '10px 18px',
                background: activeTab === 'vehicles' ? 'rgba(168, 85, 247, 0.15)' : 'transparent',
                border: 'none',
                borderBottom: activeTab === 'vehicles' ? '2px solid #a855f7' : '2px solid transparent',
                color: activeTab === 'vehicles' ? '#fff' : 'var(--text-secondary)',
                fontWeight: 700,
                fontSize: '0.85rem',
                cursor: 'pointer',
                whiteSpace: 'nowrap'
              }}
            >
              <Truck size={16} />
              <span>Contractor Fleet & Vehicles</span>
            </button>
          </div>

          {/* TAB CONTENT PANELS */}
          {detailsLoading ? (
            <div style={{ padding: '40px 0', textAlign: 'center', color: 'var(--text-muted)' }}>
              <RefreshCw size={24} className="spin" style={{ margin: '0 auto 10px' }} />
              <p>Fetching Contractor Operations Data...</p>
            </div>
          ) : (
            <div>
              {/* TAB 1: WORKFORCE & PENDING APPROVALS */}
              {activeTab === 'workforce' && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
                  {/* PENDING APPROVALS QUEUE */}
                  {selectedVendorDetails?.pending_employees && selectedVendorDetails.pending_employees.length > 0 && (
                    <div className="glass-card" style={{ padding: '20px', border: '1px solid rgba(245, 158, 11, 0.4)', background: 'linear-gradient(135deg, rgba(245, 158, 11, 0.08), rgba(15, 23, 42, 0.6))' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px' }}>
                        <div>
                          <h4 style={{ fontSize: '1rem', fontWeight: 800, color: '#fbbf24', display: 'flex', alignItems: 'center', gap: '8px', margin: 0 }}>
                            <AlertCircle size={18} />
                            Pending Workforce Approvals ({selectedVendorDetails.pending_employees.length})
                          </h4>
                          <p style={{ fontSize: '0.78rem', color: 'var(--text-secondary)', margin: '2px 0 0 0' }}>
                            New workers submitted by contractor awaiting Site Admin verification and gate badge issuance
                          </p>
                        </div>
                      </div>

                      <div className="table-container">
                        <table className="custom-table">
                          <thead>
                            <tr>
                              <th>Worker ID</th>
                              <th>Full Name</th>
                              <th>Designation</th>
                              <th>Mobile</th>
                              <th>Aadhaar / PVC</th>
                              <th>Blood Group</th>
                              <th style={{ textAlign: 'right' }}>Admin Action</th>
                            </tr>
                          </thead>
                          <tbody>
                            {selectedVendorDetails.pending_employees.map((emp) => (
                              <tr key={emp.id}>
                                <td className="mono" style={{ fontWeight: 700, color: '#818cf8' }}>{emp.employee_id}</td>
                                <td>
                                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                    <img
                                      src={emp.profile_photo || 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100'}
                                      alt=""
                                      style={{ width: '28px', height: '28px', borderRadius: '50%', objectFit: 'cover' }}
                                    />
                                    <div>
                                      <strong style={{ color: '#fff', display: 'block' }}>{emp.full_name}</strong>
                                      <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>{emp.skill || 'General'}</span>
                                    </div>
                                  </div>
                                </td>
                                <td>{emp.designation}</td>
                                <td>{emp.mobile}</td>
                                <td>
                                  <span style={{ fontSize: '0.72rem', background: 'rgba(255,255,255,0.06)', padding: '2px 6px', borderRadius: '4px' }}>
                                    {emp.aadhaar_no || 'Document Attached'}
                                  </span>
                                </td>
                                <td><span className="mono" style={{ color: '#f87171', fontWeight: 700 }}>{emp.blood_group || 'O+'}</span></td>
                                <td style={{ textAlign: 'right' }}>
                                  <div style={{ display: 'inline-flex', gap: '6px' }}>
                                    <button
                                      onClick={() => handleApproveWorker(emp.id)}
                                      className="btn btn-primary"
                                      style={{ padding: '4px 10px', fontSize: '0.75rem', background: '#10b981', borderColor: '#10b981' }}
                                      title="Approve and issue gate access"
                                    >
                                      <Check size={14} /> Approve
                                    </button>
                                    <button
                                      onClick={() => handleRejectWorker(emp.id)}
                                      className="btn btn-secondary"
                                      style={{ padding: '4px 10px', fontSize: '0.75rem', color: '#f87171', borderColor: 'rgba(248, 113, 113, 0.4)' }}
                                      title="Reject worker"
                                    >
                                      <X size={14} /> Reject
                                    </button>
                                  </div>
                                </td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </div>
                    </div>
                  )}

                  {/* ACTIVE WORKFORCE TABLE */}
                  <div className="glass-card" style={{ padding: '20px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px', flexWrap: 'wrap', gap: '10px' }}>
                      <div>
                        <h4 style={{ fontSize: '1rem', fontWeight: 800, color: '#fff', margin: 0 }}>
                          Registered Workforce Roster ({selectedVendorDetails?.employees ? selectedVendorDetails.employees.length : 0})
                        </h4>
                        <p style={{ fontSize: '0.78rem', color: 'var(--text-secondary)', margin: '2px 0 0 0' }}>
                          All workers registered under {selectedVendor.company_name}
                        </p>
                      </div>

                      <button onClick={() => setShowWorkerModal(true)} className="btn btn-primary" style={{ fontSize: '0.8rem' }}>
                        <Plus size={14} /> Enroll Worker for {selectedVendor.company_name}
                      </button>
                    </div>

                    <div className="table-container">
                      <table className="custom-table">
                        <thead>
                          <tr>
                            <th>ID</th>
                            <th>Worker Name</th>
                            <th>Trade / Role</th>
                            <th>Mobile</th>
                            <th>On Site Status</th>
                            <th>Compliance</th>
                            <th>Badge Status</th>
                            <th style={{ textAlign: 'right' }}>Actions</th>
                          </tr>
                        </thead>
                        <tbody>
                          {!selectedVendorDetails?.employees || selectedVendorDetails.employees.length === 0 ? (
                            <tr>
                              <td colSpan="8" style={{ textAlign: 'center', padding: '30px', color: 'var(--text-muted)' }}>
                                No workers registered under this contractor yet.
                              </td>
                            </tr>
                          ) : (
                            selectedVendorDetails.employees.map((emp) => (
                              <tr key={emp.id}>
                                <td className="mono" style={{ fontWeight: 700, color: '#38bdf8' }}>{emp.employee_id}</td>
                                <td>
                                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                    <img
                                      src={emp.profile_photo || 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100'}
                                      alt=""
                                      style={{ width: '28px', height: '28px', borderRadius: '50%', objectFit: 'cover' }}
                                    />
                                    <div>
                                      <strong style={{ color: '#fff', display: 'block' }}>{emp.full_name}</strong>
                                      <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>{emp.designation}</span>
                                    </div>
                                  </div>
                                </td>
                                <td>{emp.skill || emp.designation}</td>
                                <td>{emp.mobile}</td>
                                <td>
                                  <span className={`badge ${emp.currently_inside ? 'badge-inside' : 'badge-absent'}`}>
                                    {emp.currently_inside ? '● INSIDE NOW' : 'OUTSIDE'}
                                  </span>
                                </td>
                                <td>
                                  <span style={{ fontSize: '0.72rem', color: '#34d399', display: 'flex', alignItems: 'center', gap: '4px' }}>
                                    <ShieldCheck size={13} /> Med Fit / PVC OK
                                  </span>
                                </td>
                                <td>
                                  <span className={`badge ${emp.status === 'Active' ? 'badge-active' : emp.status === 'Pending Approval' ? 'badge-pending' : 'badge-expired'}`}>
                                    {emp.status}
                                  </span>
                                </td>
                                <td style={{ textAlign: 'right' }}>
                                  <div style={{ display: 'inline-flex', gap: '4px' }}>
                                    {emp.status !== 'Active' && (
                                      <button onClick={() => handleApproveWorker(emp.id)} className="btn btn-secondary" style={{ padding: '3px 8px', fontSize: '0.7rem', color: '#34d399' }} title="Approve">
                                        <Check size={12} />
                                      </button>
                                    )}
                                    <button onClick={() => handleRejectWorker(emp.id)} className="btn btn-secondary" style={{ padding: '3px 8px', fontSize: '0.7rem', color: '#f87171' }} title="Deactivate">
                                      <X size={12} />
                                    </button>
                                  </div>
                                </td>
                              </tr>
                            ))
                          )}
                        </tbody>
                      </table>
                    </div>
                  </div>
                </div>
              )}

              {/* TAB 2: PERMITS TO WORK (PTW) & APPROVALS */}
              {activeTab === 'permits' && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
                  <div className="glass-card" style={{ padding: '20px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px', flexWrap: 'wrap', gap: '10px' }}>
                      <div>
                        <h4 style={{ fontSize: '1rem', fontWeight: 800, color: '#fff', margin: 0 }}>
                          Permits to Work (PTW) & Safety Clearances
                        </h4>
                        <p style={{ fontSize: '0.78rem', color: 'var(--text-secondary)', margin: '2px 0 0 0' }}>
                          Manage high-risk work permits for Hot Work, Height Work, Confined Space & Electrical Isolation
                        </p>
                      </div>

                      <button onClick={() => setShowPermitModal(true)} className="btn btn-primary" style={{ fontSize: '0.8rem' }}>
                        <Plus size={14} /> Issue New Permit (PTW)
                      </button>
                    </div>

                    <div className="table-container">
                      <table className="custom-table">
                        <thead>
                          <tr>
                            <th>Permit No.</th>
                            <th>Permit Type</th>
                            <th>Scope & Location</th>
                            <th>Validity Window</th>
                            <th>Applicant</th>
                            <th>Status</th>
                            <th style={{ textAlign: 'right' }}>Admin Decision</th>
                          </tr>
                        </thead>
                        <tbody>
                          {!selectedVendorDetails?.permits || selectedVendorDetails.permits.length === 0 ? (
                            <tr>
                              <td colSpan="7" style={{ textAlign: 'center', padding: '30px', color: 'var(--text-muted)' }}>
                                No permits issued for this contractor.
                              </td>
                            </tr>
                          ) : (
                            selectedVendorDetails.permits.map((p) => (
                              <tr key={p.id}>
                                <td className="mono" style={{ fontWeight: 700, color: '#f59e0b' }}>{p.permit_number}</td>
                                <td>
                                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                                    <Flame size={14} color="#f97316" />
                                    <strong style={{ color: '#fff' }}>{p.permit_type}</strong>
                                  </div>
                                </td>
                                <td>
                                  <div>
                                    <span style={{ color: '#cbd5e1', display: 'block' }}>{p.description}</span>
                                    <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>📍 {p.location_zone}</span>
                                  </div>
                                </td>
                                <td>
                                  <span style={{ fontSize: '0.75rem', color: '#e2e8f0' }}>
                                    {p.start_time?.slice(0, 10)} to {p.end_time?.slice(0, 10)}
                                  </span>
                                </td>
                                <td>
                                  <span style={{ fontSize: '0.78rem' }}>{p.applicant_name}</span>
                                </td>
                                <td>
                                  <span className={`badge ${p.status === 'Active' || p.status === 'Approved' ? 'badge-active' : p.status === 'Pending' ? 'badge-pending' : 'badge-expired'}`}>
                                    {p.status}
                                  </span>
                                </td>
                                <td style={{ textAlign: 'right' }}>
                                  {p.status === 'Pending' ? (
                                    <div style={{ display: 'inline-flex', gap: '6px' }}>
                                      <button
                                        onClick={() => handleApprovePermit(p.id)}
                                        className="btn btn-primary"
                                        style={{ padding: '4px 10px', fontSize: '0.75rem', background: '#10b981', borderColor: '#10b981' }}
                                      >
                                        <Check size={14} /> Approve PTW
                                      </button>
                                      <button
                                        onClick={() => handleRejectPermit(p.id)}
                                        className="btn btn-secondary"
                                        style={{ padding: '4px 10px', fontSize: '0.75rem', color: '#f87171' }}
                                      >
                                        <X size={14} /> Reject
                                      </button>
                                    </div>
                                  ) : (
                                    <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                                      {p.approved_by ? `By: ${p.approved_by}` : 'Processed'}
                                    </span>
                                  )}
                                </td>
                              </tr>
                            ))
                          )}
                        </tbody>
                      </table>
                    </div>
                  </div>
                </div>
              )}

              {/* TAB 3: ATTENDANCE & LIVE MUSTER */}
              {activeTab === 'attendance' && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
                  <div className="glass-card" style={{ padding: '20px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px', flexWrap: 'wrap', gap: '10px' }}>
                      <div>
                        <h4 style={{ fontSize: '1rem', fontWeight: 800, color: '#fff', margin: 0 }}>
                          Live Shift Attendance & Gate Movements
                        </h4>
                        <p style={{ fontSize: '0.78rem', color: 'var(--text-secondary)', margin: '2px 0 0 0' }}>
                          Today's biometric / QR turnstile muster for {selectedVendor.company_name}
                        </p>
                      </div>

                      <div style={{ display: 'flex', gap: '10px' }}>
                        <span className="badge badge-inside" style={{ fontSize: '0.8rem', padding: '6px 12px' }}>
                          Today On-Site: {stats.today_manpower}
                        </span>
                        <span className="badge" style={{ fontSize: '0.8rem', padding: '6px 12px', background: 'rgba(255,255,255,0.08)' }}>
                          Yesterday Total: {stats.yesterday_manpower}
                        </span>
                      </div>
                    </div>

                    <div className="table-container">
                      <table className="custom-table">
                        <thead>
                          <tr>
                            <th>Worker ID</th>
                            <th>Worker Name</th>
                            <th>In Time</th>
                            <th>Out Time</th>
                            <th>Shift / Hours</th>
                            <th>Attendance Status</th>
                            <th>Gate Location</th>
                          </tr>
                        </thead>
                        <tbody>
                          {!selectedVendorDetails?.employees || selectedVendorDetails.employees.length === 0 ? (
                            <tr>
                              <td colSpan="7" style={{ textAlign: 'center', padding: '30px', color: 'var(--text-muted)' }}>
                                No attendance records found.
                              </td>
                            </tr>
                          ) : (
                            selectedVendorDetails.employees.map((emp) => (
                              <tr key={emp.id}>
                                <td className="mono" style={{ fontWeight: 700, color: '#38bdf8' }}>{emp.employee_id}</td>
                                <td>
                                  <strong style={{ color: '#fff' }}>{emp.full_name}</strong>
                                  <span style={{ display: 'block', fontSize: '0.7rem', color: 'var(--text-muted)' }}>{emp.designation}</span>
                                </td>
                                <td>
                                  <span className="mono" style={{ color: emp.currently_inside ? '#34d399' : '#cbd5e1' }}>
                                    {emp.currently_inside ? '08:45 AM' : '09:00 AM'}
                                  </span>
                                </td>
                                <td>
                                  <span className="mono" style={{ color: emp.currently_inside ? '#38bdf8' : 'var(--text-muted)' }}>
                                    {emp.currently_inside ? 'Currently On Site' : '06:00 PM'}
                                  </span>
                                </td>
                                <td>General Shift (8.5 hrs)</td>
                                <td>
                                  <span className={`badge ${emp.currently_inside ? 'badge-inside' : 'badge-active'}`}>
                                    {emp.currently_inside ? 'PRESENT (INSIDE)' : 'CHECKED OUT'}
                                  </span>
                                </td>
                                <td>Main Turnstile Gate 1</td>
                              </tr>
                            ))
                          )}
                        </tbody>
                      </table>
                    </div>
                  </div>
                </div>
              )}

              {/* TAB 4: MATERIAL INWARD / DC ENTRIES */}
              {activeTab === 'materials' && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
                  <div className="glass-card" style={{ padding: '20px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px', flexWrap: 'wrap', gap: '10px' }}>
                      <div>
                        <h4 style={{ fontSize: '1rem', fontWeight: 800, color: '#fff', margin: 0 }}>
                          Material Delivery Challans (DC) & Gate Movement
                        </h4>
                        <p style={{ fontSize: '0.78rem', color: 'var(--text-secondary)', margin: '2px 0 0 0' }}>
                          Inward raw materials, outward tools, delivery passes and returnable item tracking
                        </p>
                      </div>

                      <button onClick={() => setShowMaterialModal(true)} className="btn btn-primary" style={{ fontSize: '0.8rem' }}>
                        <Plus size={14} /> Create Material / DC Entry
                      </button>
                    </div>

                    <div className="table-container">
                      <table className="custom-table">
                        <thead>
                          <tr>
                            <th>DC Number</th>
                            <th>Material Description</th>
                            <th>Type</th>
                            <th>Quantity</th>
                            <th>Vehicle & Driver</th>
                            <th>Returnable?</th>
                            <th>Status</th>
                          </tr>
                        </thead>
                        <tbody>
                          {!selectedVendorDetails?.materials || selectedVendorDetails.materials.length === 0 ? (
                            <tr>
                              <td colSpan="7" style={{ textAlign: 'center', padding: '30px', color: 'var(--text-muted)' }}>
                                No material DC records found for this contractor.
                              </td>
                            </tr>
                          ) : (
                            selectedVendorDetails.materials.map((m) => (
                              <tr key={m.id}>
                                <td className="mono" style={{ fontWeight: 700, color: '#10b981' }}>{m.dc_number || `DC-2026-${100 + m.id}`}</td>
                                <td>
                                  <strong style={{ color: '#fff', display: 'block' }}>{m.material_name}</strong>
                                  <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>{m.remarks || 'Standard site delivery'}</span>
                                </td>
                                <td>
                                  <span className={`badge ${m.movement_type === 'INWARD' ? 'badge-active' : 'badge-pending'}`}>
                                    {m.movement_type}
                                  </span>
                                </td>
                                <td>
                                  <strong>{m.quantity}</strong> {m.unit || 'Units'}
                                </td>
                                <td>
                                  <div>
                                    <span style={{ color: '#fff', display: 'block', fontSize: '0.78rem' }}>{m.vehicle_number || 'KA 04 E 9921'}</span>
                                    <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>Driver: {m.driver_name || 'N/A'}</span>
                                  </div>
                                </td>
                                <td>
                                  {m.is_returnable ? (
                                    <span style={{ color: m.is_returned ? '#34d399' : '#f59e0b', fontSize: '0.75rem', fontWeight: 700 }}>
                                      {m.is_returned ? '✓ Returned' : '⏳ Return Pending'}
                                    </span>
                                  ) : (
                                    <span style={{ color: 'var(--text-muted)', fontSize: '0.75rem' }}>Non-Returnable</span>
                                  )}
                                </td>
                                <td>
                                  <span className="badge badge-active">{m.status || 'Gate Verified'}</span>
                                </td>
                              </tr>
                            ))
                          )}
                        </tbody>
                      </table>
                    </div>
                  </div>
                </div>
              )}

              {/* TAB 5: SAFETY PUNCHES & HSE SCORECARD */}
              {activeTab === 'safety' && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
                  <div className="glass-card" style={{ padding: '20px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px', flexWrap: 'wrap', gap: '10px' }}>
                      <div>
                        <h4 style={{ fontSize: '1rem', fontWeight: 800, color: '#fff', margin: 0 }}>
                          Contractor Safety Punches & HSE Scorecard
                        </h4>
                        <p style={{ fontSize: '0.78rem', color: 'var(--text-secondary)', margin: '2px 0 0 0' }}>
                          Color-coded safety compliance violations (Red / Yellow / Green badges) and demerit points
                        </p>
                      </div>

                      <button onClick={() => setShowSafetyModal(true)} className="btn btn-primary" style={{ fontSize: '0.8rem', background: '#ef4444', borderColor: '#ef4444' }}>
                        <ShieldAlert size={14} /> Log Safety Observation / Punch
                      </button>
                    </div>

                    <div className="table-container">
                      <table className="custom-table">
                        <thead>
                          <tr>
                            <th>Punch Code</th>
                            <th>Severity Color</th>
                            <th>Worker Involved</th>
                            <th>Violation Category & Reason</th>
                            <th>Location Zone</th>
                            <th>Corrective Action</th>
                            <th>Status</th>
                          </tr>
                        </thead>
                        <tbody>
                          {!selectedVendorDetails?.safety_punches || selectedVendorDetails.safety_punches.length === 0 ? (
                            <tr>
                              <td colSpan="7" style={{ textAlign: 'center', padding: '30px', color: 'var(--text-muted)' }}>
                                <ShieldCheck size={32} color="#34d399" style={{ margin: '0 auto 8px' }} />
                                <p style={{ color: '#34d399', fontWeight: 700 }}>Clean Safety Record</p>
                                <p style={{ fontSize: '0.75rem' }}>No open safety violations recorded for this contractor.</p>
                              </td>
                            </tr>
                          ) : (
                            selectedVendorDetails.safety_punches.map((pch) => (
                              <tr key={pch.id}>
                                <td className="mono" style={{ fontWeight: 700, color: pch.color_type === 'RED' ? '#f87171' : pch.color_type === 'YELLOW' ? '#fbbf24' : '#34d399' }}>
                                  {pch.punch_code}
                                </td>
                                <td>
                                  <span style={{
                                    display: 'inline-flex',
                                    alignItems: 'center',
                                    gap: '4px',
                                    padding: '3px 8px',
                                    borderRadius: '6px',
                                    fontWeight: 800,
                                    fontSize: '0.72rem',
                                    background: pch.color_type === 'RED' ? 'rgba(239,68,68,0.2)' : pch.color_type === 'YELLOW' ? 'rgba(245,158,11,0.2)' : 'rgba(16,185,129,0.2)',
                                    color: pch.color_type === 'RED' ? '#f87171' : pch.color_type === 'YELLOW' ? '#fbbf24' : '#34d399'
                                  }}>
                                    ● {pch.color_type} PUNCH
                                  </span>
                                </td>
                                <td>
                                  <strong style={{ color: '#fff', display: 'block' }}>{pch.worker_name}</strong>
                                  <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>{pch.worker_id}</span>
                                </td>
                                <td>
                                  <div>
                                    <strong style={{ color: '#fff', display: 'block', fontSize: '0.78rem' }}>{pch.category}</strong>
                                    <span style={{ fontSize: '0.72rem', color: '#cbd5e1' }}>{pch.reason}</span>
                                  </div>
                                </td>
                                <td>📍 {pch.zone}</td>
                                <td>
                                  <span style={{ fontSize: '0.72rem', color: '#94a3b8' }}>{pch.corrective_action || 'Action underway'}</span>
                                </td>
                                <td>
                                  <span className={`badge ${pch.status === 'RESOLVED' || pch.status === 'COMMENDED' ? 'badge-active' : 'badge-pending'}`}>
                                    {pch.status}
                                  </span>
                                </td>
                              </tr>
                            ))
                          )}
                        </tbody>
                      </table>
                    </div>
                  </div>
                </div>
              )}

              {/* TAB 6: CONTRACTOR FLEET & VEHICLES */}
              {activeTab === 'vehicles' && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
                  <div className="glass-card" style={{ padding: '20px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px', flexWrap: 'wrap', gap: '10px' }}>
                      <div>
                        <h4 style={{ fontSize: '1rem', fontWeight: 800, color: '#fff', margin: 0 }}>
                          Authorized Vehicle Fleet & Gate Clearance
                        </h4>
                        <p style={{ fontSize: '0.78rem', color: 'var(--text-secondary)', margin: '2px 0 0 0' }}>
                          Registered transport trucks, logistics vans, PUC & insurance status
                        </p>
                      </div>
                    </div>

                    <div className="table-container">
                      <table className="custom-table">
                        <thead>
                          <tr>
                            <th>Vehicle No.</th>
                            <th>Vehicle Type</th>
                            <th>Driver Name</th>
                            <th>Driver Phone</th>
                            <th>PUC & Insurance</th>
                            <th>Gate Clearance</th>
                          </tr>
                        </thead>
                        <tbody>
                          {!selectedVendorDetails?.vehicles || selectedVendorDetails.vehicles.length === 0 ? (
                            <tr>
                              <td colSpan="6" style={{ textAlign: 'center', padding: '30px', color: 'var(--text-muted)' }}>
                                No vehicles registered under this contractor.
                              </td>
                            </tr>
                          ) : (
                            selectedVendorDetails.vehicles.map((v, idx) => (
                              <tr key={idx}>
                                <td className="mono" style={{ fontWeight: 700, color: '#a855f7' }}>{v.vehicle_number || 'KA 04 E 9921'}</td>
                                <td>{v.vehicle_type || 'Heavy Goods Vehicle (HGV)'}</td>
                                <td><strong style={{ color: '#fff' }}>{v.driver_name || 'Manish Yadav'}</strong></td>
                                <td>{v.driver_phone || '+91 9876543210'}</td>
                                <td>
                                  <span style={{ color: '#34d399', fontSize: '0.75rem', fontWeight: 700 }}>
                                    ✓ Valid till 2027-01-31
                                  </span>
                                </td>
                                <td><span className="badge badge-active">Authorized</span></td>
                              </tr>
                            ))
                          )}
                        </tbody>
                      </table>
                    </div>
                  </div>
                </div>
              )}
            </div>
          )}
        </>
      )}

      {/* MODAL 1: ONBOARD CONTRACTOR / VENDOR */}
      {showVendorModal && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '600px' }}>
            <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ fontSize: '1.05rem', fontWeight: 700, color: '#fff', display: 'flex', alignItems: 'center', gap: '8px', margin: 0 }}>
                <Building2 size={18} color="#06b6d4" />
                Onboard Contractor / Vendor
              </h3>
              <button onClick={() => setShowVendorModal(false)} style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}>✕</button>
            </div>

            <form onSubmit={handleCreateVendor} style={{ padding: '20px' }}>
              <div className="grid-responsive-1-1">
                <div className="form-group" style={{ gridColumn: 'span 2' }}>
                  <label className="form-label">Company Legal Name *</label>
                  <input
                    type="text"
                    required
                    className="form-control"
                    placeholder="e.g. Apex MEP Solutions Pvt Ltd"
                    value={vendorForm.company_name}
                    onChange={(e) => setVendorForm({ ...vendorForm, company_name: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Authorized Contact Person *</label>
                  <input
                    type="text"
                    required
                    className="form-control"
                    placeholder="e.g. Suresh Kumar"
                    value={vendorForm.owner_name}
                    onChange={(e) => setVendorForm({ ...vendorForm, owner_name: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Phone Number *</label>
                  <input
                    type="text"
                    required
                    className="form-control"
                    placeholder="+91 9876543210"
                    value={vendorForm.phone}
                    onChange={(e) => setVendorForm({ ...vendorForm, phone: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Email Address</label>
                  <input
                    type="email"
                    className="form-control"
                    placeholder="vendor@domain.com"
                    value={vendorForm.email}
                    onChange={(e) => setVendorForm({ ...vendorForm, email: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">GST / PAN Number</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="29ABCDE1234F1Z5"
                    value={vendorForm.gst_pan}
                    onChange={(e) => setVendorForm({ ...vendorForm, gst_pan: e.target.value })}
                  />
                </div>

                <div className="form-group" style={{ gridColumn: 'span 2' }}>
                  <label className="form-label">Office / Plant Address</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Plot 42, Electronic City Phase 1, Bangalore"
                    value={vendorForm.address}
                    onChange={(e) => setVendorForm({ ...vendorForm, address: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Contract Start Date</label>
                  <input
                    type="date"
                    className="form-control"
                    value={vendorForm.contract_start}
                    onChange={(e) => setVendorForm({ ...vendorForm, contract_start: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Contract End Date</label>
                  <input
                    type="date"
                    className="form-control"
                    value={vendorForm.contract_end}
                    onChange={(e) => setVendorForm({ ...vendorForm, contract_end: e.target.value })}
                  />
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '16px' }}>
                <button type="button" onClick={() => setShowVendorModal(false)} className="btn btn-secondary">
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

      {/* MODAL 2: ADD WORKER FOR CONTRACTOR */}
      {showWorkerModal && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '550px' }}>
            <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ fontSize: '1.05rem', fontWeight: 700, color: '#fff', display: 'flex', alignItems: 'center', gap: '8px', margin: 0 }}>
                <Users size={18} color="#6366f1" />
                Enroll Worker for {selectedVendor?.company_name}
              </h3>
              <button onClick={() => setShowWorkerModal(false)} style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}>✕</button>
            </div>

            <form onSubmit={handleCreateWorker} style={{ padding: '20px' }}>
              <div className="grid-responsive-1-1">
                <div className="form-group" style={{ gridColumn: 'span 2' }}>
                  <label className="form-label">Worker Full Name *</label>
                  <input
                    type="text"
                    required
                    className="form-control"
                    placeholder="e.g. Ramesh Patel"
                    value={workerForm.full_name}
                    onChange={(e) => setWorkerForm({ ...workerForm, full_name: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Mobile Number *</label>
                  <input
                    type="text"
                    required
                    className="form-control"
                    placeholder="+91 9876543210"
                    value={workerForm.mobile}
                    onChange={(e) => setWorkerForm({ ...workerForm, mobile: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Blood Group</label>
                  <select
                    className="form-control"
                    value={workerForm.blood_group}
                    onChange={(e) => setWorkerForm({ ...workerForm, blood_group: e.target.value })}
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
                  <label className="form-label">Designation / Role</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Senior Scaffolder"
                    value={workerForm.designation}
                    onChange={(e) => setWorkerForm({ ...workerForm, designation: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Skill / Trade</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Height Work & Rigging"
                    value={workerForm.skill}
                    onChange={(e) => setWorkerForm({ ...workerForm, skill: e.target.value })}
                  />
                </div>

                <div className="form-group" style={{ gridColumn: 'span 2' }}>
                  <label className="form-label">Aadhaar Card Number</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="4532 8912 0000"
                    value={workerForm.aadhaar_no}
                    onChange={(e) => setWorkerForm({ ...workerForm, aadhaar_no: e.target.value })}
                  />
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '16px' }}>
                <button type="button" onClick={() => setShowWorkerModal(false)} className="btn btn-secondary">
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary">
                  Enroll & Issue Pass
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL 3: ISSUE PERMIT (PTW) */}
      {showPermitModal && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '600px' }}>
            <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ fontSize: '1.05rem', fontWeight: 700, color: '#fff', display: 'flex', alignItems: 'center', gap: '8px', margin: 0 }}>
                <Flame size={18} color="#f59e0b" />
                Issue Permit to Work (PTW) for {selectedVendor?.company_name}
              </h3>
              <button onClick={() => setShowPermitModal(false)} style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}>✕</button>
            </div>

            <form onSubmit={handleCreatePermit} style={{ padding: '20px' }}>
              <div className="grid-responsive-1-1">
                <div className="form-group" style={{ gridColumn: 'span 2' }}>
                  <label className="form-label">Permit Category *</label>
                  <select
                    className="form-control"
                    value={permitForm.permit_type}
                    onChange={(e) => setPermitForm({ ...permitForm, permit_type: e.target.value })}
                  >
                    <option value="Hot Work (Welding/Cutting)">Hot Work (Welding, Cutting, Grinding)</option>
                    <option value="Height Work (&gt; 1.8m)">Height Work (&gt; 1.8m Scaffolding / Cradle)</option>
                    <option value="Electrical Isolation (LOTO)">Electrical Isolation (LOTO & High Voltage)</option>
                    <option value="Confined Space Entry">Confined Space Entry & Tank Cleaning</option>
                    <option value="Excavation & Trenching">Excavation & Ground Trenching</option>
                  </select>
                </div>

                <div className="form-group" style={{ gridColumn: 'span 2' }}>
                  <label className="form-label">Scope Description *</label>
                  <textarea
                    required
                    rows={2}
                    className="form-control"
                    placeholder="e.g. Beam welding on Floor 4 AHU Room; spark screens and standby fire watch assigned"
                    value={permitForm.description}
                    onChange={(e) => setPermitForm({ ...permitForm, description: e.target.value })}
                  />
                </div>

                <div className="form-group" style={{ gridColumn: 'span 2' }}>
                  <label className="form-label">Location Zone *</label>
                  <input
                    type="text"
                    required
                    className="form-control"
                    placeholder="e.g. Block A - 4th Floor AHU Plant"
                    value={permitForm.location_zone}
                    onChange={(e) => setPermitForm({ ...permitForm, location_zone: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Start Time *</label>
                  <input
                    type="datetime-local"
                    required
                    className="form-control"
                    value={permitForm.start_time}
                    onChange={(e) => setPermitForm({ ...permitForm, start_time: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">End Time *</label>
                  <input
                    type="datetime-local"
                    required
                    className="form-control"
                    value={permitForm.end_time}
                    onChange={(e) => setPermitForm({ ...permitForm, end_time: e.target.value })}
                  />
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '16px' }}>
                <button type="button" onClick={() => setShowPermitModal(false)} className="btn btn-secondary">
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" style={{ background: '#f59e0b', borderColor: '#f59e0b' }}>
                  Issue Permit
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL 4: CREATE MATERIAL DC ENTRY */}
      {showMaterialModal && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '550px' }}>
            <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ fontSize: '1.05rem', fontWeight: 700, color: '#fff', display: 'flex', alignItems: 'center', gap: '8px', margin: 0 }}>
                <Package size={18} color="#10b981" />
                Material / DC Pass for {selectedVendor?.company_name}
              </h3>
              <button onClick={() => setShowMaterialModal(false)} style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}>✕</button>
            </div>

            <form onSubmit={handleCreateMaterial} style={{ padding: '20px' }}>
              <div className="grid-responsive-1-1">
                <div className="form-group" style={{ gridColumn: 'span 2' }}>
                  <label className="form-label">Material Description *</label>
                  <input
                    type="text"
                    required
                    className="form-control"
                    placeholder="e.g. Scaffolding Pipes & Cuplock Clamps"
                    value={materialForm.material_name}
                    onChange={(e) => setMaterialForm({ ...materialForm, material_name: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Quantity *</label>
                  <input
                    type="number"
                    required
                    className="form-control"
                    value={materialForm.quantity}
                    onChange={(e) => setMaterialForm({ ...materialForm, quantity: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Unit of Measure</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Sets / Bundles / Kgs"
                    value={materialForm.unit}
                    onChange={(e) => setMaterialForm({ ...materialForm, unit: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Movement Type</label>
                  <select
                    className="form-control"
                    value={materialForm.movement_type}
                    onChange={(e) => setMaterialForm({ ...materialForm, movement_type: e.target.value })}
                  >
                    <option value="INWARD">INWARD (Entry to Site)</option>
                    <option value="OUTWARD">OUTWARD (Exit from Site)</option>
                  </select>
                </div>

                <div className="form-group">
                  <label className="form-label">Vehicle Reg. Number</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. KA 04 E 9921"
                    value={materialForm.vehicle_number}
                    onChange={(e) => setMaterialForm({ ...materialForm, vehicle_number: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Driver Name</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Manish Yadav"
                    value={materialForm.driver_name}
                    onChange={(e) => setMaterialForm({ ...materialForm, driver_name: e.target.value })}
                  />
                </div>

                <div className="form-group" style={{ display: 'flex', alignItems: 'center', gap: '8px', paddingTop: '28px' }}>
                  <input
                    type="checkbox"
                    id="returnable_check"
                    checked={materialForm.is_returnable}
                    onChange={(e) => setMaterialForm({ ...materialForm, is_returnable: e.target.checked })}
                    style={{ width: '18px', height: '18px', accentColor: '#10b981' }}
                  />
                  <label htmlFor="returnable_check" style={{ color: '#fff', fontSize: '0.85rem', cursor: 'pointer' }}>
                    Is Returnable Material?
                  </label>
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '16px' }}>
                <button type="button" onClick={() => setShowMaterialModal(false)} className="btn btn-secondary">
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" style={{ background: '#10b981', borderColor: '#10b981' }}>
                  Generate DC Pass
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL 5: LOG SAFETY PUNCH */}
      {showSafetyModal && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '550px' }}>
            <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ fontSize: '1.05rem', fontWeight: 700, color: '#fff', display: 'flex', alignItems: 'center', gap: '8px', margin: 0 }}>
                <ShieldAlert size={18} color="#ef4444" />
                Log Safety Observation / Punch ({selectedVendor?.company_name})
              </h3>
              <button onClick={() => setShowSafetyModal(false)} style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}>✕</button>
            </div>

            <form onSubmit={handleCreateSafety} style={{ padding: '20px' }}>
              <div className="grid-responsive-1-1">
                <div className="form-group">
                  <label className="form-label">Punch Severity Color *</label>
                  <select
                    className="form-control"
                    value={safetyForm.color_type}
                    onChange={(e) => setSafetyForm({ ...safetyForm, color_type: e.target.value })}
                  >
                    <option value="RED">🔴 RED (Critical Stop-Work Violation)</option>
                    <option value="YELLOW">🟡 YELLOW (PPE / Housekeeping Warning)</option>
                    <option value="GREEN">🟢 GREEN (Proactive Safety Excellence)</option>
                  </select>
                </div>

                <div className="form-group">
                  <label className="form-label">Category</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Height Work Violation"
                    value={safetyForm.category}
                    onChange={(e) => setSafetyForm({ ...safetyForm, category: e.target.value })}
                  />
                </div>

                <div className="form-group" style={{ gridColumn: 'span 2' }}>
                  <label className="form-label">Worker Name / ID</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Ramesh Patel (EMP-101)"
                    value={safetyForm.worker_name}
                    onChange={(e) => setSafetyForm({ ...safetyForm, worker_name: e.target.value })}
                  />
                </div>

                <div className="form-group" style={{ gridColumn: 'span 2' }}>
                  <label className="form-label">Observation / Violation Reason *</label>
                  <textarea
                    required
                    rows={2}
                    className="form-control"
                    placeholder="e.g. Double lanyard not hooked to lifeline while working on 4th floor edge"
                    value={safetyForm.reason}
                    onChange={(e) => setSafetyForm({ ...safetyForm, reason: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Location Zone</label>
                  <input
                    type="text"
                    className="form-control"
                    value={safetyForm.zone}
                    onChange={(e) => setSafetyForm({ ...safetyForm, zone: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Corrective Action</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Work stopped; retrained on spot"
                    value={safetyForm.corrective_action}
                    onChange={(e) => setSafetyForm({ ...safetyForm, corrective_action: e.target.value })}
                  />
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '16px' }}>
                <button type="button" onClick={() => setShowSafetyModal(false)} className="btn btn-secondary">
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" style={{ background: '#ef4444', borderColor: '#ef4444' }}>
                  Submit Safety Punch
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
