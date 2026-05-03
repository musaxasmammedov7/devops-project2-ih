import React, { useState, useEffect } from 'react';
import { useAuth } from '../../context/AuthContext';
import './OrderTracker.css';

const OrderTracker: React.FC = () => {
  const { activeOrder, clearActiveOrder } = useAuth();
  const [timeLeft, setTimeLeft] = useState<number>(0);

  useEffect(() => {
    if (activeOrder) {
      setTimeLeft(activeOrder.readyIn);
    }
  }, [activeOrder]);

  useEffect(() => {
    if (timeLeft <= 0) return;

    const timer = setInterval(() => {
      setTimeLeft((prev) => {
        if (prev <= 1) {
          clearInterval(timer);
          return 0;
        }
        return prev - 1;
      });
    }, 60000); // Update every minute

    return () => clearInterval(timer);
  }, [timeLeft]);

  if (!activeOrder) return null;

  return (
    <div className="order-tracker-badge" onClick={timeLeft === 0 ? clearActiveOrder : undefined}>
      <div className="tracker-circle">
        <span className="tracker-icon">{timeLeft === 0 ? '✅' : '👨‍🍳'}</span>
        <div className="tracker-info">
          <span className="tracker-label">
            {timeLeft === 0 ? 'Ready!' : 'Cooking...'}
          </span>
          <span className="tracker-time">
            {timeLeft === 0 ? 'Done' : `${timeLeft}m`}
          </span>
        </div>
      </div>
      {timeLeft === 0 && <div className="tracker-hint">Click to dismiss</div>}
    </div>
  );
};

export default OrderTracker;
