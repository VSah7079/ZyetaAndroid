const db = require('../config/db');
const { logAudit, notify } = require('../middleware/audit');

const getMaterials = async (req, res) => {
  try {
    const { movement_type, vendor_id, return_status, search } = req.query;
    let list = db.materials.find();

    if (req.user.role === 'Vendor' && req.user.vendor_id) {
      list = list.filter((m) => Number(m.vendor_id) === Number(req.user.vendor_id));
    } else if (vendor_id) {
      list = list.filter((m) => Number(m.vendor_id) === Number(vendor_id));
    }

    if (movement_type) {
      list = list.filter((m) => m.movement_type === movement_type);
    }

    if (return_status) {
      list = list.filter((m) => m.return_status.toLowerCase() === return_status.toLowerCase());
    }

    if (search) {
      const q = search.toLowerCase();
      list = list.filter((m) =>
        m.dc_number.toLowerCase().includes(q) ||
        m.material_name.toLowerCase().includes(q) ||
        m.vendor_name.toLowerCase().includes(q) ||
        (m.vehicle_number && m.vehicle_number.toLowerCase().includes(q))
      );
    }

    list.sort((a, b) => new Date(b.entry_time) - new Date(a.entry_time));

    res.json({ success: true, count: list.length, data: list });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const createMaterialEntry = async (req, res) => {
  try {
    const data = req.body;
    if (!data.material_name || !data.quantity || !data.unit || !data.movement_type) {
      return res.status(400).json({ success: false, message: 'Missing required material entry fields' });
    }

    let vendorId = data.vendor_id;
    if (req.user.role === 'Vendor') {
      vendorId = req.user.vendor_id;
    }
    const vendor = vendorId ? db.vendors.findById(vendorId) : null;

    let dcNumber = data.dc_number;
    if (!dcNumber) {
      const count = db.materials.count() + 1;
      dcNumber = `DC-2026-${String(100 + count).padStart(3, '0')}`;
    }

    const isReturnable = data.movement_type.startsWith('RETURNABLE');

    const newMaterial = db.materials.create({
      dc_number: dcNumber,
      vendor_id: vendorId ? Number(vendorId) : null,
      vendor_name: vendor ? vendor.company_name : data.vendor_name || 'Direct Contractor',
      material_name: data.material_name,
      category: data.category || 'General Material',
      quantity: Number(data.quantity),
      unit: data.unit,
      invoice_number: data.invoice_number || '',
      vehicle_number: data.vehicle_number || '',
      driver_name: data.driver_name || '',
      driver_mobile: data.driver_mobile || '',
      movement_type: data.movement_type, // INWARD, OUTWARD, RETURNABLE_IN, RETURNABLE_OUT
      entry_time: new Date().toISOString(),
      exit_time: null,
      gate_id: data.gate_id ? Number(data.gate_id) : 2,
      photo_url: data.photo_url || null,
      return_dc_number: null,
      return_quantity: 0,
      return_status: isReturnable ? 'Pending' : 'Not Applicable',
      status: 'Approved',
      remarks: data.remarks || '',
      created_by: req.user ? req.user.full_name : 'Security Gate'
    });

    logAudit({
      userId: req.user ? req.user.id : null,
      userName: req.user ? req.user.full_name : 'Security Officer',
      userRole: req.user ? req.user.role : 'Security',
      actionType: 'CREATE',
      module: 'Material',
      affectedRecordId: newMaterial.id,
      details: `Gate Material pass created: ${newMaterial.dc_number} (${newMaterial.material_name}, ${newMaterial.quantity} ${newMaterial.unit})`,
      ipAddress: req.ip
    });

    res.status(201).json({ success: true, message: 'Material gate pass logged successfully', data: newMaterial });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const updateMaterialReturn = async (req, res) => {
  try {
    const { return_quantity, return_dc_number, remarks } = req.body;
    const material = db.materials.findById(req.params.id);
    if (!material) return res.status(404).json({ success: false, message: 'Material record not found' });

    const totalReturned = (Number(material.return_quantity) || 0) + Number(return_quantity || 0);
    const returnStatus = totalReturned >= Number(material.quantity) ? 'Fully Returned' : 'Partially Returned';

    const updated = db.materials.update(material.id, {
      return_quantity: totalReturned,
      return_dc_number: return_dc_number || material.return_dc_number,
      return_status: returnStatus,
      exit_time: totalReturned >= Number(material.quantity) ? new Date().toISOString() : material.exit_time,
      remarks: remarks ? `${material.remarks ? material.remarks + ' | ' : ''}Return Note: ${remarks}` : material.remarks
    });

    logAudit({
      userId: req.user.id,
      userName: req.user.full_name,
      userRole: req.user.role,
      actionType: 'UPDATE',
      module: 'Material',
      affectedRecordId: material.id,
      details: `Updated return quantity ${return_quantity} for DC ${material.dc_number}. New Status: ${returnStatus}`,
      ipAddress: req.ip
    });

    res.json({ success: true, message: 'Material return updated', data: updated });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getMaterials,
  createMaterialEntry,
  updateMaterialReturn
};
