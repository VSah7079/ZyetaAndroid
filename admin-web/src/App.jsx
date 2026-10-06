import React, { useState } from 'react';
import { AuthProvider, useAuth } from './context/AuthContext';
import { Sidebar } from './components/Sidebar';
import { Header } from './components/Header';
import { QRScannerModal } from './components/QRScannerModal';
import { Login } from './pages/Login';
import { Dashboard } from './pages/Dashboard';
import { GateOperations } from './pages/GateOperations';
import { Employees } from './pages/Employees';
import { Vendors } from './pages/Vendors';
import { Attendance } from './pages/Attendance';
import { Permits } from './pages/Permits';
import { Materials } from './pages/Materials';
import { Visitors } from './pages/Visitors';
import { Vehicles } from './pages/Vehicles';
import { Reports } from './pages/Reports';
import { AuditLogs } from './pages/AuditLogs';
import { SuperAdmin } from './pages/SuperAdmin';

const MainLayout = () => {
  const { user, isAuthenticated, loading } = useAuth();
  const [activeTab, setActiveTab] = useState('dashboard');
  const [isScannerOpen, setIsScannerOpen] = useState(false);
  const [sidebarOpen, setSidebarOpen] = useState(false);

  if (loading) {
    return (
      <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', backgroundColor: '#0b0f19', color: '#fff' }}>
        <p>Initializing Workforce Security OS...</p>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Login />;
  }

  const handleTabChange = (tabId) => {
    setActiveTab(tabId);
    setSidebarOpen(false);
  };

  const renderActivePage = () => {
    switch (activeTab) {
      case 'superadmin':
        return <SuperAdmin />;
      case 'dashboard':
        return <Dashboard onNavigate={handleTabChange} onOpenScanner={() => setIsScannerOpen(true)} />;
      case 'gate':
        return <GateOperations onOpenScanner={() => setIsScannerOpen(true)} />;
      case 'employees':
        return <Employees />;
      case 'vendors':
        return <Vendors />;
      case 'attendance':
        return <Attendance />;
      case 'permits':
        return <Permits />;
      case 'materials':
        return <Materials />;
      case 'visitors':
        return <Visitors />;
      case 'vehicles':
        return <Vehicles />;
      case 'reports':
        return <Reports />;
      case 'audit':
        return <AuditLogs />;
      default:
        return <Dashboard onNavigate={handleTabChange} onOpenScanner={() => setIsScannerOpen(true)} />;
    }
  };

  return (
    <div style={{ display: 'flex', minHeight: '100vh', backgroundColor: 'var(--bg-primary)', position: 'relative', width: '100%', overflowX: 'hidden' }}>
      {/* Sidebar Navigation */}
      <Sidebar 
        activeTab={activeTab} 
        setActiveTab={handleTabChange}
        isOpen={sidebarOpen}
        onClose={() => setSidebarOpen(false)}
      />

      {/* Main Content Area */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0, width: '100%', overflowX: 'hidden' }}>
        <Header 
          onOpenScanner={() => setIsScannerOpen(true)} 
          onToggleSidebar={() => setSidebarOpen(prev => !prev)}
        />
        <main style={{ flex: 1, overflowY: 'auto', overflowX: 'hidden' }}>
          {renderActivePage()}
        </main>
      </div>

      {/* Global QR Scanner Modal */}
      <QRScannerModal
        isOpen={isScannerOpen}
        onClose={() => setIsScannerOpen(false)}
        onMovementRecorded={() => {
          // Trigger refresh if needed
        }}
      />
    </div>
  );
};

export function App() {
  return (
    <AuthProvider>
      <MainLayout />
    </AuthProvider>
  );
}

export default App;
