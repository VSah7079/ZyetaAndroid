const QRCode = require('qrcode');
const db = require('../config/db');
const { logAudit, notify } = require('../middleware/audit');

const getEmployees = async (req, res) => {
  try {
    const { vendor_id, department_id, status, search, inside } = req.query;
    let list = db.employees.find();

    // If logged in as Vendor, scope only to their vendor_id
    if (req.user.role === 'Vendor' && req.user.vendor_id) {
      list = list.filter((emp) => Number(emp.vendor_id) === Number(req.user.vendor_id));
    } else if (vendor_id) {
      list = list.filter((emp) => Number(emp.vendor_id) === Number(vendor_id));
    }

    if (department_id) {
      list = list.filter((emp) => Number(emp.department_id) === Number(department_id));
    }

    if (status) {
      list = list.filter((emp) => emp.status.toLowerCase() === status.toLowerCase());
    }

    if (inside !== undefined) {
      const isInside = inside === 'true' || inside === '1' ? 1 : 0;
      list = list.filter((emp) => emp.currently_inside === isInside);
    }

    if (search) {
      const q = search.toLowerCase();
      list = list.filter((emp) =>
        emp.full_name.toLowerCase().includes(q) ||
        emp.employee_id.toLowerCase().includes(q) ||
        (emp.mobile && emp.mobile.includes(q)) ||
        (emp.designation && emp.designation.toLowerCase().includes(q))
      );
    }

    // Attach vendor details and documents
    const enriched = list.map((emp) => {
      const vendor = emp.vendor_id ? db.vendors.findById(emp.vendor_id) : null;
      const dept = emp.department_id ? db.departments.findById(emp.department_id) : null;
      const docs = db.employee_documents.find((d) => Number(d.employee_id) === Number(emp.id));
      return {
        ...emp,
        vendor_name: vendor ? vendor.company_name : 'Direct Hire',
        department_name: dept ? dept.name : 'General',
        documents: docs
      };
    });

    res.json({ success: true, count: enriched.length, data: enriched });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const getEmployeeById = async (req, res) => {
  try {
    const emp = db.employees.findById(req.params.id);
    if (!emp) {
      return res.status(404).json({ success: false, message: 'Employee not found' });
    }

    // Role check for Vendor
    if (req.user.role === 'Vendor' && req.user.vendor_id && Number(emp.vendor_id) !== Number(req.user.vendor_id)) {
      return res.status(403).json({ success: false, message: 'Unauthorized to view this employee' });
    }

    const vendor = emp.vendor_id ? db.vendors.findById(emp.vendor_id) : null;
    const dept = emp.department_id ? db.departments.findById(emp.department_id) : null;
    const shift = emp.shift_id ? db.shifts.findById(emp.shift_id) : null;
    const docs = db.employee_documents.find((d) => Number(d.employee_id) === Number(emp.id));
    const recentGate = db.gate_transactions.find((g) => Number(g.entity_id) === Number(emp.id)).slice(-10);
    const recentAttendance = db.attendance.find((a) => Number(a.employee_id) === Number(emp.id)).slice(-15);

    res.json({
      success: true,
      data: {
        ...emp,
        vendor_name: vendor ? vendor.company_name : 'Direct Hire',
        department_name: dept ? dept.name : 'General',
        shift_name: shift ? shift.name : 'General Shift',
        documents: docs,
        gate_history: recentGate,
        attendance_history: recentAttendance
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const createEmployee = async (req, res) => {
  try {
    const data = req.body;
    if (!data.full_name || !data.mobile) {
      return res.status(400).json({ success: false, message: 'Full name and mobile are required' });
    }

    // Auto-generate employee ID if not provided
    let empId = data.employee_id;
    if (!empId) {
      const count = db.employees.count() + 1;
      empId = `EMP-${100 + count}`;
    }

    // If Vendor is creating, ensure vendor_id is set to their vendor
    let vendorId = data.vendor_id;
    if (req.user.role === 'Vendor') {
      vendorId = req.user.vendor_id;
    }

    const vendorObj = vendorId ? db.vendors.findById(vendorId) : null;

    // Generate QR Code data
    const qrPayload = JSON.stringify({
      empId,
      name: data.full_name,
      vendor: vendorObj ? vendorObj.company_name : 'Direct',
      type: data.employee_type || 'Contractor',
      bloodGroup: data.blood_group || 'O+',
      validUntil: '2027-12-31'
    });
    const qrCodeData = await QRCode.toDataURL(qrPayload);

    const newEmp = db.employees.create({
      employee_id: empId,
      full_name: data.full_name,
      father_name: data.father_name || '',
      dob: data.dob || '',
      gender: data.gender || 'Male',
      mobile: data.mobile,
      alternate_mobile: data.alternate_mobile || '',
      email: data.email || '',
      address: data.address || '',
      city: data.city || 'Bangalore',
      state: data.state || 'Karnataka',
      pincode: data.pincode || '560001',
      emergency_name: data.emergency_name || '',
      emergency_relation: data.emergency_relation || '',
      emergency_phone: data.emergency_phone || '',
      blood_group: data.blood_group || 'O+',
      medical_cert: data.medical_cert || 'General Fitness',
      medical_validity: data.medical_validity || '2027-12-31',
      vendor_id: vendorId ? Number(vendorId) : null,
      department_id: data.department_id ? Number(data.department_id) : 1,
      designation: data.designation || 'Technician',
      skill: data.skill || 'General',
      employee_type: data.employee_type || 'Contractor',
      joining_date: data.joining_date || new Date().toISOString().split('T')[0],
      shift_id: data.shift_id ? Number(data.shift_id) : 1,
      aadhaar_no: data.aadhaar_no || '',
      aadhaar_doc: data.aadhaar_doc || data.aadhaar_file || 'aadhaar_card_front_back.pdf',
      pan_no: data.pan_no || '',
      police_verification_doc: data.police_verification_doc || 'pending_pvc.pdf',
      police_verification_expiry: data.police_verification_expiry || '2027-12-31',
      profile_photo: data.profile_photo || data.photo_url || 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&auto=format&fit=crop&q=80',
      photo_url: data.photo_url || data.profile_photo || 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&auto=format&fit=crop&q=80',
      medical_doc: data.medical_doc || 'medical_fitness_cert.pdf',
      medical_cert: data.medical_cert || 'General Fitness',
      medical_validity: data.medical_validity || '2027-12-31',
      qr_code_data: qrCodeData,
      status: (req.user.role === 'Super Admin' && data.pre_approved) ? 'Active' : 'Pending ID Clearance',
      id_card_status: (req.user.role === 'Super Admin' && data.pre_approved) ? 'Issued' : 'Awaiting Approvals',
      approval_stage: (req.user.role === 'Super Admin' && data.pre_approved) ? 'Completed' : 'Pending Admin & Safety',
      approvals: {
        admin: {
          status: (req.user.role === 'Super Admin' && data.pre_approved) ? 'Approved' : 'Pending',
          approved_by: (req.user.role === 'Super Admin' && data.pre_approved) ? req.user.full_name : null,
          approved_at: (req.user.role === 'Super Admin' && data.pre_approved) ? new Date().toISOString() : null,
          remarks: (req.user.role === 'Super Admin' && data.pre_approved) ? 'Pre-approved' : 'Awaiting Site Admin KYC & Aadhaar Verification'
        },
        safety: {
          status: (req.user.role === 'Super Admin' && data.pre_approved) ? 'Approved' : 'Pending',
          approved_by: (req.user.role === 'Super Admin' && data.pre_approved) ? req.user.full_name : null,
          approved_at: (req.user.role === 'Super Admin' && data.pre_approved) ? new Date().toISOString() : null,
          remarks: (req.user.role === 'Super Admin' && data.pre_approved) ? 'Pre-cleared' : 'Awaiting HSE Medical & Safety Clearance'
        },
        super_admin: {
          status: (req.user.role === 'Super Admin' && data.pre_approved) ? 'Approved' : 'Pending',
          approved_by: (req.user.role === 'Super Admin' && data.pre_approved) ? req.user.full_name : null,
          approved_at: (req.user.role === 'Super Admin' && data.pre_approved) ? new Date().toISOString() : null,
          remarks: (req.user.role === 'Super Admin' && data.pre_approved) ? 'Badge Generated' : 'Awaiting Dual Admin & Safety Clearances'
        }
      },
      currently_inside: 0,
      created_by: req.user.id
    });

    // Add Aadhaar doc record
    if (data.aadhaar_no || data.aadhaar_doc) {
      db.employee_documents.create({
        employee_id: newEmp.id,
        document_type: 'Aadhaar Card',
        document_number: data.aadhaar_no || 'Pending Entry',
        document_file: data.aadhaar_doc || `aadhaar_${empId}.pdf`,
        issue_date: '2020-01-01',
        expiry_date: '2099-12-31',
        verification_status: 'Pending',
        verified_by: null,
        verified_at: null
      });
    }

    // Add Medical fitness certificate doc record
    if (data.medical_doc) {
      db.employee_documents.create({
        employee_id: newEmp.id,
        document_type: 'Medical Fitness Certificate',
        document_number: `MED-${empId}`,
        document_file: data.medical_doc,
        issue_date: new Date().toISOString().split('T')[0],
        expiry_date: data.medical_validity || '2027-12-31',
        verification_status: 'Pending',
        verified_by: null,
        verified_at: null
      });
    }

    logAudit({
      userId: req.user.id,
      userName: req.user.full_name,
      userRole: req.user.role,
      actionType: 'CREATE',
      module: 'Employee',
      affectedRecordId: newEmp.id,
      details: `Created worker registration ${newEmp.full_name} (${newEmp.employee_id}) - Pending Site Admin & Safety HSE Clearance`,
      ipAddress: req.ip
    });

    // 1. Notify Site Admin
    notify({
      recipientRole: 'Admin',
      title: 'New Worker Registered - KYC & Aadhaar Clearance Required',
      message: `${newEmp.full_name} (${newEmp.employee_id}) registered under ${vendorObj ? vendorObj.company_name : 'Direct'}. Verify Aadhaar doc: ${newEmp.aadhaar_doc}.`,
      eventType: 'NEW_EMPLOYEE_ADMIN_CLEARANCE',
      relatedId: newEmp.id
    });

    // 2. Notify Safety Officer (Safety Wala)
    notify({
      recipientRole: 'Safety Officer',
      title: 'Worker Medical & Safety HSE Clearance Required',
      message: `${newEmp.full_name} requires HSE clearance. Verify Medical Certificate: ${newEmp.medical_doc}.`,
      eventType: 'NEW_EMPLOYEE_SAFETY_CLEARANCE',
      relatedId: newEmp.id
    });

    // 3. Notify Super Admin
    notify({
      recipientRole: 'Super Admin',
      title: 'Worker ID Generation Request Queued',
      message: `ID badge issuance queued for ${newEmp.full_name} (${vendorObj ? vendorObj.company_name : 'Direct'}).`,
      eventType: 'NEW_EMPLOYEE_SUPER_ADMIN_QUEUE',
      relatedId: newEmp.id
    });

    res.status(201).json({ success: true, message: 'Employee created successfully & sent for multi-tier clearance', data: newEmp });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const approveEmployeeStage = async (req, res) => {
  try {
    const emp = db.employees.findById(req.params.id);
    if (!emp) {
      return res.status(404).json({ success: false, message: 'Employee not found' });
    }

    const { stage, action, remarks } = req.body; // stage: 'admin' | 'safety' | 'super_admin', action: 'Approved' | 'Rejected'
    if (!stage || !action) {
      return res.status(400).json({ success: false, message: 'Stage and action are required' });
    }

    const approvals = emp.approvals || {
      admin: { status: 'Pending' },
      safety: { status: 'Pending' },
      super_admin: { status: 'Pending' }
    };

    if (stage === 'admin') {
      approvals.admin = {
        status: action,
        approved_by: req.user.full_name,
        approved_at: new Date().toISOString(),
        remarks: remarks || (action === 'Approved' ? 'Identity & Contract Verified' : 'KYC Rejected')
      };
    } else if (stage === 'safety') {
      approvals.safety = {
        status: action,
        approved_by: req.user.full_name,
        approved_at: new Date().toISOString(),
        remarks: remarks || (action === 'Approved' ? 'Medical Fitness & PPE Cleared' : 'Safety/Medical Incomplete')
      };
    } else if (stage === 'super_admin') {
      approvals.super_admin = {
        status: action,
        approved_by: req.user.full_name,
        approved_at: new Date().toISOString(),
        remarks: remarks || (action === 'Approved' ? 'Digital ID Pass Authorized & Activated' : 'ID Request Rejected')
      };
    }

    let nextStage = emp.approval_stage || 'Pending Admin';
    let status = emp.status;
    let idCardStatus = emp.id_card_status || 'Awaiting Approvals';

    if (action === 'Rejected') {
      status = 'Rejected';
      idCardStatus = 'Rejected';
      nextStage = 'Rejected';
    } else {
      const adminOk = approvals.admin?.status === 'Approved';
      const safetyOk = approvals.safety?.status === 'Approved';
      const superOk = approvals.super_admin?.status === 'Approved';

      if (adminOk && safetyOk) {
        status = 'Active';
        idCardStatus = 'Issued';
        nextStage = 'Completed';
        if (!approvals.super_admin || approvals.super_admin.status !== 'Approved') {
          approvals.super_admin = {
            status: 'Approved',
            approved_by: req.user.full_name || 'System Gate Authority',
            approved_at: new Date().toISOString(),
            remarks: 'Authorized & Active upon Site Admin KYC & Safety HSE Clearances'
          };
        }
      } else if (adminOk) {
        nextStage = 'Pending Safety';
        idCardStatus = 'Awaiting Safety HSE Clearance';
      } else if (safetyOk) {
        nextStage = 'Pending Site Admin';
        idCardStatus = 'Awaiting Site Admin KYC';
      } else {
        nextStage = 'Pending Admin & Safety';
        idCardStatus = 'Awaiting Approvals';
      }
    }

    let qrCode = emp.qr_code_data;
    if (status === 'Active' && !qrCode) {
      const vendorObj = emp.vendor_id ? db.vendors.findById(emp.vendor_id) : null;
      const qrPayload = JSON.stringify({
        empId: emp.employee_id,
        name: emp.full_name,
        vendor: vendorObj ? vendorObj.company_name : 'Direct',
        type: emp.employee_type || 'Contractor',
        bloodGroup: emp.blood_group || 'O+',
        validUntil: '2027-12-31'
      });
      qrCode = await QRCode.toDataURL(qrPayload);
    }

    const updated = db.employees.update(emp.id, {
      approvals,
      approval_stage: nextStage,
      status,
      id_card_status: idCardStatus,
      ...(qrCode ? { qr_code_data: qrCode } : {})
    });

    logAudit({
      userId: req.user.id,
      userName: req.user.full_name,
      userRole: req.user.role,
      actionType: 'WORKER_ID_APPROVAL_STAGE',
      module: 'Employee ID Approval',
      affectedRecordId: emp.id,
      details: `${req.user.role} (${req.user.full_name}) marked stage "${stage}" as ${action} for ${emp.full_name} (${emp.employee_id})`,
      ipAddress: req.ip
    });

    if (status === 'Active') {
      notify({
        recipientRole: 'Vendor',
        title: 'Worker ID Card Approved & Issued',
        message: `ID badge for ${emp.full_name} (${emp.employee_id}) is officially approved and issued. You can now view and print the ID card from your Vendor Portal.`,
        eventType: 'WORKER_ID_ISSUED',
        relatedId: emp.id
      });
    }

    res.json({
      success: true,
      message: `Worker ID clearance stage [${stage}] set to ${action}`,
      data: updated
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const updateEmployee = async (req, res) => {
  try {
    const emp = db.employees.findById(req.params.id);
    if (!emp) {
      return res.status(404).json({ success: false, message: 'Employee not found' });
    }

    const oldValues = { ...emp };
    const updates = { ...req.body };

    // When fast-approved or activated
    if (updates.status === 'Active') {
      updates.id_card_status = 'Issued';
      updates.approval_stage = 'Completed';
      if (!emp.qr_code_data && !updates.qr_code_data) {
        const vendorObj = emp.vendor_id ? db.vendors.findById(emp.vendor_id) : null;
        const qrPayload = JSON.stringify({
          empId: emp.employee_id,
          name: updates.full_name || emp.full_name,
          vendor: vendorObj ? vendorObj.company_name : 'Direct',
          type: updates.employee_type || emp.employee_type || 'Contractor',
          bloodGroup: updates.blood_group || emp.blood_group || 'O+',
          validUntil: '2027-12-31'
        });
        updates.qr_code_data = await QRCode.toDataURL(qrPayload);
      }

      notify({
        recipientRole: 'Vendor',
        title: 'Worker ID Card Approved & Issued',
        message: `ID badge for ${emp.full_name} (${emp.employee_id}) is approved. ID card is now available on your Vendor Portal.`,
        eventType: 'WORKER_ID_ISSUED',
        relatedId: emp.id
      });
    }

    const updated = db.employees.update(emp.id, updates);

    logAudit({
      userId: req.user.id,
      userName: req.user.full_name,
      userRole: req.user.role,
      actionType: 'UPDATE',
      module: 'Employee',
      affectedRecordId: emp.id,
      details: `Updated employee record ${updated.full_name}`,
      oldValues,
      newValues: updated,
      ipAddress: req.ip
    });

    res.json({ success: true, message: 'Employee updated successfully', data: updated });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const deleteEmployee = async (req, res) => {
  try {
    const emp = db.employees.findById(req.params.id);
    if (!emp) {
      return res.status(404).json({ success: false, message: 'Employee not found' });
    }

    // Soft deactivate instead of hard delete
    db.employees.update(emp.id, { status: 'Deactivated' });

    logAudit({
      userId: req.user.id,
      userName: req.user.full_name,
      userRole: req.user.role,
      actionType: 'DEACTIVATE',
      module: 'Employee',
      affectedRecordId: emp.id,
      details: `Deactivated employee ${emp.full_name} (${emp.employee_id})`,
      ipAddress: req.ip
    });

    res.json({ success: true, message: 'Employee deactivated successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getEmployees,
  getEmployeeById,
  createEmployee,
  approveEmployeeStage,
  updateEmployee,
  deleteEmployee
};
