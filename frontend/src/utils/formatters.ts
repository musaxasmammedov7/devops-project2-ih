export const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
};

export const getStatusColor = (status: string) => {
  switch (status.toLowerCase()) {
    case 'pending':
      return '#ffc107';
    case 'confirmed':
      return '#17a2b8';
    case 'preparing':
      return '#fd7e14';
    case 'ready':
      return '#28a745';
    case 'delivered':
      return '#6f42c1';
    case 'cancelled':
      return '#dc3545';
    default:
      return '#6c757d';
  }
};

export const getStatusIcon = (status: string) => {
  switch (status.toLowerCase()) {
    case 'pending':
      return '⏳';
    case 'confirmed':
      return '✅';
    case 'preparing':
      return '🍳';
    case 'ready':
      return '📦';
    case 'delivered':
      return '🚚';
    case 'cancelled':
      return '❌';
    default:
      return '❓';
  }
};

export const getCategoryIcon = (category: string): string => {
  const icons: Record<string, string> = {
    buns: '🍞',
    patties: '🥩',
    toppings: '🥬',
    sauces: '🧂',
  };
  return icons[category.toLowerCase()] || '🍔';
};
