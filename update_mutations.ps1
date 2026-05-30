$path = "c:\Users\tuttu\OneDrive\Desktop\index-with-admin-1.html"
$content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

# Replacement helper
function Replace-Function($funcStartStr, $endStr, $newFunc) {
    global $content
    $start = $content.IndexOf($funcStartStr)
    if ($start -gt -1) {
        $end = $content.IndexOf($endStr, $start)
        if ($end -gt $start) {
            $chunk = $content.Substring($start, $end - $start)
            $content = $content.Replace($chunk, $newFunc)
            Write-Host "Replaced: $funcStartStr"
        }
    }
}

$onPaymentSuccessNew = @"
async function onPaymentSuccess(response) {
  if (!_pendingBookingData) return;
  const bd = _pendingBookingData;
  bd.paymentId = response.razorpay_payment_id || 'PAY-DEMO';
  bd.paymentStatus = 'paid';

  try {
    const { data: { session } } = await window.supabase.auth.getSession();
    const property = PROPERTIES.find(p => p.title === bd.propertyName) || TOUR_PACKAGES.find(t => t.title === bd.propertyName);
    if (!property || !session) throw new Error("Missing property or user session");

    const { error } = await window.supabase.from('bookings').insert({
      booking_ref: bd.bookingId,
      property_id: property.id,
      guest_id: session.user.id,
      check_in: bd.rawDate,
      nights: bd.nights,
      guests: bd.guests,
      total_amount: bd.totalAmount,
      status: 'confirmed',
      payment_id: bd.paymentId
    });

    if (error) throw error;
  } catch (err) {
    console.error('Failed to save booking:', err);
    showToast('Payment successful, but failed to save booking to server. Contact support.');
  }

  state.bookingData = { ...bd };
  state.userBookings.unshift({ 
    id: bd.bookingId, 
    date: bd.rawDate, 
    total: '₹' + bd.totalAmount, 
    status: 'confirmed', 
    propertyName: bd.propertyName 
  });
  
  renderMyBookings();

  document.getElementById('success-property-name').textContent = bd.propertyName;
  document.getElementById('success-date').textContent = bd.date;
  document.getElementById('success-guests').textContent = bd.guestStr + ' • ' + bd.nights + ' Night' + (bd.nights > 1 ? 's' : '');
  document.getElementById('success-price').textContent = '₹' + bd.totalAmount.toLocaleString('en-IN');
  document.getElementById('success-booking-id').textContent = bd.bookingId;
  document.getElementById('success-host').textContent = bd.host;

  const qrContainer = document.getElementById('ticket-qr-container');
  qrContainer.innerHTML = '';
  new QRCode(qrContainer, {
    text: `BOOKING:${bd.bookingId}|PROPERTY:${bd.propertyName}|DATE:${bd.rawDate}|GUESTS:${bd.guests}|PAY:${bd.paymentId}`,
    width: 56, height: 56,
    colorDark: '#0d4f3c', colorLight: '#ffffff',
    correctLevel: QRCode.CorrectLevel.M,
  });

  _pendingBookingData = null;
  showView('success');
}
"@
Replace-Function "function onPaymentSuccess(response) {" "function onPaymentFailed(error) {" "$onPaymentSuccessNew`n`n"

$saveListingNew = @"
async function saveListing() {
  const title = document.getElementById('listing-title').value.trim();
  const location = document.getElementById('listing-location').value.trim();
  const price = parseInt(document.getElementById('listing-price').value);
  const description = document.getElementById('listing-description').value.trim();
  const category = document.getElementById('listing-category').value;
  const subtitle = document.getElementById('listing-subtitle').value.trim();
  const amenitiesStr = document.getElementById('listing-amenities').value.trim();

  if (!title) { showListingError('Property title is required.'); return; }
  if (!location) { showListingError('Location is required.'); return; }
  if (!price || price < 100) { showListingError('Please enter a valid price (min ₹100).'); return; }
  if (!description) { showListingError('Description is required.'); return; }

  const imgUrl = document.getElementById('listing-img-url').value.trim()
    || document.getElementById('listing-img-preview').src
    || 'https://images.unsplash.com/photo-1593693411515-c20261bcad6e?w=400&q=80';

  let amenities = [];
  if (amenitiesStr) {
    amenities = amenitiesStr.split(',').map(a => a.trim()).filter(Boolean);
  }

  const { data: { session } } = await window.supabase.auth.getSession();
  if (!session) { showToast('Not authenticated'); return; }

  const payload = {
    title, subtitle, category, location, price, description,
    amenities, images: [imgUrl], host_id: session.user.id, is_active: true
  };

  try {
    if (_editingListingId !== null) {
      const { error } = await window.supabase.from('properties').update(payload).eq('id', _editingListingId);
      if (error) throw error;
      showToast('Listing updated successfully!');
    } else {
      const { error } = await window.supabase.from('properties').insert(payload);
      if (error) throw error;
      showToast('Listing created successfully!');
    }
    
    closeListingModal();
    fetchAndRenderData();
  } catch (err) {
    showListingError(err.message);
  }
}
"@
Replace-Function "function saveListing() {" "function closeListingModal() {" "$saveListingNew`n`n"

$deleteListingNew = @"
async function deleteListing(id) {
  const card = document.getElementById(`agent-listing-` + id);
  if (!card) return;
  
  if (!confirm('Are you sure you want to delete this listing?')) return;
  
  try {
    const { error } = await window.supabase.from('properties').delete().eq('id', id);
    if (error) throw error;
    
    card.style.transition = 'all 0.3s ease';
    card.style.opacity = '0';
    card.style.transform = 'translateX(20px)';
    setTimeout(() => {
      card.remove();
      fetchAndRenderData();
    }, 300);
  } catch(err) {
    showToast(err.message);
  }
}
"@
Replace-Function "function deleteListing(id) {" "function toggleListingAvailability(" "$deleteListingNew`n`n"

$toggleAvailabilityNew = @"
async function toggleListingAvailability(toggleEl, id) {
  const isActive = !toggleEl.classList.contains('on');
  try {
    const { error } = await window.supabase.from('properties').update({ is_active: isActive }).eq('id', id);
    if (error) throw error;
    
    if (isActive) {
      toggleEl.classList.add('on');
    } else {
      toggleEl.classList.remove('on');
    }
    fetchAndRenderData();
  } catch(err) {
    showToast('Failed to update availability: ' + err.message);
  }
}
"@
Replace-Function "function toggleListingAvailability(toggleEl, id) {" "function openPreview(" "$toggleAvailabilityNew`n`n"


$toggleHeartNew = @"
async function toggleHeart(btn) {
  const icon = btn.querySelector('i');
  if (!icon) return;

  const card = btn.closest('[data-id]');
  const propId = card ? card.getAttribute('data-id') : null;
  
  const { data: { session } } = await window.supabase.auth.getSession();
  if (!session) {
    showToast('Please sign in to save favourites');
    return;
  }

  if (icon.classList.contains('fa-regular')) {
    icon.classList.replace('fa-regular', 'fa-solid');
    icon.style.color = '#e53e3e';
    if (propId && !state.savedProperties.includes(propId)) {
      state.savedProperties.push(propId);
      await window.supabase.from('saved_properties').insert({ user_id: session.user.id, property_id: propId });
    }
  } else {
    icon.classList.replace('fa-solid', 'fa-regular');
    icon.style.color = '';
    if (propId) {
      state.savedProperties = state.savedProperties.filter(id => id !== propId);
      await window.supabase.from('saved_properties').delete().eq('property_id', propId).eq('user_id', session.user.id);
    }
  }
  renderSavedView();
}
"@
Replace-Function "function toggleHeart(btn) {" "/*" "$toggleHeartNew`n`n"


$removeSavedNew = @"
async function removeSaved(propId, btn) {
  state.savedProperties = state.savedProperties.filter(id => id !== propId);
  const homeCard = document.querySelector(`#property-list [data-id="` + propId + `"]`);
  if (homeCard) {
    const heartIcon = homeCard.querySelector('button i.fa-solid.fa-heart');
    if (heartIcon) {
      heartIcon.classList.replace('fa-solid', 'fa-regular');
      heartIcon.style.color = '';
    }
  }
  
  const { data: { session } } = await window.supabase.auth.getSession();
  if (session) {
    await window.supabase.from('saved_properties').delete().eq('property_id', propId).eq('user_id', session.user.id);
  }
  
  renderSavedView();
}
"@
Replace-Function "function removeSaved(propId, btn) {" "/*" "$removeSavedNew`n`n"


$persistStateNew = @"
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
# Replace the block for persistence state
$start = $content.IndexOf("function persistState() {")
$end = $content.IndexOf("function showAuthSheet() {")
if ($end -eq -1) { $end = $content.IndexOf("/* `r`n   AUTH LAUNCH SHEET") }
if ($start -gt -1 -and $end -gt $start) {
    $chunk = $content.Substring($start, $end - $start)
    $content = $content.Replace($chunk, "$persistStateNew`n`n")
    Write-Host "Replaced: persistState block"
}

[System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
