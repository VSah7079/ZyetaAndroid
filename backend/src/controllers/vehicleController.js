const db = require('../config/db');
const { logAudit } = require('../middleware/audit');

const getVehicles = async (req, res) => {
  try {
    const { search, status } = req.query;
    let list = db.vehicles.find();

    if (status) {
      list = list.filter((v) => v.status.toLowerCase() === status.toLowerCase());
    }

    if (search) {
      const q = search.toLowerCase();
      list = list.filter((v) =>
        v.vehicle_number.toLowerCase().includes(q) ||
        v.driver_name.toLowerCase().includes(q) ||
        (v.owner_vendor && v.owner_vendor.toLowerCase().includes(q))
      );
    }

    // Check compliance flags (PUC / Insurance)
    const today = new Date();
    const enriched = list.map((veh) => {
      let isPucExpired = veh.puc_validity && new Date(veh.puc_validity) < today;
      let isInsuranceExpired = veh.insurance_validity && new Date(veh.insurance_validity) < today;
      return {
        ...veh,
        is_puc_expired: isPucExpired,
        is_insurance_expired: isInsuranceExpired,
        compliance_status: (isPucExpired || isInsuranceExpired) ? 'Non-Compliant' : 'Compliant'
      };
    });

    res.json({ success: true, count: enriched.length, data: enriched });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const createVehicle = async (req, res) => {
  try {
    const data = req.body;
    if (!data.vehicle_number || !data.vehicle_type) {
      return res.status(400).json({ success: false, message: 'Vehicle number and type are required' });
    }

    const newVehicle = db.vehicles.create({
      vehicle_number: data.vehicle_number.toUpperCase().trim(),
      vehicle_type: data.vehicle_type,
      owner_vendor: data.owner_vendor || 'Self / Contract',
      driver_name: data.driver_name || '',
      driver_mobile: data.driver_mobile || '',
      rc_number: data.rc_number || '',
      insurance_validity: data.insurance_validity || '2027-12-31',
      puc_validity: data.puc_validity || '2027-12-31',
      fitness_validity: data.fitness_validity || '2027-12-31',
      status: 'Active',
      notes: data.notes || ''
    });

    logAudit({
      userId: req.user.id,
      userName: req.user.full_name,
      userRole: req.user.role,
      actionType: 'CREATE',
      module: 'Vehicle',
      affectedRecordId: newVehicle.id,
      details: `Registered vehicle ${newVehicle.vehicle_number} (${newVehicle.vehicle_type})`,
      ipAddress: req.ip
    });

    res.status(201).json({ success: true, message: 'Vehicle registered successfully', data: newVehicle });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getVehicles,
  createVehicle
};
