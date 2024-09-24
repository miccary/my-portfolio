function createShootingStar() {
    const star = document.createElement('div');
    star.classList.add('shooting-star');
    document.querySelector('.sky').appendChild(star);
  
    gsap.fromTo(star, 
        { x: -100, y: -100, opacity: 0 },
        { 
            x: Math.random() * window.innerWidth, 
            y: window.innerHeight + 100, 
            opacity: 1,
            duration: 2,
            ease: 'power2.out',
            onComplete: () => star.remove()  // 动画结束后删除元素
        });
}

// 每隔一段时间生成新的流星
setInterval(createShootingStar, 1000);
