import React, { useState, useEffect } from 'react';
import { Clock, Calendar, Search, Filter, CheckCircle2, UserX, AlertCircle, Edit3 } from 'lucide-react';
import { api } from '../services/api';
import { useAuth } from '../context/AuthContext';

export const Attendance = () => {
  const { user } = useAuth();
  const [attendanceList, setAttendanceList] = useState([]);
  const [summary, setSummary] = useState(null);
  const [loading, setLoading] = useState(true);
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split('T')[0]);
  const [selectedStatus, setSelectedStatus] = useState('');
  const [search, setSearch] = useState('');
  
  // Manual mark modal
  const [showMarkModal, setShowMarkModal] = useState(false);
  const [employees, setEmployees] = useState([]);
  const [markForm, setMarkForm] = useState({
    employee_id: '',
    date: new Date().toISOString().split('T')[0],
    status: 'Present',
    notes: 'Admin manual marking'
  });

  const fetchAttendance = async () => {
    try {
      const [attRes, sumRes, empRes] = await Promise.all([
        api.getAttendance({
          date: selectedDate,
          status: selectedStatus,
          search
        }),
        api.getAttendanceSummary(),
        api.getEmployees()
      ]);

      if (attRes.success) setAttendanceList(attRes.data);
      if (sumRes.success) setSummary(sumRes.data);
      if (empRes.success) setEmployees(empRes.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAttendance();
  }, [selectedDate, selectedStatus, search]);

  const handleManualMark = async (e) => {
    e.preventDefault();
    try {
      const res = await api.markManualAttendance(markForm);
      if (res.success) {
        setShowMarkModal(false);
        fetchAttendance();
      }
    } catch (err) {
      alert(err.message);
    }
  };

  return (
    <div className="page-container">
      <div className="page-header">
        <div>
          <h2 style={{ fontSize: 'clamp(1.1rem, 2.2vw, 1.3rem)', fontWeight: 800, color: '#fff' }}>Daily Workforce Attendance Roster</h2>
          <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
            Automated gate turnstile punches, shift calculations and manual correction workflows
          </p>
        </div>

        {user?.role !== 'Vendor' && (
          <button onClick={() => setShowMarkModal(true)} className="btn btn-primary" style={{ whiteSpace: 'nowrap' }}>
            <Edit3 size={16} />
            <span>Mark / Correct Attendance</span>
          </button>
        )}
      </div>

      {/* Summary Cards */}
      {summary && (
        <div className="grid-responsive-4">
          <div className="glass-card" style={{ padding: '16px', borderLeft: '4px solid var(--accent-primary)' }}>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>TOTAL REGISTERED</span>
            <h3 style={{ fontSize: '1.6rem', fontWeight: 800, color: '#fff' }}>{summary.total_active_workforce}</h3>
          </div>
          <div className="glass-card" style={{ padding: '16px', borderLeft: '4px solid var(--accent-emerald)' }}>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>PRESENT TODAY</span>
            <h3 style={{ fontSize: '1.6rem', fontWeight: 800, color: '#34d399' }}>{summary.present}</h3>
          </div>
          <div className="glass-card" style={{ padding: '16px', borderLeft: '4px solid var(--accent-amber)' }}>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>LATE ARRIVALS</span>
            <h3 style={{ fontSize: '1.6rem', fontWeight: 800, color: '#fbbf24' }}>{summary.late}</h3>
          </div>
          <div className="glass-card" style={{ padding: '16px', borderLeft: '4px solid var(--accent-rose)' }}>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>ATTENDANCE RATE</span>
            <h3 style={{ fontSize: '1.6rem', fontWeight: 800, color: '#38bdf8' }}>{summary.attendance_percentage}%</h3>
          </div>
        </div>
      )}

      {/* Filter Toolbar */}
      <div className="glass-panel" style={{ padding: '16px', marginBottom: '20px', display: 'flex', gap: '14px', flexWrap: 'wrap', alignItems: 'center' }}>
        <div style={{ width: '170px' }}>
          <input
            type="date"
            className="form-control"
            value={selectedDate}
            onChange={(e) => setSelectedDate(e.target.value)}
          />
        </div>

        <div style={{ flex: 1, minWidth: '200px' }}>
          <input
            type="text"
            className="form-control"
            placeholder="Search employee name, ID or contractor..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        <div style={{ width: '150px' }}>
          <select
            className="form-control"
            value={selectedStatus}
            onChange={(e) => setSelectedStatus(e.target.value)}
          >
            <option value="">All Statuses</option>
            <option value="Present">Present</option>
            <option value="Absent">Absent</option>
            <option value="Late">Late</option>
            <option value="Half Day">Half Day</option>
          </select>
        </div>
      </div>

      {/* Table */}
      <div className="glass-panel" style={{ padding: '1px' }}>
        <div className="table-container">
          <table className="custom-table">
            <thead>
              <tr>
                <th>Date</th>
                <th>Employee Code</th>
                <th>Worker Name</th>
                <th>Contractor</th>
                <th>First In (Punch In)</th>
                <th>Last Out (Punch Out)</th>
                <th>Status</th>
                <th>Source</th>
              </tr>
            </thead>
            <tbody>
              {attendanceList.length === 0 ? (
                <tr>
                  <td colSpan="8" style={{ textAlign: 'center', padding: '32px', color: 'var(--text-muted)' }}>
                    No attendance records for {selectedDate}.
                  </td>
                </tr>
              ) : (
                attendanceList.map((att) => (
                  <tr key={att.id}>
                    <td style={{ color: 'var(--text-muted)' }}>{att.date}</td>
                    <td className="mono" style={{ color: '#a5b4fc', fontWeight: 600 }}>{att.employee_code}</td>
                    <td style={{ fontWeight: 700, color: '#fff' }}>{att.employee_name}</td>
                    <td>{att.vendor_name || 'Direct'}</td>
                    <td>
                      <span style={{ color: '#34d399', fontWeight: 600 }}>
                        {att.punch_in ? new Date(att.punch_in).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '—'}
                      </span>
                      {att.punch_in_gate && (
                        <span style={{ fontSize: '0.65rem', color: 'var(--text-muted)', display: 'block' }}>{att.punch_in_gate}</span>
                      )}
                    </td>
                    <td>
                      <span style={{ color: '#fb7185', fontWeight: 600 }}>
                        {att.punch_out ? new Date(att.punch_out).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '—'}
                      </span>
                      {att.punch_out_gate && (
                        <span style={{ fontSize: '0.65rem', color: 'var(--text-muted)', display: 'block' }}>{att.punch_out_gate}</span>
                      )}
                    </td>
                    <td>
                      <span className={`badge ${
                        att.status === 'Present' ? 'badge-present' :
                        att.status === 'Late' ? 'badge-pending' : 'badge-absent'
                      }`}>
                        {att.status}
                      </span>
                    </td>
                    <td style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>{att.source}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Manual Attendance Modal */}
      {showMarkModal && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '500px' }}>
            <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ fontSize: '1.05rem', fontWeight: 700, color: '#fff' }}>Manual Attendance Override</h3>
              <button onClick={() => setShowMarkModal(false)} style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}>✕</button>
            </div>

            <form onSubmit={handleManualMark} style={{ padding: '20px' }}>
              <div className="form-group">
                <label className="form-label">Select Worker *</label>
                <select
                  required
                  className="form-control"
                  value={markForm.employee_id}
                  onChange={(e) => setMarkForm({ ...markForm, employee_id: e.target.value })}
                >
                  <option value="">-- Choose Employee --</option>
                  {employees.map((e) => (
                    <option key={e.id} value={e.id}>{e.full_name} ({e.employee_id})</option>
                  ))}
                </select>
              </div>

              <div className="form-group">
                <label className="form-label">Attendance Date *</label>
                <input
                  type="date"
                  required
                  className="form-control"
                  value={markForm.date}
                  onChange={(e) => setMarkForm({ ...markForm, date: e.target.value })}
                />
              </div>

              <div className="form-group">
                <label className="form-label">Status *</label>
                <select
                  className="form-control"
                  value={markForm.status}
                  onChange={(e) => setMarkForm({ ...markForm, status: e.target.value })}
                >
                  <option value="Present">Present</option>
                  <option value="Absent">Absent</option>
                  <option value="Late">Late</option>
                  <option value="Half Day">Half Day</option>
                  <option value="Leave">Leave</option>
                </select>
              </div>

              <div className="form-group">
                <label className="form-label">Override Reason / Notes</label>
                <textarea
                  className="form-control"
                  rows="2"
                  value={markForm.notes}
                  onChange={(e) => setMarkForm({ ...markForm, notes: e.target.value })}
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '16px' }}>
                <button type="button" onClick={() => setShowMarkModal(false)} className="btn btn-secondary">
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary">
                  Save Attendance
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
