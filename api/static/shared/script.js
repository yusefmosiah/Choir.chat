// api/static/shared/script.js
console.log("Shared script loaded.");

document.addEventListener('DOMContentLoaded', () => {
    // --- Simple Fade-in Animation ---
    const fadeInElements = document.querySelectorAll('.fade-in');

    const observerOptions = {
        root: null, // relative to document viewport
        rootMargin: '0px',
        threshold: 0.1 // trigger when 10% of the element is visible
    };

    const observer = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = 1;
                entry.target.style.transform = 'translateY(0)';
                // Optional: stop observing the element once it has faded in
                // observer.unobserve(entry.target);
            } else {
                 // Optional: Reset if you want elements to fade in every time they scroll into view
                 // entry.target.style.opacity = 0;
                 // entry.target.style.transform = 'translateY(20px)';
            }
        });
    }, observerOptions);

    fadeInElements.forEach(el => {
        // Initial state for animation
        el.style.opacity = 0;
        el.style.transform = 'translateY(20px)';
        el.style.transition = 'opacity 0.6s ease-out, transform 0.6s ease-out';
        observer.observe(el);
    });

    // --- Add more animations or interactive elements below ---

});
