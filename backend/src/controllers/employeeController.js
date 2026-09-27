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
      pan_no: data.pan_no || '',
      police_verification_doc: data.police_verification_doc || 'pending_pvc.pdf',
      police_verification_expiry: data.police_verification_expiry || '2027-12-31',
      profile_photo: data.profile_photo || 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&auto=format&fit=crop&q=80',
      qr_code_data: qrCodeData,
      status: req.user.role === 'Vendor' ? 'Pending Approval' : 'Active',
      currently_inside: 0,
      created_by: req.user.id
    });

    // Add Aadhaar doc record
    if (data.aadhaar_no) {
      db.employee_documents.create({
        employee_id: newEmp.id,
        document_type: 'Aadhaar Card',
        document_number: data.aadhaar_no,
        document_file: `aadhaar_${empId}.pdf`,
        issue_date: '2020-01-01',
        expiry_date: '2099-12-31',
        verification_status: 'Verified',
        verified_by: req.user.full_name,
        verified_at: new Date().toISOString()
      });
    }

    logAudit({
      userId: req.user.id,
      userName: req.user.full_name,
      userRole: req.user.role,
      actionType: 'CREATE',
      module: 'Employee',
      affectedRecordId: newEmp.id,
      details: `Created employee record ${newEmp.full_name} (${newEmp.employee_id})`,
      ipAddress: req.ip
    });

    notify({
      recipientRole: 'Admin',
      title: 'New Employee Registered',
      message: `${newEmp.full_name} (${newEmp.employee_id}) registered under ${vendorObj ? vendorObj.company_name : 'Direct'}.`,
      eventType: 'NEW_EMPLOYEE',
      relatedId: newEmp.id
    });

    res.status(201).json({ success: true, message: 'Employee created successfully', data: newEmp });
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
    const updated = db.employees.update(emp.id, req.body);

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
  updateEmployee,
  deleteEmployee
};
