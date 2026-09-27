const db = require('../config/db');
const { logAudit } = require('../middleware/audit');

const getAttendance = async (req, res) => {
  try {
    const { date, vendor_id, status, search } = req.query;
    let list = db.attendance.find();

    if (req.user.role === 'Vendor' && req.user.vendor_id) {
      list = list.filter((a) => Number(a.vendor_id) === Number(req.user.vendor_id));
    } else if (vendor_id) {
      list = list.filter((a) => Number(a.vendor_id) === Number(vendor_id));
    }

    if (date) {
      list = list.filter((a) => a.date === date);
    }

    if (status) {
      list = list.filter((a) => a.status.toLowerCase() === status.toLowerCase());
    }

    if (search) {
      const q = search.toLowerCase();
      list = list.filter((a) =>
        a.employee_name.toLowerCase().includes(q) ||
        a.employee_code.toLowerCase().includes(q) ||
        (a.vendor_name && a.vendor_name.toLowerCase().includes(q))
      );
    }

    list.sort((a, b) => new Date(b.date) - new Date(a.date));

    res.json({ success: true, count: list.length, data: list });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const getAttendanceSummary = async (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];
    const todayRecords = db.attendance.find((a) => a.date === today);

    let totalEmployees = db.employees.count((e) => e.status === 'Active');
    if (req.user.role === 'Vendor' && req.user.vendor_id) {
      totalEmployees = db.employees.count((e) => Number(e.vendor_id) === Number(req.user.vendor_id) && e.status === 'Active');
    }

    const presentCount = todayRecords.filter((a) => a.status === 'Present').length;
    const lateCount = todayRecords.filter((a) => a.late_minutes > 0).length;
    const absentCount = Math.max(0, totalEmployees - presentCount);

    res.json({
      success: true,
      data: {
        date: today,
        total_active_workforce: totalEmployees,
        present: presentCount,
        late: lateCount,
        absent: absentCount,
        attendance_percentage: totalEmployees > 0 ? Math.round((presentCount / totalEmployees) * 100) : 0
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const markManualAttendance = async (req, res) => {
  try {
    const { employee_id, date, status, notes } = req.body;
    if (!employee_id || !date || !status) {
      return res.status(400).json({ success: false, message: 'Employee ID, date, and status are required' });
    }

    const emp = db.employees.findById(employee_id);
    if (!emp) return res.status(404).json({ success: false, message: 'Employee not found' });

    const vendor = emp.vendor_id ? db.vendors.findById(emp.vendor_id) : null;
    let existing = db.attendance.findOne((a) => Number(a.employee_id) === Number(emp.id) && a.date === date);

    let record;
    if (existing) {
      record = db.attendance.update(existing.id, {
        status,
        notes: notes || existing.notes,
        source: 'Manual Admin Correction',
        marked_by: req.user.full_name
      });
    } else {
      record = db.attendance.create({
        employee_id: emp.id,
        employee_code: emp.employee_id,
        employee_name: emp.full_name,
        vendor_id: emp.vendor_id,
        vendor_name: vendor ? vendor.company_name : 'Direct Hire',
        date,
        punch_in: status === 'Present' ? `${date}T09:00:00Z` : null,
        punch_out: status === 'Present' ? `${date}T18:00:00Z` : null,
        status,
        late_minutes: 0,
        overtime_minutes: 0,
        source: 'Manual Admin Marking',
        marked_by: req.user.full_name,
        notes: notes || ''
      });
    }

    logAudit({
      userId: req.user.id,
      userName: req.user.full_name,
      userRole: req.user.role,
      actionType: 'ATTENDANCE_OVERRIDE',
      module: 'Attendance',
      affectedRecordId: record.id,
      details: `Manual attendance marked as ${status} for ${emp.full_name} on ${date}`,
      ipAddress: req.ip
    });

    res.json({ success: true, message: 'Attendance record updated successfully', data: record });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getAttendance,
  getAttendanceSummary,
  markManualAttendance
};
