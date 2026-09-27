const db = require('../config/db');
const { logAudit } = require('../middleware/audit');

const getAuditLogs = async (req, res) => {
  try {
    const { module, action_type, user_id, search } = req.query;
    let list = db.audit_logs.find();

    if (module) {
      list = list.filter((l) => l.module.toLowerCase() === module.toLowerCase());
    }

    if (action_type) {
      list = list.filter((l) => l.action_type.toLowerCase() === action_type.toLowerCase());
    }

    if (user_id) {
      list = list.filter((l) => Number(l.user_id) === Number(user_id));
    }

    if (search) {
      const q = search.toLowerCase();
      list = list.filter((l) =>
        l.user_name.toLowerCase().includes(q) ||
        l.details.toLowerCase().includes(q) ||
        (l.affected_record_id && l.affected_record_id.includes(q))
      );
    }

    list.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

    res.json({ success: true, count: list.length, data: list });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const getReportData = async (req, res) => {
  try {
    const { report_type, start_date, end_date, vendor_id } = req.query;

    let data = [];
    let title = '';

    switch (report_type) {
      case 'employee_master':
        title = 'Employee Master Workforce Report';
        data = db.employees.find().map((emp) => {
          const v = emp.vendor_id ? db.vendors.findById(emp.vendor_id) : null;
          return {
            Employee_ID: emp.employee_id,
            Name: emp.full_name,
            Designation: emp.designation,
            Vendor: v ? v.company_name : 'Direct Hire',
            Mobile: emp.mobile,
            Blood_Group: emp.blood_group,
            Medical_Validity: emp.medical_validity,
            Police_Verification_Expiry: emp.police_verification_expiry,
            Status: emp.status,
            Currently_Inside: emp.currently_inside ? 'Yes' : 'No'
          };
        });
        break;

      case 'gate_transactions':
        title = 'Gate Movement Audit Report';
        data = db.gate_transactions.find().map((tx) => ({
          Transaction_Code: tx.transaction_code,
          Record_Type: tx.record_type,
          Name: tx.entity_name,
          Code: tx.entity_code,
          Vendor: tx.vendor_name,
          Movement: tx.movement_type,
          Gate: tx.gate_name,
          Security_Officer: tx.security_user_name,
          Timestamp: tx.timestamp,
          Status: tx.status
        }));
        break;

      case 'attendance_report':
        title = 'Workforce Attendance Report';
        data = db.attendance.find().map((att) => ({
          Date: att.date,
          Employee_ID: att.employee_code,
          Employee_Name: att.employee_name,
          Vendor: att.vendor_name,
          Status: att.status,
          Punch_In: att.punch_in,
          Punch_Out: att.punch_out,
          Late_Minutes: att.late_minutes,
          Source: att.source
        }));
        break;

      case 'document_expiry':
        title = 'Compliance & Document Expiry Report';
        const today = new Date();
        const threshold = new Date();
        threshold.setDate(today.getDate() + 30);

        data = db.employees.find().filter((e) => {
          const pExp = e.police_verification_expiry && new Date(e.police_verification_expiry) <= threshold;
          const mExp = e.medical_validity && new Date(e.medical_validity) <= threshold;
          return pExp || mExp;
        }).map((emp) => {
          const v = emp.vendor_id ? db.vendors.findById(emp.vendor_id) : null;
          return {
            Employee_ID: emp.employee_id,
            Name: emp.full_name,
            Vendor: v ? v.company_name : 'Direct Hire',
            Police_Verification_Expiry: emp.police_verification_expiry,
            Medical_Validity: emp.medical_validity,
            Status: emp.status
          };
        });
        break;

      case 'material_movement':
        title = 'Material Gate Pass & DC Movement Report';
        data = db.materials.find().map((m) => ({
          DC_Number: m.dc_number,
          Material: m.material_name,
          Category: m.category,
          Quantity: `${m.quantity} ${m.unit}`,
          Vendor: m.vendor_name,
          Type: m.movement_type,
          Vehicle_No: m.vehicle_number,
          Driver: m.driver_name,
          Entry_Time: m.entry_time,
          Return_Status: m.return_status
        }));
        break;

      default:
        title = 'Currently Inside Facility Report';
        data = db.employees.find((e) => e.currently_inside === 1).map((emp) => {
          const v = emp.vendor_id ? db.vendors.findById(emp.vendor_id) : null;
          return {
            Type: 'Employee',
            Code: emp.employee_id,
            Name: emp.full_name,
            Designation: emp.designation,
            Vendor: v ? v.company_name : 'Direct Hire',
            Entry_Time: emp.last_entry_time
          };
        });
    }

    logAudit({
      userId: req.user ? req.user.id : null,
      userName: req.user ? req.user.full_name : 'Admin',
      userRole: req.user ? req.user.role : 'Admin',
      actionType: 'EXPORT',
      module: 'Reports',
      details: `Generated and exported report: ${title}`,
      ipAddress: req.ip
    });

    res.json({
      success: true,
      title,
      report_type: report_type || 'currently_inside',
      total_records: data.length,
      data
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getAuditLogs,
  getReportData
};
