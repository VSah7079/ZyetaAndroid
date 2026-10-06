import React, { useState, useEffect } from 'react';
import { 
  DoorOpen, 
  QrCode, 
  Search, 
  ArrowUpRight, 
  ArrowDownRight, 
  CheckCircle, 
  AlertTriangle, 
  Users, 
  Clock, 
  ShieldCheck,
  RefreshCw
} from 'lucide-react';
import { api } from '../services/api';
import { useAuth } from '../context/AuthContext';

export const GateOperations = ({ onOpenScanner }) => {
  const { user } = useAuth();
  const [currentlyInside, setCurrentlyInside] = useState([]);
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTx, setSearchTx] = useState('');
  const [selectedGateFilter, setSelectedGateFilter] = useState('');
  const [selectedMovementFilter, setSelectedMovementFilter] = useState('');

  // Manual Quick Verification State
  const [manualCode, setManualCode] = useState('');
  const [verifyData, setVerifyData] = useState(null);
  const [verifyError, setVerifyError] = useState('');
  const [actionSuccess, setActionSuccess] = useState('');
  const [selectedGate, setSelectedGate] = useState(1);

  const fetchGateData = async () => {
    try {
      const [insideRes, txRes] = await Promise.all([
        api.getCurrentlyInside(),
        api.getGateTransactions({
          search: searchTx,
          gate_id: selectedGateFilter,
          movement_type: selectedMovementFilter
        })
      ]);

      if (insideRes.success) setCurrentlyInside(insideRes.data || []);
      if (txRes.success) setTransactions(txRes.data || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchGateData();
    const interval = setInterval(fetchGateData, 6000);
    return () => clearInterval(interval);
  }, [searchTx, selectedGateFilter, selectedMovementFilter]);

  const handleManualLookup = async () => {
    if (!manualCode) return;
    setVerifyError('');
    setActionSuccess('');
    setVerifyData(null);
    try {
      const res = await api.verifyQR(manualCode);
      if (res.success) {
        setVerifyData(res);
      }
    } catch (err) {
      setVerifyError(err.message || 'Lookup failed. Code not found.');
    }
  };

  const handleRecordMovement = async (movementType) => {
    if (!verifyData || !verifyData.data) return;
    setVerifyError('');
    try {
      const res = await api.recordGateMovement({
        entity_type: verifyData.entity_type,
        entity_id: verifyData.data.id,
        movement_type: movementType,
        gate_id: selectedGate,
        verification_method: 'MANUAL_LOOKUP',
        remarks: verifyData.compliance_warnings?.length ? verifyData.compliance_warnings.join('; ') : 'Manual Gate Clearance'
      });

      if (res.success) {
        setActionSuccess(`Success: ${movementType} recorded for ${verifyData.data.full_name || verifyData.data.visitor_name}`);
        fetchGateData();
        setTimeout(() => {
          setVerifyData(null);
          setManualCode('');
          setActionSuccess('');
        }, 2000);
      }
    } catch (err) {
      setVerifyError(err.message || 'Failed to record gate transaction');
    }
  };

  return (
    <div className="page-container">
      {/* Top Banner */}
      <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        flexWrap: 'wrap',
        gap: '14px',
        marginBottom: '20px',
        background: 'linear-gradient(135deg, rgba(16, 185, 129, 0.15), rgba(6, 182, 212, 0.08))',
        border: '1px solid rgba(16, 185, 129, 0.25)',
        padding: '18px 20px',
        borderRadius: 'var(--radius-lg)'
      }}>
        <div>
          <h2 style={{ fontSize: 'clamp(1.1rem, 2.2vw, 1.4rem)', fontWeight: 800, color: '#fff', display: 'flex', alignItems: 'center', gap: '10px', flexWrap: 'wrap' }}>
            <DoorOpen size={22} color="#34d399" />
            <span>Site Gate Access & Security Command</span>
          </h2>
          <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
            Real-time biometric/QR validation, presence state enforcement & duplicate entry prevention
          </p>
        </div>

        <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
          <button onClick={onOpenScanner} className="btn btn-primary" style={{ padding: '8px 16px', fontSize: '0.85rem' }}>
            <QrCode size={16} />
            <span>Launch Camera Scanner</span>
          </button>
          <button onClick={fetchGateData} className="btn btn-secondary" title="Refresh Live Data">
            <RefreshCw size={16} />
          </button>
        </div>
      </div>

      {/* Manual Quick Access Terminal Box */}
      <div className="glass-panel" style={{ padding: '18px', marginBottom: '20px' }}>
        <h4 style={{ fontSize: '0.92rem', fontWeight: 700, color: '#fff', marginBottom: '14px', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <ShieldCheck size={18} color="var(--accent-primary)" />
          <span>Security Gate Terminal — Manual Verification & Override</span>
        </h4>

        <div className="gate-terminal-grid">
          <div>
            <label className="form-label">Gate Station</label>
            <select
              className="form-control"
              value={selectedGate}
              onChange={(e) => setSelectedGate(Number(e.target.value))}
            >
              <option value={1}>Main Security Gate 1</option>
              <option value={2}>Material Gate 2</option>
              <option value={3}>Turnstile Gate 3</option>
            </select>
          </div>

          <div>
            <label className="form-label">Enter Employee ID / Aadhaar / Pass Code</label>
            <input
              type="text"
              className="form-control"
              placeholder="e.g. EMP-101, EMP-103, VIS-2026-101..."
              value={manualCode}
              onChange={(e) => setManualCode(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleManualLookup()}
            />
          </div>

          <button onClick={handleManualLookup} className="btn btn-primary" style={{ height: '42px', padding: '0 20px' }}>
            Lookup & Validate
          </button>
        </div>

        {/* Quick Test Presets */}
        <div style={{ display: 'flex', gap: '8px', marginTop: '12px', flexWrap: 'wrap', alignItems: 'center' }}>
          <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)', fontWeight: 700, textTransform: 'uppercase' }}>Fast Presets:</span>
          {[
            { label: '👷 EMP-101 (Worker)', code: 'EMP-101' },
            { label: '⚠️ EMP-102 (Flagged)', code: 'EMP-102' },
            { label: '👤 VIS-8801 (Visitor)', code: 'VIS-8801' },
            { label: '📦 DC-2026-4401 (Material DC)', code: 'DC-2026-4401' },
            { label: '🚗 KA 04 E 9921 (Truck)', code: 'KA 04 E 9921' },
            { label: '📋 PTW-2026-001 (Hot Work)', code: 'PTW-2026-001' },
          ].map((preset) => (
            <button
              key={preset.code}
              type="button"
              onClick={() => {
                setManualCode(preset.code);
                api.verifyQR(preset.code).then(res => {
                  if (res.success) setVerifyData(res);
                }).catch(err => setVerifyError(err.message));
              }}
              style={{
                fontSize: '0.75rem',
                padding: '4px 10px',
                borderRadius: '20px',
                backgroundColor: 'rgba(255, 255, 255, 0.08)',
                border: '1px solid rgba(255, 255, 255, 0.15)',
                color: '#fff',
                cursor: 'pointer',
                fontWeight: 600
              }}
            >
              {preset.label}
            </button>
          ))}
        </div>

        {/* Error / Success feedback */}
        {verifyError && (
          <div style={{ marginTop: '12px', padding: '10px 14px', background: 'rgba(244, 63, 94, 0.15)', border: '1px solid rgba(244, 63, 94, 0.3)', borderRadius: 'var(--radius-md)', color: '#fb7185', fontSize: '0.85rem' }}>
            ⚠️ {verifyError}
          </div>
        )}
        {actionSuccess && (
          <div style={{ marginTop: '12px', padding: '10px 14px', background: 'rgba(16, 185, 129, 0.15)', border: '1px solid rgba(16, 185, 129, 0.3)', borderRadius: 'var(--radius-md)', color: '#34d399', fontSize: '0.85rem', fontWeight: 700 }}>
            ✅ {actionSuccess}
          </div>
        )}

        {/* Verification Result Card */}
        {verifyData && (
          <div style={{ marginTop: '16px', padding: '16px', background: 'rgba(0,0,0,0.3)', borderRadius: 'var(--radius-md)', border: '1px solid var(--border-color)', display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '16px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
              <img
                src={verifyData.data.profile_photo || verifyData.data.photo_url || 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'}
                alt="Entity"
                style={{ width: '56px', height: '56px', borderRadius: '10px', objectFit: 'cover' }}
              />
              <div>
                <h5 style={{ fontSize: '1rem', fontWeight: 700, color: '#fff' }}>
                  {verifyData.data.full_name || verifyData.data.visitor_name}
                </h5>
                <p style={{ fontSize: '0.78rem', color: '#38bdf8' }}>
                  {verifyData.data.employee_id || verifyData.data.pass_code} • {verifyData.data.designation || 'Visitor'}
                </p>
                <p style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>
                  🏢 {verifyData.data.vendor_name || verifyData.data.company || 'Direct'}
                </p>
              </div>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
              <div style={{ textAlign: 'right' }}>
                <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)', display: 'block' }}>Current State:</span>
                <span className={`badge ${verifyData.is_currently_inside ? 'badge-inside' : 'badge-absent'}`}>
                  {verifyData.is_currently_inside ? 'INSIDE' : 'OUTSIDE'}
                </span>
              </div>

              <button
                onClick={() => handleRecordMovement('ENTRY')}
                className="btn btn-success"
                disabled={verifyData.is_currently_inside}
                style={{ padding: '8px 16px', fontSize: '0.85rem' }}
              >
                Allow Entry
              </button>

              <button
                onClick={() => handleRecordMovement('EXIT')}
                className="btn btn-danger"
                disabled={!verifyData.is_currently_inside}
                style={{ padding: '8px 16px', fontSize: '0.85rem' }}
              >
                Allow Exit
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Two Column Layout: Currently Inside Stream & Historical Transaction Log */}
      <div className="gate-live-grid">
        {/* Left: Currently Inside List */}
        <div className="glass-panel" style={{ padding: '20px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '14px' }}>
            <h4 style={{ fontSize: '0.95rem', fontWeight: 700, color: '#fff', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span className="pulse-dot" />
              <span>Personnel On Site ({currentlyInside.length})</span>
            </h4>
          </div>

          <div style={{ maxHeight: '420px', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '8px' }}>
            {currentlyInside.length === 0 ? (
              <p style={{ padding: '20px', textAlign: 'center', color: 'var(--text-muted)', fontSize: '0.8rem' }}>
                No active personnel inside facility.
              </p>
            ) : (
              currentlyInside.map((person) => (
                <div
                  key={`${person.type}-${person.id}`}
                  style={{
                    padding: '10px 12px',
                    background: 'rgba(0,0,0,0.25)',
                    borderRadius: 'var(--radius-md)',
                    border: '1px solid rgba(255,255,255,0.04)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between'
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <img
                      src={person.photo || 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'}
                      alt="avatar"
                      style={{ width: '36px', height: '36px', borderRadius: '8px', objectFit: 'cover' }}
                    />
                    <div>
                      <p style={{ fontSize: '0.82rem', fontWeight: 700, color: '#fff' }}>{person.full_name}</p>
                      <p style={{ fontSize: '0.7rem', color: 'var(--text-secondary)' }}>
                        {person.entity_code} • {person.designation}
                      </p>
                    </div>
                  </div>

                  <div style={{ textAlign: 'right' }}>
                    <span className="badge badge-inside" style={{ fontSize: '0.62rem' }}>{person.type}</span>
                    <span style={{ fontSize: '0.65rem', color: 'var(--text-muted)', display: 'block', marginTop: '3px' }}>
                      In: {person.entry_time ? new Date(person.entry_time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : 'Today'}
                    </span>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Right: Movement Audit Transactions */}
        <div className="glass-panel" style={{ padding: '20px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '14px', flexWrap: 'wrap', gap: '10px' }}>
            <h4 style={{ fontSize: '0.95rem', fontWeight: 700, color: '#fff' }}>Gate Movement Logs</h4>
            
            <div style={{ display: 'flex', gap: '8px' }}>
              <select
                className="form-control"
                value={selectedMovementFilter}
                onChange={(e) => setSelectedMovementFilter(e.target.value)}
                style={{ fontSize: '0.75rem', padding: '4px 8px', width: '110px' }}
              >
                <option value="">All Types</option>
                <option value="ENTRY">ENTRY</option>
                <option value="EXIT">EXIT</option>
              </select>

              <input
                type="text"
                placeholder="Search logs..."
                className="form-control"
                value={searchTx}
                onChange={(e) => setSearchTx(e.target.value)}
                style={{ fontSize: '0.75rem', padding: '4px 8px', width: '130px' }}
              />
            </div>
          </div>

          <div className="table-container" style={{ maxHeight: '420px', overflowY: 'auto' }}>
            <table className="custom-table" style={{ fontSize: '0.78rem' }}>
              <thead>
                <tr>
                  <th>Time</th>
                  <th>Name / ID</th>
                  <th>Type</th>
                  <th>Gate</th>
                  <th>Officer</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {transactions.map((tx) => (
                  <tr key={tx.id}>
                    <td style={{ color: 'var(--text-muted)', whiteSpace: 'nowrap' }}>
                      {new Date(tx.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                    </td>
                    <td>
                      <span style={{ fontWeight: 700, color: '#fff' }}>{tx.entity_name}</span>
                      <span className="mono" style={{ fontSize: '0.68rem', color: '#a5b4fc', display: 'block' }}>{tx.entity_code}</span>
                    </td>
                    <td>
                      <span className={`badge ${tx.movement_type === 'ENTRY' ? 'badge-active' : 'badge-denied'}`}>
                        {tx.movement_type}
                      </span>
                    </td>
                    <td>{tx.gate_name}</td>
                    <td style={{ color: 'var(--text-secondary)' }}>{tx.security_user_name}</td>
                    <td><span className="badge badge-active">{tx.status}</span></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
};
