import React, { useState, useEffect } from 'react';
import { getOrdersByCustomerEmail } from '../../services/api';
import { useAuth } from '../../context/AuthContext';
import type { Order } from '../../types';
import './OrderHistory.css';

const OrderHistory: React.FC = () => {
  const { user } = useAuth();
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (user?.email) {
      loadUserOrders(user.email);
    }
  }, [user]);

  const loadUserOrders = async (email: string) => {
    try {
      setLoading(true);
      setError(null);
      const orderData = await getOrdersByCustomerEmail(email);
      setOrders(orderData);
    } catch (err) {
      console.error('Failed to load order history:', err);
      setError('Failed to load your orders. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const getStatusColor = (status: string) => {
    const s = status.toLowerCase();
    if (s === 'pending') return '#ffc107';
    if (s === 'confirmed') return '#17a2b8';
    if (s === 'preparing') return '#fd7e14';
    if (s === 'ready') return '#28a745';
    if (s === 'delivered') return '#6f42c1';
    if (s === 'cancelled') return '#dc3545';
    return '#6c757d';
  };

  const getStatusIcon = (status: string) => {
    const s = status.toLowerCase();
    if (s === 'pending') return '⏳';
    if (s === 'confirmed') return '✅';
    if (s === 'preparing') return '🍳';
    if (s === 'ready') return '📦';
    if (s === 'delivered') return '🚚';
    if (s === 'cancelled') return '❌';
    return '❓';
  };

  if (loading) {
    return (
      <div className="order-history">
        <div className="loading-container glass-card">
          <div className="loading-spinner">🍔</div>
          <p>Loading your orders...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="order-history">
      <div className="order-history-header">
        <h1>Your Orders</h1>
        <p className="user-email-badge">Logged in as: {user?.email}</p>
        <button 
          className="refresh-button"
          onClick={() => user?.email && loadUserOrders(user.email)}
        >
          🔄 Refresh History
        </button>
      </div>

      {error && (
        <div className="error-container glass-card">
          <p>⚠️ {error}</p>
        </div>
      )}

      {orders.length === 0 ? (
        <div className="no-orders glass-card">
          <div className="no-orders-icon">📋</div>
          <h2>No orders found</h2>
          <p>You haven't placed any orders yet. Time to build a burger!</p>
        </div>
      ) : (
        <div className="orders-list">
          {orders.map((order) => (
            <div key={order.id} className="order-card glass-card">
              <div className="order-header">
                <div className="order-info">
                  <h3 className="order-number">#{order.orderNumber}</h3>
                  <p className="order-date">{formatDate(order.createdAt)}</p>
                </div>
                <div 
                  className="order-status"
                  style={{ backgroundColor: getStatusColor(order.status) }}
                >
                  <span className="status-icon">{getStatusIcon(order.status)}</span>
                  <span className="status-text">{order.status}</span>
                </div>
              </div>
              
              <div className="order-details">
                <div className="customer-info">
                  <p><strong>Customer:</strong> {order.customerName}</p>
                  <p><strong>Email:</strong> {order.customerEmail}</p>
                </div>
                
                <div className="order-summary">
                  <p className="total-amount">
                    <strong>Total: ${order.totalAmount.toFixed(2)}</strong>
                  </p>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default OrderHistory;
