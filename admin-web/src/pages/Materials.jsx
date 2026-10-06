import React, { useState, useEffect } from 'react';
import { Package, Plus, Truck, ArrowDownLeft, ArrowUpRight, Search, CheckCircle, RefreshCcw } from 'lucide-react';
import { api } from '../services/api';

export const Materials = () => {
  const [materials, setMaterials] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [movementFilter, setMovementFilter] = useState('');
  
  // Modals
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showReturnModal, setShowReturnModal] = useState(null);
  const [returnQty, setReturnQty] = useState('');
  const [returnDc, setReturnDc] = useState('');

  const [formData, setFormData] = useState({
    dc_number: '',
    material_name: '',
    category: 'Scaffolding & Structural',
    quantity: '',
    unit: 'Nos',
    vendor_name: 'ABC Infra Projects Pvt Ltd',
    vehicle_number: '',
    driver_name: '',
    driver_mobile: '',
    movement_type: 'RETURNABLE_IN',
    remarks: ''
  });

  const fetchMaterials = async () => {
    try {
      const res = await api.getMaterials({
        search,
        movement_type: movementFilter
      });
      if (res.success) setMaterials(res.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchMaterials();
  }, [search, movementFilter]);

  const handleCreate = async (e) => {
    e.preventDefault();
    try {
      const res = await api.createMaterialEntry(formData);
      if (res.success) {
        setShowCreateModal(false);
        fetchMaterials();
      }
    } catch (err) {
      alert(err.message);
    }
  };

  const handleReturn = async (e) => {
    e.preventDefault();
    if (!showReturnModal) return;
    try {
      const res = await api.updateMaterialReturn(showReturnModal.id, {
        return_quantity: Number(returnQty),
        return_dc_number: returnDc,
        remarks: 'Returned via Material Gate 2'
      });
      if (res.success) {
        setShowReturnModal(null);
        setReturnQty('');
        setReturnDc('');
        fetchMaterials();
      }
    } catch (err) {
      alert(err.message);
    }
  };

  return (
    <div className="page-container">
      <div className="page-header">
        <div>
          <h2 style={{ fontSize: 'clamp(1.1rem, 2.2vw, 1.3rem)', fontWeight: 800, color: '#fff' }}>Material & DC Gate Movement</h2>
          <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
            Delivery Challan tracking, Returnable & Inward raw materials verification
          </p>
        </div>

        <button onClick={() => setShowCreateModal(true)} className="btn btn-primary" style={{ whiteSpace: 'nowrap' }}>
          <Plus size={16} />
          <span>New Material Gate Pass</span>
        </button>
      </div>

      {/* Filter Bar */}
      <div className="glass-panel" style={{ padding: '16px', marginBottom: '20px', display: 'flex', gap: '14px', flexWrap: 'wrap' }}>
        <div style={{ flex: 1, minWidth: '220px' }}>
          <input
            type="text"
            className="form-control"
            placeholder="Search by DC number, material name, vendor or vehicle..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        <div style={{ width: '200px' }}>
          <select
            className="form-control"
            value={movementFilter}
            onChange={(e) => setMovementFilter(e.target.value)}
          >
            <option value="">All Movement Types</option>
            <option value="INWARD">Inward (Direct)</option>
            <option value="OUTWARD">Outward</option>
            <option value="RETURNABLE_IN">Returnable Inward</option>
            <option value="RETURNABLE_OUT">Returnable Outward</option>
          </select>
        </div>
      </div>

      {/* Materials Table */}
      <div className="glass-panel" style={{ padding: '1px' }}>
        <div className="table-container">
          <table className="custom-table">
            <thead>
              <tr>
                <th>DC Number</th>
                <th>Material Details</th>
                <th>Quantity</th>
                <th>Contractor</th>
                <th>Vehicle & Driver</th>
                <th>Type</th>
                <th>Return Status</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {materials.length === 0 ? (
                <tr>
                  <td colSpan="8" style={{ textAlign: 'center', padding: '32px', color: 'var(--text-muted)' }}>
                    No material records found.
                  </td>
                </tr>
              ) : (
                materials.map((m) => (
                  <tr key={m.id}>
                    <td className="mono" style={{ color: '#a5b4fc', fontWeight: 600 }}>{m.dc_number}</td>
                    <td>
                      <span style={{ fontWeight: 700, color: '#fff' }}>{m.material_name}</span>
                      <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)', display: 'block' }}>{m.category}</span>
                    </td>
                    <td>
                      <strong style={{ color: '#fff' }}>{m.quantity}</strong> {m.unit}
                    </td>
                    <td>{m.vendor_name}</td>
                    <td>
                      <span style={{ color: '#e2e8f0', fontSize: '0.8rem' }}>{m.vehicle_number || '—'}</span>
                      <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)', display: 'block' }}>{m.driver_name} ({m.driver_mobile})</span>
                    </td>
                    <td>
                      <span className={`badge ${m.movement_type.startsWith('RETURNABLE') ? 'badge-pending' : 'badge-info'}`}>
                        {m.movement_type}
                      </span>
                    </td>
                    <td>
                      <span className={`badge ${
                        m.return_status === 'Fully Returned' ? 'badge-active' :
                        m.return_status === 'Pending' ? 'badge-pending' : 'badge-info'
                      }`}>
                        {m.return_status} ({m.return_quantity || 0}/{m.quantity})
                      </span>
                    </td>
                    <td>
                      {m.movement_type.startsWith('RETURNABLE') && m.return_status !== 'Fully Returned' && (
                        <button
                          onClick={() => { setShowReturnModal(m); setReturnQty(String(m.quantity - (m.return_quantity || 0))); }}
                          className="btn btn-secondary"
                          style={{ padding: '4px 10px', fontSize: '0.72rem' }}
                        >
                          <RefreshCcw size={12} />
                          <span>Record Return</span>
                        </button>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* New Material Modal */}
      {showCreateModal && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '640px' }}>
            <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ fontSize: '1.05rem', fontWeight: 700, color: '#fff' }}>Generate Material Gate Pass</h3>
              <button onClick={() => setShowCreateModal(false)} style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}>✕</button>
            </div>

            <form onSubmit={handleCreate} style={{ padding: '20px' }}>
              <div className="grid-responsive-1-1">
                <div className="form-group" style={{ gridColumn: 'span 2' }}>
                  <label className="form-label">Material Name *</label>
                  <input
                    type="text"
                    required
                    className="form-control"
                    placeholder="e.g. Scaffolding Pipes, Structural Steel, Cement"
                    value={formData.material_name}
                    onChange={(e) => setFormData({ ...formData, material_name: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Quantity *</label>
                  <input
                    type="number"
                    required
                    className="form-control"
                    placeholder="e.g. 50"
                    value={formData.quantity}
                    onChange={(e) => setFormData({ ...formData, quantity: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Unit *</label>
                  <select
                    className="form-control"
                    value={formData.unit}
                    onChange={(e) => setFormData({ ...formData, unit: e.target.value })}
                  >
                    <option value="Nos">Nos</option>
                    <option value="Kg">Kg</option>
                    <option value="Ton">Ton</option>
                    <option value="Box">Box</option>
                    <option value="Litre">Litre</option>
                    <option value="Meter">Meter</option>
                  </select>
                </div>

                <div className="form-group">
                  <label className="form-label">Movement Type *</label>
                  <select
                    className="form-control"
                    value={formData.movement_type}
                    onChange={(e) => setFormData({ ...formData, movement_type: e.target.value })}
                  >
                    <option value="RETURNABLE_IN">Returnable Inward (To Site)</option>
                    <option value="INWARD">Non-Returnable Inward</option>
                    <option value="OUTWARD">Outward Dispatch</option>
                    <option value="RETURNABLE_OUT">Returnable Outward</option>
                  </select>
                </div>

                <div className="form-group">
                  <label className="form-label">Contractor / Vendor</label>
                  <input
                    type="text"
                    className="form-control"
                    value={formData.vendor_name}
                    onChange={(e) => setFormData({ ...formData, vendor_name: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Vehicle Number</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="KA 01 AB 1234"
                    value={formData.vehicle_number}
                    onChange={(e) => setFormData({ ...formData, vehicle_number: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Driver Name & Contact</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Ramesh (+91 9876543210)"
                    value={formData.driver_name}
                    onChange={(e) => setFormData({ ...formData, driver_name: e.target.value })}
                  />
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '16px' }}>
                <button type="button" onClick={() => setShowCreateModal(false)} className="btn btn-secondary">
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary">
                  Authorize & Create Gate Pass
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Return Material Modal */}
      {showReturnModal && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '480px' }}>
            <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ fontSize: '1.05rem', fontWeight: 700, color: '#fff' }}>Record Material Return</h3>
              <button onClick={() => setShowReturnModal(null)} style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}>✕</button>
            </div>

            <form onSubmit={handleReturn} style={{ padding: '20px' }}>
              <p style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', marginBottom: '14px' }}>
                Returning items for DC: <strong style={{ color: '#fff' }}>{showReturnModal.dc_number}</strong> ({showReturnModal.material_name})
              </p>

              <div className="form-group">
                <label className="form-label">Return Quantity ({showReturnModal.unit}) *</label>
                <input
                  type="number"
                  required
                  className="form-control"
                  value={returnQty}
                  onChange={(e) => setReturnQty(e.target.value)}
                />
              </div>

              <div className="form-group">
                <label className="form-label">Return Challan / Reference DC Number</label>
                <input
                  type="text"
                  className="form-control"
                  placeholder="e.g. RET-DC-2026-012"
                  value={returnDc}
                  onChange={(e) => setReturnDc(e.target.value)}
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '16px' }}>
                <button type="button" onClick={() => setShowReturnModal(null)} className="btn btn-secondary">
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary">
                  Confirm Return
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
