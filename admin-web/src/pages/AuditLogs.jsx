import React, { useState, useEffect } from 'react';
import { ShieldAlert, Search, Filter, RefreshCw, Clock, User, Globe } from 'lucide-react';
import { api } from '../services/api';

export const AuditLogs = () => {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [moduleFilter, setModuleFilter] = useState('');
  const [actionFilter, setActionFilter] = useState('');

  const fetchLogs = async () => {
    try {
      const res = await api.getAuditLogs({
        search,
        module: moduleFilter,
        action_type: actionFilter
      });
      if (res.success) setLogs(res.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchLogs();
  }, [search, moduleFilter, actionFilter]);

  return (
    <div style={{ padding: '28px', maxWidth: '1440px', margin: '0 auto' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '20px' }}>
        <div>
          <h2 style={{ fontSize: '1.3rem', fontWeight: 800, color: '#fff' }}>Enterprise Audit Trail & Compliance Log</h2>
          <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
            Tamper-evident logs of administrative actions, safety approvals, access decisions & changes
          </p>
        </div>

        <button onClick={fetchLogs} className="btn btn-secondary" title="Refresh Logs">
          <RefreshCw size={16} />
          <span>Refresh</span>
        </button>
      </div>

      {/* Filter Bar */}
      <div className="glass-panel" style={{ padding: '16px', marginBottom: '20px', display: 'flex', gap: '14px', flexWrap: 'wrap' }}>
        <div style={{ flex: 1, minWidth: '220px' }}>
          <input
            type="text"
            className="form-control"
            placeholder="Search by user name, action details, record ID..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        <div style={{ width: '160px' }}>
          <select
            className="form-control"
            value={moduleFilter}
            onChange={(e) => setModuleFilter(e.target.value)}
          >
            <option value="">All Modules</option>
            <option value="Auth">Auth & Login</option>
            <option value="Employee">Workforce</option>
            <option value="Vendor">Contractor</option>
            <option value="Gate">Gate Movements</option>
            <option value="Permit">Safety Permits</option>
            <option value="Material">Materials</option>
            <option value="Attendance">Attendance</option>
          </select>
        </div>

        <div style={{ width: '160px' }}>
          <select
            className="form-control"
            value={actionFilter}
            onChange={(e) => setActionFilter(e.target.value)}
          >
            <option value="">All Actions</option>
            <option value="CREATE">CREATE</option>
            <option value="UPDATE">UPDATE</option>
            <option value="APPROVE">APPROVE</option>
            <option value="REJECT">REJECT</option>
            <option value="GATE_ENTRY">GATE ENTRY</option>
            <option value="GATE_EXIT">GATE EXIT</option>
            <option value="EXPORT">EXPORT</option>
          </select>
        </div>
      </div>

      {/* Audit Log Table */}
      <div className="glass-panel" style={{ padding: '1px' }}>
        <div className="table-container">
          <table className="custom-table">
            <thead>
              <tr>
                <th>Timestamp</th>
                <th>Actor / User</th>
                <th>Role</th>
                <th>Action Type</th>
                <th>Module</th>
                <th>Activity Description</th>
                <th>IP Address</th>
              </tr>
            </thead>
            <tbody>
              {logs.length === 0 ? (
                <tr>
                  <td colSpan="7" style={{ textAlign: 'center', padding: '32px', color: 'var(--text-muted)' }}>
                    No audit records matching search criteria.
                  </td>
                </tr>
              ) : (
                logs.map((log) => (
                  <tr key={log.id}>
                    <td style={{ fontSize: '0.75rem', color: 'var(--text-muted)', whiteSpace: 'nowrap' }}>
                      {new Date(log.timestamp).toLocaleString()}
                    </td>
                    <td>
                      <span style={{ fontWeight: 700, color: '#fff' }}>{log.user_name}</span>
                    </td>
                    <td>
                      <span className="badge badge-info" style={{ fontSize: '0.65rem' }}>{log.user_role}</span>
                    </td>
                    <td>
                      <span className={`badge ${
                        log.action_type === 'APPROVE' || log.action_type === 'CREATE' ? 'badge-active' :
                        log.action_type === 'REJECT' || log.action_type === 'DEACTIVATE' ? 'badge-denied' : 'badge-pending'
                      }`}>
                        {log.action_type}
                      </span>
                    </td>
                    <td style={{ color: '#38bdf8', fontWeight: 600 }}>{log.module}</td>
                    <td style={{ color: '#e2e8f0', fontSize: '0.8rem' }}>{log.details}</td>
                    <td className="mono" style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>{log.ip_address}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
