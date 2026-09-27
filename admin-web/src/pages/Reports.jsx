import React, { useState, useEffect } from 'react';
import { BarChart3, Download, Printer, Filter, FileSpreadsheet, RefreshCw } from 'lucide-react';
import { api } from '../services/api';

export const Reports = () => {
  const [reportType, setReportType] = useState('employee_master');
  const [reportData, setReportData] = useState(null);
  const [loading, setLoading] = useState(false);

  const fetchReport = async () => {
    setLoading(true);
    try {
      const res = await api.getReportData({ report_type: reportType });
      if (res.success) {
        setReportData(res);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchReport();
  }, [reportType]);

  const handleExportCSV = () => {
    if (!reportData || !reportData.data || reportData.data.length === 0) return;

    const items = reportData.data;
    const header = Object.keys(items[0]);
    const csv = [
      header.join(','),
      ...items.map(row => header.map(field => `"${(row[field] ?? '').toString().replace(/"/g, '""')}"`).join(','))
    ].join('\r\n');

    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = `${reportType}_${new Date().toISOString().split('T')[0]}.csv`;
    link.click();
  };

  const handlePrint = () => {
    window.print();
  };

  return (
    <div style={{ padding: '28px', maxWidth: '1440px', margin: '0 auto' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '20px' }}>
        <div>
          <h2 style={{ fontSize: '1.3rem', fontWeight: 800, color: '#fff' }}>Compliance & Operational Reports</h2>
          <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
            Exportable workforce rosters, audit logs, turnstile transactions and expiry records
          </p>
        </div>

        <div style={{ display: 'flex', gap: '10px' }}>
          <button onClick={handleExportCSV} className="btn btn-primary">
            <Download size={16} />
            <span>Export CSV</span>
          </button>
          <button onClick={handlePrint} className="btn btn-secondary">
            <Printer size={16} />
            <span>Print Report</span>
          </button>
        </div>
      </div>

      {/* Report Selector Toolbar */}
      <div className="glass-panel" style={{ padding: '16px', marginBottom: '20px', display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
        {[
          { id: 'employee_master', label: 'Workforce Master' },
          { id: 'gate_transactions', label: 'Gate Turnstile Log' },
          { id: 'attendance_report', label: 'Attendance Sheet' },
          { id: 'document_expiry', label: 'Compliance & Expiry' },
          { id: 'material_movement', label: 'Material DC Movement' },
          { id: 'currently_inside', label: 'Currently On Site' }
        ].map((tab) => (
          <button
            key={tab.id}
            onClick={() => setReportType(tab.id)}
            className={`btn ${reportType === tab.id ? 'btn-primary' : 'btn-secondary'}`}
            style={{ fontSize: '0.8rem' }}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Report Result Preview */}
      <div className="glass-panel" style={{ padding: '20px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '16px' }}>
          <h4 style={{ fontSize: '1rem', fontWeight: 700, color: '#fff' }}>
            {reportData?.title || 'Report Table Preview'}
          </h4>
          <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
            Total Records: {reportData?.total_records || 0}
          </span>
        </div>

        {loading ? (
          <p style={{ textAlign: 'center', padding: '30px', color: 'var(--text-muted)' }}>Generating report data...</p>
        ) : !reportData || reportData.data.length === 0 ? (
          <p style={{ textAlign: 'center', padding: '30px', color: 'var(--text-muted)' }}>No data available for this report criteria.</p>
        ) : (
          <div className="table-container">
            <table className="custom-table" style={{ fontSize: '0.78rem' }}>
              <thead>
                <tr>
                  {Object.keys(reportData.data[0]).map((col) => (
                    <th key={col}>{col.replace(/_/g, ' ')}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {reportData.data.map((row, idx) => (
                  <tr key={idx}>
                    {Object.values(row).map((val, colIdx) => (
                      <td key={colIdx}>{val !== null && val !== undefined ? String(val) : '—'}</td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};
