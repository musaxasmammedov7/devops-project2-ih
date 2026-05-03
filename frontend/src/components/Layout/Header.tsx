import React from 'react';
import { Link } from 'react-router-dom';
import { useCart } from '../../context/CartContext';
import { useAuth } from '../../context/AuthContext';
import './Header.css';

const Header: React.FC = () => {
  const { getTotalItems } = useCart();
  const { user, logout, isAuthenticated } = useAuth();
  const itemCount = getTotalItems();

  return (
    <header className="header">
      <div className="header-container">
        <Link to="/" className="logo">
          <h1>🍔 Burger Builder</h1>
        </Link>
        
        <nav className="nav">
          <Link to="/" className="nav-link">Build</Link>
          <Link to="/orders" className="nav-link">Orders</Link>
          <Link to="/cart" className="nav-link cart-link">
            <span className="cart-icon">🛒</span>
            Cart
            {itemCount > 0 && (
              <span className="cart-badge">{itemCount}</span>
            )}
          </Link>
          
          {isAuthenticated ? (
            <div className="user-nav">
              <span className="user-name">👤 {user?.name}</span>
              <button onClick={logout} className="logout-btn">Logout</button>
            </div>
          ) : (
            <Link to="/login" className="login-link">Login</Link>
          )}
        </nav>
      </div>
    </header>
  );
};

export default Header;
