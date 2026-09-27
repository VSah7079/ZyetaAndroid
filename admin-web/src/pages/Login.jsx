import React, { useState } from 'react';
import { Shield, Lock, User, ArrowRight, ShieldCheck, CheckCircle } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

export const Login = () => {
  const { login } = useAuth();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleLogin = async (e) => {
    if (e) e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await login(username, password);
    } catch (err) {
      setError(err.message || 'Login failed. Please verify credentials.');
    } finally {
      setLoading(false);
    }
  };

  const quickLogin = async (u, p) => {
    setUsername(u);
    setPassword(p);
    setError('');
    setLoading(true);
    try {
      await login(u, p);
    } catch (err) {
      setError(err.message || 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{
      minHeight: '100vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      background: 'radial-gradient(circle at top, #1e1b4b 0%, #0b0f19 70%)',
      padding: '20px'
    }}>
      <div style={{ maxWidth: '440px', width: '100%' }}>
        {/* Brand Icon & Heading */}
        <div style={{ textAlign: 'center', marginBottom: '28px' }}>
          <img
            src="/app_logo.jpg"
            alt="ZyetaGate Logo"
            style={{
              width: '72px',
              height: '72px',
              borderRadius: '20px',
              boxShadow: '0 8px 30px rgba(99, 102, 241, 0.4), 0 0 15px rgba(6, 182, 212, 0.3)',
              marginBottom: '14px',
              border: '1px solid rgba(255, 255, 255, 0.15)',
              objectFit: 'cover'
            }}
          />
          <h1 style={{ fontSize: '1.6rem', fontWeight: 800, color: '#fff' }}>
            Zyeta<span style={{ color: 'var(--accent-cyan)' }}>Gate</span> OS
          </h1>
          <p style={{ fontSize: '0.82rem', color: 'var(--text-secondary)', marginTop: '4px' }}>
            Advanced Workforce, Vendor & Gate Management System
          </p>
        </div>

        {/* Login Box */}
        <div className="glass-panel" style={{ padding: '28px', marginBottom: '20px' }}>
          {error && (
            <div style={{
              padding: '12px 14px',
              background: 'rgba(244, 63, 94, 0.15)',
              border: '1px solid rgba(244, 63, 94, 0.3)',
              borderRadius: 'var(--radius-md)',
              color: '#fb7185',
              fontSize: '0.85rem',
              marginBottom: '16px'
            }}>
              ⚠️ {error}
            </div>
          )}

          <form onSubmit={handleLogin}>
            <div className="form-group">
              <label className="form-label">Username or Email</label>
              <div style={{ position: 'relative' }}>
                <User size={16} color="var(--text-muted)" style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)' }} />
                <input
                  type="text"
                  required
                  className="form-control"
                  placeholder="e.g. superadmin, admin"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  style={{ paddingLeft: '36px' }}
                />
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">Password</label>
              <div style={{ position: 'relative' }}>
                <Lock size={16} color="var(--text-muted)" style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)' }} />
                <input
                  type="password"
                  required
                  className="form-control"
                  placeholder="••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  style={{ paddingLeft: '36px' }}
                />
              </div>
            </div>

            <button
              type="submit"
              className="btn btn-primary"
              style={{ width: '100%', padding: '12px', fontSize: '0.95rem', marginTop: '10px' }}
              disabled={loading}
            >
              <span>{loading ? 'Authenticating...' : 'Sign In to Workspace'}</span>
              <ArrowRight size={16} />
            </button>
          </form>
        </div>

        {/* Quick 1-Click Role Logins */}
        <div className="glass-panel" style={{ padding: '20px' }}>
          <p style={{ fontSize: '0.75rem', fontWeight: 700, color: '#a5b4fc', textTransform: 'uppercase', letterSpacing: '0.5px', marginBottom: '12px', textAlign: 'center' }}>
            Quick 1-Click Demo Logins
          </p>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
            <button
              type="button"
              onClick={() => quickLogin('superadmin', 'admin123')}
              className="btn btn-secondary"
              style={{ fontSize: '0.75rem', padding: '8px', textAlign: 'center' }}
            >
              👑 Super Admin
            </button>
            <button
              type="button"
              onClick={() => quickLogin('admin', 'admin123')}
              className="btn btn-secondary"
              style={{ fontSize: '0.75rem', padding: '8px', textAlign: 'center' }}
            >
              🏢 Site Admin
            </button>
            <button
              type="button"
              onClick={() => quickLogin('vendor_infra', 'vendor123')}
              className="btn btn-secondary"
              style={{ fontSize: '0.75rem', padding: '8px', textAlign: 'center' }}
            >
              🏗️ Vendor Portal
            </button>
            <button
              type="button"
              onClick={() => quickLogin('security_gate1', 'security123')}
              className="btn btn-secondary"
              style={{ fontSize: '0.75rem', padding: '8px', textAlign: 'center' }}
            >
              🛡️ Security Officer
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
