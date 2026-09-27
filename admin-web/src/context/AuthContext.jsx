import React, { createContext, useContext, useState, useEffect } from 'react';
import { api } from '../services/api';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const initAuth = async () => {
      const token = localStorage.getItem('zyeta_token');
      const savedUser = localStorage.getItem('zyeta_user');
      if (token && savedUser) {
        try {
          setUser(JSON.parse(savedUser));
          const res = await api.getMe();
          if (res.success) {
            setUser(res.user);
            localStorage.setItem('zyeta_user', JSON.stringify(res.user));
          }
        } catch (err) {
          console.warn('Session expired or invalid:', err);
          logout();
        }
      }
      setLoading(false);
    };
    initAuth();
  }, []);

  const login = async (username, password) => {
    const res = await api.login({ username, password });
    if (res.success && res.token) {
      localStorage.setItem('zyeta_token', res.token);
      localStorage.setItem('zyeta_user', JSON.stringify(res.user));
      setUser(res.user);
      return res.user;
    }
    throw new Error(res.message || 'Login failed');
  };

  const logout = () => {
    localStorage.removeItem('zyeta_token');
    localStorage.removeItem('zyeta_user');
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, login, logout, loading, isAuthenticated: !!user }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
