const db = require('../config/db');
const { logAudit, notify } = require('../middleware/audit');

const verifyQR = async (req, res) => {
  try {
    const { qr_data, gate_id } = req.body;
    if (!qr_data) {
      return res.status(400).json({ success: false, message: 'QR data required' });
    }

    let searchId = qr_data;
    try {
      const parsed = JSON.parse(qr_data);
      searchId = parsed.empId || parsed.id || parsed.code || qr_data;
    } catch {
      // Raw string query
    }

    // 1. Search for Employee
    let emp = db.employees.findOne((e) =>
      e.employee_id.toLowerCase() === String(searchId).toLowerCase() ||
      String(e.id) === String(searchId) ||
      (e.aadhaar_no && e.aadhaar_no.replace(/\s/g, '') === String(searchId).replace(/\s/g, ''))
    );

    if (emp) {
      const vendor = emp.vendor_id ? db.vendors.findById(emp.vendor_id) : null;
      const dept = emp.department_id ? db.departments.findById(emp.department_id) : null;

      // Status Check
      if (emp.status !== 'Active') {
        return res.json({
          success: true,
          verification_status: 'DENIED',
          decision: 'ACCESS_DENIED',
          reason: `Employee account status is ${emp.status}. Access blocked.`,
          entity_type: 'Employee',
          data: { ...emp, vendor_name: vendor ? vendor.company_name : 'Direct' }
        });
      }

      // Compliance / Document Expiry Check
      const today = new Date();
      let complianceIssues = [];

      if (emp.police_verification_expiry && new Date(emp.police_verification_expiry) < today) {
        complianceIssues.push('Police Verification Certificate has EXPIRED.');
      }
      if (emp.medical_validity && new Date(emp.medical_validity) < today) {
        complianceIssues.push('Medical Fitness Certificate has EXPIRED.');
      }

      // Check Active Permits for Vendor
      let activePermit = null;
      if (emp.vendor_id) {
        activePermit = db.permits.findOne((p) => Number(p.vendor_id) === Number(emp.vendor_id) && p.status === 'Active');
      }

      // Presence state
      const isInside = emp.currently_inside === 1;
      const recommendedAction = isInside ? 'ALLOW_EXIT' : 'ALLOW_ENTRY';

      return res.json({
        success: true,
        verification_status: complianceIssues.length > 0 ? 'FLAGGED' : 'ALLOW',
        recommended_action: recommendedAction,
        is_currently_inside: isInside,
        compliance_warnings: complianceIssues,
        active_permit: activePermit,
        entity_type: 'Employee',
        data: {
          ...emp,
          vendor_name: vendor ? vendor.company_name : 'Direct Hire',
          department_name: dept ? dept.name : 'General'
        }
      });
    }

    // 2. Search for Visitor Pass Code
    const visitor = db.visitors.findOne((v) => 
      v.pass_code.toLowerCase() === String(searchId).toLowerCase() ||
      String(v.id) === String(searchId)
    );
    if (visitor) {
      const isInside = visitor.status === 'Inside';
      return res.json({
        success: true,
        verification_status: visitor.status === 'Blocked' ? 'DENIED' : 'ALLOW',
        recommended_action: isInside ? 'ALLOW_EXIT' : 'ALLOW_ENTRY',
        is_currently_inside: isInside,
        entity_type: 'Visitor',
        data: visitor
      });
    }

    // 3. Search for Material DC Pass
    const material = db.materials.findOne((m) =>
      m.dc_number.toLowerCase() === String(searchId).toLowerCase() ||
      String(m.id) === String(searchId)
    );
    if (material) {
      return res.json({
        success: true,
        verification_status: 'ALLOW',
        recommended_action: material.movement_type.includes('INWARD') ? 'ALLOW_ENTRY' : 'ALLOW_EXIT',
        entity_type: 'Material',
        data: material
      });
    }

    // 4. Search for Vehicle Register
    const vehicle = db.vehicles.findOne((v) =>
      v.vehicle_number.toLowerCase().replace(/\s/g, '') === String(searchId).toLowerCase().replace(/\s/g, '') ||
      String(v.id) === String(searchId)
    );
    if (vehicle) {
      const isInside = vehicle.status === 'Inside';
      return res.json({
        success: true,
        verification_status: vehicle.status === 'Blacklisted' ? 'DENIED' : 'ALLOW',
        recommended_action: isInside ? 'ALLOW_EXIT' : 'ALLOW_ENTRY',
        is_currently_inside: isInside,
        entity_type: 'Vehicle',
        data: vehicle
      });
    }

    // 5. Search for Safety Permit
    const permit = db.permits.findOne((p) =>
      p.permit_number.toLowerCase() === String(searchId).toLowerCase() ||
      String(p.id) === String(searchId)
    );
    if (permit) {
      return res.json({
        success: true,
        verification_status: permit.status === 'Active' ? 'ALLOW' : 'FLAGGED',
        recommended_action: permit.status === 'Active' ? 'VERIFIED_ACTIVE' : 'PENDING_APPROVAL',
        entity_type: 'Permit',
        data: permit
      });
    }

    return res.status(404).json({
      success: false,
      verification_status: 'NOT_FOUND',
      message: 'No active employee, visitor, material DC, vehicle, or permit record found for scanned code'
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const recordMovement = async (req, res) => {
  try {
    const { entity_type, entity_id, movement_type, gate_id, remarks, photo_url, verification_method } = req.body;
    if (!entity_type || !entity_id || !movement_type) {
      return res.status(400).json({ success: false, message: 'Missing required gate transaction fields' });
    }

    const gate = gate_id ? db.gates.findById(gate_id) : db.gates.findOne();
    const now = new Date().toISOString();
    const todayDate = now.split('T')[0];
    const txCode = `GTX-${Date.now().toString().slice(-8)}`;

    let entityName = '';
    let entityCode = '';
    let vendorName = '';
    let entityRole = '';

    if (entity_type === 'Employee') {
      const emp = db.employees.findById(entity_id);
      if (!emp) return res.status(404).json({ success: false, message: 'Employee not found' });

      // Duplicate movement check
      if (movement_type === 'ENTRY' && emp.currently_inside === 1) {
        return res.status(400).json({
          success: false,
          message: `Duplicate Entry Attempt: ${emp.full_name} is already marked as INSIDE the facility.`
        });
      }
      if (movement_type === 'EXIT' && emp.currently_inside === 0) {
        return res.status(400).json({
          success: false,
          message: `Duplicate Exit Attempt: ${emp.full_name} is already marked as OUTSIDE the facility.`
        });
      }

      const vendor = emp.vendor_id ? db.vendors.findById(emp.vendor_id) : null;
      entityName = emp.full_name;
      entityCode = emp.employee_id;
      vendorName = vendor ? vendor.company_name : 'Direct Hire';
      entityRole = emp.designation;

      // Update Employee state
      if (movement_type === 'ENTRY') {
        db.employees.update(emp.id, {
          currently_inside: 1,
          last_entry_time: now
        });

        // Auto-mark or update Attendance
        let att = db.attendance.findOne((a) => Number(a.employee_id) === Number(emp.id) && a.date === todayDate);
        if (!att) {
          db.attendance.create({
            employee_id: emp.id,
            employee_code: emp.employee_id,
            employee_name: emp.full_name,
            vendor_id: emp.vendor_id,
            vendor_name: vendorName,
            date: todayDate,
            punch_in: now,
            punch_out: null,
            punch_in_gate: gate ? gate.name : 'Main Gate',
            punch_out_gate: null,
            status: 'Present',
            late_minutes: 0,
            overtime_minutes: 0,
            source: 'Gate Movement',
            marked_by: req.user ? req.user.full_name : 'Gate Security'
          });
        }
      } else {
        db.employees.update(emp.id, {
          currently_inside: 0,
          last_exit_time: now
        });

        // Update Punch Out in attendance
        let att = db.attendance.findOne((a) => Number(a.employee_id) === Number(emp.id) && a.date === todayDate);
        if (att) {
          db.attendance.update(att.id, {
            punch_out: now,
            punch_out_gate: gate ? gate.name : 'Main Gate'
          });
        }
      }
    } else if (entity_type === 'Visitor') {
      const visitor = db.visitors.findById(entity_id);
      if (!visitor) return res.status(404).json({ success: false, message: 'Visitor not found' });
      entityName = visitor.visitor_name;
      entityCode = visitor.pass_code;
      vendorName = visitor.company;
      entityRole = 'Visitor';

      if (movement_type === 'ENTRY') {
        db.visitors.update(visitor.id, { status: 'Inside', actual_entry: now });
      } else {
        db.visitors.update(visitor.id, { status: 'Exited', actual_exit: now });
      }
    } else if (entity_type === 'Material') {
      const material = db.materials.findById(entity_id);
      if (!material) return res.status(404).json({ success: false, message: 'Material DC not found' });
      entityName = material.material_name;
      entityCode = material.dc_number;
      vendorName = material.vendor_name;
      entityRole = `Material (${material.movement_type})`;

      if (movement_type === 'ENTRY') {
        db.materials.update(material.id, { entry_time: now, status: 'Gate Verified' });
      } else {
        db.materials.update(material.id, { exit_time: now, status: 'Dispatched' });
      }
    } else if (entity_type === 'Vehicle') {
      const vehicle = db.vehicles.findById(entity_id);
      if (!vehicle) return res.status(404).json({ success: false, message: 'Vehicle not found' });
      entityName = `${vehicle.vehicle_number} (${vehicle.driver_name})`;
      entityCode = vehicle.vehicle_number;
      vendorName = vehicle.transporter_vendor || 'General';
      entityRole = `Vehicle (${vehicle.vehicle_type})`;

      if (movement_type === 'ENTRY') {
        db.vehicles.update(vehicle.id, { status: 'Inside', entry_time: now });
      } else {
        db.vehicles.update(vehicle.id, { status: 'Exited', exit_time: now });
      }
    }

    // Create Gate Transaction Record
    const tx = db.gate_transactions.create({
      transaction_code: txCode,
      record_type: entity_type,
      entity_id: Number(entity_id),
      entity_code: entityCode,
      entity_name: entityName,
      entity_role: entityRole,
      vendor_name: vendorName,
      movement_type: movement_type, // ENTRY or EXIT
      timestamp: now,
      gate_id: gate ? gate.id : 1,
      gate_name: gate ? gate.name : 'Main Security Gate',
      security_user_id: req.user ? req.user.id : 4,
      security_user_name: req.user ? req.user.full_name : 'Security Officer',
      device_id: 'GATE-TERM-01',
      verification_method: verification_method || 'QR_SCAN',
      status: 'ALLOW',
      photo_url: photo_url || null,
      remarks: remarks || ''
    });

    logAudit({
      userId: req.user ? req.user.id : null,
      userName: req.user ? req.user.full_name : 'Security Officer',
      userRole: req.user ? req.user.role : 'Security',
      actionType: movement_type === 'ENTRY' ? 'GATE_ENTRY' : 'GATE_EXIT',
      module: 'Gate',
      affectedRecordId: tx.id,
      details: `${movement_type} recorded for ${entityName} (${entityCode}) at ${gate ? gate.name : 'Main Gate'}`,
      ipAddress: req.ip
    });

    res.status(201).json({
      success: true,
      message: `${movement_type} logged successfully for ${entityName}`,
      data: tx
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const getCurrentlyInside = async (req, res) => {
  try {
    const employees = db.employees.find((e) => e.currently_inside === 1).map((emp) => {
      const vendor = emp.vendor_id ? db.vendors.findById(emp.vendor_id) : null;
      return {
        id: emp.id,
        entity_code: emp.employee_id,
        full_name: emp.full_name,
        type: 'Employee',
        designation: emp.designation,
        vendor_name: vendor ? vendor.company_name : 'Direct Hire',
        mobile: emp.mobile,
        entry_time: emp.last_entry_time,
        photo: emp.profile_photo
      };
    });

    const visitors = db.visitors.find((v) => v.status === 'Inside').map((v) => ({
      id: v.id,
      entity_code: v.pass_code,
      full_name: v.visitor_name,
      type: 'Visitor',
      designation: `Visiting ${v.person_to_meet}`,
      vendor_name: v.company,
      mobile: v.mobile,
      entry_time: v.actual_entry,
      photo: v.photo_url
    }));

    const totalInside = employees.length + visitors.length;

    res.json({
      success: true,
      total_count: totalInside,
      employee_count: employees.length,
      visitor_count: visitors.length,
      data: [...employees, ...visitors]
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const getTransactions = async (req, res) => {
  try {
    const { date, gate_id, movement_type, search } = req.query;
    let list = db.gate_transactions.find();

    if (date) {
      list = list.filter((tx) => tx.timestamp.startsWith(date));
    }

    if (gate_id) {
      list = list.filter((tx) => Number(tx.gate_id) === Number(gate_id));
    }

    if (movement_type) {
      list = list.filter((tx) => tx.movement_type.toUpperCase() === movement_type.toUpperCase());
    }

    if (search) {
      const q = search.toLowerCase();
      list = list.filter((tx) =>
        tx.entity_name.toLowerCase().includes(q) ||
        tx.entity_code.toLowerCase().includes(q) ||
        tx.vendor_name.toLowerCase().includes(q) ||
        tx.transaction_code.toLowerCase().includes(q)
      );
    }

    // Sort descending by timestamp
    list.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

    res.json({ success: true, count: list.length, data: list });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  verifyQR,
  recordMovement,
  getCurrentlyInside,
  getTransactions
};
