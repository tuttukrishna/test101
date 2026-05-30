$path = "c:\Users\tuttu\OneDrive\Desktop\index-with-admin-1.html"
$content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

# Replace loginAsCustomer
$start = $content.IndexOf("function loginAsCustomer() {")
$end = $content.IndexOf("function loginAsAgent() {", $start)
if ($start -gt -1 -and $end -gt $start) {
    $chunk = $content.Substring($start, $end - $start)
    $newCode = @"
async function loginAsCustomer() {
  const emailInput = document.querySelector('#form-customer input[type="email"]');
  const passInput = document.querySelector('#form-customer input[type="password"]');
  const email = emailInput ? emailInput.value.trim() : '';
  const pass = passInput ? passInput.value.trim() : '';

  if(!email || !pass) {
    showToast('Please enter both email and password');
    return;
  }

  const { data, error } = await window.supabase.auth.signInWithPassword({ email, password: pass });

  if (error) {
    if (error.message.includes('Invalid login credentials') || error.message.includes('signups not allowed')) {
      const { error: signUpError } = await window.supabase.auth.signUp({
        email, password: pass,
        options: { data: { full_name: email.split('@')[0], role: 'customer' } }
      });
      if (signUpError) { showToast(signUpError.message); return; }
      showToast(`Account created! Please sign in again or check your email.`);
    } else {
      showToast(error.message);
      return;
    }
  } else {
    showToast(`Welcome back!`);
    showView('home');
    setActiveNav(document.querySelector('#customer-bottom-nav .nav-item'));
  }
}

"@
    $content = $content.Replace($chunk, $newCode)
}

# Replace loginAsAgent
$start = $content.IndexOf("function loginAsAgent() {")
$end = $content.IndexOf("function adminLogOut()", $start) # adminLogOut is at the end of the file? No, wait. 
$end = $content.IndexOf("function renderPropertyCards", $start)
if ($end -eq -1) { $end = $content.IndexOf("/* ", $start) }

if ($start -gt -1 -and $end -gt $start) {
    $chunk = $content.Substring($start, $end - $start)
    $newCode = @"
async function loginAsAgent() {
  const emailInput = document.getElementById('agent-login-email');
  const passInput  = document.getElementById('agent-login-pass');
  const email = emailInput ? emailInput.value.trim() : '';
  const pass  = passInput  ? passInput.value.trim()  : '';

  if(!email || !pass) { showToast('Please enter both email and password'); return; }

  if (email === 'Admin' && pass === 'Admin123') {
    _saveSession('admin', { name: 'Super Admin' });
    showView('admin');
    return;
  }

  const { error } = await window.supabase.auth.signInWithPassword({ email, password: pass });
  if (error) {
    if (error.message.includes('Invalid login credentials')) {
      const { error: signUpError } = await window.supabase.auth.signUp({
        email, password: pass,
        options: { data: { full_name: email.split('@')[0], role: 'agent' } }
      });
      if (signUpError) { showToast(signUpError.message); return; }
      showToast(`Agent account created! Check email or sign in.`);
    } else {
      showToast(error.message);
      return;
    }
  } else {
    showToast(`Welcome back, Agent!`);
    showView('agent');
  }
}

"@
    $content = $content.Replace($chunk, $newCode)
}

# Replace logOut
$start = $content.IndexOf("function logOut() {")
$end = $content.IndexOf("function _saveSession(", $start)
if ($start -gt -1 -and $end -gt $start) {
    $chunk = $content.Substring($start, $end - $start)
    $newCode = @"
async function logOut() {
  await window.supabase.auth.signOut();
  clearUserState();
  showView('login');
  setTimeout(() => switchLoginTab('customer'), 50);
  setTimeout(() => showToast('You have been signed out'), 100);
}

"@
    $content = $content.Replace($chunk, $newCode)
}

[System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
