import React, { useState, useEffect } from 'react';
import {
  FileCheck, Plus, CheckCircle, XCircle, ShieldCheck, AlertTriangle,
  Clock, MapPin, Building, Camera, Trash2, Award, Zap, Eye, ZoomIn, Search
} from 'lucide-react';
import { api } from '../services/api';
import { useAuth } from '../context/AuthContext';

export const Permits = () => {
  const { user } = useAuth();
  const [activeSubTab, setActiveSubTab] = useState('permits'); // 'permits' | 'punches'

  // Permits State
  const [permits, setPermits] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedStatus, setSelectedStatus] = useState('');
  const [selectedType, setSelectedType] = useState('');
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [selectedPermitDetails, setSelectedPermitDetails] = useState(null);
  const [rejectReason, setRejectReason] = useState('');
  const [showRejectBox, setShowRejectBox] = useState(false);

  // Safety Punches State
  const [punches, setPunches] = useState([
    {
      id: 1,
      punch_code: 'PCH-2026-101',
      worker_name: 'Ramesh Patel',
      worker_id: 'EMP-101',
      vendor_name: 'ABC Infra Projects Pvt Ltd',
      color_type: 'RED',
      category: 'Critical Stop-Work Violation',
      reason: 'Working at 14m scaffold elevation without chin strap and harness hook loose.',
      zone: 'Block A - 4th Floor Facade',
      photo_url: 'https://images.unsplash.com/photo-1541888946425-d0fbb186156a?w=400&auto=format&fit=crop&q=80',
      corrective_action: 'Immediate Work Stoppage. Chin-strap fastened & harness dual-lanyards anchored to 100% lifeline.',
      reported_by: 'Er. Rajesh Varma (HSE Head)',
      timestamp: '2026-09-29T10:15:00Z',
      status: 'STOP_WORK',
    },
    {
      id: 2,
      punch_code: 'PCH-2026-102',
      worker_name: 'Amitabh Sen',
      worker_id: 'EMP-102',
      vendor_name: 'Apex MEP Solutions',
      color_type: 'YELLOW',
      category: 'Moderate Warning / PPE',
      reason: 'Missing cut-resistant safety gloves & eye protection goggles in active fabrication zone.',
      zone: 'Tower B - Electrical Sub-station',
      photo_url: 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=400&auto=format&fit=crop&q=80',
      corrective_action: 'Issued compliant PPE kit from central safety store. 24hr rectification warning recorded.',
      reported_by: 'Er. Rajesh Varma (HSE Head)',
      timestamp: '2026-09-29T11:45:00Z',
      status: 'ACKNOWLEDGED',
    },
    {
      id: 3,
      punch_code: 'PCH-2026-103',
      worker_name: 'Vikram Rathore',
      worker_id: 'EMP-104',
      vendor_name: 'ABC Infra Projects Pvt Ltd',
      color_type: 'GREEN',
      category: 'Safety Excellence / Proactive',
      reason: 'Proactive deployment of spark capture fire blankets & standby fire extinguisher before welding.',
      zone: 'Basement 1 - Structural Bay',
      photo_url: 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=400&auto=format&fit=crop&q=80',
      corrective_action: 'Commended during safety briefing. Awarded +25 Zero Harm Safety points.',
      reported_by: 'Er. Rajesh Varma (HSE Head)',
      timestamp: '2026-09-29T13:20:00Z',
      status: 'COMMENDED',
    },
  ]);
  const [selectedPunchColor, setSelectedPunchColor] = useState('ALL');
  const [punchSearch, setPunchSearch] = useState('');
  const [showNewPunchModal, setShowNewPunchModal] = useState(false);
  const [previewPhoto, setPreviewPhoto] = useState(null);

  // New Punch Form State
  const [punchForm, setPunchForm] = useState({
    color_type: 'RED',
    worker_name: 'Ramesh Patel',
    worker_id: 'EMP-101',
    vendor_name: 'ABC Infra Projects Pvt Ltd',
    zone: 'Block A - Scaffolding Area',
    reason: 'Working at height without safety harness tie-off / chin strap unfastened.',
    photo_url: 'https://images.unsplash.com/photo-1541888946425-d0fbb186156a?w=400&auto=format&fit=crop&q=80',
    corrective_action: 'Work stopped immediately. Chin-strap fastened & harness dual-lanyards secured.',
  });

  const photoPresets = [
    { title: 'Height Scaffolding', url: 'https://images.unsplash.com/photo-1541888946425-d0fbb186156a?w=400&auto=format&fit=crop&q=80' },
    { title: 'PPE Violation', url: 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=400&auto=format&fit=crop&q=80' },
    { title: 'Welding Fire Watch', url: 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=400&auto=format&fit=crop&q=80' },
    { title: 'Excavation & Shoring', url: 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?w=400&auto=format&fit=crop&q=80' },
  ];

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

  const fetchPunches = async () => {
    try {
      const res = await api.getSafetyPunches({
        color_type: selectedPunchColor !== 'ALL' ? selectedPunchColor : undefined,
        search: punchSearch || undefined
      });
      if (res.success && res.data) {
        setPunches(res.data);
      }
    } catch (err) {
      console.error(err);
    }
  };

  useEffect(() => {
    fetchPermits();
  }, [selectedStatus, selectedType]);

  useEffect(() => {
    fetchPunches();
  }, [selectedPunchColor, punchSearch]);

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

  const handleCreatePunch = async (e) => {
    e.preventDefault();
    try {
      const res = await api.createSafetyPunch(punchForm);
      if (res.success) {
        setShowNewPunchModal(false);
        fetchPunches();
      }
    } catch (err) {
      // Local fallback
      const newP = {
        id: Date.now(),
        punch_code: `PCH-2026-${punches.length + 101}`,
        ...punchForm,
        reported_by: user?.full_name || 'HSE Lead',
        timestamp: new Date().toISOString(),
        status: punchForm.color_type === 'GREEN' ? 'COMMENDED' : 'OPEN'
      };
      setPunches([newP, ...punches]);
      setShowNewPunchModal(false);
    }
  };

  const handleDeletePunch = async (id) => {
    try {
      await api.deleteSafetyPunch(id);
      fetchPunches();
    } catch (err) {
      setPunches(punches.filter(p => p.id !== id));
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

  const filteredPunches = punches.filter(p => {
    if (selectedPunchColor !== 'ALL' && p.color_type !== selectedPunchColor) return false;
    if (punchSearch) {
      const s = punchSearch.toLowerCase();
      return (
        p.worker_name?.toLowerCase().includes(s) ||
        p.worker_id?.toLowerCase().includes(s) ||
        p.punch_code?.toLowerCase().includes(s) ||
        p.reason?.toLowerCase().includes(s) ||
        p.zone?.toLowerCase().includes(s)
      );
    }
    return true;
  });

  const redCount = punches.filter(p => p.color_type === 'RED').length;
  const yellowCount = punches.filter(p => p.color_type === 'YELLOW').length;
  const greenCount = punches.filter(p => p.color_type === 'GREEN').length;

  return (
    <div className="page-container">
      {/* Top Header */}
      <div className="page-header">
        <div>
          <h2 style={{ fontSize: 'clamp(1.1rem, 2.2vw, 1.3rem)', fontWeight: 800, color: '#fff' }}>HSE Safety & Permits Command</h2>
          <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
            Digital permits-to-work, 3-color safety punch enforcement (🔴 Red / 🟡 Yellow / 🟢 Green), and live compliance
          </p>
        </div>

        {activeSubTab === 'permits' ? (
          <button onClick={() => setShowCreateModal(true)} className="btn btn-primary" style={{ whiteSpace: 'nowrap' }}>
            <Plus size={16} />
            <span>Request New Permit</span>
          </button>
        ) : (
          <button
            onClick={() => setShowNewPunchModal(true)}
            className="btn"
            style={{ backgroundColor: '#06b6d4', color: '#000', fontWeight: 700, whiteSpace: 'nowrap' }}
          >
            <Camera size={16} />
            <span>Record Safety Punch</span>
          </button>
        )}
      </div>

      {/* SUB-TABS NAVIGATION (Scrollable on mobile) */}
      <div className="nav-tabs-scroll" style={{ paddingBottom: '8px' }}>
        <button
          onClick={() => setActiveSubTab('permits')}
          className="btn"
          style={{
            backgroundColor: activeSubTab === 'permits' ? 'rgba(99, 102, 241, 0.2)' : 'transparent',
            border: activeSubTab === 'permits' ? '1px solid #6366f1' : '1px solid rgba(255,255,255,0.1)',
            color: activeSubTab === 'permits' ? '#a5b4fc' : 'var(--text-secondary)',
            fontWeight: 700,
            fontSize: '0.85rem'
          }}
        >
          <FileCheck size={16} />
          <span>📋 Work Permits ({permits.length})</span>
        </button>

        <button
          onClick={() => setActiveSubTab('punches')}
          className="btn"
          style={{
            backgroundColor: activeSubTab === 'punches' ? 'rgba(6, 182, 212, 0.2)' : 'transparent',
            border: activeSubTab === 'punches' ? '1px solid #06b6d4' : '1px solid rgba(255,255,255,0.1)',
            color: activeSubTab === 'punches' ? '#67e8f9' : 'var(--text-secondary)',
            fontWeight: 700,
            fontSize: '0.85rem'
          }}
        >
          <Zap size={16} />
          <span>🎯 Safety Punch System ({punches.length})</span>
        </button>
      </div>

      {/* ========================================================= */}
      {/* VIEW 1: WORK PERMITS (PTW)                                */}
      {/* ========================================================= */}
      {activeSubTab === 'permits' && (
        <>
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
          <div className="grid-cards-responsive">
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
        </>
      )}

      {/* ========================================================= */}
      {/* VIEW 2: SAFETY PUNCH SYSTEM (RED / YELLOW / GREEN)        */}
      {/* ========================================================= */}
      {activeSubTab === 'punches' && (
        <div>
          {/* Summary Badges Row */}
          <div className="grid-responsive-4" style={{ gap: '14px', marginBottom: '20px' }}>
            <div className="glass-panel" style={{ padding: '14px 18px', borderLeft: '4px solid #64748b' }}>
              <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', fontWeight: 600 }}>TOTAL PUNCHES</div>
              <div style={{ fontSize: '1.4rem', fontWeight: 800, color: '#fff', marginTop: '4px' }}>{punches.length}</div>
            </div>
            <div className="glass-panel" style={{ padding: '14px 18px', borderLeft: '4px solid #ef4444', backgroundColor: 'rgba(239, 68, 68, 0.08)' }}>
              <div style={{ fontSize: '0.75rem', color: '#fca5a5', fontWeight: 600 }}>🔴 RED (STOP-WORK)</div>
              <div style={{ fontSize: '1.4rem', fontWeight: 800, color: '#ef4444', marginTop: '4px' }}>{redCount} <span style={{ fontSize: '0.75rem', fontWeight: 400 }}>(-50 pts)</span></div>
            </div>
            <div className="glass-panel" style={{ padding: '14px 18px', borderLeft: '4px solid #f59e0b', backgroundColor: 'rgba(245, 158, 11, 0.08)' }}>
              <div style={{ fontSize: '0.75rem', color: '#fde68a', fontWeight: 600 }}>🟡 YELLOW (WARNING)</div>
              <div style={{ fontSize: '1.4rem', fontWeight: 800, color: '#f59e0b', marginTop: '4px' }}>{yellowCount} <span style={{ fontSize: '0.75rem', fontWeight: 400 }}>(-15 pts)</span></div>
            </div>
            <div className="glass-panel" style={{ padding: '14px 18px', borderLeft: '4px solid #10b981', backgroundColor: 'rgba(16, 185, 129, 0.08)' }}>
              <div style={{ fontSize: '0.75rem', color: '#6ee7b7', fontWeight: 600 }}>🟢 GREEN (EXCELLENCE)</div>
              <div style={{ fontSize: '1.4rem', fontWeight: 800, color: '#10b981', marginTop: '4px' }}>{greenCount} <span style={{ fontSize: '0.75rem', fontWeight: 400 }}>(+25 pts)</span></div>
            </div>
          </div>

          {/* Filter and Search Toolbar */}
          <div className="glass-panel" style={{ padding: '16px', marginBottom: '20px', display: 'flex', gap: '14px', alignItems: 'center', flexWrap: 'wrap' }}>
            <div style={{ flex: 1, minWidth: '220px', position: 'relative' }}>
              <Search size={16} color="var(--text-muted)" style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)' }} />
              <input
                type="text"
                className="form-control"
                style={{ paddingLeft: '36px' }}
                placeholder="Search punch by worker, ID, code, reason, or location..."
                value={punchSearch}
                onChange={(e) => setPunchSearch(e.target.value)}
              />
            </div>

            <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
              {['ALL', 'RED', 'YELLOW', 'GREEN'].map((c) => {
                let colorHex = '#64748b';
                let label = `All (${punches.length})`;
                if (c === 'RED') { colorHex = '#ef4444'; label = `🔴 Red (${redCount})`; }
                if (c === 'YELLOW') { colorHex = '#f59e0b'; label = `🟡 Yellow (${yellowCount})`; }
                if (c === 'GREEN') { colorHex = '#10b981'; label = `🟢 Green (${greenCount})`; }

                const isSelected = selectedPunchColor === c;
                return (
                  <button
                    key={c}
                    onClick={() => setSelectedPunchColor(c)}
                    className="btn"
                    style={{
                      backgroundColor: isSelected ? `${colorHex}33` : 'rgba(255,255,255,0.05)',
                      border: `1px solid ${isSelected ? colorHex : 'rgba(255,255,255,0.1)'}`,
                      color: isSelected ? '#fff' : 'var(--text-secondary)',
                      fontSize: '0.78rem',
                      fontWeight: isSelected ? 700 : 500
                    }}
                  >
                    {label}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Grid of Safety Punches */}
          <div className="grid-cards-responsive">
            {filteredPunches.map((p) => {
              let accent = '#ef4444';
              let badgeTitle = '🔴 CRITICAL STOP-WORK';
              let demerit = '-50 Points';
              if (p.color_type === 'YELLOW') {
                accent = '#f59e0b';
                badgeTitle = '🟡 MODERATE WARNING';
                demerit = '-15 Points';
              } else if (p.color_type === 'GREEN') {
                accent = '#10b981';
                badgeTitle = '🟢 SAFETY EXCELLENCE';
                demerit = '+25 Points';
              }

              return (
                <div
                  key={p.id}
                  className="glass-card"
                  style={{
                    padding: '0',
                    overflow: 'hidden',
                    border: `1.5px solid ${accent}66`,
                    boxShadow: `0 4px 20px ${accent}1a`,
                    display: 'flex',
                    flexDirection: 'column'
                  }}
                >
                  {/* Top Severity Banner */}
                  <div style={{
                    padding: '10px 16px',
                    backgroundColor: `${accent}22`,
                    borderBottom: `1px solid ${accent}44`,
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center'
                  }}>
                    <span style={{ fontSize: '0.75rem', fontWeight: 800, color: accent, letterSpacing: '0.5px' }}>
                      {badgeTitle} ({demerit})
                    </span>
                    <span className="mono" style={{ fontSize: '0.72rem', backgroundColor: '#0f172a', padding: '2px 8px', borderRadius: '4px', color: accent, border: `1px solid ${accent}66` }}>
                      {p.punch_code}
                    </span>
                  </div>

                  {/* Body Content */}
                  <div style={{ padding: '16px', flex: 1, display: 'flex', flexDirection: 'column', gap: '10px' }}>
                    {/* Worker Info */}
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                      <div>
                        <h4 style={{ fontSize: '0.98rem', fontWeight: 700, color: '#fff' }}>
                          {p.worker_name} <span style={{ fontSize: '0.75rem', color: 'var(--accent-cyan)', fontWeight: 600 }}>({p.worker_id})</span>
                        </h4>
                        <span style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>{p.vendor_name}</span>
                      </div>
                      <span className="badge" style={{ backgroundColor: `${accent}22`, color: accent, border: `1px solid ${accent}55` }}>
                        {p.status}
                      </span>
                    </div>

                    {/* Reason Box */}
                    <div style={{ background: 'rgba(0,0,0,0.3)', padding: '10px 12px', borderRadius: 'var(--radius-md)', borderLeft: `3px solid ${accent}` }}>
                      <div style={{ fontSize: '0.68rem', color: 'var(--text-muted)', fontWeight: 700, marginBottom: '2px' }}>OBSERVATION / REASON:</div>
                      <div style={{ fontSize: '0.8rem', color: '#e2e8f0', lineHeight: 1.35 }}>{p.reason}</div>
                    </div>

                    {/* Photo Evidence Thumbnail */}
                    {p.photo_url && (
                      <div
                        onClick={() => setPreviewPhoto(p)}
                        style={{
                          height: '140px',
                          borderRadius: '8px',
                          backgroundImage: `url(${p.photo_url})`,
                          backgroundSize: 'cover',
                          backgroundPosition: 'center',
                          position: 'relative',
                          cursor: 'pointer',
                          overflow: 'hidden',
                          border: '1px solid rgba(255,255,255,0.15)'
                        }}
                      >
                        <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(to top, rgba(0,0,0,0.7), transparent)' }} />
                        <div style={{ position: 'absolute', bottom: '8px', left: '10px', display: 'flex', alignItems: 'center', gap: '6px', color: '#fff', fontSize: '0.75rem', fontWeight: 600 }}>
                          <ZoomIn size={14} />
                          <span>Click to zoom photographic evidence</span>
                        </div>
                      </div>
                    )}

                    {/* Corrective Action */}
                    <div style={{ background: 'rgba(255,255,255,0.03)', padding: '8px 10px', borderRadius: '6px', fontSize: '0.75rem', color: 'var(--text-secondary)' }}>
                      <strong style={{ color: 'var(--accent-cyan)' }}>Action:</strong> {p.corrective_action}
                    </div>

                    {/* Footer Info */}
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 'auto', paddingTop: '8px', borderTop: '1px solid rgba(255,255,255,0.06)' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '0.72rem', color: 'var(--text-muted)' }}>
                        <MapPin size={12} />
                        <span>{p.zone}</span>
                      </div>
                      <button
                        onClick={() => handleDeletePunch(p.id)}
                        className="btn"
                        style={{ padding: '4px 8px', background: 'transparent', color: '#f87171', border: 'none', cursor: 'pointer' }}
                        title="Delete Punch"
                      >
                        <Trash2 size={15} />
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL: RECORD SAFETY PUNCH                                */}
      {/* ========================================================= */}
      {showNewPunchModal && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '620px' }}>
            <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Zap size={18} color="#06b6d4" />
                <h3 style={{ fontSize: '1.05rem', fontWeight: 800, color: '#fff' }}>Record Safety Punch (Red / Yellow / Green)</h3>
              </div>
              <button onClick={() => setShowNewPunchModal(false)} style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}>✕</button>
            </div>

            <form onSubmit={handleCreatePunch} style={{ padding: '20px', display: 'flex', flexDirection: 'column', gap: '14px' }}>
              {/* 1. THREE COLOR SELECTOR */}
              <div>
                <label className="form-label" style={{ fontWeight: 700 }}>PUNCH SEVERITY & COLOR CLASSIFICATION *</label>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '10px' }}>
                  {/* RED */}
                  <div
                    onClick={() => setPunchForm({
                      ...punchForm,
                      color_type: 'RED',
                      reason: 'Working at height without safety harness tie-off / chin strap unfastened.',
                      corrective_action: 'Immediate work stoppage & mandatory safety retraining before resume.'
                    })}
                    style={{
                      padding: '12px',
                      borderRadius: '10px',
                      cursor: 'pointer',
                      textAlign: 'center',
                      border: punchForm.color_type === 'RED' ? '2px solid #ef4444' : '1px solid rgba(255,255,255,0.1)',
                      backgroundColor: punchForm.color_type === 'RED' ? 'rgba(239, 68, 68, 0.2)' : 'rgba(255,255,255,0.03)'
                    }}
                  >
                    <div style={{ color: '#ef4444', fontWeight: 800, fontSize: '0.9rem' }}>🔴 RED</div>
                    <div style={{ fontSize: '0.7rem', color: '#fca5a5', marginTop: '2px' }}>Stop-Work (-50pt)</div>
                  </div>

                  {/* YELLOW */}
                  <div
                    onClick={() => setPunchForm({
                      ...punchForm,
                      color_type: 'YELLOW',
                      reason: 'Missing cut-resistant safety gloves & eye protection goggles.',
                      corrective_action: 'Issued compliant PPE from store and recorded 24hr rectification warning.'
                    })}
                    style={{
                      padding: '12px',
                      borderRadius: '10px',
                      cursor: 'pointer',
                      textAlign: 'center',
                      border: punchForm.color_type === 'YELLOW' ? '2px solid #f59e0b' : '1px solid rgba(255,255,255,0.1)',
                      backgroundColor: punchForm.color_type === 'YELLOW' ? 'rgba(245, 158, 11, 0.2)' : 'rgba(255,255,255,0.03)'
                    }}
                  >
                    <div style={{ color: '#f59e0b', fontWeight: 800, fontSize: '0.9rem' }}>🟡 YELLOW</div>
                    <div style={{ fontSize: '0.7rem', color: '#fde68a', marginTop: '2px' }}>Warning (-15pt)</div>
                  </div>

                  {/* GREEN */}
                  <div
                    onClick={() => setPunchForm({
                      ...punchForm,
                      color_type: 'GREEN',
                      reason: 'Proactive deployment of spark fire blankets and standby fire extinguisher prior to welding.',
                      corrective_action: 'Commended during safety briefing & awarded +25 Zero Harm points.'
                    })}
                    style={{
                      padding: '12px',
                      borderRadius: '10px',
                      cursor: 'pointer',
                      textAlign: 'center',
                      border: punchForm.color_type === 'GREEN' ? '2px solid #10b981' : '1px solid rgba(255,255,255,0.1)',
                      backgroundColor: punchForm.color_type === 'GREEN' ? 'rgba(16, 185, 129, 0.2)' : 'rgba(255,255,255,0.03)'
                    }}
                  >
                    <div style={{ color: '#10b981', fontWeight: 800, fontSize: '0.9rem' }}>🟢 GREEN</div>
                    <div style={{ fontSize: '0.7rem', color: '#6ee7b7', marginTop: '2px' }}>Excellence (+25pt)</div>
                  </div>
                </div>
              </div>

              {/* 2. Worker & Vendor */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                <div className="form-group">
                  <label className="form-label">Worker Name *</label>
                  <input
                    type="text"
                    required
                    className="form-control"
                    value={punchForm.worker_name}
                    onChange={(e) => setPunchForm({ ...punchForm, worker_name: e.target.value })}
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">Worker ID *</label>
                  <input
                    type="text"
                    required
                    className="form-control"
                    value={punchForm.worker_id}
                    onChange={(e) => setPunchForm({ ...punchForm, worker_id: e.target.value })}
                  />
                </div>
              </div>

              {/* 3. Vendor & Zone */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                <div className="form-group">
                  <label className="form-label">Contractor Vendor *</label>
                  <input
                    type="text"
                    required
                    className="form-control"
                    value={punchForm.vendor_name}
                    onChange={(e) => setPunchForm({ ...punchForm, vendor_name: e.target.value })}
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">Location / Site Zone *</label>
                  <input
                    type="text"
                    required
                    className="form-control"
                    value={punchForm.zone}
                    onChange={(e) => setPunchForm({ ...punchForm, zone: e.target.value })}
                  />
                </div>
              </div>

              {/* 4. Reason */}
              <div className="form-group">
                <label className="form-label">Punch Reason / Safety Observation *</label>
                <textarea
                  required
                  rows="2"
                  className="form-control"
                  placeholder="Describe exact safety violation or excellence observed..."
                  value={punchForm.reason}
                  onChange={(e) => setPunchForm({ ...punchForm, reason: e.target.value })}
                />
              </div>

              {/* 5. Photo URL & Presets */}
              <div className="form-group">
                <label className="form-label">Photographic Evidence Attachment *</label>
                <input
                  type="text"
                  required
                  className="form-control"
                  placeholder="Photo image URL..."
                  value={punchForm.photo_url}
                  onChange={(e) => setPunchForm({ ...punchForm, photo_url: e.target.value })}
                  style={{ marginBottom: '8px' }}
                />

                {/* Quick Presets */}
                <div style={{ display: 'flex', gap: '8px', overflowX: 'auto', paddingBottom: '4px' }}>
                  {photoPresets.map((p, idx) => (
                    <button
                      key={idx}
                      type="button"
                      onClick={() => setPunchForm({ ...punchForm, photo_url: p.url })}
                      className="btn"
                      style={{
                        padding: '4px 8px',
                        fontSize: '0.72rem',
                        backgroundColor: punchForm.photo_url === p.url ? 'rgba(6, 182, 212, 0.2)' : 'rgba(255,255,255,0.05)',
                        border: `1px solid ${punchForm.photo_url === p.url ? '#06b6d4' : 'rgba(255,255,255,0.1)'}`,
                        color: punchForm.photo_url === p.url ? '#67e8f9' : 'var(--text-secondary)'
                      }}
                    >
                      📷 {p.title}
                    </button>
                  ))}
                </div>
              </div>

              {/* 6. Corrective Action */}
              <div className="form-group">
                <label className="form-label">Immediate Action Taken *</label>
                <input
                  type="text"
                  required
                  className="form-control"
                  value={punchForm.corrective_action}
                  onChange={(e) => setPunchForm({ ...punchForm, corrective_action: e.target.value })}
                />
              </div>

              {/* Submit Buttons */}
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '10px' }}>
                <button type="button" onClick={() => setShowNewPunchModal(false)} className="btn btn-secondary">
                  Cancel
                </button>
                <button
                  type="submit"
                  className="btn"
                  style={{
                    backgroundColor: punchForm.color_type === 'RED' ? '#ef4444' : (punchForm.color_type === 'YELLOW' ? '#f59e0b' : '#10b981'),
                    color: '#fff',
                    fontWeight: 700
                  }}
                >
                  Save {punchForm.color_type} Safety Punch
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL: PHOTO FULLSCREEN PREVIEW                           */}
      {/* ========================================================= */}
      {previewPhoto && (
        <div className="modal-overlay" onClick={() => setPreviewPhoto(null)}>
          <div className="modal-content" style={{ maxWidth: '650px', padding: '0', overflow: 'hidden' }} onClick={(e) => e.stopPropagation()}>
            <div style={{ position: 'relative' }}>
              <img
                src={previewPhoto.photo_url}
                alt="Evidence"
                style={{ width: '100%', height: '340px', objectFit: 'cover' }}
              />
              <button
                onClick={() => setPreviewPhoto(null)}
                style={{
                  position: 'absolute',
                  top: '12px',
                  right: '12px',
                  background: 'rgba(0,0,0,0.6)',
                  border: 'none',
                  color: '#fff',
                  borderRadius: '50%',
                  width: '32px',
                  height: '32px',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontWeight: 'bold'
                }}
              >
                ✕
              </button>
            </div>
            <div style={{ padding: '16px 20px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                <span style={{ fontSize: '0.8rem', fontWeight: 800, color: 'var(--accent-cyan)' }}>
                  Photographic Evidence • {previewPhoto.punch_code}
                </span>
                <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{previewPhoto.zone}</span>
              </div>
              <p style={{ fontSize: '0.85rem', color: '#fff', margin: 0 }}>
                {previewPhoto.reason}
              </p>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL: CREATE WORK PERMIT                                 */}
      {/* ========================================================= */}
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
