import React, { useState, useEffect } from 'react';
import { QrCode, Bell, Building, Check, Sparkles } from 'lucide-react';
import { api } from '../services/api';
import { useAuth } from '../context/AuthContext';

export const Header = ({ onOpenScanner }) => {
  const { user } = useAuth();
  const [notifications, setNotifications] = useState([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [showNotifMenu, setShowNotifMenu] = useState(false);
  const [insideCount, setInsideCount] = useState(0);

  const fetchNotifsAndInside = async () => {
    try {
      const notifRes = await api.getNotifications();
      if (notifRes.success) {
        setNotifications(notifRes.data);
        setUnreadCount(notifRes.unread_count);
      }
      const insideRes = await api.getCurrentlyInside();
      if (insideRes.success) {
        setInsideCount(insideRes.total_count);
      }
    } catch (err) {
      console.error(err);
    }
  };

  useEffect(() => {
    fetchNotifsAndInside();
    const interval = setInterval(fetchNotifsAndInside, 10000);
    return () => clearInterval(interval);
  }, []);

  const handleMarkAllRead = async () => {
    try {
      await api.markAllNotificationsRead();
      setUnreadCount(0);
      setNotifications(notifications.map(n => ({ ...n, is_read: 1 })));
    } catch (err) {
      console.error(err);
    }
  };

  return (
    <header style={{
      height: '68px',
      backgroundColor: '#0f172a',
      borderBottom: '1px solid var(--border-color)',
      padding: '0 28px',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      position: 'sticky',
      top: 0,
      zIndex: 30
    }}>
      {/* Site Selector & Live Indicator */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <Building size={18} color="var(--accent-cyan)" />
          <span style={{ fontSize: '0.875rem', fontWeight: 600, color: '#fff' }}>
            Bangalore Tech Park Campus (BLR-01)
          </span>
        </div>

        {/* Live Inside Count Badge */}
        <div style={{
          display: 'flex',
          alignItems: 'center',
          gap: '8px',
          background: 'rgba(16, 185, 129, 0.1)',
          border: '1px solid rgba(16, 185, 129, 0.3)',
          padding: '4px 12px',
          borderRadius: 'var(--radius-full)'
        }}>
          <span className="pulse-dot"></span>
          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#34d399' }}>
            {insideCount} ON SITE NOW
          </span>
        </div>
      </div>

      {/* Action Buttons */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
        {/* Quick QR Scanner Button */}
        <button
          onClick={onOpenScanner}
          className="btn btn-primary"
          style={{ padding: '7px 14px', fontSize: '0.8rem' }}
        >
          <QrCode size={16} />
          <span>Quick QR Scan</span>
        </button>

        {/* Notifications Dropdown */}
        <div style={{ position: 'relative' }}>
          <button
            onClick={() => setShowNotifMenu(!showNotifMenu)}
            style={{
              position: 'relative',
              background: 'var(--bg-hover)',
              border: '1px solid var(--border-color)',
              color: 'var(--text-primary)',
              width: '38px',
              height: '38px',
              borderRadius: 'var(--radius-md)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              cursor: 'pointer'
            }}
          >
            <Bell size={18} />
            {unreadCount > 0 && (
              <span style={{
                position: 'absolute',
                top: '-4px',
                right: '-4px',
                background: '#f43f5e',
                color: '#fff',
                fontSize: '0.65rem',
                fontWeight: 800,
                width: '18px',
                height: '18px',
                borderRadius: '50%',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                border: '2px solid #0f172a'
              }}>
                {unreadCount}
              </span>
            )}
          </button>

          {showNotifMenu && (
            <div style={{
              position: 'absolute',
              right: 0,
              top: '48px',
              width: '340px',
              backgroundColor: '#111827',
              border: '1px solid var(--border-color)',
              borderRadius: 'var(--radius-lg)',
              boxShadow: 'var(--shadow-lg)',
              zIndex: 100,
              overflow: 'hidden'
            }}>
              <div style={{
                padding: '12px 16px',
                borderBottom: '1px solid var(--border-color)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between'
              }}>
                <span style={{ fontSize: '0.85rem', fontWeight: 700, color: '#fff' }}>Notifications</span>
                {unreadCount > 0 && (
                  <button
                    onClick={handleMarkAllRead}
                    style={{
                      background: 'transparent',
                      border: 'none',
                      color: 'var(--accent-primary)',
                      fontSize: '0.75rem',
                      fontWeight: 600,
                      cursor: 'pointer'
                    }}
                  >
                    Mark all read
                  </button>
                )}
              </div>

              <div style={{ maxHeight: '300px', overflowY: 'auto' }}>
                {notifications.length === 0 ? (
                  <p style={{ padding: '20px', textAlign: 'center', color: 'var(--text-muted)', fontSize: '0.8rem' }}>
                    No notifications
                  </p>
                ) : (
                  notifications.slice(0, 5).map((n) => (
                    <div
                      key={n.id}
                      style={{
                        padding: '12px 16px',
                        borderBottom: '1px solid rgba(255, 255, 255, 0.04)',
                        backgroundColor: n.is_read ? 'transparent' : 'rgba(99, 102, 241, 0.05)',
                        transition: 'background 0.2s'
                      }}
                    >
                      <p style={{ fontSize: '0.8rem', fontWeight: 600, color: '#fff', marginBottom: '2px' }}>
                        {n.title}
                      </p>
                      <p style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>
                        {n.message}
                      </p>
                      <span style={{ fontSize: '0.65rem', color: 'var(--text-muted)', marginTop: '4px', display: 'block' }}>
                        {new Date(n.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </span>
                    </div>
                  ))
                )}
              </div>
            </div>
          )}
        </div>
      </div>
    </header>
  );
};
