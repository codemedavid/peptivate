import React from 'react';
import { Shield, Beaker, Sparkles, Heart } from 'lucide-react';

const Hero: React.FC = () => {
  return (
    <div className="relative overflow-hidden bg-gradient-to-br from-blue-50 via-purple-50 to-pink-50 min-h-[calc(100vh-80px)] flex items-center">
      {/* Decorative Elements */}
      <div className="absolute top-0 left-0 w-72 h-72 bg-blue-200 rounded-full mix-blend-multiply filter blur-xl opacity-30 animate-blob"></div>
      <div className="absolute top-0 right-0 w-72 h-72 bg-purple-200 rounded-full mix-blend-multiply filter blur-xl opacity-30 animate-blob animation-delay-2000"></div>
      <div className="absolute -bottom-8 left-20 w-72 h-72 bg-pink-200 rounded-full mix-blend-multiply filter blur-xl opacity-30 animate-blob animation-delay-4000"></div>

      {/* Main Content */}
      <div className="relative container mx-auto px-4 py-12 md:py-16 lg:py-20 w-full">
        <div className="text-center max-w-5xl mx-auto">
          {/* Badge */}
          <div className="inline-flex items-center gap-2 md:gap-2.5 bg-white/80 backdrop-blur-sm px-4 py-2 md:px-6 md:py-3 rounded-full shadow-lg mb-6 md:mb-8 lg:mb-10 border border-blue-100">
            <Sparkles className="w-4 h-4 md:w-5 md:h-5 text-yellow-500" />
            <span className="text-sm md:text-base lg:text-lg font-semibold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
              Premium Quality Guaranteed
            </span>
            <Sparkles className="w-4 h-4 md:w-5 md:h-5 text-yellow-500" />
          </div>

          {/* Main Heading */}
          <h1 className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl xl:text-7xl font-bold mb-4 md:mb-6 lg:mb-8">
            <span className="bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent">
              Research-Grade
            </span>
            <br />
            <span className="text-gray-800">Peptides</span>
            <Heart className="inline-block w-8 h-8 sm:w-10 sm:h-10 md:w-12 md:h-12 lg:w-16 lg:h-16 text-pink-500 ml-2 md:ml-3 mb-1 md:mb-2 animate-pulse" />
          </h1>
          
          <p className="text-xl sm:text-2xl md:text-3xl lg:text-4xl font-bold text-gray-700 mb-8 md:mb-12 lg:mb-16 max-w-3xl mx-auto leading-relaxed px-2">
            <span className="bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
              Verified reseller- Jonina David
            </span>
          </p>
          
          {/* Trust Badges */}
          <div className="grid grid-cols-2 gap-4 sm:gap-6 md:gap-8 lg:gap-10 max-w-2xl lg:max-w-3xl mx-auto">
            <div className="bg-white/80 backdrop-blur-sm rounded-2xl md:rounded-3xl p-4 sm:p-6 md:p-8 lg:p-10 shadow-xl hover:shadow-2xl transition-all transform hover:-translate-y-2 border border-blue-100">
              <div className="bg-gradient-to-br from-blue-400 to-blue-600 p-3 md:p-4 lg:p-5 rounded-xl md:rounded-2xl mb-3 md:mb-4 inline-block shadow-md">
                <Shield className="w-6 h-6 md:w-8 md:h-8 lg:w-10 lg:h-10 text-white" />
              </div>
              <h3 className="text-sm sm:text-base md:text-lg lg:text-xl font-bold text-gray-800 mb-1 md:mb-2">Lab Tested</h3>
              <p className="text-xs sm:text-sm md:text-base text-gray-500">Third-party verified</p>
            </div>
            
            <div className="bg-white/80 backdrop-blur-sm rounded-2xl md:rounded-3xl p-4 sm:p-6 md:p-8 lg:p-10 shadow-xl hover:shadow-2xl transition-all transform hover:-translate-y-2 border border-purple-100">
              <div className="bg-gradient-to-br from-purple-400 to-purple-600 p-3 md:p-4 lg:p-5 rounded-xl md:rounded-2xl mb-3 md:mb-4 inline-block shadow-md">
                <Beaker className="w-6 h-6 md:w-8 md:h-8 lg:w-10 lg:h-10 text-white" />
              </div>
              <h3 className="text-sm sm:text-base md:text-lg lg:text-xl font-bold text-gray-800 mb-1 md:mb-2">99%+ Purity</h3>
              <p className="text-xs sm:text-sm md:text-base text-gray-500">Research grade</p>
            </div>
          </div>
        </div>
      </div>

      {/* Disclaimer */}
      <div className="relative bg-white/90 backdrop-blur-sm border-t-2 border-blue-100">
        <div className="container mx-auto px-4 py-3 md:py-4">
          <p className="text-xs sm:text-sm md:text-base text-center text-gray-600">
            <span className="inline-flex items-center gap-1 md:gap-1.5">
              <Shield className="w-4 h-4 md:w-5 md:h-5 text-blue-600" />
              <strong className="text-blue-700">Research Use Only:</strong>
            </span>
            {' '}All peptides are sold for research purposes only. Not for human consumption.
          </p>
        </div>
      </div>

      {/* Custom Animations */}
      <style>{`
        @keyframes blob {
          0% { transform: translate(0px, 0px) scale(1); }
          33% { transform: translate(30px, -50px) scale(1.1); }
          66% { transform: translate(-20px, 20px) scale(0.9); }
          100% { transform: translate(0px, 0px) scale(1); }
        }
        .animate-blob {
          animation: blob 7s infinite;
        }
        .animation-delay-2000 {
          animation-delay: 2s;
        }
        .animation-delay-4000 {
          animation-delay: 4s;
        }
      `}</style>
    </div>
  );
};

export default Hero;
