import React, { useState, useEffect } from 'react';
import './OrderTimer.css';

interface OrderTimerProps {
  readyInMinutes: number;
  onComplete?: () => void;
}

export const OrderTimer: React.FC<OrderTimerProps> = ({ readyInMinutes, onComplete }) => {
  const [timeLeft, setTimeLeft] = useState(readyInMinutes * 60);

  useEffect(() => {
    if (timeLeft === 0) {
      onComplete?.();
      return;
    }

    const interval = setInterval(() => {
      setTimeLeft((prev) => prev - 1);
    }, 1000);

    return () => clearInterval(interval);
  }, [timeLeft, onComplete]);

  const minutes = Math.floor(timeLeft / 60);
  const seconds = timeLeft % 60;
  const percentage = ((readyInMinutes * 60 - timeLeft) / (readyInMinutes * 60)) * 100;

  return (
    <div className="order-timer">
      <div className="timer-circle">
        <svg className="timer-svg" viewBox="0 0 100 100">
          <circle
            className="timer-bg"
            cx="50"
            cy="50"
            r="45"
            fill="none"
            stroke="#e0e0e0"
            strokeWidth="8"
          />
          <circle
            className="timer-progress"
            cx="50"
            cy="50"
            r="45"
            fill="none"
            stroke="#e63946"
            strokeWidth="8"
            strokeLinecap="round"
            strokeDasharray={`${2 * Math.PI * 45}`}
            strokeDashoffset={`${2 * Math.PI * 45 * (1 - percentage / 100)}`}
            style={{ transform: 'rotate(-90deg)', transformOrigin: '50% 50%' }}
          />
        </svg>
        <div className="timer-content">
          {timeLeft === 0 ? (
            <div className="timer-complete">
              <span className="timer-icon">✅</span>
              <span className="timer-text">Ready!</span>
            </div>
          ) : (
            <div className="timer-countdown">
              <span className="timer-time">
                {minutes.toString().padStart(2, '0')}:{seconds.toString().padStart(2, '0')}
              </span>
              <span className="timer-label">min left</span>
            </div>
          )}
        </div>
      </div>
      <div className="timer-status">
        <span className="timer-title">Order Status</span>
        <span className="timer-message">
          {timeLeft === 0 ? 'Your order is ready! 🎉' : 'Preparing your delicious burger...'}
        </span>
      </div>
    </div>
  );
};

export default OrderTimer;
