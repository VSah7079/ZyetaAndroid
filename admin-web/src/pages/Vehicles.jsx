import React, { useState, useEffect } from 'react';
import { Truck, Plus, ShieldCheck, AlertTriangle, Search, CheckCircle } from 'lucide-react';
import { api } from '../services/api';

export const Vehicles = () => {
  const [vehicles, setVehicles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [showModal, setShowModal] = useState(false);

  const [formData, setFormData] = useState({
    vehicle_number: '',
    vehicle_type: 'Truck (Multi-Axle)',
    owner_vendor: 'ABC Infra Projects Pvt Ltd',
    driver_name: '',
    driver_mobile: '',
    rc_number: '',
    insurance_validity: '2027-12-31',
    puc_validity: '2027-12-31',
    fitness_validity: '2027-12-31',
    notes: ''
  });

  const fetchVehicles = async () => {
    try {
      const res = await api.getVehicles({ search });
      if (res.success) setVehicles(res.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchVehicles();
  }, [search]);

  const handleCreate = async (e) => {
    e.preventDefault();
    try {
      const res = await api.createVehicle(formData);
      if (res.success) {
        setShowModal(false);
        fetchVehicles();
      }
    } catch (err) {
      alert(err.message);
    }
  };

  return (
    <div className="page-container">
      <div className="page-header">
        <div>
          <h2 style={{ fontSize: 'clamp(1.1rem, 2.2vw, 1.3rem)', fontWeight: 800, color: '#fff' }}>Commercial & Site Vehicle Register</h2>
          <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
            PUC, Insurance, Fitness certificate verification & driver authorization
          </p>
        </div>

        <button onClick={() => setShowModal(true)} className="btn btn-primary" style={{ whiteSpace: 'nowrap' }}>
          <Plus size={16} />
          <span>Register Site Vehicle</span>
        </button>
      </div>

      {/* Filter Toolbar */}
      <div className="glass-panel" style={{ padding: '16px', marginBottom: '20px' }}>
        <input
          type="text"
          className="form-control"
          placeholder="Search by vehicle number, driver or contractor..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
      </div>

      {/* Vehicles Table */}
      <div className="glass-panel" style={{ padding: '1px' }}>
        <div className="table-container">
          <table className="custom-table">
            <thead>
              <tr>
                <th>Vehicle Number</th>
                <th>Type</th>
                <th>Contractor / Owner</th>
                <th>Driver & Mobile</th>
                <th>PUC Validity</th>
                <th>Insurance Validity</th>
                <th>Compliance Status</th>
              </tr>
            </thead>
            <tbody>
              {vehicles.length === 0 ? (
                <tr>
                  <td colSpan="7" style={{ textAlign: 'center', padding: '32px', color: 'var(--text-muted)' }}>
                    No vehicle records found.
                  </td>
                </tr>
              ) : (
                vehicles.map((v) => (
                  <tr key={v.id}>
                    <td className="mono" style={{ color: '#fff', fontWeight: 700 }}>{v.vehicle_number}</td>
                    <td>{v.vehicle_type}</td>
                    <td>{v.owner_vendor}</td>
                    <td>
                      <span style={{ fontWeight: 600, color: '#e2e8f0' }}>{v.driver_name || 'Assigned Driver'}</span>
                      <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)', display: 'block' }}>{v.driver_mobile}</span>
                    </td>
                    <td>
                      <span style={{ color: v.is_puc_expired ? '#f43f5e' : '#34d399', fontWeight: 600 }}>
                        {v.puc_validity} {v.is_puc_expired && '⚠️ EXPIRED'}
                      </span>
                    </td>
                    <td>
                      <span style={{ color: v.is_insurance_expired ? '#f43f5e' : '#34d399', fontWeight: 600 }}>
                        {v.insurance_validity} {v.is_insurance_expired && '⚠️ EXPIRED'}
                      </span>
                    </td>
                    <td>
                      <span className={`badge ${v.compliance_status === 'Compliant' ? 'badge-active' : 'badge-denied'}`}>
                        {v.compliance_status}
                      </span>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal */}
      {showModal && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '600px' }}>
            <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ fontSize: '1.05rem', fontWeight: 700, color: '#fff' }}>Register Commercial Site Vehicle</h3>
              <button onClick={() => setShowModal(false)} style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}>✕</button>
            </div>

            <form onSubmit={handleCreate} style={{ padding: '20px' }}>
              <div className="grid-responsive-1-1">
                <div className="form-group">
                  <label className="form-label">Vehicle Registration Number *</label>
                  <input
                    type="text"
                    required
                    className="form-control"
                    placeholder="e.g. KA 01 MJ 8812"
                    value={formData.vehicle_number}
                    onChange={(e) => setFormData({ ...formData, vehicle_number: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Vehicle Type *</label>
                  <select
                    className="form-control"
                    value={formData.vehicle_type}
                    onChange={(e) => setFormData({ ...formData, vehicle_type: e.target.value })}
                  >
                    <option value="Truck (Multi-Axle)">Truck (Multi-Axle)</option>
                    <option value="Transit Mixer (RMC)">Transit Mixer (RMC)</option>
                    <option value="Dumper / Tipper">Dumper / Tipper</option>
                    <option value="JCB / Excavator">JCB / Excavator</option>
                    <option value="Pickup Van">Pickup Van</option>
                    <option value="Car / SUV">Car / SUV</option>
                  </select>
                </div>

                <div className="form-group">
                  <label className="form-label">Owner / Contractor</label>
                  <input
                    type="text"
                    className="form-control"
                    value={formData.owner_vendor}
                    onChange={(e) => setFormData({ ...formData, owner_vendor: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Driver Name</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Manoj Kumar"
                    value={formData.driver_name}
                    onChange={(e) => setFormData({ ...formData, driver_name: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">PUC Validity Date *</label>
                  <input
                    type="date"
                    required
                    className="form-control"
                    value={formData.puc_validity}
                    onChange={(e) => setFormData({ ...formData, puc_validity: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Insurance Validity Date *</label>
                  <input
                    type="date"
                    required
                    className="form-control"
                    value={formData.insurance_validity}
                    onChange={(e) => setFormData({ ...formData, insurance_validity: e.target.value })}
                  />
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '16px' }}>
                <button type="button" onClick={() => setShowModal(false)} className="btn btn-secondary">
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary">
                  Save Vehicle
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
