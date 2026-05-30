$path = "c:\Users\tuttu\OneDrive\Desktop\index-with-admin-1.html"
$content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

# Replace init() function
$initStart = $content.IndexOf("function init() {")
$initEnd = $content.IndexOf("}", $content.IndexOf("const nightsInput = document.getElementById('booking-nights');"))

if ($initStart -gt -1) {
    $newInit = @"
async function fetchAndRenderData() {
  try {
    const { data: propertiesData, error: propError } = await supabase
      .from('properties')
      .select('*, profiles(full_name)');
    
    if (propError) throw propError;
    
    // Map to frontend expected shape
    const mappedProps = propertiesData.map(dbProp => ({
      id: dbProp.id,
      category: dbProp.category,
      title: dbProp.title,
      subtitle: dbProp.subtitle,
      location: dbProp.location,
      price: dbProp.price,
      rating: dbProp.rating,
      reviews: dbProp.review_count,
      host: dbProp.profiles?.full_name || 'Host',
      description: dbProp.description,
      amenities: dbProp.amenities || [],
      images: dbProp.images || [],
      available: dbProp.is_active
    }));

    PROPERTIES = mappedProps.filter(p => p.category !== 'tour');
    TOUR_PACKAGES = mappedProps.filter(p => p.category === 'tour');
    
    renderProperties();
    renderTourCards();
    
    // If user is logged in, fetch their bookings and saved properties
    const { data: { session } } = await supabase.auth.getSession();
    if (session) {
      await fetchUserData(session.user.id);
    }
  } catch (err) {
    console.error('Error fetching data:', err);
    showToast('Failed to load properties. Please refresh.');
  }
}

async function fetchUserData(userId) {
  try {
    const { data: savedData } = await supabase.from('saved_properties').select('property_id').eq('user_id', userId);
    if (savedData) {
      state.savedProperties = savedData.map(d => d.property_id);
    }

    const { data: bookingData } = await supabase.from('bookings').select('*, properties(*)').eq('guest_id', userId);
    if (bookingData) {
      state.userBookings = bookingData.map(b => ({
        id: b.booking_ref,
        date: b.check_in,
        total: `₹${b.total_amount}`,
        status: b.status,
        propertyName: b.properties?.title
      }));
    }
    
    renderSavedView();
    renderMyBookings();
    
    // Restore heart icons
    if (state.savedProperties.length > 0) {
      state.savedProperties.forEach(id => {
        const card = document.querySelector(`#property-list [data-id="${id}"]`);
        if (card) {
          const icon = card.querySelector('button i.fa-regular.fa-heart');
          if (icon) { icon.classList.replace('fa-regular', 'fa-solid'); icon.style.color = '#e53e3e'; }
        }
      });
    }
  } catch (err) {
    console.error('Error fetching user data:', err);
  }
}

async function init() {
  await fetchAndRenderData();

  supabase.auth.onAuthStateChange(async (event, session) => {
    if (session) {
      state.loggedInUser = {
        username: session.user.user_metadata?.full_name || 'User',
        email: session.user.email,
        id: session.user.id,
        role: session.user.user_metadata?.role || 'customer'
      };
      
      state.avatarIdx = Math.floor(Math.random() * PROFILE_AVATARS.length);
      state.bannerIdx = Math.floor(Math.random() * PROFILE_BANNERS.length);
      
      renderProfileView(state.loggedInUser.username, state.loggedInUser.email);
      
      if (state.loggedInUser.role === 'agent') {
        showView('agent');
        renderAgentBookings();
      }
      
      await fetchUserData(session.user.id);
    } else {
      state.loggedInUser = null;
      state.savedProperties = [];
      state.userBookings = [];
      renderSavedView();
      renderMyBookings();
      setTimeout(showAuthSheet, 420);
    }
  });

  // Seed initial history entry so back-button has a state to return to
  history.replaceState({ view: 'home' }, '', '#home');

  // Set today's date as min for booking date
  const today = new Date().toISOString().split('T')[0];
  const dateInput = document.getElementById('booking-date');
  if (dateInput) dateInput.min = today;

  const nightsInput = document.getElementById('booking-nights');
  if (nightsInput) nightsInput.addEventListener('input', updatePriceSummary);
}
"@
    
    $chunk = $content.Substring($initStart, $initEnd - $initStart + 1)
    $content = $content.Replace($chunk, $newInit)
}

[System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
