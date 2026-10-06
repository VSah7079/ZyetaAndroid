import React, { useState, useEffect } from 'react';
import { 
  Users, 
  Building2, 
  DoorOpen, 
  Clock, 
  FileCheck, 
  Package, 
  UserCheck, 
  AlertTriangle,
  ArrowUpRight,
  ArrowDownRight,
  ShieldCheck,
  TrendingUp
} from 'lucide-react';
import { api } from '../services/api';
import { useAuth } from '../context/AuthContext';

export const Dashboard = ({ onNavigate, onOpenScanner }) => {
  const { user } = useAuth();
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);

  const fetchStats = async () => {
    try {
      const res = await api.getDashboardStats();
      if (res.success) {
        setStats(res.data);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchStats();
    const timer = setInterval(fetchStats, 8000);
    return () => clearInterval(timer);
  }, []);

  if (loading || !stats) {
    return (
      <div style={{ padding: '32px', textAlign: 'center', color: 'var(--text-secondary)' }}>
        <p>Loading Dashboard Telemetry...</p>
      </div>
    );
  }

  const { kpis, hourly_traffic, vendor_distribution, recent_activity } = stats;

  return (
    <div className="page-container">
      {/* Welcome Banner */}
      <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        flexWrap: 'wrap',
        gap: '14px',
        marginBottom: '20px',
        background: 'linear-gradient(135deg, rgba(99, 102, 241, 0.15), rgba(6, 182, 212, 0.08))',
        border: '1px solid rgba(99, 102, 241, 0.25)',
        padding: '18px 20px',
        borderRadius: 'var(--radius-lg)'
      }}>
        <div>
          <h2 style={{ fontSize: 'clamp(1.1rem, 2.2vw, 1.4rem)', fontWeight: 800, color: '#fff', marginBottom: '4px' }}>
            Welcome back, {user?.full_name || 'Administrator'}
          </h2>
          <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
            Site Operations & Workforce Access Control Center • {new Date().toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'short', day: 'numeric' })}
          </p>
        </div>

        <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
          <button onClick={onOpenScanner} className="btn btn-primary" style={{ fontSize: '0.85rem' }}>
            <DoorOpen size={16} />
            <span>Open Gate Scanner</span>
          </button>
          <button onClick={() => onNavigate('employees')} className="btn btn-secondary" style={{ fontSize: '0.85rem' }}>
            <Users size={16} />
            <span>Manage Workforce</span>
          </button>
        </div>
      </div>

      {/* KPI Cards Grid (PRD Section 7.1) */}
      <div className="grid-kpis-responsive">
        {/* Currently Inside */}
        <div className="glass-card" style={{ padding: '16px', borderLeft: '4px solid var(--accent-emerald)' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', fontWeight: 600 }}>CURRENTLY INSIDE</span>
            <div style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: '#10b981' }} className="pulse-dot" />
          </div>
          <h3 style={{ fontSize: '1.7rem', fontWeight: 800, color: '#fff' }}>{kpis.currently_inside}</h3>
          <p style={{ fontSize: '0.72rem', color: '#34d399', display: 'flex', alignItems: 'center', gap: '4px', marginTop: '4px' }}>
            <Users size={13} /> Active personnel on site
          </p>
        </div>

        {/* Today's Entries */}
        <div className="glass-card" style={{ padding: '16px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', fontWeight: 600 }}>TODAY'S ENTRIES</span>
            <ArrowUpRight size={18} color="var(--accent-cyan)" />
          </div>
          <h3 style={{ fontSize: '1.7rem', fontWeight: 800, color: '#fff' }}>{kpis.today_entries}</h3>
          <p style={{ fontSize: '0.72rem', color: 'var(--text-muted)', marginTop: '4px' }}>Gate Check-ins today</p>
        </div>

        {/* Today's Exits */}
        <div className="glass-card" style={{ padding: '16px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', fontWeight: 600 }}>TODAY'S EXITS</span>
            <ArrowDownRight size={18} color="var(--accent-rose)" />
          </div>
          <h3 style={{ fontSize: '1.7rem', fontWeight: 800, color: '#fff' }}>{kpis.today_exits}</h3>
          <p style={{ fontSize: '0.72rem', color: 'var(--text-muted)', marginTop: '4px' }}>Gate Check-outs today</p>
        </div>

        {/* Total Workforce */}
        <div className="glass-card" style={{ padding: '16px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', fontWeight: 600 }}>TOTAL WORKFORCE</span>
            <Users size={18} color="var(--accent-primary)" />
          </div>
          <h3 style={{ fontSize: '1.7rem', fontWeight: 800, color: '#fff' }}>{kpis.total_employees}</h3>
          <p style={{ fontSize: '0.72rem', color: '#a5b4fc', marginTop: '4px' }}>{kpis.active_employees} Active verified</p>
        </div>

        {/* Active Permits */}
        <div className="glass-card" style={{ padding: '16px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', fontWeight: 600 }}>SAFETY PERMITS</span>
            <FileCheck size={18} color="var(--accent-amber)" />
          </div>
          <h3 style={{ fontSize: '1.7rem', fontWeight: 800, color: '#fff' }}>{kpis.active_permits}</h3>
          <p style={{ fontSize: '0.72rem', color: '#fde047', marginTop: '4px' }}>{kpis.pending_permits} Pending approval</p>
        </div>

        {/* Expiring Compliance Alerts */}
        <div className="glass-card" style={{ padding: '16px', borderLeft: kpis.expiring_compliance_docs > 0 ? '4px solid var(--accent-amber)' : 'none' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', fontWeight: 600 }}>COMPLIANCE ALERTS</span>
            <AlertTriangle size={18} color="#f59e0b" />
          </div>
          <h3 style={{ fontSize: '1.7rem', fontWeight: 800, color: kpis.expiring_compliance_docs > 0 ? '#fbbf24' : '#fff' }}>
            {kpis.expiring_compliance_docs}
          </h3>
          <p style={{ fontSize: '0.72rem', color: '#fde047', marginTop: '4px' }}>PVC / Medical expiring</p>
        </div>
      </div>

      {/* Middle Grid: Traffic Distribution & Vendor Breakdown */}
      <div className="grid-responsive-2">
        {/* Hourly Gate Movement Traffic */}
        <div className="glass-panel" style={{ padding: '18px', overflow: 'hidden' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '8px', marginBottom: '16px' }}>
            <h4 style={{ fontSize: '0.92rem', fontWeight: 700, color: '#fff', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <TrendingUp size={18} color="var(--accent-cyan)" />
              <span>Today's Gate Movement Flow (Hourly)</span>
            </h4>
            <div style={{ display: 'flex', gap: '12px', fontSize: '0.72rem' }}>
              <span style={{ display: 'flex', alignItems: 'center', gap: '4px', color: '#38bdf8' }}>
                <span style={{ width: '10px', height: '10px', backgroundColor: '#38bdf8', borderRadius: '2px' }} /> Inward Entries
              </span>
              <span style={{ display: 'flex', alignItems: 'center', gap: '4px', color: '#fb7185' }}>
                <span style={{ width: '10px', height: '10px', backgroundColor: '#fb7185', borderRadius: '2px' }} /> Outward Exits
              </span>
            </div>
          </div>

          {/* Simple Visual Bar Chart */}
          <div style={{ overflowX: 'auto', paddingBottom: '6px' }}>
            <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', height: '150px', minWidth: '320px', padding: '10px 0', borderBottom: '1px solid var(--border-color)' }}>
              {hourly_traffic.map((h) => {
              const maxVal = Math.max(1, ...hourly_traffic.map(x => Math.max(x.entries, x.exits)));
              const entryHeight = (h.entries / maxVal) * 120;
              const exitHeight = (h.exits / maxVal) * 120;
              return (
                <div key={h.hour} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '6px', flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'flex-end', gap: '4px', height: '120px' }}>
                    <div
                      title={`Entries: ${h.entries}`}
                      style={{
                        width: '14px',
                        height: `${Math.max(4, entryHeight)}px`,
                        backgroundColor: '#38bdf8',
                        borderRadius: '4px 4px 0 0',
                        transition: 'height 0.3s ease'
                      }}
                    />
                    <div
                      title={`Exits: ${h.exits}`}
                      style={{
                        width: '14px',
                        height: `${Math.max(4, exitHeight)}px`,
                        backgroundColor: '#fb7185',
                        borderRadius: '4px 4px 0 0',
                        transition: 'height 0.3s ease'
                      }}
                    />
                  </div>
                  <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>{h.hour}</span>
                </div>
              );
            })}
            </div>
          </div>
        </div>

        {/* Vendor Workforce Breakdown */}
        <div className="glass-panel" style={{ padding: '20px' }}>
          <h4 style={{ fontSize: '0.95rem', fontWeight: 700, color: '#fff', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <Building2 size={18} color="var(--accent-primary)" />
            <span>Contractor Breakdown</span>
          </h4>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            {vendor_distribution.map((v) => (
              <div key={v.vendor_name} style={{ background: 'rgba(0,0,0,0.2)', padding: '10px 12px', borderRadius: 'var(--radius-md)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '4px' }}>
                  <span style={{ fontSize: '0.8rem', fontWeight: 600, color: '#fff' }}>{v.vendor_name}</span>
                  <span style={{ fontSize: '0.75rem', color: '#34d399', fontWeight: 700 }}>{v.inside_now} Inside</span>
                </div>
                <div style={{ width: '100%', height: '6px', backgroundColor: '#1e293b', borderRadius: '3px', overflow: 'hidden' }}>
                  <div
                    style={{
                      width: `${v.total_workforce > 0 ? (v.inside_now / v.total_workforce) * 100 : 0}%`,
                      height: '100%',
                      background: 'linear-gradient(90deg, #6366f1, #06b6d4)'
                    }}
                  />
                </div>
                <span style={{ fontSize: '0.68rem', color: 'var(--text-muted)', marginTop: '3px', display: 'block' }}>
                  Total registered: {v.total_workforce}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Recent Gate Activity Stream */}
      <div className="glass-panel" style={{ padding: '20px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '16px' }}>
          <h4 style={{ fontSize: '0.95rem', fontWeight: 700, color: '#fff', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <DoorOpen size={18} color="var(--accent-emerald)" />
            <span>Recent Gate Activity Stream</span>
          </h4>
          <button onClick={() => onNavigate('gate')} className="btn btn-secondary" style={{ fontSize: '0.75rem', padding: '4px 10px' }}>
            View Full Gate Log
          </button>
        </div>

        <div className="table-container">
          <table className="custom-table">
            <thead>
              <tr>
                <th>Code</th>
                <th>Entity Name</th>
                <th>Role / Desig</th>
                <th>Contractor</th>
                <th>Movement</th>
                <th>Gate</th>
                <th>Time</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {recent_activity.map((tx) => (
                <tr key={tx.id}>
                  <td className="mono" style={{ fontSize: '0.75rem', color: '#94a3b8' }}>{tx.entity_code}</td>
                  <td style={{ fontWeight: 600, color: '#fff' }}>{tx.entity_name}</td>
                  <td>{tx.entity_role || tx.record_type}</td>
                  <td>{tx.vendor_name || 'Direct'}</td>
                  <td>
                    <span className={`badge ${tx.movement_type === 'ENTRY' ? 'badge-active' : 'badge-denied'}`}>
                      {tx.movement_type}
                    </span>
                  </td>
                  <td>{tx.gate_name}</td>
                  <td style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                    {new Date(tx.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                  </td>
                  <td>
                    <span className="badge badge-active">{tx.status}</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
