import React, { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import './Login.css';

const Login: React.FC = () => {
  const [email, setEmail] = useState('');
  const [name, setName] = useState('');
  const { login } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const from = (location.state as any)?.from?.pathname || "/";

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (email && name) {
      login(email, name);
      navigate(from, { replace: true });
    }
  };

  return (
    <div className="login-page">
      <div className="login-glass-card">
        <div className="login-header">
          <span className="login-logo">🍔</span>
          <h1>Welcome Back!</h1>
          <p>Login to track your burgers and orders</p>
        </div>

        <form onSubmit={handleSubmit} className="login-form">
          <div className="login-input-group">
            <label>Full Name</label>
            <input 
              type="text" 
              placeholder="Enter your name" 
              value={name}
              onChange={(e) => setName(e.target.value)}
              required 
            />
          </div>
          
          <div className="login-input-group">
            <label>Email Address</label>
            <input 
              type="email" 
              placeholder="name@example.com" 
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required 
            />
          </div>

          <button type="submit" className="login-submit-btn">
            Login & Continue
          </button>
        </form>

        <div className="login-footer">
          <p>Don't have an account? <span>It's automatic! Just type any name.</span></p>
        </div>
      </div>
    </div>
  );
};

export default Login;
