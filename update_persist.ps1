$path = "c:\Users\tuttu\OneDrive\Desktop\index-with-admin-1.html"
$content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

$oldStr = @"
function persistState() {
  if (!state.loggedInUser) return;
  const payload = {
    username:            state.loggedInUser.username,
    email:               state.loggedInUser.email,
    savedProperties:     state.savedProperties,
    userBookings:        state.userBookings,
    avatarIdx:           state.avatarIdx,
    bannerIdx:           state.bannerIdx,
    profileDisplayName:  state.profileDisplayName || '',
    profilePhone:        state.profilePhone        || '',
    profileLocation:     state.profileLocation     || '',
    profileBio:          state.profileBio          || '',
  };
  try {
    localStorage.setItem(ALP_STORAGE_KEY, JSON.stringify(payload));
  } catch(e) {
    console.warn('localStorage write failed', e);
  }
}

function loadPersistedState() {
  try {
    const raw = localStorage.getItem(ALP_STORAGE_KEY);
    if (!raw) return null;
    return JSON.parse(raw);
  } catch(e) {
    console.warn('localStorage read failed', e);
    return null;
  }
}

function clearUserState() {
  // Clear persisted data
  localStorage.removeItem(ALP_STORAGE_KEY);
  localStorage.removeItem('alp_session');
  // Reset in-memory state
  state.loggedInUser   = null;
  state.savedProperties = [];
  state.userBookings   = [];
  state.bookingData    = {};
  state.avatarIdx      = undefined;
  state.bannerIdx      = undefined;
  state.profileDisplayName = '';
  state.profilePhone       = '';
  state.profileLocation    = '';
  state.profileBio         = '';
  // Reset profile view to logged-out state
  const profileContainer = document.getElementById('profile-dynamic-content');
  if (profileContainer) {
    profileContainer.innerHTML = `
      <div class="bg-white rounded-3xl p-8 text-center shadow-card border border-gray-100 max-w-sm mx-auto mb-6 relative overflow-hidden">
        <div class="w-16 h-16 rounded-2xl bg-emerald-mist flex items-center justify-center mx-auto mb-4">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#0d4f3c" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>
        </div>
        <h3 class="font-display text-2xl font-light text-ink mb-2">You're not signed in</h3>
        <p class="text-gray-400 text-sm font-body mb-6 max-w-[260px] leading-relaxed">Sign in to view your profile, bookings and saved properties.</p>
        <button onclick="showView('login')" class="btn-emerald text-white font-semibold text-sm rounded-2xl px-6 py-3 font-body">Sign In</button>
      </div>`;
  }
  // Navigate to login view and trigger sign-up mode (create account section)
  showView('login');
  setTimeout(() => {
    switchLoginTab('customer');
    // Scroll to "create account" row smoothly
    const createLink = document.querySelector('#form-customer .text-emerald.font-semibold.cursor-pointer');
    if (createLink) {
      createLink.scrollIntoView({ behavior: 'smooth', block: 'center' });
      // Pulse the element to draw attention
      createLink.style.transition = 'all 0.3s ease';
      createLink.style.background = 'var(--emerald-mist)';
      createLink.style.borderRadius = '8px';
      createLink.style.padding = '2px 6px';
      setTimeout(() => {
        createLink.style.background = '';
        createLink.style.padding = '';
      }, 1800);
    }
  }, 80);
}
"@

$newStr = @"
function persistState() {}
function loadPersistedState() { return null; }
function clearUserState() {
  state.loggedInUser = null;
  state.savedProperties = [];
  state.userBookings = [];
  state.bookingData = {};
  state.avatarIdx = undefined;
  state.bannerIdx = undefined;
  state.profileDisplayName = '';
  state.profilePhone = '';
  state.profileLocation = '';
  state.profileBio = '';
  
  const profileContainer = document.getElementById('profile-dynamic-content');
  if (profileContainer) {
    profileContainer.innerHTML = `<div class="bg-white rounded-3xl p-8 text-center shadow-card border border-gray-100 max-w-sm mx-auto mb-6 relative overflow-hidden"><div class="w-16 h-16 rounded-2xl bg-emerald-mist flex items-center justify-center mx-auto mb-4"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#0d4f3c" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg></div><h3 class="font-display text-2xl font-light text-ink mb-2">You're not signed in</h3><p class="text-gray-400 text-sm font-body mb-6 max-w-[260px] leading-relaxed">Sign in to view your profile, bookings and saved properties.</p><button onclick="showView('login')" class="btn-emerald text-white font-semibold text-sm rounded-2xl px-6 py-3 font-body">Sign In</button></div>`;
  }
}
"@

$content = $content.Replace($oldStr, $newStr)
[System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
