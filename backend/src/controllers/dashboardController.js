const db = require('../config/db');

const getDashboardStats = async (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];
    const isVendor = req.user.role === 'Vendor';
    const vendorId = isVendor ? req.user.vendor_id : null;

    // Filtered lists if Vendor
    let employees = db.employees.find((e) => e.status !== 'Deactivated');
    let permits = db.permits.find();
    let materials = db.materials.find();

    if (isVendor && vendorId) {
      employees = employees.filter((e) => Number(e.vendor_id) === Number(vendorId));
      permits = permits.filter((p) => Number(p.vendor_id) === Number(vendorId));
      materials = materials.filter((m) => Number(m.vendor_id) === Number(vendorId));
    }

    const totalEmployees = employees.length;
    const activeEmployees = employees.filter((e) => e.status === 'Active').length;
    const currentlyInside = employees.filter((e) => e.currently_inside === 1).length;

    // Vendors
    const allVendors = db.vendors.find();
    const totalVendors = allVendors.length;
    const activeVendors = allVendors.filter((v) => v.status === 'Active').length;

    // Gate movements today
    const todayTransactions = db.gate_transactions.find((tx) => tx.timestamp.startsWith(today));
    const todayEntries = todayTransactions.filter((tx) => tx.movement_type === 'ENTRY').length;
    const todayExits = todayTransactions.filter((tx) => tx.movement_type === 'EXIT').length;

    // Attendance today
    let todayAttendance = db.attendance.find((a) => a.date === today);
    if (isVendor && vendorId) {
      todayAttendance = todayAttendance.filter((a) => Number(a.vendor_id) === Number(vendorId));
    }
    const presentToday = todayAttendance.filter((a) => a.status === 'Present').length;

    // Permits
    const pendingPermits = permits.filter((p) => p.status === 'Pending').length;
    const activePermits = permits.filter((p) => p.status === 'Active').length;

    // Visitors & Materials
    const totalVisitorsInside = db.visitors.count((v) => v.status === 'Inside');
    const todayMaterialEntries = materials.filter((m) => m.entry_time.startsWith(today)).length;

    // Compliance / Expiring Documents (next 30 days)
    const now = new Date();
    const expiryThreshold = new Date();
    expiryThreshold.setDate(now.getDate() + 30);

    const expiringDocumentsCount = employees.filter((emp) => {
      const isPoliceExpiring = emp.police_verification_expiry && new Date(emp.police_verification_expiry) <= expiryThreshold;
      const isMedicalExpiring = emp.medical_validity && new Date(emp.medical_validity) <= expiryThreshold;
      return isPoliceExpiring || isMedicalExpiring;
    }).length;

    // Hourly Entry/Exit Distribution for Today (06:00 to 20:00)
    const hours = ['06:00', '08:00', '10:00', '12:00', '14:00', '16:00', '18:00', '20:00'];
    const hourlyTraffic = hours.map((hourStr) => {
      const hourInt = parseInt(hourStr.split(':')[0], 10);
      const entries = todayTransactions.filter((tx) => {
        const txHour = new Date(tx.timestamp).getHours();
        return tx.movement_type === 'ENTRY' && txHour >= hourInt && txHour < hourInt + 2;
      }).length;
      const exits = todayTransactions.filter((tx) => {
        const txHour = new Date(tx.timestamp).getHours();
        return tx.movement_type === 'EXIT' && txHour >= hourInt && txHour < hourInt + 2;
      }).length;
      return { hour: hourStr, entries, exits };
    });

    // Vendor-wise Workforce Distribution
    const vendorDistribution = allVendors.map((v) => ({
      vendor_name: v.company_name,
      total_workforce: db.employees.count((e) => Number(e.vendor_id) === Number(v.id) && e.status !== 'Deactivated'),
      inside_now: db.employees.count((e) => Number(e.vendor_id) === Number(v.id) && e.currently_inside === 1)
    }));

    // Recent Gate Activity
    const recentActivity = todayTransactions.slice(-6).reverse();

    res.json({
      success: true,
      data: {
        kpis: {
          total_employees: totalEmployees,
          active_employees: activeEmployees,
          currently_inside: currentlyInside,
          total_vendors: totalVendors,
          active_vendors: activeVendors,
          today_entries: todayEntries,
          today_exits: todayExits,
          today_attendance_present: presentToday,
          pending_permits: pendingPermits,
          active_permits: activePermits,
          visitors_inside: totalVisitorsInside,
          material_entries_today: todayMaterialEntries,
          expiring_compliance_docs: expiringDocumentsCount
        },
        hourly_traffic: hourlyTraffic,
        vendor_distribution: vendorDistribution,
        recent_activity: recentActivity
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getDashboardStats
};
