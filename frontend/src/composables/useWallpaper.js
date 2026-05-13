import { ref } from 'vue';

const STORAGE_KEY = 'xui-wallpaper';
const DEFAULT_WALLPAPER = 'https://raw.githubusercontent.com/michaelScopic/Wallpapers/main/anime/Konachan.com_-_376008_sample.jpg';

const availableWallpapers = [
  // Cute Waifu
  { 
    name: 'Cute Waifu', 
    file: 'Konachan.com_-_376008_sample.jpg', 
    previewUrl: 'https://raw.githubusercontent.com/michaelScopic/Wallpapers/main/anime/Konachan.com_-_376008_sample.jpg',
    wallpaperUrl: 'https://raw.githubusercontent.com/michaelScopic/Wallpapers/main/anime/Konachan.com_-_376008_sample.jpg'
  },
  // Gunfighter Waifu
  { 
    name: 'Gunfighter Waifu', 
    file: '114753344_p0.png', 
    previewUrl: 'https://raw.githubusercontent.com/JoydeepMallick/Wallpapers/main/KawaiiWaifu/114753344_p0.png',
    wallpaperUrl: 'https://raw.githubusercontent.com/JoydeepMallick/Wallpapers/main/KawaiiWaifu/114753344_p0.png'
  },
  // Alley
  { 
    name: 'Alley', 
    file: 'alley.gif', 
    previewUrl: 'https://raw.githubusercontent.com/michaelScopic/Wallpapers/main/animated/alley.gif',
    wallpaperUrl: 'https://raw.githubusercontent.com/michaelScopic/Wallpapers/main/animated/alley.gif'
  },
  // GT86
  { 
    name: 'GT86', 
    file: 'wallhaven-k7ezz7.jpg', 
    previewUrl: 'https://raw.githubusercontent.com/michaelScopic/Wallpapers/main/cars/wallhaven-k7ezz7.jpg',
    wallpaperUrl: 'https://raw.githubusercontent.com/michaelScopic/Wallpapers/main/cars/wallhaven-k7ezz7.jpg'
  },
  // Autumn
  { 
    name: 'Autumn', 
    file: 'pixel-art-red-city-autumn.png', 
    previewUrl: 'https://raw.githubusercontent.com/michaelScopic/Wallpapers/main/pastel/pixel-art-red-city-autumn.png',
    wallpaperUrl: 'https://raw.githubusercontent.com/michaelScopic/Wallpapers/main/pastel/pixel-art-red-city-autumn.png'
  },
  // Sky
  { 
    name: 'Sky', 
    file: 'aesthetic2.jpg', 
    previewUrl: 'https://raw.githubusercontent.com/michaelScopic/Wallpapers/main/purple/aesthetic2.jpg',
    wallpaperUrl: 'https://raw.githubusercontent.com/michaelScopic/Wallpapers/main/purple/aesthetic2.jpg'
  },
  // Tokyo Night
  { 
    name: 'Tokyo Night', 
    file: 'street-tn.png', 
    previewUrl: 'https://raw.githubusercontent.com/michaelScopic/Wallpapers/main/tokyo-night/street-tn.png',
    wallpaperUrl: 'https://raw.githubusercontent.com/michaelScopic/Wallpapers/main/tokyo-night/street-tn.png'
  },
  // Arch
  { 
    name: 'Arch', 
    file: 'arch_girl.png', 
    previewUrl: 'https://raw.githubusercontent.com/JoydeepMallick/Wallpapers/main/DistroLure/arch_girl.png',
    wallpaperUrl: 'https://raw.githubusercontent.com/JoydeepMallick/Wallpapers/main/DistroLure/arch_girl.png'
  },
];

// Get saved
const saved = localStorage.getItem(STORAGE_KEY);
const current = ref(saved || DEFAULT_WALLPAPER);

function getWallpaperUrl(source) {

  if (source && source.startsWith('http')) {
    return source;
  }
  
  // Otherwise treat as filename and find wallpaper
  const wallpaper = availableWallpapers.find(w => w.file === source);
  return wallpaper ? (wallpaper.wallpaperUrl || wallpaper.previewUrl) : DEFAULT_WALLPAPER;
}

function getPreviewUrl(filename) {
  if (filename === DEFAULT_WALLPAPER) {
    return DEFAULT_WALLPAPER;
  }
  
  const wallpaper = availableWallpapers.find(w => w.file === filename);
  return wallpaper ? wallpaper.previewUrl : DEFAULT_WALLPAPER;
}

function applyWallpaper(source) {
  const url = getWallpaperUrl(source);
  if (!url) return;
  
  document.documentElement.style.setProperty('--wallpaper-url', `url(${url})`);
  document.body.style.backgroundImage = `url(${url})`;
  document.body.style.backgroundSize = 'cover';
  document.body.style.backgroundPosition = 'center';
  document.body.style.backgroundAttachment = 'fixed';
  document.body.style.backgroundRepeat = 'no-repeat';
}

// Apply
applyWallpaper(current.value);

export function useWallpaper() {
  function setWallpaper(source) {
    current.value = source;
    localStorage.setItem(STORAGE_KEY, source);
    applyWallpaper(source);
  }

  function resetToDefault() {
    setWallpaper(DEFAULT_WALLPAPER);
  }

  return {
    current,
    availableWallpapers,
    setWallpaper,
    resetToDefault,
    getPreviewUrl,
    getWallpaperUrl,
  };
}