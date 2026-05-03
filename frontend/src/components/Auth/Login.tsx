import React, { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import './Login.css';

const Login: React.FC = () => {
  const [isRegister, setIsRegister] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [error, setError] = useState('');
  
  const { login, register } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const from = (location.state as any)?.from?.pathname || "/";

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (isRegister) {
      const success = register(email, password, name);
      if (success) {
        setIsRegister(false);
        setError('Registration successful! Please login.');
      } else {
        setError('User already exists!');
      }
    } else {
      const success = login(email, password);
      if (success) {
        navigate(from, { replace: true });
      } else {
        setError('Invalid email or password!');
      }
    }
  };

  return (
    <div className="login-page">
      <div className="login-glass-card">
        <div className="login-header">
          <span className="login-logo">🍔</span>
          <h1>{isRegister ? 'Create Account' : 'Welcome Back!'}</h1>
          <p>{isRegister ? 'Join the burger revolution' : 'Login to track your burgers'}</p>
        </div>

        {error && <div className="login-error">{error}</div>}

        <form onSubmit={handleSubmit} className="login-form">
          {isRegister && (
            <div className="login-input-group">
              <label>Full Name</label>
              <input 
                type="text" 
                placeholder="John Doe" 
                value={name}
                onChange={(e) => setName(e.target.value)}
                required 
              />
            </div>
          )}
          
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

          <div className="login-input-group">
            <label>Password</label>
            <input 
              type="password" 
              placeholder="••••••••" 
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required 
            />
          </div>

          <button type="submit" className="login-submit-btn">
            {isRegister ? 'Sign Up' : 'Login'}
          </button>
        </form>

        <div className="login-footer">
          <p>
            {isRegister ? 'Already have an account?' : "Don't have an account?"}
            <button 
              className="toggle-auth-btn"
              onClick={() => {
                setIsRegister(!isRegister);
                setError('');
              }}
            >
              {isRegister ? 'Login' : 'Register now'}
            </button>
          </p>
        </div>
      </div>
    </div>
  );
};

export default Login;
