const db = require('../config/db');

const getNotifications = async (req, res) => {
  try {
    const userRole = req.user.role;
    const vendorId = req.user.vendor_id;

    let list = db.notifications.find((n) => {
      if (n.recipient_role === 'All') return true;
      if (n.recipient_role === userRole) return true;
      if (userRole === 'Vendor' && n.recipient_vendor_id && Number(n.recipient_vendor_id) === Number(vendorId)) return true;
      return false;
    });

    list.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

    const unreadCount = list.filter((n) => n.is_read === 0).length;

    res.json({
      success: true,
      unread_count: unreadCount,
      data: list
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const markAsRead = async (req, res) => {
  try {
    const notif = db.notifications.findById(req.params.id);
    if (!notif) return res.status(404).json({ success: false, message: 'Notification not found' });

    const updated = db.notifications.update(notif.id, { is_read: 1 });
    res.json({ success: true, message: 'Notification marked as read', data: updated });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const markAllAsRead = async (req, res) => {
  try {
    const list = db.notifications.find();
    list.forEach((n) => {
      db.notifications.update(n.id, { is_read: 1 });
    });
    res.json({ success: true, message: 'All notifications marked as read' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getNotifications,
  markAsRead,
  markAllAsRead
};
