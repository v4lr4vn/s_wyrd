// Wyrd Health HUD — renders the wound-tier bar + WP from server-pushed state.
(function () {
    const hud   = document.getElementById('hud');
    const nameEl = document.getElementById('hud-name');
    const classEl = document.getElementById('hud-class');
    const woundFill = document.getElementById('wound-fill');
    const woundLabel = document.getElementById('wound-label');
    const wpRow = document.getElementById('wp-row');
    const wpFill = document.getElementById('wp-fill');
    const wpText = document.getElementById('wp-text');

    // green (full) -> red (downed)
    function tierColor(frac) {
        const hue = Math.round(120 * frac);          // 120=green .. 0=red
        const a = `hsl(${hue}, 55%, 32%)`;
        const b = `hsl(${hue}, 60%, 46%)`;
        return `linear-gradient(90deg, ${a}, ${b})`;
    }

    function render(d) {
        if (!d || d.show === false) { hud.classList.add('hidden'); return; }
        hud.classList.remove('hidden');

        nameEl.textContent = d.name && d.name.length ? d.name : 'Wyrd Health';
        classEl.textContent = d.class || '';

        const count = d.tierCount || 6;
        const idx = Math.min(Math.max(d.tierIndex || 1, 1), count);
        const frac = (count - idx) / (count - 1);     // 1.0 at Unharmed, 0.0 at Downed
        woundFill.style.width = (frac * 100) + '%';
        woundFill.style.background = tierColor(frac);
        woundLabel.textContent = d.tierLabel || '';
        woundLabel.title = d.tierNote || '';

        if (d.magic && (d.wpMax || 0) > 0) {
            wpRow.classList.remove('hidden');
            const wpFrac = Math.max(0, Math.min(1, (d.wp || 0) / d.wpMax));
            wpFill.style.width = (wpFrac * 100) + '%';
            wpText.textContent = `WP ${d.wp || 0} / ${d.wpMax}`;
        } else {
            wpRow.classList.add('hidden');
        }
    }

    window.addEventListener('message', function (e) {
        const d = e.data || {};
        if (d.action === 'wyrd:pos') {
            hud.style.left = d.x + '%';
            hud.style.top = d.y + '%';
            hud.style.bottom = 'auto';
            hud.style.right = 'auto';
            return;
        }
        if (d.action === 'wyrd:hud') render(d);
    });
})();
