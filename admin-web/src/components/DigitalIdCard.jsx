import React from 'react';
import { X, Printer, ShieldCheck, Heart, Phone, Building, Calendar } from 'lucide-react';

export const DigitalIdCard = ({ employee, isOpen, onClose }) => {
  if (!isOpen || !employee) return null;

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content" style={{ maxWidth: '440px', background: '#0b0f19' }}>
        {/* Header */}
        <div style={{
          padding: '14px 18px',
          borderBottom: '1px solid var(--border-color)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between'
        }}>
          <h3 style={{ fontSize: '0.95rem', fontWeight: 700, color: '#fff' }}>Digital Site ID Card</h3>
          <div style={{ display: 'flex', gap: '8px' }}>
            <button onClick={handlePrint} className="btn btn-primary" style={{ padding: '5px 10px', fontSize: '0.75rem' }}>
              <Printer size={14} />
              <span>Print ID</span>
            </button>
            <button onClick={onClose} style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}>
              <X size={18} />
            </button>
          </div>
        </div>

        {/* Physical ID Card Preview Container */}
        <div style={{ padding: '16px 10px', display: 'flex', justifyContent: 'center' }}>
          <div
            id="printable-id-card"
            style={{
              width: '100%',
              maxWidth: '320px',
              height: '500px',
              background: 'linear-gradient(180deg, #1e1b4b 0%, #0f172a 100%)',
              borderRadius: '16px',
              border: '2px solid rgba(99, 102, 241, 0.4)',
              boxShadow: '0 12px 30px rgba(0, 0, 0, 0.6), 0 0 20px rgba(99, 102, 241, 0.2)',
              position: 'relative',
              overflow: 'hidden',
              display: 'flex',
              flexDirection: 'column',
              color: '#fff',
              padding: '18px'
            }}
          >
            {/* Lanyard Hole Mockup */}
            <div style={{
              width: '50px',
              height: '8px',
              background: '#0b0f19',
              borderRadius: '4px',
              margin: '0 auto 12px auto',
              border: '1px solid rgba(255, 255, 255, 0.1)'
            }} />

            {/* Header / Org */}
            <div style={{ textAlign: 'center', marginBottom: '14px' }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '6px' }}>
                <ShieldCheck size={18} color="#06b6d4" />
                <span style={{ fontSize: '0.9rem', fontWeight: 800, letterSpacing: '0.5px' }}>ZYETA WORKFORCE</span>
              </div>
              <p style={{ fontSize: '0.62rem', color: '#94a3b8', textTransform: 'uppercase', letterSpacing: '1px' }}>
                OFFICIAL SITE ACCESS BADGE
              </p>
            </div>

            {/* Photo & Hologram */}
            <div style={{ display: 'flex', justifyContent: 'center', marginBottom: '12px', position: 'relative' }}>
              <img
                src={employee.profile_photo || 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'}
                alt="Employee"
                style={{
                  width: '95px',
                  height: '95px',
                  borderRadius: '50%',
                  objectFit: 'cover',
                  border: '3px solid #6366f1',
                  boxShadow: '0 4px 10px rgba(0, 0, 0, 0.4)'
                }}
              />
              <span style={{
                position: 'absolute',
                bottom: '-4px',
                background: '#10b981',
                color: '#fff',
                fontSize: '0.6rem',
                fontWeight: 800,
                padding: '2px 8px',
                borderRadius: '10px'
              }}>
                {employee.employee_type || 'CONTRACTOR'}
              </span>
            </div>

            {/* Name & ID */}
            <div style={{ textAlign: 'center', marginBottom: '10px' }}>
              <h4 style={{ fontSize: '1.05rem', fontWeight: 800, color: '#fff' }}>{employee.full_name}</h4>
              <p style={{ fontSize: '0.8rem', color: '#38bdf8', fontWeight: 700 }}>{employee.designation}</p>
              <span className="mono" style={{ fontSize: '0.75rem', color: '#cbd5e1', fontWeight: 600 }}>
                ID: {employee.employee_id}
              </span>
            </div>

            {/* Key Metadata Table */}
            <div style={{
              background: 'rgba(0, 0, 0, 0.3)',
              borderRadius: '8px',
              padding: '8px 10px',
              fontSize: '0.7rem',
              display: 'flex',
              flexDirection: 'column',
              gap: '4px',
              marginBottom: '12px'
            }}>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ color: '#94a3b8' }}>Vendor:</span>
                <span style={{ fontWeight: 600, color: '#fff' }}>{employee.vendor_name || 'Direct'}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ color: '#94a3b8' }}>Blood Group:</span>
                <span style={{ fontWeight: 700, color: '#f43f5e' }}>{employee.blood_group || 'O+'}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ color: '#94a3b8' }}>Emergency:</span>
                <span style={{ fontWeight: 600, color: '#e2e8f0' }}>{employee.emergency_phone || employee.mobile}</span>
              </div>
            </div>

            {/* QR Code */}
            <div style={{ marginTop: 'auto', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '12px' }}>
              {employee.qr_code_data ? (
                <img
                  src={employee.qr_code_data}
                  alt="QR Code"
                  style={{
                    width: '64px',
                    height: '64px',
                    backgroundColor: '#fff',
                    padding: '3px',
                    borderRadius: '6px'
                  }}
                />
              ) : (
                <div style={{ width: '64px', height: '64px', background: '#334155', borderRadius: '6px' }} />
              )}
              <div style={{ fontSize: '0.65rem', color: '#94a3b8' }}>
                <p style={{ fontWeight: 600, color: '#34d399' }}>● VERIFIED BADGE</p>
                <p>Scan at any site gate</p>
                <p className="mono">BLR-CAMPUS-01</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
