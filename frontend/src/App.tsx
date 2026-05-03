import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { CartProvider } from './context/CartContext';
import { BurgerBuilderProvider } from './context/BurgerBuilderContext';
import { AuthProvider } from './context/AuthContext';
import ProtectedRoute from './components/Auth/ProtectedRoute';
import Layout from './components/Layout/Layout';
import BurgerBuilder from './components/BurgerBuilder/BurgerBuilder';
import Cart from './components/Cart/Cart';
import OrderSummary from './components/OrderSummary/OrderSummary';
import OrderHistory from './components/OrderHistory/OrderHistory';
import Login from './components/Auth/Login';
import './App.css';

const App: React.FC = () => {
  return (
    <Router>
      <AuthProvider>
        <CartProvider>
          <BurgerBuilderProvider>
            <Layout>
              <Routes>
                <Route path="/" element={<BurgerBuilder />} />
                <Route path="/cart" element={<Cart />} />
                <Route path="/login" element={<Login />} />
                <Route 
                  path="/checkout" 
                  element={
                    <ProtectedRoute>
                      <OrderSummary />
                    </ProtectedRoute>
                  } 
                />
                <Route 
                  path="/orders" 
                  element={
                    <ProtectedRoute>
                      <OrderHistory />
                    </ProtectedRoute>
                  } 
                />
              </Routes>
            </Layout>
          </BurgerBuilderProvider>
        </CartProvider>
      </AuthProvider>
    </Router>
  );
};

export default App;
