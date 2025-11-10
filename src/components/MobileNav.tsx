import React from 'react';
import { useCategories } from '../hooks/useCategories';

interface MobileNavProps {
  activeCategory: string;
  onCategoryClick: (categoryId: string) => void;
}

const MobileNav: React.FC<MobileNavProps> = ({ activeCategory, onCategoryClick }) => {
  const { categories } = useCategories();

  return (
    <div className="sticky top-[66px] sm:top-[72px] z-40 bg-white/95 backdrop-blur-sm border-b border-gray-200 md:hidden shadow-sm">
      <div className="flex overflow-x-auto scrollbar-hide px-3 py-2">
        {categories.map((category) => (
          <button
            key={category.id}
            onClick={() => onCategoryClick(category.id)}
            className={`flex-shrink-0 flex items-center space-x-1.5 px-3 py-1.5 rounded-full mr-2 transition-all duration-200 text-xs ${
              activeCategory === category.id
                ? 'bg-blue-600 text-white shadow-md'
                : 'bg-blue-50 text-gray-700 hover:bg-blue-100'
            }`}
          >
            <span className="font-medium whitespace-nowrap">{category.name}</span>
          </button>
        ))}
      </div>
    </div>
  );
};

export default MobileNav;
