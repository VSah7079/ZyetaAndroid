const db = require('../config/db');
const { logAudit, notify } = require('../middleware/audit');

const getPermits = async (req, res) => {
  try {
    const { status, vendor_id, permit_type, search } = req.query;
    let list = db.permits.find();

    if (req.user.role === 'Vendor' && req.user.vendor_id) {
      list = list.filter((p) => Number(p.vendor_id) === Number(req.user.vendor_id));
    } else if (vendor_id) {
      list = list.filter((p) => Number(p.vendor_id) === Number(vendor_id));
    }

    if (status) {
      list = list.filter((p) => p.status.toLowerCase() === status.toLowerCase());
    }

    if (permit_type) {
      list = list.filter((p) => p.permit_type.toLowerCase() === permit_type.toLowerCase());
    }

    if (search) {
      const q = search.toLowerCase();
      list = list.filter((p) =>
        p.permit_number.toLowerCase().includes(q) ||
        p.description.toLowerCase().includes(q) ||
        p.location_zone.toLowerCase().includes(q) ||
        (p.vendor_name && p.vendor_name.toLowerCase().includes(q))
      );
    }

    list.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

    res.json({ success: true, count: list.length, data: list });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const getPermitById = async (req, res) => {
  try {
    const permit = db.permits.findById(req.params.id);
    if (!permit) return res.status(404).json({ success: false, message: 'Permit not found' });
    res.json({ success: true, data: permit });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const createPermit = async (req, res) => {
  try {
    const data = req.body;
    if (!data.permit_type || !data.description || !data.location_zone || !data.start_time || !data.end_time) {
      return res.status(400).json({ success: false, message: 'Missing required permit fields' });
    }

    let vendorId = data.vendor_id;
    if (req.user.role === 'Vendor') {
      vendorId = req.user.vendor_id;
    }
    const vendor = vendorId ? db.vendors.findById(vendorId) : null;

    const count = db.permits.count() + 1;
    const permitNumber = `PRM-2026-${String(count).padStart(3, '0')}`;

    const newPermit = db.permits.create({
      permit_number: permitNumber,
      permit_type: data.permit_type,
      vendor_id: vendorId ? Number(vendorId) : null,
      vendor_name: vendor ? vendor.company_name : 'Direct Project',
      applicant_name: data.applicant_name || req.user.full_name,
      applicant_contact: data.applicant_contact || req.user.phone || '',
      description: data.description,
      location_zone: data.location_zone,
      start_time: data.start_time,
      end_time: data.end_time,
      status: 'Pending',
      safety_checklist: typeof data.safety_checklist === 'object' ? JSON.stringify(data.safety_checklist) : data.safety_checklist || '{}',
      attachment_file: data.attachment_file || null
    });

    logAudit({
      userId: req.user.id,
      userName: req.user.full_name,
      userRole: req.user.role,
      actionType: 'CREATE',
      module: 'Permit',
      affectedRecordId: newPermit.id,
      details: `Submitted new permit request ${newPermit.permit_number} (${newPermit.permit_type})`,
      ipAddress: req.ip
    });

    notify({
      recipientRole: 'Admin',
      title: 'New Permit Approval Request',
      message: `${newPermit.permit_number} (${newPermit.permit_type}) requires review.`,
      eventType: 'PERMIT_PENDING',
      relatedId: newPermit.id
    });

    res.status(201).json({ success: true, message: 'Permit request submitted successfully', data: newPermit });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const approvePermit = async (req, res) => {
  try {
    const permit = db.permits.findById(req.params.id);
    if (!permit) return res.status(404).json({ success: false, message: 'Permit not found' });

    const updated = db.permits.update(permit.id, {
      status: 'Active',
      approved_by: req.user.full_name,
      approved_at: new Date().toISOString(),
      rejection_reason: null
    });

    logAudit({
      userId: req.user.id,
      userName: req.user.full_name,
      userRole: req.user.role,
      actionType: 'APPROVE',
      module: 'Permit',
      affectedRecordId: permit.id,
      details: `Permit ${permit.permit_number} approved by ${req.user.full_name}`,
      ipAddress: req.ip
    });

    notify({
      recipientRole: 'Vendor',
      recipientVendorId: permit.vendor_id,
      title: 'Permit Approved',
      message: `Your permit ${permit.permit_number} (${permit.permit_type}) has been approved.`,
      eventType: 'PERMIT_STATUS',
      relatedId: permit.id
    });

    res.json({ success: true, message: 'Permit approved successfully', data: updated });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const rejectPermit = async (req, res) => {
  try {
    const { reason } = req.body;
    const permit = db.permits.findById(req.params.id);
    if (!permit) return res.status(404).json({ success: false, message: 'Permit not found' });

    const updated = db.permits.update(permit.id, {
      status: 'Rejected',
      approved_by: req.user.full_name,
      rejection_reason: reason || 'Requirements or safety documentation insufficient'
    });

    logAudit({
      userId: req.user.id,
      userName: req.user.full_name,
      userRole: req.user.role,
      actionType: 'REJECT',
      module: 'Permit',
      affectedRecordId: permit.id,
      details: `Permit ${permit.permit_number} rejected. Reason: ${reason}`,
      ipAddress: req.ip
    });

    notify({
      recipientRole: 'Vendor',
      recipientVendorId: permit.vendor_id,
      title: 'Permit Rejected',
      message: `Your permit ${permit.permit_number} was rejected. Reason: ${reason}`,
      eventType: 'PERMIT_STATUS',
      relatedId: permit.id
    });

    res.json({ success: true, message: 'Permit rejected', data: updated });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const verifyPermitGate = async (req, res) => {
  try {
    const permit = db.permits.findById(req.params.id);
    if (!permit) return res.status(404).json({ success: false, message: 'Permit not found' });

    if (permit.status !== 'Active' && permit.status !== 'Approved') {
      return res.status(400).json({
        success: false,
        message: `Permit ${permit.permit_number} is in ${permit.status} status. Cannot verify at gate.`
      });
    }

    const updated = db.permits.update(permit.id, {
      security_verified_at: new Date().toISOString(),
      security_verified_by: req.user ? req.user.full_name : 'Security Officer'
    });

    res.json({ success: true, message: 'Permit verified at gate successfully', data: updated });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getPermits,
  getPermitById,
  createPermit,
  approvePermit,
  rejectPermit,
  verifyPermitGate
};
