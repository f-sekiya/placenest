document.addEventListener("DOMContentLoaded", function () {
  const toggle = document.querySelector('.header__toggle')
  const nav = document.getElementById('primary-navigation')
  if (!toggle || !nav) return

  toggle.addEventListener('click', function (e) {
    const expanded = toggle.getAttribute('aria-expanded') === 'true'
    toggle.setAttribute('aria-expanded', String(!expanded))
    nav.classList.toggle('is-open')
    // update aria-label for clarity
    toggle.setAttribute('aria-label', expanded ? 'メニューを開く' : 'メニューを閉じる')
  })

  // close when clicking outside (mobile)
  document.addEventListener('click', function (e) {
    if (!nav.classList.contains('is-open')) return
    if (toggle.contains(e.target) || nav.contains(e.target)) return
    nav.classList.remove('is-open')
    toggle.setAttribute('aria-expanded', 'false')
    toggle.setAttribute('aria-label', 'メニューを開く')
  })
})
