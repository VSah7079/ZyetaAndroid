const db = require('../config/db');
const { logAudit } = require('../middleware/audit');

const getVendors = async (req, res) => {
  try {
    const list = db.vendors.find();
    const enriched = list.map((v) => {
      const employeeCount = db.employees.count((e) => Number(e.vendor_id) === Number(v.id) && e.status !== 'Deactivated');
      const insideCount = db.employees.count((e) => Number(e.vendor_id) === Number(v.id) && e.currently_inside === 1);
      const activePermits = db.permits.count((p) => Number(p.vendor_id) === Number(v.id) && p.status === 'Active');
      return {
        ...v,
        employee_count: employeeCount,
        inside_count: insideCount,
        active_permits: activePermits
      };
    });
    res.json({ success: true, count: enriched.length, data: enriched });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const getVendorById = async (req, res) => {
  try {
    const vendorId = req.params.id;
    const vendor = db.vendors.findById(vendorId);
    if (!vendor) {
      return res.status(404).json({ success: false, message: 'Vendor not found' });
    }

    const employees = db.employees.find((e) => Number(e.vendor_id) === Number(vendor.id));
    const permits = db.permits.find((p) => Number(p.vendor_id) === Number(vendor.id));
    const materials = db.materials.find((m) => Number(m.vendor_id) === Number(vendor.id));
    const documents = db.vendor_documents.find((d) => Number(d.vendor_id) === Number(vendor.id));

    // Expiry check
    const today = new Date();
    const expiringThreshold = new Date();
    expiringThreshold.setDate(today.getDate() + 30);

    const expiringEmployees = employees.filter((emp) => {
      if (emp.police_verification_expiry && new Date(emp.police_verification_expiry) <= expiringThreshold) return true;
      if (emp.medical_validity && new Date(emp.medical_validity) <= expiringThreshold) return true;
      return false;
    });

    res.json({
      success: true,
      data: {
        ...vendor,
        stats: {
          total_employees: employees.length,
          currently_inside: employees.filter((e) => e.currently_inside === 1).length,
          active_permits: permits.filter((p) => p.status === 'Active').length,
          pending_permits: permits.filter((p) => p.status === 'Pending').length,
          expiring_compliance_docs: expiringEmployees.length
        },
        employees,
        permits,
        materials,
        documents
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const createVendor = async (req, res) => {
  try {
    const data = req.body;
    if (!data.company_name) {
      return res.status(400).json({ success: false, message: 'Company name is required' });
    }

    let vendorId = data.vendor_id;
    if (!vendorId) {
      const count = db.vendors.count() + 1;
      vendorId = `VND-${1000 + count}`;
    }

    const newVendor = db.vendors.create({
      vendor_id: vendorId,
      company_name: data.company_name,
      owner_name: data.owner_name || '',
      email: data.email || '',
      phone: data.phone || '',
      address: data.address || '',
      gst_pan: data.gst_pan || '',
      agreement_doc: data.agreement_doc || 'vendor_agreement.pdf',
      contract_start: data.contract_start || new Date().toISOString().split('T')[0],
      contract_end: data.contract_end || '2027-12-31',
      status: 'Active'
    });

    logAudit({
      userId: req.user.id,
      userName: req.user.full_name,
      userRole: req.user.role,
      actionType: 'CREATE',
      module: 'Vendor',
      affectedRecordId: newVendor.id,
      details: `Created contractor vendor ${newVendor.company_name} (${newVendor.vendor_id})`,
      ipAddress: req.ip
    });

    res.status(201).json({ success: true, message: 'Vendor created successfully', data: newVendor });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const updateVendor = async (req, res) => {
  try {
    const vendor = db.vendors.findById(req.params.id);
    if (!vendor) {
      return res.status(404).json({ success: false, message: 'Vendor not found' });
    }

    const updated = db.vendors.update(vendor.id, req.body);

    logAudit({
      userId: req.user.id,
      userName: req.user.full_name,
      userRole: req.user.role,
      actionType: 'UPDATE',
      module: 'Vendor',
      affectedRecordId: vendor.id,
      details: `Updated vendor ${updated.company_name}`,
      ipAddress: req.ip
    });

    res.json({ success: true, message: 'Vendor updated successfully', data: updated });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getVendors,
  getVendorById,
  createVendor,
  updateVendor
};
