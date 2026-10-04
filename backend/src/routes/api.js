const express = require('express');
const router = express.Router();

const { authenticateToken, authorizeRoles } = require('../middleware/auth');
const authController = require('../controllers/authController');
const employeeController = require('../controllers/employeeController');
const vendorController = require('../controllers/vendorController');
const gateController = require('../controllers/gateController');
const attendanceController = require('../controllers/attendanceController');
const permitController = require('../controllers/permitController');
const materialController = require('../controllers/materialController');
const visitorController = require('../controllers/visitorController');
const vehicleController = require('../controllers/vehicleController');
const dashboardController = require('../controllers/dashboardController');
const reportController = require('../controllers/reportController');
const notificationController = require('../controllers/notificationController');
const safetyController = require('../controllers/safetyController');

// --- 1. Auth Endpoints ---
router.post('/auth/login', authController.login);
router.get('/auth/me', authenticateToken, authController.getMe);
router.get('/auth/users', authenticateToken, authorizeRoles('Super Admin', 'Admin'), authController.getUsers);
router.post('/auth/users', authenticateToken, authorizeRoles('Super Admin'), authController.createUser);
router.get('/auth/roles', authenticateToken, authController.getRoles);

// --- 2. Dashboard & KPIs ---
router.get('/dashboard/stats', authenticateToken, dashboardController.getDashboardStats);

// --- 3. Employee Management ---
router.get('/employees', authenticateToken, employeeController.getEmployees);
router.get('/employees/:id', authenticateToken, employeeController.getEmployeeById);
router.post('/employees', authenticateToken, authorizeRoles('Super Admin', 'Admin', 'Vendor'), employeeController.createEmployee);
router.put('/employees/:id', authenticateToken, authorizeRoles('Super Admin', 'Admin', 'Vendor'), employeeController.updateEmployee);
router.delete('/employees/:id', authenticateToken, authorizeRoles('Super Admin', 'Admin'), employeeController.deleteEmployee);

// --- 4. Vendor Management ---
router.get('/vendors', authenticateToken, vendorController.getVendors);
router.get('/vendors/:id', authenticateToken, vendorController.getVendorById);
router.post('/vendors', authenticateToken, authorizeRoles('Super Admin', 'Admin'), vendorController.createVendor);
router.put('/vendors/:id', authenticateToken, authorizeRoles('Super Admin', 'Admin'), vendorController.updateVendor);

// --- 5. Gate & Security Operations ---
router.post('/gate/verify-qr', authenticateToken, gateController.verifyQR);
router.post('/gate/movement', authenticateToken, authorizeRoles('Super Admin', 'Admin', 'Security'), gateController.recordMovement);
router.get('/gate/inside', authenticateToken, gateController.getCurrentlyInside);
router.get('/gate/transactions', authenticateToken, gateController.getTransactions);

// --- 6. Attendance ---
router.get('/attendance', authenticateToken, attendanceController.getAttendance);
router.get('/attendance/summary', authenticateToken, attendanceController.getAttendanceSummary);
router.post('/attendance/manual', authenticateToken, authorizeRoles('Super Admin', 'Admin'), attendanceController.markManualAttendance);

// --- 7. Permits ---
router.get('/permits', authenticateToken, permitController.getPermits);
router.get('/permits/:id', authenticateToken, permitController.getPermitById);
router.post('/permits', authenticateToken, authorizeRoles('Super Admin', 'Admin', 'Vendor', 'Safety Officer'), permitController.createPermit);
router.put('/permits/:id/approve', authenticateToken, authorizeRoles('Super Admin', 'Admin', 'Safety Officer'), permitController.approvePermit);
router.put('/permits/:id/reject', authenticateToken, authorizeRoles('Super Admin', 'Admin', 'Safety Officer'), permitController.rejectPermit);
router.put('/permits/:id/verify-gate', authenticateToken, authorizeRoles('Super Admin', 'Admin', 'Security', 'Safety Officer'), permitController.verifyPermitGate);

// --- 8. Materials ---
router.get('/materials', authenticateToken, materialController.getMaterials);
router.post('/materials/entry', authenticateToken, authorizeRoles('Super Admin', 'Admin', 'Security', 'Vendor'), materialController.createMaterialEntry);
router.put('/materials/:id/return', authenticateToken, authorizeRoles('Super Admin', 'Admin', 'Security'), materialController.updateMaterialReturn);

// --- 9. Visitors ---
router.get('/visitors', authenticateToken, visitorController.getVisitors);
router.post('/visitors/register', authenticateToken, authorizeRoles('Super Admin', 'Admin', 'Security'), visitorController.registerVisitor);
router.put('/visitors/:id/checkout', authenticateToken, authorizeRoles('Super Admin', 'Admin', 'Security'), visitorController.checkoutVisitor);

// --- 10. Vehicles ---
router.get('/vehicles', authenticateToken, vehicleController.getVehicles);
router.post('/vehicles', authenticateToken, authorizeRoles('Super Admin', 'Admin', 'Security'), vehicleController.createVehicle);

// --- 11. Reports & Audit Logs ---
router.get('/reports/data', authenticateToken, authorizeRoles('Super Admin', 'Admin', 'Safety Officer'), reportController.getReportData);
router.get('/audit/logs', authenticateToken, authorizeRoles('Super Admin', 'Admin', 'Safety Officer'), reportController.getAuditLogs);

// --- 12. Notifications ---
router.get('/notifications', authenticateToken, notificationController.getNotifications);
router.put('/notifications/:id/read', authenticateToken, notificationController.markAsRead);
router.put('/notifications/read-all', authenticateToken, notificationController.markAllAsRead);

// --- 13. Safety Punches (Red / Yellow / Green) ---
router.get('/safety/punches', authenticateToken, safetyController.getPunches);
router.post('/safety/punches', authenticateToken, authorizeRoles('Super Admin', 'Admin', 'Safety Officer'), safetyController.createPunch);
router.delete('/safety/punches/:id', authenticateToken, authorizeRoles('Super Admin', 'Admin', 'Safety Officer'), safetyController.deletePunch);

module.exports = router;
