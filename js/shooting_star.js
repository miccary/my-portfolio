// shooting_star.js
function createShootingStar() {
    const star = document.createElement('div');
    star.classList.add('shooting-star');

    // Randomize the position
    star.style.left = `${Math.random() * window.innerWidth}px`;
    star.style.top = `${Math.random() * window.innerHeight}px`;

    document.querySelector('.sky').appendChild(star);

    // Remove the star after its animation is over
    setTimeout(() => {
        star.remove();
    }, 2000); // matches the animation duration
}

// Create a new shooting star every 1 second
setInterval(createShootingStar, 1000);
