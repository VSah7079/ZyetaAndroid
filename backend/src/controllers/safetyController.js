const db = require('../config/db');

let _safetyPunches = [
  {
    id: 1,
    punch_code: 'PCH-2026-101',
    worker_name: 'Ramesh Patel',
    worker_id: 'EMP-101',
    vendor_name: 'ABC Infra Projects Pvt Ltd',
    color_type: 'RED',
    category: 'Critical Stop-Work Violation',
    reason: 'Working at 14m scaffold elevation without chin strap and harness hook loose.',
    zone: 'Block A - 4th Floor Facade',
    photo_url: 'https://images.unsplash.com/photo-1541888946425-d0fbb186156a?w=400&auto=format&fit=crop&q=80',
    corrective_action: 'Immediate Work Stoppage. Chin-strap fastened & harness dual-lanyards anchored to 100% lifeline.',
    reported_by: 'Er. Rajesh Varma (HSE Head)',
    timestamp: '2026-09-29T10:15:00Z',
    status: 'STOP_WORK',
  },
  {
    id: 2,
    punch_code: 'PCH-2026-102',
    worker_name: 'Amitabh Sen',
    worker_id: 'EMP-102',
    vendor_name: 'Apex MEP Solutions',
    color_type: 'YELLOW',
    category: 'Moderate Warning / PPE',
    reason: 'Missing cut-resistant safety gloves & eye protection goggles in active fabrication zone.',
    zone: 'Tower B - Electrical Sub-station',
    photo_url: 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=400&auto=format&fit=crop&q=80',
    corrective_action: 'Issued compliant PPE kit from central safety store. 24hr rectification warning recorded.',
    reported_by: 'Er. Rajesh Varma (HSE Head)',
    timestamp: '2026-09-29T11:45:00Z',
    status: 'ACKNOWLEDGED',
  },
  {
    id: 3,
    punch_code: 'PCH-2026-103',
    worker_name: 'Vikram Rathore',
    worker_id: 'EMP-104',
    vendor_name: 'ABC Infra Projects Pvt Ltd',
    color_type: 'GREEN',
    category: 'Safety Excellence / Proactive',
    reason: 'Proactive deployment of spark capture fire blankets & standby fire extinguisher before welding.',
    zone: 'Basement 1 - Structural Bay',
    photo_url: 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=400&auto=format&fit=crop&q=80',
    corrective_action: 'Commended during safety briefing. Awarded +25 Zero Harm Safety points.',
    reported_by: 'Er. Rajesh Varma (HSE Head)',
    timestamp: '2026-09-29T13:20:00Z',
    status: 'COMMENDED',
  },
];

exports.getPunches = (req, res) => {
  const { color_type, search } = req.query;
  let list = _safetyPunches;

  if (color_type && color_type !== 'ALL') {
    list = list.filter(p => p.color_type === color_type);
  }

  if (search) {
    const s = search.toLowerCase();
    list = list.filter(p =>
      p.worker_name.toLowerCase().includes(s) ||
      p.worker_id.toLowerCase().includes(s) ||
      p.punch_code.toLowerCase().includes(s) ||
      p.reason.toLowerCase().includes(s) ||
      p.zone.toLowerCase().includes(s)
    );
  }

  res.json({ success: true, data: list });
};

exports.createPunch = (req, res) => {
  const { color_type, worker_name, worker_id, vendor_name, reason, photo_url, zone, corrective_action, category } = req.body;
  const newId = _safetyPunches.length + 101;

  const punch = {
    id: Date.now(),
    punch_code: `PCH-2026-${newId}`,
    worker_name: worker_name || 'Worker',
    worker_id: worker_id || 'EMP-101',
    vendor_name: vendor_name || 'Contractor',
    color_type: color_type || 'RED',
    category: category || (color_type === 'RED' ? 'Critical Stop-Work' : (color_type === 'YELLOW' ? 'PPE Warning' : 'Safety Excellence')),
    reason: reason || 'Safety observation logged',
    zone: zone || 'Main Site Zone',
    photo_url: photo_url || 'https://images.unsplash.com/photo-1541888946425-d0fbb186156a?w=400&auto=format&fit=crop&q=80',
    corrective_action: corrective_action || 'Corrective action initiated',
    reported_by: req.user?.full_name || 'Er. Rajesh Varma',
    timestamp: new Date().toISOString(),
    status: color_type === 'GREEN' ? 'COMMENDED' : 'OPEN',
  };

  _safetyPunches.unshift(punch);
  res.status(201).json({ success: true, message: 'Safety punch recorded', data: punch });
};

exports.deletePunch = (req, res) => {
  const id = parseInt(req.params.id);
  _safetyPunches = _safetyPunches.filter(p => p.id !== id);
  res.json({ success: true, message: 'Safety punch deleted' });
};
