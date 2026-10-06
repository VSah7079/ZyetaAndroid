import React from 'react';
import { 
  LayoutDashboard, 
  Users, 
  Building2, 
  DoorOpen, 
  Clock, 
  FileCheck, 
  Package, 
  UserCheck, 
  Truck, 
  BarChart3, 
  ShieldAlert, 
  LogOut,
  Shield,
  Layers,
  X
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';

export const Sidebar = ({ activeTab, setActiveTab, isOpen, onClose }) => {
  const { user, logout } = useAuth();
  const role = user?.role || 'Admin';

  const menuItems = [
    { id: 'superadmin', label: '👑 Super Admin Hub', icon: Shield, roles: ['Super Admin'] },
    { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard, roles: ['Super Admin', 'Admin', 'Safety Officer', 'Vendor', 'Security'] },
    { id: 'gate', label: 'Gate Operations', icon: DoorOpen, roles: ['Super Admin', 'Admin', 'Security'] },
    { id: 'employees', label: role === 'Vendor' ? 'My Workforce' : 'Employees', icon: Users, roles: ['Super Admin', 'Admin', 'Safety Officer', 'Vendor'] },
    { id: 'vendors', label: 'Contractors / Vendors', icon: Building2, roles: ['Super Admin', 'Admin'] },
    { id: 'attendance', label: 'Attendance Roster', icon: Clock, roles: ['Super Admin', 'Admin', 'Safety Officer', 'Vendor'] },
    { id: 'permits', label: 'Permits & Safety (PTW)', icon: FileCheck, roles: ['Super Admin', 'Admin', 'Safety Officer', 'Vendor', 'Security'] },
    { id: 'materials', label: 'Materials & DC Pass', icon: Package, roles: ['Super Admin', 'Admin', 'Security', 'Vendor'] },
    { id: 'visitors', label: 'Visitor Pass Kiosk', icon: UserCheck, roles: ['Super Admin', 'Admin', 'Security'] },
    { id: 'vehicles', label: 'Vehicles Register', icon: Truck, roles: ['Super Admin', 'Admin', 'Security'] },
    { id: 'reports', label: 'Reports & Export', icon: BarChart3, roles: ['Super Admin', 'Admin', 'Safety Officer'] },
    { id: 'audit', label: 'Audit Trail Logs', icon: ShieldAlert, roles: ['Super Admin', 'Admin'] },
  ];

  const allowedItems = menuItems.filter(item => item.roles.includes(role));

  const handleItemClick = (id) => {
    setActiveTab(id);
    if (onClose) onClose();
  };

  return (
    <>
      {/* Mobile Drawer Backdrop */}
      <div 
        className={`sidebar-backdrop ${isOpen ? 'active' : ''}`}
        onClick={onClose}
        aria-hidden="true"
      />

      <aside className={`sidebar-container ${isOpen ? 'open' : ''}`} style={{
        width: '260px',
        minWidth: '260px',
        backgroundColor: '#0f172a',
        borderRight: '1px solid var(--border-color)',
        display: 'flex',
        flexDirection: 'column',
        height: '100vh',
        position: 'sticky',
        top: 0,
        zIndex: 40
      }}>
        {/* Brand Header */}
        <div style={{
          padding: '18px 20px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          borderBottom: '1px solid var(--border-color)'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <img
              src="/app_logo.jpg"
              alt="ZyetaGate Logo"
              style={{
                width: '40px',
                height: '40px',
                borderRadius: '10px',
                boxShadow: '0 4px 15px rgba(99, 102, 241, 0.35)',
                border: '1px solid rgba(255, 255, 255, 0.15)',
                objectFit: 'cover'
              }}
            />
            <div>
              <h1 style={{ fontSize: '1.05rem', fontWeight: 800, letterSpacing: '-0.3px', color: '#fff' }}>
                Zyeta<span style={{ color: 'var(--accent-cyan)' }}>Gate</span>
              </h1>
              <p style={{ fontSize: '0.68rem', color: 'var(--text-muted)', fontWeight: 600, textTransform: 'uppercase' }}>
                Workforce & Gate OS
              </p>
            </div>
          </div>

          {/* Mobile Close Button */}
          <button 
            className="sidebar-close-btn"
            onClick={onClose}
            title="Close Menu"
          >
            <X size={20} />
          </button>
        </div>

        {/* Role Pill */}
        <div style={{ padding: '12px 16px 4px 16px' }}>
          <div style={{
            background: 'rgba(99, 102, 241, 0.1)',
            border: '1px solid rgba(99, 102, 241, 0.25)',
            padding: '6px 12px',
            borderRadius: 'var(--radius-md)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between'
          }}>
            <span style={{ fontSize: '0.75rem', color: '#a5b4fc', fontWeight: 600 }}>Active Role</span>
            <span className="badge badge-active" style={{ fontSize: '0.65rem' }}>{role}</span>
          </div>
        </div>

        {/* Navigation List */}
        <nav style={{ flex: 1, padding: '12px', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '4px' }}>
          {allowedItems.map((item) => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => handleItemClick(item.id)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '12px',
                  padding: '10px 14px',
                  borderRadius: 'var(--radius-md)',
                  fontSize: '0.85rem',
                  fontWeight: isActive ? 700 : 500,
                  color: isActive ? '#ffffff' : 'var(--text-secondary)',
                  backgroundColor: isActive ? 'rgba(99, 102, 241, 0.2)' : 'transparent',
                  border: isActive ? '1px solid rgba(99, 102, 241, 0.4)' : '1px solid transparent',
                  cursor: 'pointer',
                  textAlign: 'left',
                  width: '100%',
                  transition: 'all 0.15s ease'
                }}
                onMouseEnter={(e) => {
                  if (!isActive) {
                    e.currentTarget.style.backgroundColor = 'rgba(255, 255, 255, 0.04)';
                    e.currentTarget.style.color = '#fff';
                  }
                }}
                onMouseLeave={(e) => {
                  if (!isActive) {
                    e.currentTarget.style.backgroundColor = 'transparent';
                    e.currentTarget.style.color = 'var(--text-secondary)';
                  }
                }}
              >
                <Icon size={18} color={isActive ? '#818cf8' : 'currentColor'} />
                <span>{item.label}</span>
              </button>
            );
          })}
        </nav>

        {/* User Profile & Logout */}
        <div style={{
          padding: '16px',
          borderTop: '1px solid var(--border-color)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          backgroundColor: 'rgba(0, 0, 0, 0.2)'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', overflow: 'hidden' }}>
            <div style={{
              width: '34px',
              height: '34px',
              borderRadius: '50%',
              background: 'linear-gradient(135deg, #4f46e5, #9333ea)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontWeight: 700,
              fontSize: '0.85rem',
              color: '#fff',
              flexShrink: 0
            }}>
              {user?.full_name ? user.full_name.charAt(0).toUpperCase() : 'U'}
            </div>
            <div style={{ overflow: 'hidden' }}>
              <p style={{ fontSize: '0.8rem', fontWeight: 600, color: '#fff', whiteSpace: 'nowrap', textOverflow: 'ellipsis', overflow: 'hidden' }}>
                {user?.full_name || 'User'}
              </p>
              <p style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>{user?.username}</p>
            </div>
          </div>

          <button
            onClick={logout}
            title="Sign Out"
            style={{
              background: 'transparent',
              border: 'none',
              color: 'var(--text-muted)',
              cursor: 'pointer',
              padding: '6px',
              borderRadius: '6px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center'
            }}
            onMouseEnter={(e) => e.currentTarget.style.color = '#f43f5e'}
            onMouseLeave={(e) => e.currentTarget.style.color = 'var(--text-muted)'}
          >
            <LogOut size={18} />
          </button>
        </div>
      </aside>
    </>
  );
};
