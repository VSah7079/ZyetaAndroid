const bcrypt = require('bcryptjs');
const QRCode = require('qrcode');
const db = require('../config/db');

async function seed() {
  console.log('--- Starting Database Seeding ---');

  // Clear existing
  db.users.clear();
  db.roles.clear();
  db.sites.clear();
  db.departments.clear();
  db.shifts.clear();
  db.gates.clear();
  db.vendors.clear();
  db.employees.clear();
  db.employee_documents.clear();
  db.vendor_documents.clear();
  db.gate_transactions.clear();
  db.attendance.clear();
  db.permits.clear();
  db.materials.clear();
  db.visitors.clear();
  db.vehicles.clear();
  db.notifications.clear();
  db.audit_logs.clear();

  // 1. Roles
  const roles = [
    { id: 1, name: 'Super Admin', description: 'Complete system-wide access and master configuration', permissions: ['all'] },
    { id: 2, name: 'Admin', description: 'Workforce, vendor, permits and reports management', permissions: ['employees', 'vendors', 'attendance', 'permits', 'materials', 'visitors', 'vehicles', 'reports'] },
    { id: 3, name: 'Vendor', description: 'Contractor portal for employee onboarding and permit requests', permissions: ['my_employees', 'my_permits', 'my_attendance', 'my_documents'] },
    { id: 4, name: 'Security', description: 'Gate operations, QR verification, entry/exit logs', permissions: ['scan_qr', 'gate_entry', 'gate_exit', 'visitors', 'materials', 'vehicles'] }
  ];
  roles.forEach(r => db.roles.create(r));

  // 2. Sites & Gates
  db.sites.create({ id: 1, name: 'Bangalore Tech Park Campus', code: 'BLR-01', address: 'Whitefield Industrial Area', city: 'Bangalore', status: 'Active' });
  db.sites.create({ id: 2, name: 'Hyderabad Manufacturing Plant', code: 'HYD-01', address: 'HITEC Zone 3', city: 'Hyderabad', status: 'Active' });

  db.departments.create({ id: 1, name: 'Civil & Construction', code: 'CIVIL', site_id: 1 });
  db.departments.create({ id: 2, name: 'Electrical & MEP', code: 'MEP', site_id: 1 });
  db.departments.create({ id: 3, name: 'Logistics & Warehousing', code: 'LOG', site_id: 1 });
  db.departments.create({ id: 4, name: 'Safety & Quality', code: 'HSE', site_id: 1 });

  db.shifts.create({ id: 1, name: 'General Shift (09:00 - 18:00)', start_time: '09:00', end_time: '18:00', grace_minutes: 15 });
  db.shifts.create({ id: 2, name: 'Morning Shift A (06:00 - 14:30)', start_time: '06:00', end_time: '14:30', grace_minutes: 15 });
  db.shifts.create({ id: 3, name: 'Night Shift C (22:00 - 06:30)', start_time: '22:00', end_time: '06:30', grace_minutes: 15 });

  db.gates.create({ id: 1, site_id: 1, name: 'Main Security Gate 1', code: 'G-01', gate_type: 'Main Gate', status: 'Active' });
  db.gates.create({ id: 2, site_id: 1, name: 'Material & Heavy Vehicle Gate 2', code: 'G-02', gate_type: 'Material Gate', status: 'Active' });
  db.gates.create({ id: 3, site_id: 1, name: 'Turnstile Pedestrian Gate 3', code: 'G-03', gate_type: 'Pedestrian Gate', status: 'Active' });

  // 3. Vendors
  const vendor1 = db.vendors.create({
    id: 1,
    vendor_id: 'VND-1001',
    company_name: 'ABC Infra Projects Pvt Ltd',
    owner_name: 'Rajesh Sharma',
    email: 'rajesh@abcinfra.com',
    phone: '+91 9845012345',
    address: 'Plot 45, Peenya Industrial Area, Bangalore',
    gst_pan: '29ABCDE1234F1Z5 / ABCDE1234F',
    agreement_doc: 'doc_vnd_1001_contract.pdf',
    contract_start: '2026-01-01',
    contract_end: '2026-12-31',
    status: 'Active'
  });

  const vendor2 = db.vendors.create({
    id: 2,
    vendor_id: 'VND-1002',
    company_name: 'Apex MEP & Electrical Solutions',
    owner_name: 'Suresh Kumar',
    email: 'suresh@apexservices.in',
    phone: '+91 9845098765',
    address: 'Electronic City Phase 1, Bangalore',
    gst_pan: '29APEXM5678G2Z1 / APEXM5678G',
    agreement_doc: 'doc_vnd_1002_contract.pdf',
    contract_start: '2026-03-01',
    contract_end: '2027-02-28',
    status: 'Active'
  });

  const vendor3 = db.vendors.create({
    id: 3,
    vendor_id: 'VND-1003',
    company_name: 'FastTrack Logistics & Supply',
    owner_name: 'Anil Verma',
    email: 'anil@fasttracklog.com',
    phone: '+91 9711223344',
    address: 'Bommasandra Industrial Area, Bangalore',
    gst_pan: '29FTLSC9988H1Z9 / FTLSC9988H',
    agreement_doc: 'doc_vnd_1003_contract.pdf',
    contract_start: '2025-06-01',
    contract_end: '2026-10-31', // Expiring soon!
    status: 'Active'
  });

  // 4. Users (Hashed Passwords)
  const salt = bcrypt.genSaltSync(10);
  const passwordHash = bcrypt.hashSync('admin123', salt);
  const vendorHash = bcrypt.hashSync('vendor123', salt);
  const securityHash = bcrypt.hashSync('security123', salt);

  db.users.create({
    id: 1,
    username: 'superadmin',
    email: 'superadmin@zyeta.com',
    password_hash: passwordHash,
    role: 'Super Admin',
    full_name: 'Vikram Malhotra',
    phone: '+91 9900112233',
    site_id: 1,
    status: 'Active'
  });

  db.users.create({
    id: 2,
    username: 'admin',
    email: 'admin@zyeta.com',
    password_hash: passwordHash,
    role: 'Admin',
    full_name: 'Priya Sundaram',
    phone: '+91 9900223344',
    site_id: 1,
    status: 'Active'
  });

  db.users.create({
    id: 3,
    username: 'vendor_infra',
    email: 'vendor@abcinfra.com',
    password_hash: vendorHash,
    role: 'Vendor',
    vendor_id: 1,
    full_name: 'Rajesh Sharma (ABC Infra)',
    phone: '+91 9845012345',
    site_id: 1,
    status: 'Active'
  });

  db.users.create({
    id: 4,
    username: 'security_gate1',
    email: 'security@zyeta.com',
    password_hash: securityHash,
    role: 'Security',
    full_name: 'Commander R. K. Singh',
    phone: '+91 9122334455',
    site_id: 1,
    status: 'Active'
  });

  // 5. Employees & KYC Data & Dynamic QR
  const sampleEmployees = [
    {
      id: 1,
      employee_id: 'EMP-101',
      full_name: 'Ramesh Patel',
      father_name: 'Dinesh Patel',
      dob: '1990-05-14',
      gender: 'Male',
      mobile: '+91 9876543210',
      alternate_mobile: '+91 9876543211',
      email: 'ramesh.patel@workforce.com',
      address: 'House #42, Munnekolala',
      city: 'Bangalore',
      state: 'Karnataka',
      pincode: '560037',
      emergency_name: 'Sunita Patel',
      emergency_relation: 'Spouse',
      emergency_phone: '+91 9876543212',
      blood_group: 'B+',
      medical_cert: 'Fit for Height Work',
      medical_validity: '2027-01-15',
      vendor_id: 1,
      department_id: 1,
      designation: 'Senior Scaffolding Lead',
      skill: 'Expert Scaffolder',
      employee_type: 'Contractor',
      joining_date: '2024-02-10',
      shift_id: 1,
      aadhaar_no: '4532 8912 7701',
      pan_no: 'ABCDE9876K',
      police_verification_doc: 'police_verified_blr_101.pdf',
      police_verification_expiry: '2027-02-01',
      profile_photo: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
      status: 'Active',
      currently_inside: 1,
      last_entry_time: '2026-09-26T08:45:00Z',
      last_exit_time: null
    },
    {
      id: 2,
      employee_id: 'EMP-102',
      full_name: 'Amitabh Sen',
      father_name: 'Prabir Sen',
      dob: '1988-11-20',
      gender: 'Male',
      mobile: '+91 9876501234',
      alternate_mobile: '',
      email: 'amitabh.sen@apexservices.in',
      address: 'Flat 302, Green Glen Layout, Bellandur',
      city: 'Bangalore',
      state: 'Karnataka',
      pincode: '560103',
      emergency_name: 'Shampa Sen',
      emergency_relation: 'Spouse',
      emergency_phone: '+91 9876509988',
      blood_group: 'O+',
      medical_cert: 'Fit for Electrical Hot Work',
      medical_validity: '2026-11-30',
      vendor_id: 2,
      department_id: 2,
      designation: 'Certified HT Electrician',
      skill: 'High Voltage Specialist',
      employee_type: 'Contractor',
      joining_date: '2024-04-15',
      shift_id: 1,
      aadhaar_no: '8821 3490 1123',
      pan_no: 'BLRPS4412M',
      police_verification_doc: 'police_verified_blr_102.pdf',
      police_verification_expiry: '2026-10-05', // Expiring in < 15 days!
      profile_photo: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
      status: 'Active',
      currently_inside: 1,
      last_entry_time: '2026-09-26T08:52:00Z',
      last_exit_time: null
    },
    {
      id: 3,
      employee_id: 'EMP-103',
      full_name: 'Kavita Reddy',
      father_name: 'Narayana Reddy',
      dob: '1995-03-08',
      gender: 'Female',
      mobile: '+91 9811223344',
      alternate_mobile: '',
      email: 'kavita.reddy@zyeta.com',
      address: '22/B, Indiranagar 100ft Road',
      city: 'Bangalore',
      state: 'Karnataka',
      pincode: '560038',
      emergency_name: 'Narayana Reddy',
      emergency_relation: 'Father',
      emergency_phone: '+91 9811223399',
      blood_group: 'A+',
      medical_cert: 'General Medical Fitness',
      medical_validity: '2027-05-10',
      vendor_id: null,
      department_id: 4,
      designation: 'HSE Safety Officer',
      skill: 'NEBOSH IGC Certified',
      employee_type: 'Permanent',
      joining_date: '2023-01-10',
      shift_id: 1,
      aadhaar_no: '7612 9901 3345',
      pan_no: 'REDDK1290Z',
      police_verification_doc: 'police_verified_blr_103.pdf',
      police_verification_expiry: '2027-08-20',
      profile_photo: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
      status: 'Active',
      currently_inside: 1,
      last_entry_time: '2026-09-26T08:30:00Z',
      last_exit_time: null
    },
    {
      id: 4,
      employee_id: 'EMP-104',
      full_name: 'Mohd. Salim Khan',
      father_name: 'Ayub Khan',
      dob: '1992-08-12',
      gender: 'Male',
      mobile: '+91 9740112233',
      alternate_mobile: '',
      email: 'salim.khan@abcinfra.com',
      address: 'K.R. Puram, Old Madras Road',
      city: 'Bangalore',
      state: 'Karnataka',
      pincode: '560036',
      emergency_name: 'Farida Khan',
      emergency_relation: 'Mother',
      emergency_phone: '+91 9740112299',
      blood_group: 'AB+',
      medical_cert: 'Fit for Heavy Equipment Operation',
      medical_validity: '2026-12-31',
      vendor_id: 1,
      department_id: 1,
      designation: 'Hydraulic Crane Operator',
      skill: 'Heavy Vehicle Class IV',
      employee_type: 'Contractor',
      joining_date: '2024-05-01',
      shift_id: 1,
      aadhaar_no: '3321 6789 4455',
      pan_no: 'KHANM7788P',
      police_verification_doc: 'police_verified_blr_104.pdf',
      police_verification_expiry: '2026-09-15', // EXPIRED!
      profile_photo: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&auto=format&fit=crop&q=80',
      status: 'Active',
      currently_inside: 0,
      last_entry_time: '2026-09-25T09:00:00Z',
      last_exit_time: '2026-09-25T18:05:00Z'
    },
    {
      id: 5,
      employee_id: 'EMP-105',
      full_name: 'Gurpreet Singh',
      father_name: 'Harbhajan Singh',
      dob: '1994-01-25',
      gender: 'Male',
      mobile: '+91 9620334455',
      alternate_mobile: '',
      email: 'gurpreet@fasttracklog.com',
      address: 'Anekal Road, Chandapura',
      city: 'Bangalore',
      state: 'Karnataka',
      pincode: '560099',
      emergency_name: 'Jaspreet Kaur',
      emergency_relation: 'Sister',
      emergency_phone: '+91 9620334499',
      blood_group: 'B+',
      medical_cert: 'Forklift & Logistics Fitness',
      medical_validity: '2027-03-20',
      vendor_id: 3,
      department_id: 3,
      designation: 'Warehouse Inventory Lead',
      skill: 'Forklift & Material Movement',
      employee_type: 'Contractor',
      joining_date: '2024-08-01',
      shift_id: 2,
      aadhaar_no: '9901 2234 5566',
      pan_no: 'SNGHG4433Q',
      police_verification_doc: 'police_verified_blr_105.pdf',
      police_verification_expiry: '2027-01-10',
      profile_photo: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150&auto=format&fit=crop&q=80',
      status: 'Active',
      currently_inside: 0,
      last_entry_time: '2026-09-25T06:10:00Z',
      last_exit_time: '2026-09-25T14:40:00Z'
    },
    {
      id: 6,
      employee_id: 'EMP-106',
      full_name: 'Sunil Verma',
      father_name: 'Radheshyam Verma',
      dob: '1996-09-12',
      gender: 'Male',
      mobile: '+91 9880112233',
      alternate_mobile: '',
      email: 'sunil.verma@abcinfra.com',
      address: 'Marathahalli Village',
      city: 'Bangalore',
      state: 'Karnataka',
      pincode: '560037',
      emergency_name: 'Radheshyam Verma',
      emergency_relation: 'Father',
      emergency_phone: '+91 9880112299',
      blood_group: 'A-',
      medical_cert: 'General Fitness',
      medical_validity: '2027-04-12',
      vendor_id: 1,
      department_id: 1,
      designation: 'Bar Bender & Steel Fixer',
      skill: 'Rebar Fabrication',
      employee_type: 'Contractor',
      joining_date: '2025-01-15',
      shift_id: 1,
      aadhaar_no: '5544 3322 1100',
      pan_no: 'VRMAS9900L',
      police_verification_doc: 'police_verified_blr_106.pdf',
      police_verification_expiry: '2027-06-18',
      profile_photo: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
      status: 'Active',
      currently_inside: 1,
      last_entry_time: '2026-09-26T08:58:00Z',
      last_exit_time: null
    }
  ];

  for (const emp of sampleEmployees) {
    // Generate QR code data string & data URI
    const qrPayload = JSON.stringify({
      id: emp.id,
      empId: emp.employee_id,
      name: emp.full_name,
      vendor: emp.vendor_id === 1 ? 'ABC Infra Projects' : emp.vendor_id === 2 ? 'Apex MEP' : emp.vendor_id === 3 ? 'FastTrack' : 'Zyeta Direct',
      type: emp.employee_type,
      bloodGroup: emp.blood_group,
      validUntil: '2027-12-31'
    });
    emp.qr_code_data = await QRCode.toDataURL(qrPayload);
    db.employees.create(emp);

    // Add documents
    db.employee_documents.create({
      employee_id: emp.id,
      document_type: 'Aadhaar Card',
      document_number: emp.aadhaar_no,
      document_file: `aadhaar_${emp.employee_id}.pdf`,
      issue_date: '2018-01-01',
      expiry_date: '2099-12-31',
      verification_status: 'Verified',
      verified_by: 'Admin Priya',
      verified_at: '2024-02-10T10:00:00Z',
      notes: 'Original Aadhaar Verified with biometric match'
    });

    db.employee_documents.create({
      employee_id: emp.id,
      document_type: 'Police Verification Certificate',
      document_number: `PVC-${emp.employee_id}-BLR`,
      document_file: emp.police_verification_doc,
      issue_date: '2024-01-01',
      expiry_date: emp.police_verification_expiry,
      verification_status: new Date(emp.police_verification_expiry) < new Date() ? 'Expired' : 'Verified',
      verified_by: 'Super Admin Vikram',
      verified_at: '2024-02-11T12:00:00Z',
      notes: 'State Police Background Check'
    });
  }

  // 6. Gate Transactions
  db.gate_transactions.create({
    transaction_code: 'GTX-20260926-001',
    record_type: 'Employee',
    entity_id: 3,
    entity_code: 'EMP-103',
    entity_name: 'Kavita Reddy',
    entity_role: 'HSE Safety Officer',
    vendor_name: 'Zyeta Direct',
    movement_type: 'ENTRY',
    timestamp: '2026-09-26T08:30:15Z',
    gate_id: 1,
    gate_name: 'Main Security Gate 1',
    security_user_id: 4,
    security_user_name: 'Commander R. K. Singh',
    device_id: 'TAB-GATE-01',
    verification_method: 'QR_SCAN',
    status: 'ALLOW',
    remarks: 'Routine Morning Entry'
  });

  db.gate_transactions.create({
    transaction_code: 'GTX-20260926-002',
    record_type: 'Employee',
    entity_id: 1,
    entity_code: 'EMP-101',
    entity_name: 'Ramesh Patel',
    entity_role: 'Senior Scaffolding Lead',
    vendor_name: 'ABC Infra Projects Pvt Ltd',
    movement_type: 'ENTRY',
    timestamp: '2026-09-26T08:45:22Z',
    gate_id: 1,
    gate_name: 'Main Security Gate 1',
    security_user_id: 4,
    security_user_name: 'Commander R. K. Singh',
    device_id: 'TAB-GATE-01',
    verification_method: 'QR_SCAN',
    status: 'ALLOW',
    remarks: 'Approved Contractor Access'
  });

  db.gate_transactions.create({
    transaction_code: 'GTX-20260926-003',
    record_type: 'Employee',
    entity_id: 2,
    entity_code: 'EMP-102',
    entity_name: 'Amitabh Sen',
    entity_role: 'Certified HT Electrician',
    vendor_name: 'Apex MEP & Electrical Solutions',
    movement_type: 'ENTRY',
    timestamp: '2026-09-26T08:52:10Z',
    gate_id: 1,
    gate_name: 'Main Security Gate 1',
    security_user_id: 4,
    security_user_name: 'Commander R. K. Singh',
    device_id: 'TAB-GATE-01',
    verification_method: 'QR_SCAN',
    status: 'ALLOW',
    remarks: 'Hot Work Permit Attached'
  });

  db.gate_transactions.create({
    transaction_code: 'GTX-20260926-004',
    record_type: 'Employee',
    entity_id: 6,
    entity_code: 'EMP-106',
    entity_name: 'Sunil Verma',
    entity_role: 'Bar Bender & Steel Fixer',
    vendor_name: 'ABC Infra Projects Pvt Ltd',
    movement_type: 'ENTRY',
    timestamp: '2026-09-26T08:58:40Z',
    gate_id: 3,
    gate_name: 'Turnstile Pedestrian Gate 3',
    security_user_id: 4,
    security_user_name: 'Commander R. K. Singh',
    device_id: 'TAB-GATE-03',
    verification_method: 'QR_SCAN',
    status: 'ALLOW',
    remarks: 'Shift 1 Entry'
  });

  // 7. Attendance Records for Today
  const todayDate = new Date().toISOString().split('T')[0];
  db.attendance.create({
    employee_id: 3,
    employee_code: 'EMP-103',
    employee_name: 'Kavita Reddy',
    vendor_id: null,
    vendor_name: 'Zyeta Direct',
    date: todayDate,
    punch_in: '2026-09-26T08:30:15Z',
    punch_out: null,
    punch_in_gate: 'Main Security Gate 1',
    punch_out_gate: null,
    status: 'Present',
    late_minutes: 0,
    overtime_minutes: 0,
    source: 'Gate Movement',
    marked_by: 'Gate Automation'
  });

  db.attendance.create({
    employee_id: 1,
    employee_code: 'EMP-101',
    employee_name: 'Ramesh Patel',
    vendor_id: 1,
    vendor_name: 'ABC Infra Projects Pvt Ltd',
    date: todayDate,
    punch_in: '2026-09-26T08:45:22Z',
    punch_out: null,
    punch_in_gate: 'Main Security Gate 1',
    punch_out_gate: null,
    status: 'Present',
    late_minutes: 0,
    overtime_minutes: 0,
    source: 'Gate Movement',
    marked_by: 'Gate Automation'
  });

  db.attendance.create({
    employee_id: 2,
    employee_code: 'EMP-102',
    employee_name: 'Amitabh Sen',
    vendor_id: 2,
    vendor_name: 'Apex MEP & Electrical Solutions',
    date: todayDate,
    punch_in: '2026-09-26T08:52:10Z',
    punch_out: null,
    punch_in_gate: 'Main Security Gate 1',
    punch_out_gate: null,
    status: 'Present',
    late_minutes: 0,
    overtime_minutes: 0,
    source: 'Gate Movement',
    marked_by: 'Gate Automation'
  });

  db.attendance.create({
    employee_id: 6,
    employee_code: 'EMP-106',
    employee_name: 'Sunil Verma',
    vendor_id: 1,
    vendor_name: 'ABC Infra Projects Pvt Ltd',
    date: todayDate,
    punch_in: '2026-09-26T08:58:40Z',
    punch_out: null,
    punch_in_gate: 'Turnstile Pedestrian Gate 3',
    punch_out_gate: null,
    status: 'Present',
    late_minutes: 0,
    overtime_minutes: 0,
    source: 'Gate Movement',
    marked_by: 'Gate Automation'
  });

  // 8. Permits
  db.permits.create({
    id: 1,
    permit_number: 'PRM-2026-001',
    permit_type: 'Hot Work Permit',
    vendor_id: 2,
    vendor_name: 'Apex MEP & Electrical Solutions',
    applicant_name: 'Suresh Kumar',
    applicant_contact: '+91 9845098765',
    description: 'Gas cutting and arc welding on 3rd floor HVAC ducting framework',
    location_zone: 'Building B - Level 3 Mechanical Room',
    start_time: '2026-09-26T09:00:00Z',
    end_time: '2026-09-26T17:00:00Z',
    status: 'Active',
    approved_by: 'Priya Sundaram (Admin)',
    approved_at: '2026-09-26T08:00:00Z',
    security_verified_by: 'Commander R. K. Singh',
    security_verified_at: '2026-09-26T08:50:00Z',
    safety_checklist: JSON.stringify({
      fire_extinguisher_placed: true,
      ppe_flame_resistant: true,
      spark_shield_installed: true,
      gas_detector_calibrated: true,
      standby_fire_watcher: 'Assigned'
    }),
    attachment_file: 'hot_work_risk_assessment_01.pdf'
  });

  db.permits.create({
    id: 2,
    permit_number: 'PRM-2026-002',
    permit_type: 'Height Work Permit',
    vendor_id: 1,
    vendor_name: 'ABC Infra Projects Pvt Ltd',
    applicant_name: 'Rajesh Sharma',
    applicant_contact: '+91 9845012345',
    description: 'External facade scaffolding erection above 15 meters',
    location_zone: 'Tower A - North Elevation Facade',
    start_time: '2026-09-26T08:30:00Z',
    end_time: '2026-09-26T18:00:00Z',
    status: 'Active',
    approved_by: 'Priya Sundaram (Admin)',
    approved_at: '2026-09-26T08:15:00Z',
    security_verified_by: 'Commander R. K. Singh',
    security_verified_at: '2026-09-26T08:42:00Z',
    safety_checklist: JSON.stringify({
      full_body_harness: true,
      double_lanyard_shock_absorber: true,
      scaffold_tagged_green: true,
      weather_conditions_safe: true
    }),
    attachment_file: 'scaffold_structural_cert_02.pdf'
  });

  db.permits.create({
    id: 3,
    permit_number: 'PRM-2026-003',
    permit_type: 'Electrical Permit',
    vendor_id: 2,
    vendor_name: 'Apex MEP & Electrical Solutions',
    applicant_name: 'Suresh Kumar',
    applicant_contact: '+91 9845098765',
    description: 'Main substation 11kV busbar shutdown and preventive maintenance',
    location_zone: 'Substation Yard - Transformer Bay 2',
    start_time: '2026-09-27T10:00:00Z',
    end_time: '2026-09-27T16:00:00Z',
    status: 'Pending',
    approved_by: null,
    safety_checklist: JSON.stringify({
      loto_applied: true,
      earthing_rods_connected: true,
      arc_flash_suit: true
    }),
    attachment_file: 'loto_procedure_substation.pdf'
  });

  // 9. Materials & DC Movement
  db.materials.create({
    id: 1,
    dc_number: 'DC-2026-098',
    vendor_id: 1,
    vendor_name: 'ABC Infra Projects Pvt Ltd',
    material_name: 'Heavy Duty Cuplock Scaffolding Pipes & Clamps',
    category: 'Scaffolding',
    quantity: 450,
    unit: 'Nos',
    invoice_number: 'INV/2026/7821',
    vehicle_number: 'KA 01 MJ 8812',
    driver_name: 'Manoj Kumar',
    driver_mobile: '+91 9822334455',
    movement_type: 'RETURNABLE_IN',
    entry_time: '2026-09-26T08:15:00Z',
    exit_time: null,
    gate_id: 2,
    photo_url: 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=300&auto=format&fit=crop&q=80',
    return_dc_number: null,
    return_quantity: 0,
    return_status: 'Pending',
    status: 'Approved',
    remarks: 'Expected return in 30 days upon facade completion',
    created_by: 'Commander R. K. Singh'
  });

  db.materials.create({
    id: 2,
    dc_number: 'DC-2026-099',
    vendor_id: 3,
    vendor_name: 'FastTrack Logistics & Supply',
    material_name: 'Ready Mix Concrete Grade M35',
    category: 'Raw Material',
    quantity: 24,
    unit: 'Ton',
    invoice_number: 'RMC/BLR/4509',
    vehicle_number: 'KA 51 D 9002',
    driver_name: 'Basavaraj G.',
    driver_mobile: '+91 9911445566',
    movement_type: 'INWARD',
    entry_time: '2026-09-26T09:10:00Z',
    exit_time: '2026-09-26T10:05:00Z',
    gate_id: 2,
    photo_url: 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?w=300&auto=format&fit=crop&q=80',
    return_status: 'Not Applicable',
    status: 'Approved',
    remarks: 'Discharged at Foundation Block C',
    created_by: 'Commander R. K. Singh'
  });

  // 10. Visitors
  db.visitors.create({
    id: 1,
    pass_code: 'VIS-2026-101',
    visitor_name: 'Dr. Anand Deshmukh',
    mobile: '+91 9833445566',
    company: 'Structural Safety Audits India',
    person_to_meet: 'Priya Sundaram (Admin)',
    purpose: 'Third-party Structural Stability Audit',
    vehicle_number: 'KA 03 NA 4422',
    id_proof_type: 'Aadhaar',
    id_proof_number: 'XXXX-XXXX-9021',
    photo_url: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&auto=format&fit=crop&q=80',
    expected_entry: '2026-09-26T10:00:00Z',
    expected_exit: '2026-09-26T14:00:00Z',
    actual_entry: '2026-09-26T09:55:00Z',
    actual_exit: null,
    gate_id: 1,
    status: 'Inside',
    host_approved: 1
  });

  db.visitors.create({
    id: 2,
    pass_code: 'VIS-2026-102',
    visitor_name: 'Meenakshi Iyer',
    mobile: '+91 9844556677',
    company: 'Schneider Electric Field Service',
    person_to_meet: 'Amitabh Sen',
    purpose: 'HT Panel Commissioning Assistance',
    vehicle_number: 'KA 05 MN 1234',
    id_proof_type: 'Driving License',
    id_proof_number: 'KA-05-2015-0091223',
    photo_url: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80',
    expected_entry: '2026-09-26T11:00:00Z',
    expected_exit: '2026-09-26T15:00:00Z',
    actual_entry: null,
    actual_exit: null,
    gate_id: 1,
    status: 'Pre-Registered',
    host_approved: 1
  });

  // 11. Vehicles
  db.vehicles.create({
    id: 1,
    vehicle_number: 'KA 01 MJ 8812',
    vehicle_type: 'Truck (Multi-Axle)',
    owner_vendor: 'ABC Infra Projects Pvt Ltd',
    driver_name: 'Manoj Kumar',
    driver_mobile: '+91 9822334455',
    rc_number: 'RC-KA01-2022-901',
    insurance_validity: '2027-03-15',
    puc_validity: '2026-11-20',
    fitness_validity: '2027-01-30',
    status: 'Active',
    notes: 'Regular site delivery truck'
  });

  db.vehicles.create({
    id: 2,
    vehicle_number: 'KA 51 D 9002',
    vehicle_type: 'Transit Mixer (RMC)',
    owner_vendor: 'FastTrack Logistics & Supply',
    driver_name: 'Basavaraj G.',
    driver_mobile: '+91 9911445566',
    rc_number: 'RC-KA51-2023-455',
    insurance_validity: '2026-12-10',
    puc_validity: '2026-09-10', // EXPIRED PUC ALERT!
    fitness_validity: '2026-12-31',
    status: 'Active',
    notes: 'PUC renewal pending'
  });

  // 12. Notifications
  db.notifications.create({
    recipient_role: 'All',
    title: 'Site Safety Briefing Scheduled',
    message: 'Mandatory safety protocol refresher at 14:00 today at Briefing Area 1.',
    event_type: 'SAFETY_ALERT',
    related_id: null,
    is_read: 0
  });

  db.notifications.create({
    recipient_role: 'Admin',
    title: 'New Permit Request: Electrical Bay Shutdown',
    message: 'Apex MEP submitted PRM-2026-003 for substation maintenance. Requires approval.',
    event_type: 'PERMIT_PENDING',
    related_id: 3,
    is_read: 0
  });

  db.notifications.create({
    recipient_role: 'Admin',
    recipient_vendor_id: 1,
    title: 'Document Expiry Alert: Mohd. Salim Khan',
    message: 'Police Verification document for Mohd. Salim Khan (EMP-104) has expired.',
    event_type: 'DOC_EXPIRY',
    related_id: 4,
    is_read: 0
  });

  // 13. Audit Log
  db.audit_logs.create({
    user_id: 1,
    user_name: 'Vikram Malhotra',
    user_role: 'Super Admin',
    action_type: 'CREATE',
    module: 'Auth',
    affected_record_id: '1',
    details: 'Initial system setup, role definitions, and site configuration initialized.',
    ip_address: '192.168.1.1'
  });

  console.log('--- Database Seeding Completed Successfully ---');
}

if (require.main === module) {
  seed();
}

module.exports = seed;
