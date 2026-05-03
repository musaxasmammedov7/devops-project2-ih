import React, { createContext, useContext, useState, useEffect } from 'react';
import type { ReactNode } from 'react';

interface User {
  name: string;
  email: string;
}

interface AuthContextType {
  user: User | null;
  activeOrder: { id: string; readyIn: number } | null;
  login: (email: string, password: string) => boolean;
  register: (email: string, password: string, name: string) => boolean;
  logout: () => void;
  setActiveOrder: (orderId: string, time: number) => void;
  clearActiveOrder: () => void;
  isAuthenticated: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [activeOrder, setActiveOrderState] = useState<{ id: string; readyIn: number } | null>(null);

  useEffect(() => {
    const savedUser = localStorage.getItem('burger_user');
    if (savedUser) setUser(JSON.parse(savedUser));
    
    const savedOrder = localStorage.getItem('active_order');
    if (savedOrder) setActiveOrderState(JSON.parse(savedOrder));
  }, []);

  const register = (email: string, password: string, name: string) => {
    const users = JSON.parse(localStorage.getItem('registered_users') || '[]');
    if (users.find((u: any) => u.email === email)) return false;
    
    users.push({ email, password, name });
    localStorage.setItem('registered_users', JSON.stringify(users));
    return true;
  };

  const login = (email: string, password: string) => {
    const users = JSON.parse(localStorage.getItem('registered_users') || '[]');
    const foundUser = users.find((u: any) => u.email === email && u.password === password);
    
    if (foundUser) {
      const userData = { email: foundUser.email, name: foundUser.name };
      setUser(userData);
      localStorage.setItem('burger_user', JSON.stringify(userData));
      return true;
    }
    return false;
  };

  const logout = () => {
    setUser(null);
    localStorage.removeItem('burger_user');
  };

  const setActiveOrder = (id: string, time: number) => {
    const order = { id, readyIn: time };
    setActiveOrderState(order);
    localStorage.setItem('active_order', JSON.stringify(order));
  };

  const clearActiveOrder = () => {
    setActiveOrderState(null);
    localStorage.removeItem('active_order');
  };

  return (
    <AuthContext.Provider value={{ 
      user, activeOrder, login, register, logout, 
      setActiveOrder, clearActiveOrder, isAuthenticated: !!user 
    }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within an AuthProvider');
  return context;
};
