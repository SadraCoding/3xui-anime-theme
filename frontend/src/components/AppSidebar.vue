<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  DashboardOutlined,
  UserOutlined,
  SettingOutlined,
  ToolOutlined,
  ClusterOutlined,
  LogoutOutlined,
  CloseOutlined,
  MenuOutlined,
  ApiOutlined,
} from '@ant-design/icons-vue';

import { theme, currentTheme, toggleTheme, toggleUltra, pauseAnimationsUntilLeave } from '@/composables/useTheme.js';
import { useWallpaper } from '@/composables/useWallpaper.js';

const { t } = useI18n();
const { current, availableWallpapers, setWallpaper } = useWallpaper();

const SIDEBAR_COLLAPSED_KEY = 'isSidebarCollapsed';

const props = defineProps({
  basePath: { type: String, default: '' },
  requestUri: { type: String, default: '' },
});

const iconByName = {
  dashboard: DashboardOutlined,
  user: UserOutlined,
  setting: SettingOutlined,
  tool: ToolOutlined,
  cluster: ClusterOutlined,
  logout: LogoutOutlined,
  apidocs: ApiOutlined,
};

const prefix = props.basePath?.startsWith('/') ? props.basePath : `/${props.basePath || ''}`;

const tabs = computed(() => [
  { key: `${prefix}panel/`, icon: 'dashboard', title: t('menu.dashboard') },
  { key: `${prefix}panel/inbounds`, icon: 'user', title: t('menu.inbounds') },
  { key: `${prefix}panel/nodes`, icon: 'cluster', title: t('menu.nodes') },
  { key: `${prefix}panel/settings`, icon: 'setting', title: t('menu.settings') },
  { key: `${prefix}panel/xray`, icon: 'tool', title: t('menu.xray') },
  { key: `${prefix}panel/api-docs`, icon: 'apidocs', title: t('menu.apiDocs') },
  { key: `${prefix}logout`, icon: 'logout', title: t('logout') },
]);

const navTabs = computed(() => tabs.value.filter((tab) => tab.icon !== 'logout'));
const utilTabs = computed(() => tabs.value.filter((tab) => tab.icon === 'logout'));
const activeTab = ref([props.requestUri]);
const drawerOpen = ref(false);
const collapsed = ref(JSON.parse(localStorage.getItem(SIDEBAR_COLLAPSED_KEY) || 'false'));
const drawerWidth = 'min(82vw, 320px)';

function openLink(key) {
  if (key.startsWith('http')) {
    window.open(key);
  } else {
    window.location.href = key;
  }
}

function onCollapse(isCollapsed, type) {
  if (type === 'clickTrigger') {
    localStorage.setItem(SIDEBAR_COLLAPSED_KEY, isCollapsed);
    collapsed.value = isCollapsed;
  }
}

function toggleDrawer() {
  drawerOpen.value = !drawerOpen.value;
}

function closeDrawer() {
  drawerOpen.value = false;
}

function cycleTheme() {
  pauseAnimationsUntilLeave('theme-cycle');
  if (!theme.isDark) {
    toggleTheme();
    if (theme.isUltra) toggleUltra();
  } else if (!theme.isUltra) {
    toggleUltra();
  } else {
    toggleUltra();
    toggleTheme();
  }
}
</script>

<template>
  <div class="ant-sidebar">
    <!-- LIQUID GLASS SIDEBAR -->
    <a-layout-sider 
      :theme="currentTheme" 
      collapsible 
      :collapsed="collapsed" 
      breakpoint="md" 
      @collapse="onCollapse" 
      class="glass-sider"
    >
      <div class="sider-brand" :class="{ 'sider-brand-collapsed': collapsed }">
        <span class="brand-text">{{ collapsed ? '3X' : '3X-UI' }}</span>
        <div v-if="!collapsed" class="sider-brand-actions">
          <!-- Theme Toggle Button -->
          <button id="theme-cycle" type="button" class="glass-icon-btn" :aria-label="t('menu.theme')" :title="t('menu.theme')" @click="cycleTheme">
            <svg v-if="!theme.isDark" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
              <circle cx="12" cy="12" r="4" />
              <path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41" />
            </svg>
            <svg v-else-if="!theme.isUltra" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
              <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
            </svg>
            <svg v-else viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
              <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
              <path fill="none" d="M19 3l0.7 1.4 1.4 0.7-1.4 0.7L19 7.2l-0.7-1.4-1.4-0.7 1.4-0.7z" />
            </svg>
          </button>

          <!-- Modern Wallpaper Picker Button -->
          <a-popover trigger="click" placement="bottomRight" overlay-class-name="wallpaper-popover">
            <template #content>
              <div class="wallpaper-grid">
                <div
                  v-for="wp in availableWallpapers"
                  :key="wp.file"
                  class="wallpaper-item"
                  :class="{ active: current === wp.file }"
                  @click="setWallpaper(wp.file)"
                >
                  <div
                    class="wallpaper-thumb"
                    :style="{ backgroundImage: `url('${wp.previewUrl}')` }"
                  ></div>
                  <span class="wallpaper-name">{{ wp.name }}</span>
                  <div v-if="current === wp.file" class="wallpaper-check">
                    <svg viewBox="0 0 24 24" width="12" height="12" fill="none" stroke="currentColor" stroke-width="3">
                      <polyline points="20 6 9 17 4 12" />
                    </svg>
                  </div>
                </div>
              </div>
            </template>
            <button class="glass-icon-btn" aria-label="Change wallpaper" title="Change wallpaper">
              <!-- Modern layered landscape/mountain wallpaper icon -->
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                <rect x="4" y="4" width="16" height="16" rx="2"/>
                <path d="M4 15l4-3 3 3 5-5 4 4"/>
                <circle cx="9" cy="9" r="1" fill="currentColor"/>
              </svg>
            </button>
          </a-popover>
        </div>
      </div>

      <!-- Glass Menu Navigation - Icons remain visible when collapsed -->
      <a-menu :theme="currentTheme" mode="inline" :selected-keys="activeTab" class="glass-menu sider-nav" @click="({ key }) => openLink(key)">
        <a-menu-item v-for="tab in navTabs" :key="tab.key" class="glass-menu-item" :data-title="tab.title">
          <component :is="iconByName[tab.icon]" class="menu-icon" />
          <span class="menu-text">{{ tab.title }}</span>
          <div class="menu-glow"></div>
        </a-menu-item>
      </a-menu>

      <!-- Glass Utility Menu - Icons remain visible when collapsed -->
      <a-menu :theme="currentTheme" mode="inline" :selected-keys="activeTab" class="glass-menu sider-utility" @click="({ key }) => openLink(key)">
        <a-menu-item v-for="tab in utilTabs" :key="tab.key" class="glass-menu-item" :data-title="tab.title">
          <component :is="iconByName[tab.icon]" class="menu-icon" />
          <span class="menu-text">{{ tab.title }}</span>
          <div class="menu-glow"></div>
        </a-menu-item>
      </a-menu>
    </a-layout-sider>

    <!-- LIQUID GLASS DRAWER (MOBILE) -->
    <a-drawer placement="left" :closable="false" :open="drawerOpen" :wrap-class-name="currentTheme"
      :wrap-style="{ padding: 0 }" :width="drawerWidth"
      :body-style="{ padding: 0, display: 'flex', flexDirection: 'column', height: '100%' }"
      :header-style="{ display: 'none' }" @close="closeDrawer" class="glass-drawer">
      <div class="drawer-header">
        <span class="drawer-brand">3X-UI</span>
        <div class="drawer-header-actions">
          <button id="theme-cycle-drawer" type="button" class="glass-icon-btn" :aria-label="t('menu.theme')" :title="t('menu.theme')" @click="cycleTheme">
            <svg v-if="!theme.isDark" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
              <circle cx="12" cy="12" r="4" />
              <path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41" />
            </svg>
            <svg v-else-if="!theme.isUltra" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
              <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
            </svg>
            <svg v-else viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
              <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
              <path fill="none" d="M19 3l0.7 1.4 1.4 0.7-1.4 0.7L19 7.2l-0.7-1.4-1.4-0.7 1.4-0.7z" />
            </svg>
          </button>

          <a-popover trigger="click" placement="bottomRight" overlay-class-name="wallpaper-popover">
            <template #content>
              <div class="wallpaper-grid">
                <div
                  v-for="wp in availableWallpapers"
                  :key="wp.file"
                  class="wallpaper-item"
                  :class="{ active: current === wp.file }"
                  @click="setWallpaper(wp.file)"
                >
                  <div class="wallpaper-thumb" :style="{ backgroundImage: `url('/backgrounds/${wp.file}')` }"></div>
                  <span class="wallpaper-name">{{ wp.name }}</span>
                  <div v-if="current === wp.file" class="wallpaper-check">
                    <svg viewBox="0 0 24 24" width="12" height="12" fill="none" stroke="currentColor" stroke-width="3">
                      <polyline points="20 6 9 17 4 12" />
                    </svg>
                  </div>
                </div>
              </div>
            </template>
            <button class="glass-icon-btn" aria-label="Change wallpaper" title="Change wallpaper">
              <!-- Modern layered landscape/mountain wallpaper icon -->
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                <rect x="4" y="4" width="16" height="16" rx="2"/>
                <path d="M4 15l4-3 3 3 5-5 4 4"/>
                <circle cx="9" cy="9" r="1" fill="currentColor"/>
              </svg>
            </button>
          </a-popover>

          <button class="glass-icon-btn close-btn" type="button" :aria-label="t('close')" @click="closeDrawer">
            <CloseOutlined />
          </button>
        </div>
      </div>

      <a-menu :theme="currentTheme" mode="inline" :selected-keys="activeTab" class="glass-menu drawer-nav" @click="({ key }) => openLink(key)">
        <a-menu-item v-for="tab in navTabs" :key="tab.key" class="glass-menu-item">
          <component :is="iconByName[tab.icon]" class="menu-icon" />
          <span class="menu-text">{{ tab.title }}</span>
        </a-menu-item>
      </a-menu>

      <a-menu :theme="currentTheme" mode="inline" :selected-keys="activeTab" class="glass-menu drawer-utility" @click="({ key }) => openLink(key)">
        <a-menu-item v-for="tab in utilTabs" :key="tab.key" class="glass-menu-item">
          <component :is="iconByName[tab.icon]" class="menu-icon" />
          <span class="menu-text">{{ tab.title }}</span>
        </a-menu-item>
      </a-menu>
    </a-drawer>

    <!-- Mobile Drawer Handle -->
    <button v-show="!drawerOpen" class="glass-handle" type="button" :aria-label="t('menu.dashboard')" @click="toggleDrawer">
      <MenuOutlined />
    </button>
  </div>
</template>

<style scoped>
/* ===== BASE LAYOUT ===== */
.ant-sidebar > .glass-sider {
  position: sticky;
  top: 0;
  height: 100vh;
  align-self: flex-start;
  z-index: 100;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

/* ===== LIQUID GLASS SIDEBAR CORE ===== */
.ant-sidebar > .glass-sider :deep(.ant-layout-sider-children) {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: rgba(255, 255, 255, 0.06);
  backdrop-filter: blur(24px) saturate(180%) brightness(1.02);
  -webkit-backdrop-filter: blur(24px) saturate(180%);
  border-right: 1px solid rgba(255, 255, 255, 0.2);
  box-shadow: inset 0 0 30px rgba(255, 255, 255, 0.03), 8px 0 32px rgba(0, 0, 0, 0.08);
  transition: all 0.3s ease;
}

/* Dark Theme Liquid Glass */
body.dark .ant-sidebar > .glass-sider :deep(.ant-layout-sider-children) {
  background: rgba(10, 10, 20, 0.45);
  backdrop-filter: blur(24px) saturate(180%) brightness(0.92);
  border-right: 1px solid rgba(255, 255, 255, 0.12);
  box-shadow: inset 0 0 40px rgba(80, 120, 255, 0.05), 8px 0 32px rgba(0, 0, 0, 0.3);
}

/* Ultra Dark Theme Liquid Glass */
html[data-theme='ultra-dark'] .ant-sidebar > .glass-sider :deep(.ant-layout-sider-children) {
  background: rgba(0, 0, 5, 0.55);
  backdrop-filter: blur(28px) saturate(160%) brightness(0.75);
  border-right: 1px solid rgba(255, 255, 255, 0.08);
  box-shadow: inset 0 0 50px rgba(120, 80, 255, 0.06), 8px 0 40px rgba(0, 0, 0, 0.5);
}

/* ===== BRAND SECTION ===== */
.sider-brand,
.drawer-brand {
  font-weight: 600;
  font-size: 18px;
  letter-spacing: 0.5px;
  color: rgba(0, 0, 0, 0.88);
}

.sider-brand {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  padding: 14px 16px;
  margin: 12px 12px 8px 12px;
  border-radius: 20px;
  background: rgba(255, 255, 255, 0.06);
  backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.15);
  user-select: none;
}

.sider-brand-collapsed {
  justify-content: center;
  padding: 14px 8px;
  margin: 12px 8px;
}

.brand-text {
  flex: 1 1 auto;
  font-weight: 700;
  background: linear-gradient(135deg, #1a1a2e, #16213e);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
}

body.dark .brand-text {
  background: linear-gradient(135deg, #eef, #88aaff);
  -webkit-background-clip: text;
  background-clip: text;
}

.sider-brand-collapsed .brand-text {
  flex: 0 0 auto;
  font-size: 20px;
}

.sider-brand-actions {
  display: flex;
  align-items: center;
  gap: 6px;
}

/* ===== LIQUID GLASS ICON BUTTONS ===== */
.glass-icon-btn {
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  backdrop-filter: blur(8px);
  width: 32px;
  height: 32px;
  border-radius: 12px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  color: rgba(0, 0, 0, 0.75);
  transition: all 0.2s cubic-bezier(0.2, 0, 0, 1);
  font-size: 16px;
}

.glass-icon-btn svg {
  width: 16px;
  height: 16px;
}

.glass-icon-btn:hover {
  background: rgba(64, 150, 255, 0.3);
  border-color: rgba(64, 150, 255, 0.5);
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(64, 150, 255, 0.2);
  color: #4096ff;
}

.glass-icon-btn:active {
  transform: translateY(1px);
}

.close-btn {
  background: rgba(255, 100, 100, 0.15);
  border-color: rgba(255, 100, 100, 0.3);
}

.close-btn:hover {
  background: rgba(255, 80, 80, 0.35);
  border-color: #ff5a5a;
  color: #ff8a8a;
  box-shadow: 0 4px 12px rgba(255, 80, 80, 0.25);
}

/* ===== LIQUID GLASS MENU ===== */
.glass-menu {
  background: transparent !important;
  margin: 8px 0;
}

.sider-nav {
  flex: 1 1 auto;
  overflow-y: auto;
  overflow-x: hidden;
  min-height: 0;
}

.sider-nav::-webkit-scrollbar {
  width: 4px;
}

.sider-nav::-webkit-scrollbar-track {
  background: rgba(255, 255, 255, 0.05);
  border-radius: 4px;
}

.sider-nav::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.2);
  border-radius: 4px;
}

.sider-utility {
  flex: 0 0 auto;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  margin-top: 8px;
}

/* Glass Menu Items - Enhanced for collapsed state */
.glass-menu-item {
  position: relative;
  margin: 6px 12px !important;
  padding: 0 16px !important;
  height: 44px !important;
  line-height: 44px !important;
  border-radius: 14px !important;
  background: transparent !important;
  transition: all 0.25s cubic-bezier(0.2, 0, 0, 1) !important;
  overflow: hidden;
  display: flex !important;
  align-items: center !important;
  gap: 8px;
}

.glass-menu-item:hover {
  background: rgba(255, 255, 255, 0.12) !important;
  backdrop-filter: blur(12px);
  transform: translateX(4px);
}

.glass-menu-item:hover .menu-icon {
  transform: scale(1.05);
  filter: drop-shadow(0 0 4px rgba(64, 150, 255, 0.5));
}

/* Active Menu Item Highlight */
.glass-menu-item.ant-menu-item-selected {
  background: rgba(64, 150, 255, 0.2) !important;
  backdrop-filter: blur(16px);
  box-shadow: 0 0 16px rgba(64, 150, 255, 0.15);
}

.glass-menu-item.ant-menu-item-selected::before {
  content: '';
  position: absolute;
  left: 0;
  top: 20%;
  height: 60%;
  width: 3px;
  background: linear-gradient(135deg, #4096ff, #6b4eff);
  border-radius: 0 4px 4px 0;
  box-shadow: 0 0 6px #4096ff;
}

.glass-menu-item.ant-menu-item-selected .menu-icon {
  color: #4096ff;
}

.menu-icon {
  font-size: 18px;
  transition: transform 0.2s ease, filter 0.2s ease, color 0.2s ease;
  flex-shrink: 0;
  margin-right: 12px;
}

.menu-text {
  font-weight: 500;
  letter-spacing: 0.3px;
  white-space: nowrap;
  transition: opacity 0.2s ease, width 0.2s ease;
}

/* Menu Glow Effect */
.menu-glow {
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.08), transparent);
  transition: left 0.5s ease;
  pointer-events: none;
}

.glass-menu-item:hover .menu-glow {
  left: 100%;
}

/* ===== COLLAPSED SIDEBAR STYLES - Icons remain fully visible and interactive ===== */
.glass-sider.ant-layout-sider-collapsed .glass-menu-item {
  justify-content: center !important;
  padding: 0 !important;
  width: 100% !important;
  margin: 6px 0 !important;
}

.glass-sider.ant-layout-sider-collapsed .menu-icon {
  margin-right: 0 !important;
  font-size: 20px !important;
}

.glass-sider.ant-layout-sider-collapsed .menu-text {
  display: none;
}

/* Tooltip style on hover for collapsed menu items - shows menu text */
.glass-sider.ant-layout-sider-collapsed .glass-menu-item:hover::after {
  content: attr(data-title);
  position: absolute;
  left: 100%;
  top: 50%;
  transform: translateY(-50%);
  margin-left: 12px;
  padding: 4px 12px;
  background: rgba(0, 0, 0, 0.75);
  backdrop-filter: blur(12px);
  color: white;
  font-size: 13px;
  font-weight: 500;
  border-radius: 8px;
  white-space: nowrap;
  z-index: 1000;
  pointer-events: none;
  border: 1px solid rgba(255, 255, 255, 0.2);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
}

/* Hover effect for collapsed menu items - enhanced liquid glass feel */
.glass-sider.ant-layout-sider-collapsed .glass-menu-item:hover {
  background: rgba(64, 150, 255, 0.25) !important;
  transform: scale(1.02);
  margin: 6px 4px !important;
  width: calc(100% - 8px) !important;
}

/* ===== LIQUID GLASS DRAWER ===== */
.glass-drawer :deep(.ant-drawer-content) {
  background: rgba(255, 255, 255, 0.08) !important;
  backdrop-filter: blur(28px) saturate(180%) !important;
  box-shadow: 8px 0 40px rgba(0, 0, 0, 0.2) !important;
  border-right: 1px solid rgba(255, 255, 255, 0.15) !important;
}

body.dark .glass-drawer :deep(.ant-drawer-content) {
  background: rgba(10, 10, 20, 0.5) !important;
  backdrop-filter: blur(28px) saturate(180%) !important;
}

html[data-theme='ultra-dark'] .glass-drawer :deep(.ant-drawer-content) {
  background: rgba(0, 0, 5, 0.6) !important;
  backdrop-filter: blur(32px) saturate(160%) !important;
}

.drawer-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  margin: 12px 12px 8px;
  background: rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(12px);
  border-radius: 24px;
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.drawer-brand {
  font-weight: 700;
  font-size: 20px;
  background: linear-gradient(135deg, #1a1a2e, #16213e);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}

body.dark .drawer-brand {
  background: linear-gradient(135deg, #eef, #88aaff);
  -webkit-background-clip: text;
  background-clip: text;
}

.drawer-header-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.drawer-menu :deep(.ant-menu-item) {
  height: 48px;
  line-height: 48px;
  margin: 0;
  border-radius: 0;
}

.drawer-menu :deep(.ant-menu-item .anticon) {
  font-size: 16px;
}

.drawer-utility {
  margin-top: auto;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
}

/* ===== MOBILE HANDLE ===== */
.glass-handle {
  position: fixed;
  top: 12px;
  left: 12px;
  z-index: 1100;
  background: rgba(0, 0, 0, 0.4);
  backdrop-filter: blur(16px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  color: #fff;
  width: 44px;
  height: 44px;
  border-radius: 16px;
  cursor: pointer;
  display: none;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.2);
  transition: all 0.2s ease;
}

.glass-handle:hover {
  background: rgba(64, 150, 255, 0.5);
  border-color: rgba(64, 150, 255, 0.6);
  transform: scale(1.02);
}

/* ===== WALLPAPER GRID ===== */
.wallpaper-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 10px;
  padding: 6px;
  min-width: 210px;
}

.wallpaper-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  padding: 8px;
  border-radius: 16px;
  transition: all 0.2s ease;
  position: relative;
  border: 1px solid transparent;
  background: rgba(255, 255, 255, 0.03);
  backdrop-filter: blur(4px);
}

.wallpaper-item:hover {
  background: rgba(255, 255, 255, 0.12);
  transform: translateY(-3px);
  border-color: rgba(255, 255, 255, 0.2);
}

.wallpaper-item.active {
  border-color: #4096ff;
  background: rgba(64, 150, 255, 0.15);
  box-shadow: 0 0 16px rgba(64, 150, 255, 0.2);
}

.wallpaper-thumb {
  width: 80px;
  height: 52px;
  border-radius: 12px;
  background-size: cover;
  background-position: center;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
  transition: transform 0.2s ease;
}

.wallpaper-item:hover .wallpaper-thumb {
  transform: scale(1.05);
}

.wallpaper-name {
  font-size: 11px;
  font-weight: 500;
  opacity: 0.85;
  text-align: center;
}

.wallpaper-check {
  position: absolute;
  top: 8px;
  right: 8px;
  width: 20px;
  height: 20px;
  border-radius: 10px;
  background: #1677ff;
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
}

/* ===== RESPONSIVE ===== */
@media (max-width: 768px) {
  .glass-handle {
    display: inline-flex;
  }

  .ant-sidebar > .glass-sider :deep(.ant-layout-sider-children),
  .ant-sidebar > .glass-sider :deep(.ant-layout-sider-trigger) {
    display: none;
  }

  .ant-sidebar > .glass-sider {
    flex: 0 0 0 !important;
    max-width: 0 !important;
    min-width: 0 !important;
    width: 0 !important;
  }
}
</style>

<style>
/* ===== GLOBAL LIQUID GLASS STYLES ===== */
body.dark .drawer-brand,
body.dark .sider-brand {
  color: rgba(255, 255, 255, 0.92);
}

html[data-theme='ultra-dark'] .drawer-brand,
html[data-theme='ultra-dark'] .sider-brand {
  color: #ffffff;
}

body.dark .glass-icon-btn {
  color: rgba(255, 255, 255, 0.85);
}

html[data-theme='ultra-dark'] .glass-icon-btn {
  color: rgba(255, 255, 255, 0.92);
}

/* Wallpaper Popover Liquid Glass */
.wallpaper-popover .ant-popover-inner {
  background: rgba(20, 20, 30, 0.85) !important;
  backdrop-filter: blur(32px) saturate(200%);
  border: 1px solid rgba(255, 255, 255, 0.15);
  border-radius: 24px;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
}

.wallpaper-popover .ant-popover-arrow::before {
  background: rgba(20, 20, 30, 0.85) !important;
  border: 1px solid rgba(255, 255, 255, 0.15);
}

/* Menu Item Text Colors */
.glass-menu-item .menu-text {
  color: rgba(0, 0, 0, 0.75);
}

body.dark .glass-menu-item .menu-text {
  color: rgba(255, 255, 255, 0.85);
}

.glass-menu-item.ant-menu-item-selected .menu-text {
  color: #4096ff;
}

/* Hover states for non-selected items */
.sider-nav .ant-menu-item-active:not(.ant-menu-item-selected) .menu-text,
.sider-utility .ant-menu-item-active:not(.ant-menu-item-selected) .menu-text,
.drawer-menu .ant-menu-item-active:not(.ant-menu-item-selected) .menu-text,
.glass-menu-item:not(.ant-menu-item-selected):hover .menu-text {
  color: #4096ff !important;
}

/* Animation for menu items */
@keyframes liquidAppear {
  from {
    opacity: 0;
    transform: translateX(-10px);
    backdrop-filter: blur(0px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
    backdrop-filter: blur(4px);
  }
}

.glass-menu-item {
  animation: liquidAppear 0.3s ease backwards;
}

.glass-menu-item:nth-child(1) { animation-delay: 0.02s; }
.glass-menu-item:nth-child(2) { animation-delay: 0.04s; }
.glass-menu-item:nth-child(3) { animation-delay: 0.06s; }
.glass-menu-item:nth-child(4) { animation-delay: 0.08s; }
.glass-menu-item:nth-child(5) { animation-delay: 0.10s; }
.glass-menu-item:nth-child(6) { animation-delay: 0.12s; }
</style>