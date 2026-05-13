<script setup>
import { computed, onBeforeUnmount, onMounted, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { UserOutlined, LockOutlined, KeyOutlined, SettingOutlined } from '@ant-design/icons-vue';
import { useWallpaper } from '@/composables/useWallpaper.js';
const { current, availableWallpapers, setWallpaper } = useWallpaper();


import { HttpUtil, LanguageManager } from '@/utils';
import {
  antdThemeConfig,
  currentTheme,
  theme as themeState,
  toggleTheme,
  toggleUltra,
  pauseAnimationsUntilLeave,
} from '@/composables/useTheme.js';

const { t } = useI18n();

const fetched = ref(false);
const submitting = ref(false);
const twoFactorEnable = ref(false);

const user = reactive({
  username: '',
  password: '',
  twoFactorCode: '',
});

const basePath = window.X_UI_BASE_PATH || '';

const headlineWords = computed(() => [t('pages.login.hello'), t('pages.login.title')]);
const HEADLINE_INTERVAL_MS = 2000;
const headlineIndex = ref(0);
let headlineTimer = null;

onMounted(() => {
  headlineTimer = window.setInterval(() => {
    headlineIndex.value = (headlineIndex.value + 1) % headlineWords.value.length;
  }, HEADLINE_INTERVAL_MS);
});

onBeforeUnmount(() => {
  if (headlineTimer != null) window.clearInterval(headlineTimer);
});

onMounted(async () => {
  const msg = await HttpUtil.post('/getTwoFactorEnable');
  if (msg.success) twoFactorEnable.value = !!msg.obj;
  fetched.value = true;
});

async function login() {
  submitting.value = true;
  try {
    const msg = await HttpUtil.post('/login', user);
    if (msg.success) window.location.href = basePath + 'panel/';
  } finally {
    submitting.value = false;
  }
}

const lang = ref(LanguageManager.getLanguage());
function onLangChange(next) {
  LanguageManager.setLanguage(next);
}

/* Same Light -> Dark -> Ultra Dark -> Light cycle the sidebar's brand
 * button uses, so the login chrome offers a one-click theme toggle
 * without the popover ceremony. */
function cycleTheme() {
  pauseAnimationsUntilLeave('login-theme-cycle');
  if (!themeState.isDark) {
    toggleTheme();
    if (themeState.isUltra) toggleUltra();
  } else if (!themeState.isUltra) {
    toggleUltra();
  } else {
    toggleUltra();
    toggleTheme();
  }
}
</script>
<template>
  <a-config-provider :theme="antdThemeConfig">
    <a-layout class="login-app" :class="{ 'is-dark': themeState.isDark, 'is-ultra': themeState.isUltra }">
      <a-layout-content class="login-content">
        <!-- Floating chrome at top-right: theme cycle, wallpaper picker,
             plus a language picker hidden behind the gear popover. -->
        <div class="login-toolbar">
          <!-- Theme Cycle Button -->
          <button type="button" class="glass-btn" id="login-theme-cycle" :aria-label="t('menu.theme')" :title="t('menu.theme')"
            @click="cycleTheme">
            <svg v-if="!themeState.isDark" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
              stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
              <circle cx="12" cy="12" r="4" />
              <path
                d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41" />
            </svg>
            <svg v-else-if="!themeState.isUltra" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
              stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
              <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
            </svg>
            <svg v-else viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" stroke-width="1.5"
              stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
              <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
              <path fill="none" d="M19 3l0.7 1.4 1.4 0.7-1.4 0.7L19 7.2l-0.7-1.4-1.4-0.7 1.4-0.7z" />
            </svg>
          </button>

          <!-- Wallpaper Picker -->
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
                    <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="3">
                      <polyline points="20 6 9 17 4 12" />
                    </svg>
                  </div>
                </div>
              </div>
            </template>
            <button class="glass-btn" aria-label="Change wallpaper" title="Change wallpaper">
              <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round">
                <rect x="3" y="3" width="18" height="18" rx="2" />
                <circle cx="8.5" cy="8.5" r="1.5" />
                <path d="m21 15-5-5L5 21" />
              </svg>
            </button>
          </a-popover>

          <!-- Language Picker -->
          <a-popover :overlay-class-name="currentTheme" :title="t('pages.settings.language')" placement="bottomRight"
            trigger="click">
            <template #content>
              <a-space direction="vertical" :size="10" class="settings-popover">
                <a-select v-model:value="lang" class="lang-select" @change="onLangChange">
                  <a-select-option v-for="l in LanguageManager.supportedLanguages" :key="l.value" :value="l.value">
                    <span :aria-label="l.name">{{ l.icon }}</span>
                    &nbsp;&nbsp;<span>{{ l.name }}</span>
                  </a-select-option>
                </a-select>
              </a-space>
            </template>
            <button class="glass-btn" :aria-label="t('menu.settings')">
              <SettingOutlined />
            </button>
          </a-popover>
        </div>

        <div class="login-wrapper">
          <div v-if="!fetched" class="login-loading">
            <a-spin size="large" />
          </div>

          <div v-else class="login-card">
            <div class="brand">
              <span class="brand-name">3X-UI</span>
              <span class="brand-accent" aria-hidden="true"></span>
            </div>
            <h2 class="welcome">
              <Transition name="headline" mode="out-in">
                <b :key="headlineIndex">{{ headlineWords[headlineIndex] }}</b>
              </Transition>
            </h2>

            <a-form layout="vertical" class="login-form" @submit.prevent="login">
              <a-form-item :label="t('username')">
                <a-input v-model:value="user.username" autocomplete="username" name="username" size="large"
                  :placeholder="t('username')" autofocus required>
                  <template #prefix>
                    <UserOutlined />
                  </template>
                </a-input>
              </a-form-item>

              <a-form-item :label="t('password')">
                <a-input-password v-model:value="user.password" autocomplete="current-password" name="password"
                  size="large" :placeholder="t('password')" required>
                  <template #prefix>
                    <LockOutlined />
                  </template>
                </a-input-password>
              </a-form-item>

              <a-form-item v-if="twoFactorEnable" :label="t('twoFactorCode')">
                <a-input v-model:value="user.twoFactorCode" autocomplete="one-time-code" name="twoFactorCode"
                  size="large" :placeholder="t('twoFactorCode')" required>
                  <template #prefix>
                    <KeyOutlined />
                  </template>
                </a-input>
              </a-form-item>

              <a-form-item class="submit-row">
                <a-button type="primary" html-type="submit" :loading="submitting" size="large" block>
                  {{ submitting ? '' : t('login') }}
                </a-button>
              </a-form-item>
            </a-form>

          </div>
        </div>
      </a-layout-content>
    </a-layout>
  </a-config-provider>
</template>

<style scoped>
.login-app {
  --bg-card: #ffffff;
  --color-text: rgba(0, 0, 0, 0.88);
  --color-text-subtle: rgba(0, 0, 0, 0.55);
  --color-accent: #1677ff;
  --color-border: rgba(0, 0, 0, 0.08);
  --shadow-card: 0 1px 3px rgba(0, 0, 0, 0.04), 0 8px 24px rgba(0, 0, 0, 0.06);

  position: relative;
  min-height: 100vh;
  overflow: hidden;
  background-image: var(--wallpaper-url);
  background-size: cover;
  background-position: center;
  background-attachment: fixed;
  background-repeat: no-repeat;
}

.login-app::before {
  content: '';
  position: absolute;
  inset: 0;
  background: rgba(255, 255, 255, 0.15);
  backdrop-filter: brightness(1.1);
  z-index: 0;
}

.login-app.is-dark {
  --bg-card: #252526;
  --color-text: rgba(255, 255, 255, 0.92);
  --color-text-subtle: rgba(255, 255, 255, 0.55);
  --color-accent: #4096ff;
  --color-border: rgba(255, 255, 255, 0.08);
  --shadow-card: 0 1px 3px rgba(0, 0, 0, 0.3), 0 8px 32px rgba(0, 0, 0, 0.4);
  background-image: var(--wallpaper-url);
  background-size: cover;
  background-position: center;
  background-attachment: fixed;
}

.login-app.is-dark::before {
  content: '';
  position: absolute;
  inset: 0;
  background: rgba(10, 15, 35, 0.45);
  backdrop-filter: brightness(0.8) contrast(1.1);
  z-index: 0;
}

.login-app.is-dark.is-ultra {
  --bg-card: #141414;
  --color-border: rgba(255, 255, 255, 0.06);
  background-image: var(--wallpaper-url);
  background-size: cover;
  background-position: center;
  background-attachment: fixed;
}

.login-app.is-dark.is-ultra::before {
  content: '';
  position: absolute;
  inset: 0;
  background: rgba(0, 0, 0, 0.65);
  backdrop-filter: brightness(0.6) contrast(1.2);
  z-index: 0;
}

.login-app :deep(.ant-layout-content) {
  background: transparent;
}

.login-content {
  position: relative;
}

.login-content > * {
  position: relative;
  z-index: 1;
}

/* ===== Glass-morphism Toolbar ===== */
.login-toolbar {
  position: fixed;
  top: 16px;
  right: 16px;
  z-index: 10;
  display: inline-flex;
  align-items: center;
  gap: 10px;
}

.glass-btn {
  width: 42px;
  height: 42px;
  border-radius: 14px;
  border: 1px solid rgba(255, 255, 255, 0.2);
  background: rgba(255, 255, 255, 0.08);
  backdrop-filter: blur(20px) saturate(180%);
  -webkit-backdrop-filter: blur(20px) saturate(180%);
  color: rgba(255, 255, 255, 0.9);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  padding: 0;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  overflow: hidden;
}

.glass-btn::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.25), transparent 60%);
  border-radius: inherit;
  opacity: 0;
  transition: opacity 0.3s;
}

.glass-btn:hover {
  background: rgba(255, 255, 255, 0.15);
  border-color: rgba(255, 255, 255, 0.35);
  transform: translateY(-2px);
  box-shadow: 0 8px 30px rgba(0, 0, 0, 0.2);
}

.glass-btn:hover::after {
  opacity: 1;
}

.glass-btn:active {
  transform: translateY(0);
  transition: transform 0.1s;
}

.glass-btn svg {
  filter: drop-shadow(0 1px 2px rgba(0, 0, 0, 0.3));
}

/* ===== Wallpaper Grid Popover ===== */
.wallpaper-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
  padding: 6px;
  min-width: 220px;
}

.wallpaper-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 7px;
  cursor: pointer;
  padding: 8px;
  border-radius: 12px;
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  border: 2px solid transparent;
}

.wallpaper-item:hover {
  background: rgba(255, 255, 255, 0.08);
  transform: translateY(-3px);
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.15);
}

.wallpaper-item.active {
  border-color: rgba(100, 180, 255, 0.7);
  background: rgba(100, 180, 255, 0.1);
}

.wallpaper-thumb {
  width: 90px;
  height: 60px;
  border-radius: 10px;
  background-size: cover;
  background-position: center;
  box-shadow: 0 3px 12px rgba(0, 0, 0, 0.25);
  transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.wallpaper-item:hover .wallpaper-thumb {
  transform: scale(1.1);
}

.wallpaper-name {
  font-size: 11px;
  font-weight: 500;
  color: rgba(255, 255, 255, 0.85);
  text-align: center;
  white-space: nowrap;
  letter-spacing: 0.3px;
}

.wallpaper-check {
  position: absolute;
  top: 10px;
  right: 10px;
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: #1677ff;
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
}

/* ===== Login Card Styles ===== */
.login-wrapper {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px 16px;
}

.login-loading {
  text-align: center;
}

.login-card {
  width: 100%;
  max-width: 400px;
  background: var(--bg-card);
  border: 1px solid var(--color-border);
  border-radius: 12px;
  padding: 40px 32px 28px;
  box-shadow: var(--shadow-card);
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
}

@media (max-width: 480px) {
  .login-card {
    padding: 32px 20px 24px;
  }
}

.brand {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
  margin-bottom: 8px;
}

.brand-name {
  font-size: 28px;
  font-weight: 700;
  letter-spacing: 1.5px;
  color: var(--color-text);
}

.brand-accent {
  display: block;
  width: 40px;
  height: 3px;
  border-radius: 2px;
  background: var(--color-accent);
}

.welcome {
  text-align: center;
  color: var(--color-text);
  font-size: 32px;
  font-weight: 700;
  line-height: 1.2;
  min-height: 42px;
  margin: 12px 0 28px;
  letter-spacing: 0.3px;
}

.welcome b {
  display: inline-block;
  font-weight: inherit;
}

.headline-enter-active,
.headline-leave-active {
  transition: opacity 280ms ease, transform 280ms ease;
}

.headline-enter-from {
  opacity: 0;
  transform: translateY(6px);
}

.headline-leave-to {
  opacity: 0;
  transform: translateY(-6px);
}

.login-form :deep(.ant-form-item-label > label) {
  color: var(--color-text);
  font-weight: 500;
}

.submit-row {
  margin-bottom: 0;
}

.settings-popover {
  min-width: 220px;
}

.lang-select {
  width: 100%;
}
</style>

<style>
/* Dark popover for wallpaper picker */
.wallpaper-popover .ant-popover-inner {
  background: rgba(30, 30, 40, 0.9) !important;
  backdrop-filter: blur(30px) saturate(200%);
  -webkit-backdrop-filter: blur(30px) saturate(200%);
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 16px;
  box-shadow: 0 20px 50px rgba(0, 0, 0, 0.4);
}

.wallpaper-popover .ant-popover-arrow::before {
  background: rgba(30, 30, 40, 0.9) !important;
  border: 1px solid rgba(255, 255, 255, 0.12);
}
</style>