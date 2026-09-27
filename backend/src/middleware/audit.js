const db = require('../config/db');

const logAudit = ({ userId, userName, userRole, actionType, module, affectedRecordId, details, oldValues, newValues, ipAddress }) => {
  try {
    db.audit_logs.create({
      user_id: userId || null,
      user_name: userName || 'System',
      user_role: userRole || 'System',
      action_type: actionType, // CREATE, UPDATE, DELETE, APPROVE, REJECT, VERIFY, GATE_ENTRY, GATE_EXIT, EXPORT
      module: module, // Auth, Employee, Vendor, Gate, Permit, Material, Visitor, Attendance, Settings
      affected_record_id: affectedRecordId ? String(affectedRecordId) : null,
      details: details || '',
      old_values: oldValues ? JSON.stringify(oldValues) : null,
      new_values: newValues ? JSON.stringify(newValues) : null,
      ip_address: ipAddress || '127.0.0.1',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Audit log creation failed:', error);
  }
};

const notify = ({ recipientRole, recipientVendorId, title, message, eventType, relatedId }) => {
  try {
    db.notifications.create({
      recipient_role: recipientRole || 'All',
      recipient_vendor_id: recipientVendorId || null,
      title,
      message,
      event_type: eventType,
      related_id: relatedId || null,
      is_read: 0,
      created_at: new Date().toISOString()
    });
  } catch (error) {
    console.error('Notification creation failed:', error);
  }
};

module.exports = {
  logAudit,
  notify
};
