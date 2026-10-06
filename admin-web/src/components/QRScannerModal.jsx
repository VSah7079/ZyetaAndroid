import React, { useState } from 'react';
import { X, QrCode, ShieldCheck, ShieldAlert, AlertTriangle, CheckCircle, ArrowRight, User, Clock, Building } from 'lucide-react';
import { api } from '../services/api';

export const QRScannerModal = ({ isOpen, onClose, onMovementRecorded }) => {
  const [scanInput, setScanInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [verifyResult, setVerifyResult] = useState(null);
  const [errorMsg, setErrorMsg] = useState('');
  const [actionSuccessMsg, setActionSuccessMsg] = useState('');
  const [selectedGate, setSelectedGate] = useState(1);

  if (!isOpen) return null;

  const handleVerify = async (codeToVerify) => {
    const code = codeToVerify || scanInput;
    if (!code) return;

    setLoading(true);
    setErrorMsg('');
    setActionSuccessMsg('');
    setVerifyResult(null);

    try {
      const res = await api.verifyQR(code);
      if (res.success) {
        setVerifyResult(res);
      }
    } catch (err) {
      setErrorMsg(err.message || 'Verification failed. QR Code not found or invalid.');
    } finally {
      setLoading(false);
    }
  };

  const handleExecuteMovement = async (movementType) => {
    if (!verifyResult || !verifyResult.data) return;

    setLoading(true);
    setErrorMsg('');
    try {
      const payload = {
        entity_type: verifyResult.entity_type,
        entity_id: verifyResult.data.id,
        movement_type: movementType, // ENTRY or EXIT
        gate_id: selectedGate,
        verification_method: 'QR_SCAN',
        remarks: verifyResult.compliance_warnings?.length ? verifyResult.compliance_warnings.join('; ') : 'Normal Gate Scan'
      };

      const res = await api.recordGateMovement(payload);
      if (res.success) {
        setActionSuccessMsg(`Gate ${movementType} recorded successfully for ${verifyResult.data.full_name || verifyResult.data.visitor_name}`);
        if (onMovementRecorded) onMovementRecorded();
        setTimeout(() => {
          setVerifyResult(null);
          setScanInput('');
          setActionSuccessMsg('');
        }, 2200);
      }
    } catch (err) {
      setErrorMsg(err.message || 'Movement recording failed');
    } finally {
      setLoading(false);
    }
  };

  const quickScanDemo = (empCode) => {
    setScanInput(empCode);
    handleVerify(empCode);
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content" style={{ maxWidth: '640px' }}>
        {/* Modal Header */}
        <div style={{
          padding: '16px 20px',
          borderBottom: '1px solid var(--border-color)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          background: 'rgba(15, 23, 42, 0.7)'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div style={{
              width: '32px',
              height: '32px',
              borderRadius: '8px',
              background: 'rgba(99, 102, 241, 0.2)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#818cf8'
            }}>
              <QrCode size={20} />
            </div>
            <div>
              <h3 style={{ fontSize: '1rem', fontWeight: 700, color: '#fff' }}>Security Gate QR Scanner</h3>
              <p style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>Real-time site access verification</p>
            </div>
          </div>

          <button
            onClick={onClose}
            style={{
              background: 'transparent',
              border: 'none',
              color: 'var(--text-muted)',
              cursor: 'pointer',
              padding: '6px'
            }}
          >
            <X size={20} />
          </button>
        </div>

        <div style={{ padding: '20px' }}>
          {/* Gate Selection & Scan Input */}
          <div className="grid-responsive-1-1" style={{ marginBottom: '16px' }}>
            <div>
              <label className="form-label">Active Gate</label>
              <select
                className="form-control"
                value={selectedGate}
                onChange={(e) => setSelectedGate(Number(e.target.value))}
              >
                <option value={1}>Main Gate 1</option>
                <option value={2}>Material Gate 2</option>
                <option value={3}>Turnstile Gate 3</option>
              </select>
            </div>

            <div>
              <label className="form-label">Scan QR / Employee ID / Pass Code</label>
              <div style={{ display: 'flex', gap: '8px' }}>
                <input
                  type="text"
                  className="form-control"
                  placeholder="e.g. EMP-101, VIS-2026-101..."
                  value={scanInput}
                  onChange={(e) => setScanInput(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && handleVerify()}
                  autoFocus
                />
                <button
                  onClick={() => handleVerify()}
                  className="btn btn-primary"
                  disabled={loading || !scanInput}
                >
                  Verify
                </button>
              </div>
            </div>
          </div>

          {/* Quick Demo Scan Buttons */}
          <div style={{ marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '6px', flexWrap: 'wrap' }}>
            <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>Quick Presets:</span>
            <button
              onClick={() => quickScanDemo('EMP-101')}
              className="btn btn-secondary"
              style={{ fontSize: '0.72rem', padding: '3px 8px' }}
            >
              EMP-101 (Inside)
            </button>
            <button
              onClick={() => quickScanDemo('EMP-104')}
              className="btn btn-secondary"
              style={{ fontSize: '0.72rem', padding: '3px 8px' }}
            >
              EMP-104 (Expired PVC)
            </button>
            <button
              onClick={() => quickScanDemo('VIS-2026-101')}
              className="btn btn-secondary"
              style={{ fontSize: '0.72rem', padding: '3px 8px' }}
            >
              VIS-101 (Visitor)
            </button>
          </div>

          {/* Error Message */}
          {errorMsg && (
            <div style={{
              background: 'rgba(244, 63, 94, 0.12)',
              border: '1px solid rgba(244, 63, 94, 0.3)',
              padding: '12px 16px',
              borderRadius: 'var(--radius-md)',
              color: '#fb7185',
              fontSize: '0.85rem',
              display: 'flex',
              alignItems: 'center',
              gap: '10px',
              marginBottom: '16px'
            }}>
              <AlertTriangle size={18} />
              <span>{errorMsg}</span>
            </div>
          )}

          {/* Action Success Message */}
          {actionSuccessMsg && (
            <div style={{
              background: 'rgba(16, 185, 129, 0.12)',
              border: '1px solid rgba(16, 185, 129, 0.3)',
              padding: '14px 18px',
              borderRadius: 'var(--radius-md)',
              color: '#34d399',
              fontSize: '0.9rem',
              fontWeight: 700,
              display: 'flex',
              alignItems: 'center',
              gap: '10px',
              marginBottom: '16px'
            }}>
              <CheckCircle size={22} />
              <span>{actionSuccessMsg}</span>
            </div>
          )}

          {/* Verification Result Card */}
          {verifyResult && (
            <div className="glass-panel" style={{ padding: '18px', marginBottom: '16px' }}>
              <div style={{ display: 'flex', gap: '16px', alignItems: 'flex-start' }}>
                {/* Profile Photo */}
                <img
                  src={verifyResult.data.profile_photo || verifyResult.data.photo_url || 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'}
                  alt="Profile"
                  style={{
                    width: '80px',
                    height: '80px',
                    borderRadius: '12px',
                    objectFit: 'cover',
                    border: '2px solid rgba(255, 255, 255, 0.15)'
                  }}
                />

                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '4px' }}>
                    <h4 style={{ fontSize: '1.1rem', fontWeight: 700, color: '#fff' }}>
                      {verifyResult.data.full_name || verifyResult.data.visitor_name}
                    </h4>
                    <span className={`badge ${
                      verifyResult.verification_status === 'ALLOW' ? 'badge-allow' :
                      verifyResult.verification_status === 'FLAGGED' ? 'badge-flagged' : 'badge-denied'
                    }`}>
                      {verifyResult.verification_status}
                    </span>
                  </div>

                  <p style={{ fontSize: '0.8rem', color: '#a5b4fc', fontWeight: 600 }}>
                    {verifyResult.data.employee_id || verifyResult.data.pass_code} • {verifyResult.data.designation || 'Visitor'}
                  </p>
                  <p style={{ fontSize: '0.78rem', color: 'var(--text-secondary)' }}>
                    🏢 {verifyResult.data.vendor_name || verifyResult.data.company || 'Direct'}
                  </p>
                </div>
              </div>

              {/* Status & Compliance warnings */}
              {verifyResult.compliance_warnings && verifyResult.compliance_warnings.length > 0 && (
                <div style={{
                  marginTop: '12px',
                  background: 'rgba(245, 158, 11, 0.1)',
                  border: '1px solid rgba(245, 158, 11, 0.3)',
                  borderRadius: 'var(--radius-sm)',
                  padding: '8px 12px',
                  fontSize: '0.78rem',
                  color: '#fde047'
                }}>
                  ⚠️ <strong>Compliance Notice:</strong> {verifyResult.compliance_warnings.join(' ')}
                </div>
              )}

              {/* Active Permit Notice */}
              {verifyResult.active_permit && (
                <div style={{
                  marginTop: '8px',
                  background: 'rgba(99, 102, 241, 0.1)',
                  border: '1px solid rgba(99, 102, 241, 0.3)',
                  borderRadius: 'var(--radius-sm)',
                  padding: '8px 12px',
                  fontSize: '0.78rem',
                  color: '#c7d2fe'
                }}>
                  🛡️ <strong>Active Permit:</strong> {verifyResult.active_permit.permit_type} ({verifyResult.active_permit.permit_number})
                </div>
              )}

              {/* Current Presence State */}
              <div style={{
                marginTop: '14px',
                padding: '10px 14px',
                background: 'rgba(0, 0, 0, 0.3)',
                borderRadius: 'var(--radius-md)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between'
              }}>
                <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>Current Presence:</span>
                <span className={`badge ${verifyResult.is_currently_inside ? 'badge-inside' : 'badge-absent'}`}>
                  {verifyResult.is_currently_inside ? 'INSIDE FACILITY' : 'OUTSIDE FACILITY'}
                </span>
              </div>

              {/* Action Buttons */}
              <div className="grid-responsive-1-1" style={{ marginTop: '16px', gap: '10px' }}>
                <button
                  onClick={() => handleExecuteMovement('ENTRY')}
                  className="btn btn-success"
                  style={{ padding: '12px', fontSize: '0.9rem' }}
                  disabled={loading || verifyResult.is_currently_inside}
                >
                  <ArrowRight size={18} />
                  <span>ALLOW ENTRY</span>
                </button>

                <button
                  onClick={() => handleExecuteMovement('EXIT')}
                  className="btn btn-danger"
                  style={{ padding: '12px', fontSize: '0.9rem' }}
                  disabled={loading || !verifyResult.is_currently_inside}
                >
                  <LogOutOutlined size={18} />
                  <span>ALLOW EXIT</span>
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

const LogOutOutlined = ({ size = 18 }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
    <polyline points="16 17 21 12 16 7"></polyline>
    <line x1="21" y1="12" x2="9" y2="12"></line>
  </svg>
);
