import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import type { BurgerLayer, Ingredient } from '../../types';
import './BurgerPreview.css';

interface BurgerPreviewProps {
  layers: BurgerLayer[];
  getIngredientById: (id: number) => Ingredient | undefined;
  onRemoveLayer: (index: number) => void;
}

const BurgerPreview: React.FC<BurgerPreviewProps> = ({ layers, getIngredientById, onRemoveLayer }) => {
  const getIngredientDisplay = (ingredient: Ingredient | undefined) => {
    if (!ingredient) return { icon: '❓', className: 'unknown' };
    
    const categoryDisplays: Record<string, { icon: string; className: string }> = {
      buns: { icon: '🍞', className: 'bun' },
      patties: { icon: '🥩', className: 'patty' },
      toppings: { icon: '🥬', className: 'topping' },
      sauces: { icon: '🧂', className: 'sauce' },
    };
    
    return categoryDisplays[ingredient.category] || { icon: '🍔', className: 'other' };
  };

  return (
    <div className="burger-preview">
      <h2 className="preview-title">Your Burger</h2>
      <div className="burger-stack">
        <div className="burger-top-bun">🍔 Top Bun</div>
        
        <AnimatePresence>
          {layers.length === 0 ? (
            <motion.div 
              key="empty"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="empty-burger"
            >
              <p>Start building your burger!</p>
              <p className="hint">Click ingredients to add them</p>
            </motion.div>
          ) : (
            [...layers].reverse().map((layer, index) => {
              const ingredient = getIngredientById(layer.ingredientId);
              const display = getIngredientDisplay(ingredient);
              const originalIndex = layers.length - 1 - index;
              
              return (
                <motion.div
                  key={`${layer.ingredientId}-${originalIndex}`}
                  initial={{ y: -50, opacity: 0, scale: 0.8 }}
                  animate={{ y: 0, opacity: 1, scale: 1 }}
                  exit={{ x: 50, opacity: 0 }}
                  transition={{ type: "spring", stiffness: 300, damping: 20 }}
                  className={`burger-layer ${display.className}`}
                  onClick={() => onRemoveLayer(originalIndex)}
                  title="Click to remove"
                >
                  <span className="layer-icon">{display.icon}</span>
                  <span className="layer-name">{ingredient?.name || 'Unknown'}</span>
                  {layer.quantity > 1 && (
                    <span className="layer-quantity">x{layer.quantity}</span>
                  )}
                </motion.div>
              );
            })
          )}
        </AnimatePresence>

        <div className="burger-bottom-bun">🍔 Bottom Bun</div>
      </div>
    </div>
  );
};

export default BurgerPreview;
