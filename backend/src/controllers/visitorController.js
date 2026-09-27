const db = require('../config/db');
const { logAudit } = require('../middleware/audit');

const getVisitors = async (req, res) => {
  try {
    const { status, search } = req.query;
    let list = db.visitors.find();

    if (status) {
      list = list.filter((v) => v.status.toLowerCase() === status.toLowerCase());
    }

    if (search) {
      const q = search.toLowerCase();
      list = list.filter((v) =>
        v.visitor_name.toLowerCase().includes(q) ||
        v.pass_code.toLowerCase().includes(q) ||
        v.company.toLowerCase().includes(q) ||
        v.person_to_meet.toLowerCase().includes(q) ||
        (v.mobile && v.mobile.includes(q))
      );
    }

    list.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

    res.json({ success: true, count: list.length, data: list });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const registerVisitor = async (req, res) => {
  try {
    const data = req.body;
    if (!data.visitor_name || !data.mobile || !data.person_to_meet) {
      return res.status(400).json({ success: false, message: 'Visitor name, mobile, and host name required' });
    }

    const count = db.visitors.count() + 1;
    const passCode = `VIS-2026-${String(100 + count).padStart(3, '0')}`;
    const now = new Date().toISOString();

    const isInstantEntry = data.instant_entry !== false;

    const newVisitor = db.visitors.create({
      pass_code: passCode,
      visitor_name: data.visitor_name,
      mobile: data.mobile,
      company: data.company || 'Individual / Guest',
      person_to_meet: data.person_to_meet,
      purpose: data.purpose || 'Official Meeting',
      vehicle_number: data.vehicle_number || '',
      id_proof_type: data.id_proof_type || 'Aadhaar',
      id_proof_number: data.id_proof_number || '',
      photo_url: data.photo_url || 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&auto=format&fit=crop&q=80',
      expected_entry: data.expected_entry || now,
      expected_exit: data.expected_exit || null,
      actual_entry: isInstantEntry ? now : null,
      actual_exit: null,
      gate_id: data.gate_id ? Number(data.gate_id) : 1,
      status: isInstantEntry ? 'Inside' : 'Pre-Registered',
      host_approved: 1
    });

    if (isInstantEntry) {
      db.gate_transactions.create({
        transaction_code: `GTX-${Date.now().toString().slice(-8)}`,
        record_type: 'Visitor',
        entity_id: newVisitor.id,
        entity_code: newVisitor.pass_code,
        entity_name: newVisitor.visitor_name,
        entity_role: 'Visitor',
        vendor_name: newVisitor.company,
        movement_type: 'ENTRY',
        timestamp: now,
        gate_id: 1,
        gate_name: 'Main Security Gate 1',
        security_user_id: req.user ? req.user.id : 4,
        security_user_name: req.user ? req.user.full_name : 'Security Officer',
        device_id: 'GATE-01',
        verification_method: 'MANUAL_PASS',
        status: 'ALLOW',
        remarks: `Visiting ${newVisitor.person_to_meet} for ${newVisitor.purpose}`
      });
    }

    logAudit({
      userId: req.user ? req.user.id : null,
      userName: req.user ? req.user.full_name : 'Security',
      userRole: req.user ? req.user.role : 'Security',
      actionType: 'CREATE',
      module: 'Visitor',
      affectedRecordId: newVisitor.id,
      details: `Registered visitor ${newVisitor.visitor_name} (${newVisitor.pass_code})`,
      ipAddress: req.ip
    });

    res.status(201).json({ success: true, message: 'Visitor registered successfully', data: newVisitor });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const checkoutVisitor = async (req, res) => {
  try {
    const visitor = db.visitors.findById(req.params.id);
    if (!visitor) return res.status(404).json({ success: false, message: 'Visitor not found' });

    const now = new Date().toISOString();
    const updated = db.visitors.update(visitor.id, {
      status: 'Exited',
      actual_exit: now
    });

    db.gate_transactions.create({
      transaction_code: `GTX-${Date.now().toString().slice(-8)}`,
      record_type: 'Visitor',
      entity_id: visitor.id,
      entity_code: visitor.pass_code,
      entity_name: visitor.visitor_name,
      entity_role: 'Visitor',
      vendor_name: visitor.company,
      movement_type: 'EXIT',
      timestamp: now,
      gate_id: 1,
      gate_name: 'Main Security Gate 1',
      security_user_id: req.user ? req.user.id : 4,
      security_user_name: req.user ? req.user.full_name : 'Security Officer',
      device_id: 'GATE-01',
      verification_method: 'PASS_CHECKOUT',
      status: 'ALLOW',
      remarks: 'Normal visitor checkout'
    });

    res.json({ success: true, message: 'Visitor checked out successfully', data: updated });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getVisitors,
  registerVisitor,
  checkoutVisitor
};
